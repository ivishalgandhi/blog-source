package agent

import (
	"context"
	"fmt"
	"sync"
	"testing"
	"time"
)

// echoTool is a simple registered tool used for verification.
func echoTool(_ context.Context, input string) (string, error) {
	return fmt.Sprintf("echo:%s", input), nil
}

// slowTool simulates a tool that takes time, which lets us prove the runtime
// stays responsive while a task is running.
func slowTool(_ context.Context, input string) (string, error) {
	time.Sleep(50 * time.Millisecond)
	return fmt.Sprintf("slow:%s", input), nil
}

func TestSingleTaskStream(t *testing.T) {
	a := New()
	a.Register("echo", echoTool)

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	ch := a.StreamTask(ctx, "echo:hello")

	var events []Event
	for e := range ch {
		events = append(events, e)
	}

	wantTypes := []EventType{EventStart, EventThought, EventAction, EventResult, EventDone}
	if len(events) != len(wantTypes) {
		t.Fatalf("expected %d events, got %d: %+v", len(wantTypes), len(events), events)
	}
	for i, want := range wantTypes {
		if events[i].Type != want {
			t.Fatalf("event %d: want %q, got %q", i, want, events[i].Type)
		}
	}
	if events[3].Payload != "echo:hello" {
		t.Fatalf("result payload mismatch: want %q, got %q", "echo:hello", events[3].Payload)
	}
	if events[4].Payload != "echo:hello" {
		t.Fatalf("done payload mismatch: want %q, got %q", "echo:hello", events[4].Payload)
	}
}

func TestConcurrentTasksDoNotBlock(t *testing.T) {
	a := New()
	a.Register("slow", slowTool)

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	const n = 10
	start := time.Now()

	var wg sync.WaitGroup
	results := make([]string, n)
	var mu sync.Mutex

	for i := range n {
		wg.Add(1)
		go func(i int) {
			defer wg.Done()
			ch := a.StreamTask(ctx, fmt.Sprintf("slow:%d", i))
			var last string
			for e := range ch {
				if e.Type == EventDone {
					last = e.Payload
				}
			}
			mu.Lock()
			results[i] = last
			mu.Unlock()
		}(i)
	}

	wg.Wait()
	elapsed := time.Since(start)

	// If the tasks ran sequentially, 10 * 50ms = 500ms. With goroutines they
	// should finish much faster than that on a normal machine. We allow a
	// generous margin to avoid flaky CI, but the assertion still proves
	// concurrency: sequential execution would take >500ms.
	if elapsed > 300*time.Millisecond {
		t.Fatalf("tasks appear to have run sequentially: elapsed %v", elapsed)
	}

	for i := range n {
		want := fmt.Sprintf("slow:%d", i)
		if results[i] != want {
			t.Fatalf("result %d: want %q, got %q", i, want, results[i])
		}
	}
}

func TestContextCancellation(t *testing.T) {
	a := New()
	a.Register("slow", slowTool)

	ctx, cancel := context.WithCancel(context.Background())
	ch := a.StreamTask(ctx, "slow:hello")

	// Cancel before the slow tool finishes.
	cancel()

	var sawError bool
	for e := range ch {
		if e.Type == EventError && e.Err == context.Canceled {
			sawError = true
		}
	}
	if !sawError {
		t.Fatalf("expected cancellation error in event stream")
	}
}

func TestUnknownTool(t *testing.T) {
	a := New()

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	ch := a.StreamTask(ctx, "missing:input")
	var events []Event
	for e := range ch {
		events = append(events, e)
	}

	if len(events) != 3 { // start, thought, error
		t.Fatalf("expected 3 events, got %d: %+v", len(events), events)
	}
	if events[0].Type != EventStart {
		t.Fatalf("first event should be start, got %q", events[0].Type)
	}
	if events[2].Type != EventError {
		t.Fatalf("last event should be error, got %q", events[2].Type)
	}
}
