---
sidebar_position: 1
title: "Python: Scripts vs. Modules with __name__"
description: "How to create dual-purpose Python files that work as both scripts and modules"
---

# Python Scripts vs. Modules: The `__name__` Variable

When you're developing in Python, you'll often encounter the statement `if __name__ == '__main__':` in code examples. This pattern might seem confusing at first, but it's a powerful feature that helps create reusable Python code.

## The Problem: Script vs. Module

Python files can serve two different purposes:

1. **Script** - Run directly to execute a task
2. **Module** - Imported by other Python files to reuse functions and classes

But what happens if you want a file to work both ways? For example, what if you want to:
- Run it directly for testing or standalone functionality
- Import it in another file to reuse its functions

This is where `if __name__ == '__main__'` comes in.

## What `__name__` Actually Is

In Python, every file has a special built-in variable called `__name__`:

- When you **run a file directly** as a script, Python sets `__name__ = '__main__'`
- When you **import a file** as a module, Python sets `__name__ = '<the_filename>'` (without the .py extension)

## Examples to Demonstrate the Difference

Let's create two files to see how this works:

### File 1: `helper.py`

```python
def greet(name):
    """Return a greeting message"""
    return f"Hello, {name}!"

def calculate_square(number):
    """Return the square of a number"""
    return number ** 2

# This code only runs when the file is executed directly
if __name__ == '__main__':
    # Test the functions
    print("Running helper.py as a script!")
    print(greet("Developer"))
    print(f"Square of 5 is {calculate_square(5)}")
    print(f"The value of __name__ is: {__name__}")
else:
    print(f"helper.py has been imported, and __name__ is: {__name__}")
```

### File 2: `main.py`

```python
# Import the helper module
import helper

print("This is main.py")
print(f"In main.py, __name__ is: {__name__}")

# Use the imported functions
name = "Python Learner"
greeting = helper.greet(name)
result = helper.calculate_square(7)

print(greeting)
print(f"The square of 7 is {result}")
```

## Running the Examples

### Scenario 1: Running `helper.py` directly

When you run `helper.py` as a script:

```bash
python helper.py
```

Output:
```
Running helper.py as a script!
Hello, Developer!
Square of 5 is 25
The value of __name__ is: __main__
```

### Scenario 2: Importing `helper.py` into `main.py`

When you run `main.py`, which imports `helper.py`:

```bash
python main.py
```

Output:
```
helper.py has been imported, and __name__ is: helper
This is main.py
In main.py, __name__ is: __main__
Hello, Python Learner!
The square of 7 is 49
```

## Why This Pattern Is Useful

This pattern allows you to:

1. **Create reusable code libraries**: Your functions and classes can be imported without running initialization code.
2. **Include self-testing code**: Add tests in the `if __name__ == '__main__':` block that only run when the file is executed directly.
3. **Create dual-purpose scripts**: Files can serve as both standalone scripts and importable modules.

## Common Use Cases

### Command-Line Tools

```python
def main():
    # Process command line arguments
    # Run the actual program
    pass

if __name__ == '__main__':
    main()
```

### Package Initialization

```python
# mypackage/__init__.py
def initialize():
    # Setup code
    pass

if __name__ == '__main__':
    print("This package isn't meant to be run directly")
```

### Testing

```python
def complex_algorithm(data):
    # Complex logic here
    return result

if __name__ == '__main__':
    # Test cases for the complex_algorithm
    test_data = [1, 2, 3, 4]
    print(complex_algorithm(test_data))
```

## Best Practices

1. **Always use this pattern** for files that might be imported.
2. **Keep the script portion minimal** - consider moving extensive script behavior to a `main()` function.
3. **Document the dual nature** of your file - explain how it can be used both ways.
4. **Include example usage** in the `if __name__ == '__main__':` block.

## Understanding Python's Special Variables

In Python, names surrounded by double underscores (like `__name__`) are special variables with built-in meaning. These are sometimes called "dunder" (double underscore) variables or attributes. Let's explore some of the most important ones:

### Common Special Variables in Python

| Variable | Description | Example |
|----------|-------------|--------|
| `__name__` | Module identifier during import | `'__main__'` or module name |
| `__file__` | Full path to the current file | `'/path/to/script.py'` |
| `__doc__` | Module documentation string | Function or class docstring |
| `__dict__` | Namespace containing symbol table | Dictionary of attributes |
| `__package__` | Package name module belongs to | `'package.subpackage'` |
| `__loader__` | Loader used to load the module | Various loader objects |
| `__spec__` | Module specification | Info used during import |
| `__path__` | List of paths for package | Only in package `__init__.py` |

### Example: Exploring Special Variables

```python
# Save as special_vars.py

"""This module demonstrates Python's special variables."""

if __name__ == '__main__':
    print(f"Module name: {__name__}")
    print(f"File path: {__file__}")
    print(f"Module doc: {__doc__}")
    print(f"Package: {__package__ or 'Not in a package'}")
    
    # Create a class to demonstrate __dict__
    class Demo:
        def __init__(self):
            self.x = 1
            self.y = 2
    
    d = Demo()
    print(f"Object attributes: {d.__dict__}")
```

### Python's Import Mechanism and `__name__`

When Python imports a module, it follows these steps:

1. **Checks if the module is in `sys.modules`** (already imported)
2. **Creates a new module object** if not found
3. **Executes the module code** in the new module's namespace
4. **Sets special variables** like `__name__`, `__file__`, etc.
5. **Returns the module object** to the importer

During this process, Python assigns the actual module name to `__name__`. When running a file directly, however, Python assigns the string `'__main__'` to `__name__` instead, marking it as the entry point.

### Special Variables in Classes

Classes have their own set of special variables and methods:

```python
class Example:
    """Example class docstring."""
    
    def __init__(self, value):
        self.value = value
    
    def __str__(self):
        return f"Example({self.value})"
    
    def __repr__(self):
        return self.__str__()

# Usage
if __name__ == '__main__':
    e = Example(42)
    print(f"Class docstring: {Example.__doc__}")
    print(f"Class name: {Example.__name__}")
    print(f"Class module: {Example.__module__}")
    print(f"Instance representation: {e}")
```

## Summary

Python's special variables like `__name__` provide crucial functionality for the language's module system and object-oriented features. The `if __name__ == '__main__':` pattern is just one example of how these internal mechanisms can be leveraged to create flexible, reusable code.

Understanding these Python internals helps you write more idiomatic code and gain deeper insights into how Python works behind the scenes. Many of Python's most powerful features rely on these special variables and methods.
