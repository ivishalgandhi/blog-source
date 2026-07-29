package main

import (
	"bufio"
	"context"
	"fmt"
	"os"
	"strings"
	"time"

	agent "verify-go-agent"
)

func main() {
	a := agent.New()

	// Register a small toolkit so the user can try different tasks.
	a.Register("echo", func(_ context.Context, input string) (string, error) {
		return fmt.Sprintf("echo: %s", input), nil
	})
	a.Register("upper", func(_ context.Context, input string) (string, error) {
		return strings.ToUpper(input), nil
	})
	a.Register("reverse", func(_ context.Context, input string) (string, error) {
		runes := []rune(input)
		for i, j := 0, len(runes)-1; i < j; i, j = i+1, j-1 {
			runes[i], runes[j] = runes[j], runes[i]
		}
		return string(runes), nil
	})
	a.Register("slow", func(_ context.Context, input string) (string, error) {
		time.Sleep(500 * time.Millisecond)
		return fmt.Sprintf("slow-done: %s", input), nil
	})

	fmt.Println("Mini Go agent — type tasks as tool:input, e.g. echo:hello")
	fmt.Println("Type 'quit' or press Ctrl-D to exit.")
	fmt.Println()

	scanner := bufio.NewScanner(os.Stdin)
	for {
		fmt.Print("> ")
		if !scanner.Scan() {
			break
		}
		line := strings.TrimSpace(scanner.Text())
		if line == "" {
			continue
		}
		if line == "quit" {
			fmt.Println("bye")
			break
		}

		ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
		ch := a.StreamTask(ctx, line)
		for e := range ch {
			switch e.Type {
			case agent.EventStart:
				fmt.Printf("  [start]   %s\n", e.Payload)
			case agent.EventThought:
				fmt.Printf("  [thought] %s\n", e.Payload)
			case agent.EventAction:
				fmt.Printf("  [action]  %s\n", e.Payload)
			case agent.EventResult:
				fmt.Printf("  [result]  %s\n", e.Payload)
			case agent.EventDone:
				fmt.Printf("  [done]    %s\n", e.Payload)
			case agent.EventError:
				fmt.Printf("  [error]   %v\n", e.Err)
			}
		}
		cancel()
		fmt.Println()
	}

	if err := scanner.Err(); err != nil {
		fmt.Fprintf(os.Stderr, "stdin error: %v\n", err)
		os.Exit(1)
	}
}
