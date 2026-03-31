---
id: python-tui-framework
title: Building a TUI Framework in Python
sidebar_label: Python TUI Framework
---

# Building a TUI Framework in Python

A Terminal User Interface (TUI) framework lets you build rich, interactive applications that run entirely in the terminal — with panels, menus, input fields, and keyboard navigation — without needing a graphical desktop environment.

## Why Build a TUI Framework?

- Works over SSH on remote servers
- Lightweight — no GUI dependencies
- Great for developer tooling, dashboards, and admin interfaces
- Runs anywhere Python runs

## Core Concepts

### 1. The Terminal as a Canvas

Terminals support ANSI escape codes to control cursor position, colors, and text formatting. A TUI framework abstracts these into higher-level primitives.

```python
# Move cursor to row 5, column 10
print("\033[5;10H", end="")

# Set foreground color to green
print("\033[32m", end="")

# Reset all attributes
print("\033[0m", end="")
```

### 2. Raw Mode Input

To capture individual keystrokes (without waiting for Enter), switch the terminal to raw mode:

```python
import sys
import tty
import termios

def get_key():
    fd = sys.stdin.fileno()
    old_settings = termios.tcgetattr(fd)
    try:
        tty.setraw(fd)
        ch = sys.stdin.read(1)
    finally:
        termios.tcsetattr(fd, termios.TCSADRAIN, old_settings)
    return ch
```

### 3. Widget Abstraction

Every UI element (a box, a list, a text input) is a widget with a `render()` method and a bounding box.

```python
class Widget:
    def __init__(self, x, y, width, height):
        self.x = x
        self.y = y
        self.width = width
        self.height = height

    def render(self):
        raise NotImplementedError

    def handle_key(self, key):
        pass
```

## Building Blocks

### Screen Buffer

Rather than writing directly to the terminal on every update, maintain a buffer and only flush changes — this prevents flickering.

```python
class Screen:
    def __init__(self, width, height):
        self.width = width
        self.height = height
        self.buffer = [[' '] * width for _ in range(height)]

    def set(self, x, y, char):
        if 0 <= x < self.width and 0 <= y < self.height:
            self.buffer[y][x] = char

    def flush(self):
        output = []
        for row_idx, row in enumerate(self.buffer):
            output.append(f"\033[{row_idx + 1};1H" + ''.join(row))
        print(''.join(output), end='', flush=True)

    def clear(self):
        self.buffer = [[' '] * self.width for _ in range(self.height)]
```

### Box Widget

Draw a bordered box at a given position:

```python
class Box(Widget):
    def __init__(self, x, y, width, height, title=""):
        super().__init__(x, y, width, height)
        self.title = title

    def render(self, screen):
        # Top border
        top = "┌" + ("─" * (self.width - 2)) + "┐"
        if self.title:
            top = "┌ " + self.title + " " + "─" * (self.width - len(self.title) - 4) + "┐"
        screen.set_string(self.x, self.y, top)

        # Side borders
        for i in range(1, self.height - 1):
            screen.set(self.x, self.y + i, "│")
            screen.set(self.x + self.width - 1, self.y + i, "│")

        # Bottom border
        bottom = "└" + ("─" * (self.width - 2)) + "┘"
        screen.set_string(self.x, self.y + self.height - 1, bottom)
```

### List Widget

A scrollable list with keyboard navigation:

```python
class ListWidget(Widget):
    def __init__(self, x, y, width, height, items):
        super().__init__(x, y, width, height)
        self.items = items
        self.selected = 0
        self.scroll_offset = 0

    def handle_key(self, key):
        if key == 'k' or key == '\x1b[A':  # up arrow
            self.selected = max(0, self.selected - 1)
        elif key == 'j' or key == '\x1b[B':  # down arrow
            self.selected = min(len(self.items) - 1, self.selected + 1)

        # Adjust scroll
        visible = self.height - 2
        if self.selected < self.scroll_offset:
            self.scroll_offset = self.selected
        elif self.selected >= self.scroll_offset + visible:
            self.scroll_offset = self.selected - visible + 1

    def render(self, screen):
        visible = self.height - 2
        for i in range(visible):
            idx = i + self.scroll_offset
            if idx >= len(self.items):
                break
            prefix = "> " if idx == self.selected else "  "
            line = (prefix + self.items[idx])[:self.width - 2]
            screen.set_string(self.x + 1, self.y + 1 + i, line)
```

## The Event Loop

The framework's core is a loop that redraws the screen and dispatches keypresses:

```python
import os
import shutil

class App:
    def __init__(self):
        size = shutil.get_terminal_size()
        self.screen = Screen(size.columns, size.lines)
        self.widgets = []
        self.focused = None
        self.running = False

    def add_widget(self, widget):
        self.widgets.append(widget)
        if self.focused is None:
            self.focused = widget

    def run(self):
        self.running = True
        # Hide cursor, clear screen
        print("\033[?25l\033[2J", end="", flush=True)
        try:
            while self.running:
                self.screen.clear()
                for widget in self.widgets:
                    widget.render(self.screen)
                self.screen.flush()

                key = get_key()
                if key == 'q':
                    self.running = False
                elif self.focused:
                    self.focused.handle_key(key)
        finally:
            # Restore cursor
            print("\033[?25h\033[0m", end="", flush=True)
```

## Putting It Together — A File Browser

```python
import os

def main():
    app = App()

    files = os.listdir('.')
    file_list = ListWidget(x=1, y=1, width=40, height=20, items=files)
    frame = Box(x=0, y=0, width=42, height=22, title="File Browser")

    app.add_widget(frame)
    app.add_widget(file_list)
    app.run()

if __name__ == "__main__":
    main()
```

## Using Existing Libraries

Rather than building everything from scratch, these libraries provide solid foundations:

| Library | Description |
|---|---|
| [Textual](https://github.com/Textualize/textual) | Full-featured TUI framework, CSS-like styling |
| [Rich](https://github.com/Textualize/rich) | Beautiful terminal output, tables, progress bars |
| [urwid](http://urwid.org/) | Mature widget library, event loop included |
| [curses](https://docs.python.org/3/library/curses.html) | Standard library, low-level terminal control |
| [prompt_toolkit](https://python-prompt-toolkit.readthedocs.io/) | Advanced input handling, used by IPython |

## Key Takeaways

- ANSI escape codes are the primitive layer — everything builds on these
- Double-buffering prevents screen flicker during redraws
- Raw mode input lets you capture every keypress including arrows and function keys
- Widget trees with a focused widget handle keyboard routing cleanly
- For production use, prefer **Textual** — it handles edge cases (resize, mouse, async) that a from-scratch implementation will struggle with
