package agent

import (
	"context"
	"fmt"
	"strings"
)

// EventType classifies what happened inside a running agent task.
type EventType string

const (
	EventStart   EventType = "start"
	EventThought EventType = "thought"
	EventAction  EventType = "action"
	EventResult  EventType = "result"
	EventDone    EventType = "done"
	EventError   EventType = "error"
)

// Event is a single streaming update from an agent thought-loop.
// This mirrors the StreamEvent channel pattern the article attributes to
// Keen Code: a goroutine emits events into a channel while the REPL/runtime
// stays responsive.
type Event struct {
	Type    EventType
	Payload string
	Err     error
}

// Tool is the type-safe boundary the article highlights: a named function
// with a string input and a string output, registered in the agent.
type Tool func(ctx context.Context, input string) (string, error)

// Agent is a minimal runtime. It owns a tool registry and can run tasks
// in their own goroutine, streaming events back to the caller.
type Agent struct {
	tools map[string]Tool
}

// New creates an empty Agent.
func New() *Agent {
	return &Agent{tools: make(map[string]Tool)}
}

// Register adds a named tool to the registry.
func (a *Agent) Register(name string, t Tool) {
	a.tools[name] = t
}

// StreamTask runs a single task inside a goroutine and returns a read-only
// channel of events. The caller consumes the channel while the runtime stays
// responsive, exactly the pattern described in the article.
func (a *Agent) StreamTask(ctx context.Context, task string) <-chan Event {
	ch := make(chan Event)

	go func() {
		defer close(ch)

		emit := func(e Event) bool {
			select {
			case <-ctx.Done():
				ch <- Event{Type: EventError, Err: ctx.Err()}
				return false
			case ch <- e:
				return true
			}
		}

		if !emit(Event{Type: EventStart, Payload: task}) {
			return
		}

		// Minimal deterministic "reasoning" loop: parse the task as
		// "tool:input" and execute one action. If no tool matches, echo it.
		parts := strings.SplitN(task, ":", 2)
		if len(parts) != 2 {
			emit(Event{Type: EventError, Err: fmt.Errorf("task must be tool:input, got %q", task)})
			return
		}
		toolName, input := parts[0], parts[1]

		if !emit(Event{Type: EventThought, Payload: fmt.Sprintf("plan: use tool %q on %q", toolName, input)}) {
			return
		}

		tool, ok := a.tools[toolName]
		if !ok {
			emit(Event{Type: EventError, Err: fmt.Errorf("unknown tool %q", toolName)})
			return
		}

		if !emit(Event{Type: EventAction, Payload: fmt.Sprintf("%s(%s)", toolName, input)}) {
			return
		}

		result, err := tool(ctx, input)
		if err != nil {
			emit(Event{Type: EventError, Err: err})
			return
		}
		if !emit(Event{Type: EventResult, Payload: result}) {
			return
		}
		emit(Event{Type: EventDone, Payload: result})
	}()

	return ch
}
