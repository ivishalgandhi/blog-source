---
sidebar_position: 4
title: Logging with Decorators in Python
description: A step-by-step tutorial on implementing Python logging with decorators
---

# Logging with Decorators in Python: A Step-by-Step Tutorial

:::info

All source code for this tutorial can be found at https://github.com/ivishalgandhi/python-logging-tutorial-source-code

:::

## Introduction

Logging is a critical skill for Python developers working on production applications. This tutorial will guide you through implementing a robust logging system using Python's built-in `logging` module and decorator patterns. By the end, you'll be able to create reusable logging decorators that can be applied across your codebase.

### What You'll Learn
- How to use Python's `logging` module effectively
- How to create and apply logging decorators
- How to configure logging for different environments
- Best practices for handling failures with logs

### Prerequisites
- Basic knowledge of Python
- Understanding of function decorators
- Python 3.6+ installed on your system

## Step 1: Understanding the Basics of Python Logging

The [`logging` module](https://docs.python.org/3/library/logging.html) is part of Python's standard library and provides a flexible framework for emitting log messages. Before diving into decorators, let's understand why professional developers prefer `logging` over simple `print` statements:

- **Log Levels**: Different severity levels (`DEBUG`, `INFO`, `WARNING`, `ERROR`, `CRITICAL`)
- **Configurability**: Can be configured to output to different destinations (console, files, network)
- **Formatting**: Customizable message formats including timestamps and context information
- **Thread Safety**: Safe for use in multi-threaded applications

## Step 2: Creating a Basic Logging Decorator

Let's start by creating a simple decorator that logs exceptions. This decorator will wrap any function and log errors that occur during execution:

```python
import logging
import functools

# Configure logging with filename and line number
logging.basicConfig(format='%(asctime)s - %(name)s - %(levelname)s - %(module)s - %(filename)s:%(lineno)d - %(message)s')

# Decorator to log errors with function name and module
def log_error(func):
    @functools.wraps(func)
    def wrapper(*args, **kwargs):
        try:
            return func(*args, **kwargs)
        except Exception as e:
            logging.error(f"An error occurred in function {func.__name__} in module {func.__module__} : {repr(e)}") #repr(e) gives a detailed representation of the exception
            raise  # Without this, exceptions would be silently caught
    return wrapper  # Without this, the decorator wouldn't work

# Example showing why raise is important
@log_error
def divide(a, b):
    return a / b

try:
    result = divide(10, 0)  # This raises ZeroDivisionError
except ZeroDivisionError as e:
    # Without raise, this except block would never execute
    logging.error(f"Caught exception: {e}")
```

**Output (in logs):**
```
2025-05-25 18:50:23,103 - root - ERROR - basic-logging-decorator - basic-logging-decorator.py:14 - An error occurred in function divide in module __main__ : ZeroDivisionError('division by zero')
2025-05-25 18:50:23,103 - root - ERROR - basic-logging-decorator - basic-logging-decorator.py:28 - Caught exception: division by zero
```

In the example above, the log output is going to the console (stdout) because we haven't configured any specific log handlers. The Python `logging` module, by default:

1. Creates a root logger (shown as "root" in the log output)
2. Uses a basic `StreamHandler` that sends logs to the console
3. Sets the default level to `WARNING`, which is why our `ERROR` message appears

If you run this code, you'll see both the log message and the print statement in your console:
```
2025-05-25 18:50:23,103 - root - ERROR - basic-logging-decorator - basic-logging-decorator.py:14 - An error occurred in function divide in module __main__ : ZeroDivisionError('division by zero')
2025-05-25 18:50:23,103 - root - ERROR - basic-logging-decorator - basic-logging-decorator.py:28 - Caught exception: division by zero
```

To verify these logs are working:
- Look for the log message in your console/terminal
- For larger applications, you might want to redirect logs to a file (we'll cover this in Step 5)

This logs errors like "division by zero" to help identify issues quickly.

## Step 3: Trying it Yourself

### Step 3.1: Create a new Python file named `basic_logging.py`

Create a new Python file named `basic_logging.py` to test the `log_error` decorator.

### Step 3.2: Copy the decorator code into your file

Copy the `log_error` decorator code into your `basic_logging.py` file.

### Step 3.3: Add a test function that might cause an error

Add a test function that might cause an error, such as the `divide` function shown earlier.

```python
@log_error
def divide(a, b):
    return a / b

try:
    divide(10, 0)
except ZeroDivisionError as e:
    logging.error(f"Caught exception: {e}")
```

### Step 3.4: Run the script and check the output

Run the script and check the output to see the error logged.

**Output (in logs):**
```
2025-05-25 18:50:23,103 - root - ERROR - basic-logging-decorator - basic-logging-decorator.py:14 - An error occurred in function divide in module __main__ : ZeroDivisionError('division by zero')
2025-05-25 18:50:23,103 - root - ERROR - basic-logging-decorator - basic-logging-decorator.py:28 - Caught exception: division by zero
```

The error is automatically logged, showing exactly what happened, while still allowing you to handle the exception normally.

## Step 4: Creating an Advanced Logging Decorator

Next, let's create a more sophisticated decorator that:
- Logs function calls with arguments
- Uses named loggers for better organization
- Allows for customization

```python
import logging
import functools

logging.basicConfig(format='%(asctime)s - %(name)s - %(levelname)s - %(module)s - %(filename)s:%(lineno)d - %(message)s')

def log(logger=None):
    if logger is None:
        logger = logging.getLogger(__name__)

    def decorator(func):
        @functools.wraps(func)
        def wrapper(*args, **kwargs):
            """
            A decorator function that logs debug information when the wrapped function is called
            and logs error information if an exception occurs.

            Args:
                *args: Variable length argument list of the wrapped function
                **kwargs: Arbitrary keyword arguments of the wrapped function
                         # kwargs allows passing key-value pair arguments to the function
                         # Example: function(name="John", age=25)

            Returns:
                The result of the wrapped function execution

            Raises:
                Exception: Re-raises any exception that occurs in the wrapped function
                          after logging the error
            """
            logger.debug(f"Calling {func.__name__} with args: {args}, kwargs: {kwargs}")
            try:
                result = func(*args, **kwargs)
                return result
            except Exception as e:
                logger.error(f"An error occurred in {func.__name__}: {str(e)}")
                raise
        return wrapper
    return decorator

# Configure a named logger
logger = logging.getLogger('my_module')

## Step 4.5: Stacking Multiple Decorators

One powerful feature of Python decorators is the ability to apply multiple decorators to a single function, combining their behaviors. This technique, called decorator stacking or chaining, lets you modularize cross-cutting concerns and apply them selectively.

### How Decorator Stacking Works

When you stack multiple decorators, they are applied from bottom to top (or inside out). For example:

```python
@decorator1
@decorator2
@decorator3
def my_function():
    pass
```

This is equivalent to:

```python
my_function = decorator1(decorator2(decorator3(my_function)))
```

The innermost decorator (`decorator3`) is applied first, and the outermost decorator (`decorator1`) is applied last.

### Example: Combining Logging and Timing Decorators

Let's combine our logging decorator with a timer decorator to track both function calls and their execution time:

```python
import time
import functools
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger('performance')

# Timing decorator
def timer(func):
    @functools.wraps(func)
    def wrapper(*args, **kwargs):
        start_time = time.time()
        result = func(*args, **kwargs)
        end_time = time.time()
        logger.info(f"{func.__name__} took {end_time - start_time:.4f} seconds to execute")
        return result
    return wrapper

# Logging decorator
def log_args(func):
    @functools.wraps(func)
    def wrapper(*args, **kwargs):
        logger.info(f"{func.__name__} called with args: {args} and kwargs: {kwargs}")
        return func(*args, **kwargs)
    return wrapper

# Apply both decorators
@timer
@log_args
def process_data(x, y):
    """Process data with artificial delay"""
    time.sleep(1)  # Simulate processing time
    return x + y

# Test the function
result = process_data(10, 20)
print(f"Result: {result}")
```

Output:
```
INFO:performance:process_data called with args: (10, 20) and kwargs: {}
INFO:performance:process_data took 1.0013 seconds to execute
Result: 30
```

Notice the order of execution:
1. First, the `log_args` decorator logs the function call and arguments
2. Then, the actual function executes
3. Finally, the `timer` decorator logs the execution time

### Advanced Example: Adding Retry Logic

For more robust applications, you might want to combine logging, timing, and retry mechanisms. Here's how you can stack all three decorators:

```python
import time
import functools
import logging
import random

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger('resilient_app')

# Retry decorator
def retry(attempts=3, delay=1):
    def decorator(func):
        @functools.wraps(func)
        def wrapper(*args, **kwargs):
            for attempt in range(1, attempts + 1):
                try:
                    return func(*args, **kwargs)
                except Exception as e:
                    logger.warning(f"Attempt {attempt}/{attempts} failed: {e}")
                    if attempt < attempts:
                        logger.info(f"Retrying in {delay} seconds...")
                        time.sleep(delay)
                    else:
                        logger.error(f"All {attempts} attempts failed")
                        raise
        return wrapper
    return decorator

# Apply all three decorators
@timer
@retry(attempts=3, delay=2)
@log_args
def unstable_operation(success_rate=0.3):
    """An operation that sometimes fails"""
    logger.info("Executing unstable operation...")
    if random.random() > success_rate:
        raise ValueError("Random failure occurred")
    return "Operation completed successfully"

# Test the function
try:
    result = unstable_operation()
    print(f"Result: {result}")
except Exception as e:
    print(f"Operation failed: {e}")
```

This example demonstrates how modular decorators can be combined to create robust, production-ready code with comprehensive logging, timing, and fault tolerance.

### Tips for Effective Decorator Stacking

1. **Consider the order carefully**: The execution flows from the innermost decorator to the outermost one
2. **Use `functools.wraps`**: Always use `@functools.wraps(func)` in each decorator to preserve function metadata
3. **Keep decorators focused**: Each decorator should have a single responsibility
4. **Document the behavior**: Make it clear how the stacked decorators interact
5. **Be mindful of performance**: Each decorator adds some overhead, so only use what you need

By stacking decorators, you can create powerful, reusable patterns that keep your code DRY and maintainable while implementing important cross-cutting concerns like logging, timing, and error handling.

## Step 4.6: Class-Based Decorators for Stateful Logging

While function-based decorators are common, class-based decorators offer additional capabilities, particularly when you need to maintain state across function calls.

### How Class-Based Decorators Work

Class-based decorators leverage Python's `__init__` and `__call__` methods:
- `__init__` receives the decorated function and initializes the decorator
- `__call__` is invoked when the decorated function is called

Here's how to implement a class-based decorator for logging that maintains state:

```python
import logging
import functools

class CountCalls:
    """A decorator that counts and logs the number of times a function is called."""
    
    def __init__(self, func):
        functools.update_wrapper(self, func)  # Preserve function metadata
        self.func = func
        self.counter = 0
    
    def __call__(self, *args, **kwargs):
        self.counter += 1
        logger.info(f"Call #{'{'}self.counter{'}'} to {'{'}self.func.__name__{'}'}")
        return self.func(*args, **kwargs)
    
    def reset_counter(self):
        """Reset the call counter."""
        self.counter = 0
        logger.info(f"Counter for {'{'}self.func.__name__{'}'}  has been reset")

# Apply the class-based decorator
@CountCalls
def process_request(request_id):
    logger.info(f"Processing request {request_id}")
    return f"Request {request_id} processed"

# Test the function
process_request("A001")
process_request("B002")
process_request("C003")
```

Output:
```
INFO:function_stats:Call #1 to process_request
INFO:function_stats:Processing request A001
INFO:function_stats:Call #2 to process_request
INFO:function_stats:Processing request B002
INFO:function_stats:Call #3 to process_request
INFO:function_stats:Processing request C003
```

### Advanced Usage: Accessing Decorator State

A key advantage of class-based decorators is that you can access their state externally:

```python
# Access the counter directly
print(f"Total calls: {'{'}process_request.counter{'}'}")  # Output: Total calls: 3

# We can even reset the counter
process_request.reset_counter()

# And start counting again
process_request("D004")
print(f"Calls after reset: {'{'}process_request.counter{'}'}")  # Output: Calls after reset: 1
```

This approach is especially useful for:

1. **Rate limiting**: Tracking API calls and enforcing limits
2. **Caching**: Maintaining a cache of function results based on arguments
3. **Statistics**: Collecting performance metrics across multiple function calls
4. **Logging patterns**: Identifying execution patterns and potential issues

## Step 4.7: Parameterized Decorators for Flexible Logging

Sometimes you need decorators that can be configured at decoration time. Parameterized decorators allow you to create more flexible logging behaviors.

### Basic Structure of Parameterized Decorators

A parameterized decorator involves three levels of functions:
1. An outer function that accepts the decorator parameters
2. A middle function that accepts the function to decorate
3. An inner wrapper function that handles the actual function execution

```python
import logging
import functools

def conditional_log(enabled=True, log_level=logging.INFO):
    """A decorator that conditionally logs function calls."""
    
    def decorator(func):
        @functools.wraps(func)
        def wrapper(*args, **kwargs):
            if enabled:
                if args and kwargs:
                    logger.log(log_level, f"{func.__name__} called with args: {args} and kwargs: {kwargs}")
                elif args:
                    logger.log(log_level, f"{func.__name__} called with args: {args}")
                elif kwargs:
                    logger.log(log_level, f"{func.__name__} called with kwargs: {kwargs}")
                else:
                    logger.log(log_level, f"{func.__name__} called with no arguments")
            return func(*args, **kwargs)
        return wrapper
    return decorator

# Apply with default parameters (enabled=True, log_level=INFO)
@conditional_log()
def process_data(data):
    return f"Processed {data}"

# Apply with custom parameters
@conditional_log(enabled=False)
def silent_function(data):
    return f"Silently processed {data}"

@conditional_log(log_level=logging.DEBUG)
def debug_function(data):
    return f"Debug processed {data}"
```

### Real-World Example: Role-Based Access Control with Logging

Here's a practical example for a web application that combines access control and logging:

```python
import logging
import functools
from datetime import datetime

# Simulated current user context
user_context = {
    "user_id": "user_123",
    "roles": ["user", "editor"],
    "session_id": "abc-xyz-123"
}

def require_role(role, log_access_attempts=True):
    """A decorator that controls access based on user role and logs attempts."""
    
    def decorator(func):
        @functools.wraps(func)
        def wrapper(*args, **kwargs):
            # Check if user has the required role
            has_permission = role in user_context["roles"]
            
            # Log the access attempt if configured
            if log_access_attempts:
                timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
                if has_permission:
                    logger.info(f"[{'{'}timestamp{'}'}] User {'{'}user_context['user_id']{'}'}  GRANTED access to {'{'}func.__name__{'}'}") 
                else:
                    logger.warning(f"[{'{'}timestamp{'}'}] User {'{'}user_context['user_id']{'}'}  DENIED access to {'{'}func.__name__{'}'}  (requires {'{'}role{'}'})")
            
            # Either execute the function or raise an exception
            if has_permission:
                return func(*args, **kwargs)
            else:
                raise PermissionError(f"Access denied: {'{'}func.__name__{'}'}  requires {'{'}role{'}'}  role")
        
        return wrapper
    
    return decorator

# Regular user access - will succeed
@require_role("user")
def view_content(content_id):
    return f"Viewing content {content_id}"

# Admin access - will fail with our simulated user
@require_role("admin", log_access_attempts=True)
def delete_content(content_id):
    return f"Deleted content {content_id}"

# Test the functions
try:
    print(view_content("article-123"))
    print(delete_content("article-123"))
except PermissionError as e:
    print(f"Error: {e}")
```

Output:
```
INFO:security:[2025-05-27 22:47:05] User user_123 GRANTED access to view_content
Viewing content article-123
WARNING:security:[2025-05-27 22:47:05] User user_123 DENIED access to delete_content (requires admin)
Error: Access denied: delete_content requires admin role
```

This example demonstrates how parameterized decorators can provide flexible, configurable behaviors that enhance your application's logging and security capabilities.

### Benefits of Parameterized Decorators for Logging

1. **Configurable logging levels**: Adjust log verbosity based on environment or function importance
2. **Conditional logging**: Enable/disable logging based on context
3. **Custom log formats**: Specify different formats for different functions
4. **Integration with security**: Combine logging with access control
5. **Environment awareness**: Different logging behaviors for development, testing, and production

By mastering parameterized decorators, you can create a highly adaptable logging system that meets various requirements across your application.
logger.setLevel(logging.DEBUG) # Set the logger to debug level for both debug and error messages

# Create a console handler to output logs to the console

handler = logging.StreamHandler()  # Output to console
formatter = logging.Formatter('%(asctime)s [%(levelname)s] %(name)s: %(message)s')  # Format with timestamp
handler.setFormatter(formatter)
logger.addHandler(handler)

@log(logger=logger)
def divide(a, b):
    return a / b
try:
    divide(4, 0)
except ZeroDivisionError as e:
    logger.error(f"Caught an exception: {'{'} e {'}'}")


```

```bash
2025-05-26 06:24:51,419 [ERROR] my_module: An error occurred in divide: division by zero
2025-05-26 06:24:51,419 - my_module - ERROR - advance_logging - advance_logging.py:18 - An error occurred in divide: division by zero
2025-05-26 06:24:51,419 [ERROR] my_module: Caught an exception: {'{'} e {'}'} division by zero
2025-05-26 06:24:51,419 - my_module - ERROR - advance_logging - advance_logging.py:37 - Caught an exception: {'{'} e {'}'} division by zero
```

This advanced decorator logs both function calls with their arguments (at DEBUG level) and any exceptions (at ERROR level), providing more context for debugging.

## Step 5: Setting Up Centralized Logging Configuration

As your application grows, you'll want to centralize logging configuration for consistency across modules. In this step, we'll set up a reusable configuration system.

### Step 5.1: Create a configuration file

Create a new file named `logging_config.py` with the following dictionary-based configuration:

```python
import logging.config

LOGGING_CONFIG = {
    'version': 1,
    'disable_existing_loggers': False,  # Important: keeps existing loggers active
    'formatters': {
        'standard': {
            'format': '%(asctime)s [%(levelname)s] %(name)s: %(message)s'
        },
        'json': {
            '()': 'pythonjsonlogger.jsonlogger.JsonFormatter',
            'format': '%(asctime)s %(levelname)s %(name)s %(message)s %(pathname)s %(lineno)d'
        },
    },
    'handlers': {
        'console': {
            'level': 'INFO',
            'formatter': 'standard',
            'class': 'logging.StreamHandler',
            'stream': 'ext://sys.stdout'
        },
        'file': {
            'level': 'DEBUG',
            'formatter': 'json',
            'class': 'logging.handlers.RotatingFileHandler',
            'filename': 'application.log',
            'maxBytes': 10485760,  # 10MB
            'backupCount': 5
        },
    },
    'loggers': {
        '': {  # Root logger
            'handlers': ['console', 'file'],
            'level': 'DEBUG',
            'propagate': True
        },
        'my_module': {  # Module-specific logger
            'handlers': ['file'],
            'level': 'DEBUG',
            'propagate': False  # Won't propagate to root logger
        },
    }
}

logging.config.dictConfig(LOGGING_CONFIG)
```

### Step 5.2: Apply the configuration

Add this code to your `logging_config.py` file to apply the configuration:

```python
def setup_logging():
    logging.config.dictConfig(LOGGING_CONFIG)
    logging.info("Logging configured successfully")

# Call this function at the start of your application
if __name__ == "__main__":
    setup_logging()
```

### Step 5.3: Alternative - File-based configuration

For larger projects, you might prefer to store your configuration in a separate file:

```python
import logging.config

def setup_file_based_logging():
    # Load configuration from a file
    logging.config.fileConfig('logging.conf', disable_existing_loggers=False)
    logging.info("Logging configured from file successfully")
```

This centralized approach ensures consistent logging across all modules in your application.

## Step 6: Troubleshooting with Logs

One of the most valuable aspects of logging is troubleshooting issues in production. Let's walk through the process of using logs to diagnose problems.

### Step 6.1: Locate your log files

When an issue occurs, first locate your log files:

- **For local development**: Check the file specified in your handler (e.g., `application.log`)
- **For production systems**: Access logs via centralized platforms like [ELK Stack](https://www.elastic.co/what-is/elk-stack) or [Splunk](https://www.splunk.com/)

### Step 6.2: Filter logs to find errors

Use these techniques to identify issues:

- Filter for `ERROR` or `CRITICAL` level messages to find serious problems
- Use timestamps to trace the sequence of events leading to the failure
- Examine stack traces for detailed exception information

### Step 6.3: Analyze the problem

Once you've identified error messages:

- Use logged function calls and arguments to reproduce the issue
- Look for patterns or recurring errors that might indicate systemic problems
- Use structured logs (JSON format) to programmatically analyze trends

### Step 6.4: Set up real-time monitoring

For critical applications, implement real-time log monitoring:

- Configure tools like ELK Stack, Splunk, or [SigNoz](https://signoz.io/) for live monitoring
- Set up alerts for critical log levels to receive immediate notifications

### Step 6.5: Practice with a simulated error

Let's practice troubleshooting by analyzing logs from a division by zero error:

```
2025-05-25 06:17:00 [DEBUG] my_module: Calling divide with args: (10, 0), kwargs: {}
2025-05-25 06:17:00 [ERROR] my_module: An error occurred in divide: division by zero
```

From these logs, we can identify:
- The function that failed (`divide`)
- The problematic input values (`10` and `0`)
- The exact error (`division by zero`)
- The time when it occurred

This information allows you to quickly identify and fix the issue (in this case, adding validation to prevent division by zero).

## Step 7: Adding Context to Your Logs

To make logs more useful, you can add additional context information. In this step, we'll create a decorator that adds contextual data to each log message.

### Step 7.1: Create a contextual logging decorator

Create a new file named `contextual_logging.py` with this decorator that adds context to log messages:

```python
import logging
import functools

def log_with_context(logger=None):
    if logger is None:
        logger = logging.getLogger(__name__)

    def decorator(func):
        @functools.wraps(func)
        def wrapper(*args, **kwargs):
            # Add context to all log messages from this function
            context = {
                'function': func.__name__,
                'module': func.__module__,
                'user_id': kwargs.get('user_id', 'anonymous')
            }

            # Create a logger adapter with extra context
            adapter = logging.LoggerAdapter(logger, context)

            try:
                result = func(*args, **kwargs)
                adapter.info(f"Function executed successfully")
                return result
            except Exception as e:
                adapter.error(f"Function failed: {str(e)}", exc_info=True)
                raise
        return wrapper
    return decorator
```

### Step 7.2: Try out contextual logging

Test the decorator with a simple function that uses the context:

```python
# Configure the logger
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(name)s: [%(function)s] [User: %(user_id)s] %(message)s'
)

# Apply the decorator
@log_with_context()
def process_user_data(data, user_id="unknown"):
    # Some processing
    return data

# Call the function
process_user_data({"name": "John"}, user_id="user123")
```

You'll see output like:
```
2025-05-25 06:30:00 [INFO] __main__: [process_user_data] [User: user123] Function executed successfully
```

## Step 8: Handling Thread Safety in Logging

When working with multi-threaded applications, you need to ensure your logging is thread-safe.

### Step 8.1: Use thread-local storage for request-specific data

Create a file named `thread_safe_logging.py`:

```python
import logging
import threading

# Thread-local storage for request-specific data
thread_local = threading.local()

class RequestContextFilter(logging.Filter):
    """Add request-specific information to log records."""
    
    def filter(self, record):
        if hasattr(thread_local, 'request_id'):
            record.request_id = thread_local.request_id
        else:
            record.request_id = 'no-request-id'
        return True
```

### Step 8.2: Configure your logger with the filter

```python
# Setup logging with the filter
logger = logging.getLogger('app')
logger.setLevel(logging.INFO)

# Add the custom filter
request_filter = RequestContextFilter()
logger.addFilter(request_filter)

# Add a handler
handler = logging.StreamHandler()
formatter = logging.Formatter('%(asctime)s [%(levelname)s] [%(request_id)s] %(message)s')
handler.setFormatter(formatter)
logger.addHandler(handler)
```

### Step 8.3: Use in a multi-threaded context

```python
def process_request(request_number):
    # Set request ID in thread-local storage
    thread_local.request_id = f"req-{request_number}"
    
    logger.info(f"Processing request {request_number}")
    # Processing logic here
    logger.info(f"Completed request {request_number}")

# Create threads to simulate concurrent requests
import concurrent.futures

with concurrent.futures.ThreadPoolExecutor(max_workers=3) as executor:
    executor.map(process_request, range(5))
```

## Step 9: Implementing Best Practices

Let's create a checklist of best practices to follow in your logging implementation:

### Step 9.1: Use named loggers

```python
# Instead of using the root logger
logging.info("Message")  # Not recommended for larger applications

# Use a named logger specific to the module
logger = logging.getLogger(__name__)  # Best practice
logger.info("Message")
```

### Step 9.2: Set appropriate log levels

```python
# Development environment
logger.setLevel(logging.DEBUG)  # Capture detailed diagnostic information

# Production environment
logger.setLevel(logging.INFO)  # Only capture significant events
```

### Step 9.3: Protect sensitive data

```python
# WRONG - exposing sensitive information
logger.info(f"User authenticated with password: {'{'} password {'}'}")  

# RIGHT - logging the event without exposing secrets
logger.info(f"User {'{'} username {'}'} authenticated successfully")
```

### Step 9.4: Implement log rotation

```python
from logging.handlers import RotatingFileHandler

handler = RotatingFileHandler(
    'application.log',
    maxBytes=10*1024*1024,  # 10MB
    backupCount=5            # Keep 5 backup files
)
logger.addHandler(handler)
```

## Step 10: Integration with Web Frameworks

Logging becomes even more powerful when integrated with web frameworks.

### Step 10.1: Flask integration

**Scenario covered: Web application logging with request context**

Create a file named `flask_logging_example.py`:

```python
from flask import Flask, request, g
import logging
import uuid
import functools

app = Flask(__name__)

# Setup logging
logger = logging.getLogger('flask_app')
logger.setLevel(logging.INFO)
handler = logging.StreamHandler()
formatter = logging.Formatter('%(asctime)s [%(levelname)s] %(name)s: %(message)s')
handler.setFormatter(formatter)
logger.addHandler(handler)

# Create a logging decorator
def log_route(f):
    @functools.wraps(f)
    def decorated_function(*args, **kwargs):
        logger.info(f"Route {'{'} request.path {'}'} called")
        return f(*args, **kwargs)
    return decorated_function

# Add request ID middleware
@app.before_request
def before_request():
    g.request_id = request.headers.get('X-Request-ID', str(uuid.uuid4()))
    # Make request ID available to logger
    logger.filter(lambda record: setattr(record, 'request_id', g.request_id) or True)

# Apply decorator to routes
@app.route('/')
@log_route
def index():
    logger.info("Processing index request")
    return "Hello World"

if __name__ == '__main__':
    app.run(debug=True)
```

### Step 10.2: Django integration

**Scenario covered: Distributed web applications with request tracking**

For Django applications, create a file named `django_logging_middleware.py`:

```python
# middleware.py
import logging
import uuid

logger = logging.getLogger('django_app')

class RequestLoggingMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        # Generate or extract request ID
        request_id = request.headers.get('X-Request-ID', str(uuid.uuid4()))
        request.request_id = request_id
        
        # Log the request
        logger.info(f"Request {'{'} request.method {'}'} {'{'} request.path {'}'}", 
                   extra={'request_id': request_id})
        
        # Process the request
        response = self.get_response(request)
        
        # Add request ID to response
        response['X-Request-ID'] = request_id
        
        # Log the response
        logger.info(f"Response status: {'{'} response.status_code {'}'}",
                   extra={'request_id': request_id})
        
        return response
```

## Step 11: Containerized Logging

**Scenario covered: Logging in Docker containers**

When running Python applications in containers, logging requires special consideration. Let's implement logging for containerized applications.

### Step 11.1: Configure logging to stdout/stderr

Create a file named `container_logging.py`:

```python
import logging
import sys
import json

# When running in containers, log to stdout/stderr instead of files
def setup_container_logging():
    # Create a custom JSON formatter
    class JsonFormatter(logging.Formatter):
        def format(self, record):
            log_record = {
                "timestamp": self.formatTime(record, self.datefmt),
                "level": record.levelname,
                "message": record.getMessage(),
                "logger": record.name
            }
            
            # Add exception info if present
            if record.exc_info:
                log_record["exception"] = self.formatException(record.exc_info)
                
            # Add extra fields from record
            for key, value in record.__dict__.items():
                if key not in ["args", "asctime", "created", "exc_info", "exc_text", 
                              "filename", "funcName", "id", "levelname", "levelno", 
                              "lineno", "module", "msecs", "message", "msg", 
                              "name", "pathname", "process", "processName", 
                              "relativeCreated", "stack_info", "thread", "threadName"]:
                    log_record[key] = value
                    
            return json.dumps(log_record)
    
    # Configure root logger
    root_logger = logging.getLogger()
    root_logger.setLevel(logging.INFO)
    
    # Remove existing handlers
    for handler in root_logger.handlers:
        root_logger.removeHandler(handler)
    
    # Add stdout handler for INFO and below
    stdout_handler = logging.StreamHandler(sys.stdout)
    stdout_handler.setLevel(logging.DEBUG)
    stdout_handler.addFilter(lambda record: record.levelno <= logging.INFO)
    stdout_handler.setFormatter(JsonFormatter())
    
    # Add stderr handler for WARNING and above
    stderr_handler = logging.StreamHandler(sys.stderr)
    stderr_handler.setLevel(logging.WARNING)
    stderr_handler.setFormatter(JsonFormatter())
    
    # Add handlers to root logger
    root_logger.addHandler(stdout_handler)
    root_logger.addHandler(stderr_handler)
    
    return root_logger
```

### Step 11.2: Create a Dockerfile

Create a `Dockerfile` to package your application:

```Dockerfile
FROM python:3.9-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# Use environment variables for configuration
ENV LOG_LEVEL=INFO

# Run the application
CMD ["python", "app.py"]
```

### Step 11.3: Modify your application for container-friendly logging

Update your application code to use environment variables for configuration:

```python
# app.py
import os
import logging
from container_logging import setup_container_logging

# Setup container-friendly logging
logger = setup_container_logging()

# Get log level from environment variable
log_level = os.environ.get("LOG_LEVEL", "INFO").upper()
logger.setLevel(getattr(logging, log_level))

@log_error
def my_function():
    logger.info("This is a containerized application")
    # Your application code here

if __name__ == "__main__":
    logger.info("Application starting up")
    my_function()
    logger.info("Application shutting down")
```

## Step 12: Kubernetes Logging

**Scenario covered: Structured logging in Kubernetes environments**

When running applications in Kubernetes, effective logging becomes even more important due to the distributed nature of the platform.

### Step 12.1: Configure logging for Kubernetes

Create a file named `k8s_logging.py` with Kubernetes-specific enhancements:

```python
import logging
import json
import os
import socket

def setup_k8s_logging():
    # Create a Kubernetes-aware formatter
    class KubernetesJsonFormatter(logging.Formatter):
        def format(self, record):
            # Basic log record fields
            log_record = {
                "timestamp": self.formatTime(record, self.datefmt),
                "level": record.levelname,
                "message": record.getMessage(),
                "logger": record.name,
                
                # Kubernetes metadata
                "kubernetes": {
                    "pod_name": os.environ.get("HOSTNAME", socket.gethostname()),
                    "namespace": os.environ.get("K8S_NAMESPACE", "default"),
                    "container_name": os.environ.get("K8S_CONTAINER_NAME", "app"),
                    "node_name": os.environ.get("K8S_NODE_NAME", "unknown")
                }
            }
            
            # Add service name if available
            service_name = os.environ.get("SERVICE_NAME")
            if service_name:
                log_record["service"] = service_name
                
            # Add trace ID if available (for distributed tracing)
            trace_id = getattr(record, 'trace_id', None)
            if trace_id:
                log_record["trace_id"] = trace_id
                
            # Include exception info
            if record.exc_info:
                log_record["exception"] = {
                    "type": record.exc_info[0].__name__,
                    "message": str(record.exc_info[1]),
                    "traceback": traceback.format_exception(*record.exc_info)
                }
                
            # Add any extra attributes from the LogRecord
            for key, value in record.__dict__.items():
                if key not in ("args", "asctime", "created", "exc_info", "exc_text", 
                              "filename", "funcName", "id", "levelname", "levelno", 
                              "lineno", "module", "msecs", "message", "msg", "name", 
                              "pathname", "process", "processName", "relativeCreated", 
                              "stack_info", "thread", "threadName", "props"):
                    log_record[key] = value
        
            return json.dumps(log_record)
    
    # Configure the logger
    logger = logging.getLogger()
    logger.setLevel(logging.INFO)
    
    # Clear existing handlers
    for handler in logger.handlers:
        logger.removeHandler(handler)
        
    # Add stdout handler with JSON formatting
    handler = logging.StreamHandler()
    handler.setFormatter(KubernetesJsonFormatter())
    logger.addHandler(handler)
    
    return logger
```

### Step 12.2: Create decorators for Kubernetes-aware logging

```python
import functools
import time
import uuid

def k8s_log(logger=None):
    if logger is None:
        logger = logging.getLogger(__name__)
        
    def decorator(func):
        @functools.wraps(func)
        def wrapper(*args, **kwargs):
            # Generate a unique ID for this operation
            operation_id = str(uuid.uuid4())
            
            # Capture start time
            start_time = time.time()
            
            # Log the start of the operation
            logger.info(f"Starting operation {'{'}func.__name__{'}'}", 
                       extra={"operation_id": operation_id})
            
            try:
                # Execute the function
                result = func(*args, **kwargs)
                
                # Log successful completion
                execution_time = time.time() - start_time
                logger.info(f"Operation {'{'}func.__name__{'}'} completed successfully",
                           extra={"operation_id": operation_id})
                return result
            except Exception as e:
                # Log the failure
                execution_time = time.time() - start_time
                logger.error(f"Operation {'{'}func.__name__{'}'} failed: {'{'} str(e) {'}'}",
                            extra={"operation_id": operation_id},
                            exc_info=True)
                raise
        return wrapper
    return decorator
```

### Step 12.3: Kubernetes deployment configuration

Create a Kubernetes deployment YAML with appropriate logging configuration:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: python-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: python-app
  template:
    metadata:
      labels:
        app: python-app
    spec:
      containers:
      - name: app
        image: your-registry/python-app:latest
        env:
        - name: LOG_LEVEL
          value: "INFO"
        - name: K8S_NAMESPACE
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
        - name: K8S_NODE_NAME
          valueFrom:
            fieldRef:
              fieldPath: spec.nodeName
        - name: K8S_CONTAINER_NAME
          value: "app"
        - name: SERVICE_NAME
          value: "python-app"
        resources:
          limits:
            memory: "256Mi"
            cpu: "500m"
          requests:
            memory: "128Mi"
            cpu: "250m"
        volumeMounts:
        - name: log-volume
          mountPath: /app/logs
      # Sidecar container for log forwarding
      - name: log-forwarder
        image: fluent/fluent-bit:latest
        volumeMounts:
        - name: log-volume
          mountPath: /logs
          readOnly: true
        - name: fluent-bit-config
          mountPath: /fluent-bit/etc/
      volumes:
      - name: log-volume
        emptyDir: {}
      - name: fluent-bit-config
        configMap:
          name: fluent-bit-config
```

## Step 13: Distributed Tracing with Logging

**Scenario covered: Microservices logging across Kubernetes pods**

In a microservices architecture running in Kubernetes, request tracing becomes critical.

### Step 13.1: Create a tracing decorator

```python
import functools
import uuid
import logging
from opentelemetry import trace
from opentelemetry.trace.propagation.tracecontext import TraceContextTextMapPropagator

# Initialize tracer
tracer = trace.get_tracer(__name__)

def trace_request(logger=None):
    if logger is None:
        logger = logging.getLogger(__name__)
        
    def decorator(func):
        @functools.wraps(func)
        def wrapper(*args, **kwargs):
            # Get current span context or create a new one
            current_span = trace.get_current_span()
            span_context = current_span.get_span_context()
            
            # If no span context exists, create a new trace ID
            if not span_context.is_valid:
                trace_id = str(uuid.uuid4())
            else:
                trace_id = format(span_context.trace_id, '032x')
            
            # Log with trace ID
            with tracer.start_as_current_span(func.__name__) as span:
                logger.info(f"Executing {'{'}func.__name__{'}'}", 
                           extra={"trace_id": trace_id})
                
                try:
                    # Execute the function
                    result = func(*args, **kwargs)
                    span.set_status(trace.StatusCode.OK)
                    return result
                except Exception as e:
                    span.set_status(trace.StatusCode.ERROR)
                    logger.error(f"Error in {'{'}func.__name__{'}'}: {'{'} str(e) {'}'}", 
                               extra={"trace_id": trace_id}, 
                               exc_info=True)
                    raise
        return wrapper
    return decorator
```

### Step 13.2: Set up service-to-service communication with trace propagation

```python
import requests
from opentelemetry.trace.propagation.tracecontext import TraceContextTextMapPropagator

def call_service(service_url, endpoint, data=None, method="GET"):
    # Create a carrier for the trace context
    carrier = {}
    
    # Inject the current trace context into the carrier
    TraceContextTextMapPropagator().inject(carrier)
    
    # Add the trace context to request headers
    headers = {"Content-Type": "application/json"}
    headers.update(carrier)
    
    # Make the request with the propagated context
    if method == "GET":
        response = requests.get(f"{service_url}/{endpoint}", headers=headers)
    elif method == "POST":
        response = requests.post(f"{service_url}/{endpoint}", json=data, headers=headers)
    
    return response.json()
```

### Step 13.3: Kubernetes configuration for log aggregation

Create a ConfigMap for Fluentd to collect and forward logs:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: fluent-bit-config
data:
  fluent.conf: |
    <source>
      @type tail
      path /var/log/containers/*.log
      pos_file /var/log/fluent-bit-containers.log.pos
      tag kubernetes.*
      read_from_head true
      <parse>
        @type json
        time_format %Y-%m-%dT%H:%M:%S.%NZ
      </parse>
    </source>
    
    <filter kubernetes.**>
      @type kubernetes_metadata
      kubernetes_url https://kubernetes.default.svc
      bearer_token_file /var/run/secrets/kubernetes.io/serviceaccount/token
      ca_file /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
    </filter>
    
    <match kubernetes.**>
      @type elasticsearch
      host elasticsearch-logging
      port 9200
      logstash_format true
      logstash_prefix k8s
      <buffer>
        @type file
        path /var/log/fluent-bit-buffers/kubernetes.system.buffer
        flush_mode interval
        retry_type exponential_backoff
        flush_thread_count 2
        flush_interval 5s
        retry_forever true
        retry_max_interval 30
        chunk_limit_size 2M
        queue_limit_length 8
        overflow_action block
      </buffer>
    </match>
```

## Step 14: Kubernetes Logging Best Practices

**Scenario covered: Production-ready logging for Kubernetes-deployed applications**

Here are essential best practices for implementing logging in Kubernetes environments:

### Step 14.1: Use structured logging consistently

```python
# All log messages should be structured (JSON)
# Example with structured context
def process_order(order_data):
    logger.info("Processing order", extra={
        "order_id": order_data.get("id"),
        "customer_id": order_data.get("customer_id"),
        "items_count": len(order_data.get("items", [])),
        "total_amount": order_data.get("total"),
        "operation": "order_processing"
    })
```

### Step 14.2: Implement health checks that verify logging

Create a health check endpoint that verifies your logging pipeline is functioning properly:

```python
from flask import Flask, jsonify
import logging
import time

app = Flask(__name__)
logger = logging.getLogger()

@app.route('/health')
def health_check():
    # Verify logging is working
    check_id = f"health-{int(time.time())}"
    logger.info("Health check executed", extra={"check_id": check_id})
    
    return jsonify({"status": "healthy", "logging": "verified", "check_id": check_id})
```

### Step 14.3: Use a sidecar pattern for log collection

Create a Kubernetes deployment that uses a sidecar container for log collection:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: python-app-with-logging
spec:
  replicas: 3
  selector:
    matchLabels:
      app: python-app
  template:
    metadata:
      labels:
        app: python-app
    spec:
      containers:
      - name: app
        image: your-registry/python-app:latest
        env:
        - name: LOG_LEVEL
          value: "INFO"
        - name: K8S_NAMESPACE
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
        - name: K8S_NODE_NAME
          valueFrom:
            fieldRef:
              fieldPath: spec.nodeName
        - name: K8S_CONTAINER_NAME
          value: "app"
        - name: SERVICE_NAME
          value: "python-app"
        resources:
          limits:
            memory: "256Mi"
            cpu: "500m"
          requests:
            memory: "128Mi"
            cpu: "250m"
        volumeMounts:
        - name: log-volume
          mountPath: /app/logs
      # Sidecar container for log forwarding
      - name: log-forwarder
        image: fluent/fluent-bit:latest
        volumeMounts:
        - name: log-volume
          mountPath: /logs
          readOnly: true
        - name: fluent-bit-config
          mountPath: /fluent-bit/etc/
      volumes:
      - name: log-volume
        emptyDir: {}
      - name: fluent-bit-config
        configMap:
          name: fluent-bit-config
```

### Step 14.4: Configure log rotation in Kubernetes

Set up log rotation to prevent pods from running out of disk space:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: log-rotation-config
data:
  logrotate.conf: |
    /app/logs/*.log {
      daily
      rotate 7
      compress
      delaycompress
      missingok
      notifempty
      create 0640 root root
      size 10M
    }
```

## Step 15: Setting up ELK Stack with Docker

**Scenario covered: Centralized logging with ELK Stack for distributed applications**

The ELK Stack (Elasticsearch, Logstash, Kibana) is one of the most popular logging solutions for distributed applications. In this step, we'll set up an ELK stack using Docker and integrate it with our Python application.

### Step 15.1: Create a Docker Compose configuration

Create a directory for your ELK stack configuration:

```bash
mkdir -p elk-stack/logstash/pipeline
cd elk-stack
```

Create a `docker-compose.yml` file with the following content:

```yaml
version: '3.8'

services:
  # Elasticsearch
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:7.14.0
    container_name: elasticsearch
    environment:
      - discovery.type=single-node
      - "ES_JAVA_OPTS=-Xms512m -Xmx512m"
    ulimits:
      memlock:
        soft: -1
        hard: -1
    ports:
      - "9200:9200"
    networks:
      - elk
    volumes:
      - elasticsearch-data:/usr/share/elasticsearch/data
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:9200"]
      interval: 30s
      timeout: 10s
      retries: 5

  # Logstash
  logstash:
    image: docker.elastic.co/logstash/logstash:7.14.0
    container_name: logstash
    ports:
      - "5000:5000/tcp"
      - "5000:5000/udp"
      - "9600:9600"
    networks:
      - elk
    volumes:
      - ./logstash/pipeline:/usr/share/logstash/pipeline
    depends_on:
      - elasticsearch

  # Kibana
  kibana:
    image: docker.elastic.co/kibana/kibana:7.14.0
    container_name: kibana
    ports:
      - "5601:5601"
    networks:
      - elk
    depends_on:
      - elasticsearch

networks:
  elk:
    driver: bridge

volumes:
  elasticsearch-data:
    driver: local
```

### Step 15.2: Start the ELK Stack

Start the ELK stack with Docker Compose:

```bash
docker-compose up -d
```

### Step 15.3: Configure Python logging to send logs to ELK

Create a new file `elk_logging.py` to configure Python logging for ELK:

```python
import logging
import socket
import json
import traceback
from logging.handlers import SocketHandler
import datetime

class ELKLogstashFormatter(logging.Formatter):
    def __init__(self, service_name):
        super(ELKLogstashFormatter, self).__init__()
        self.service_name = service_name
        self.hostname = socket.gethostname()
    
    def format(self, record):
        log_record = {}
        
        # Standard fields
        log_record['timestamp'] = datetime.datetime.utcfromtimestamp(record.created).isoformat() + 'Z'
        log_record['level'] = record.levelname
        log_record['host'] = self.hostname
        log_record['service'] = self.service_name
        log_record['message'] = record.getMessage()
        log_record['logger'] = record.name
        
        # Add exception info
        if record.exc_info:
            log_record['exception'] = {
                'type': record.exc_info[0].__name__,
                'message': str(record.exc_info[1]),
                'traceback': traceback.format_exception(*record.exc_info)
            }
        
        # Add extra fields
        if hasattr(record, 'props'):
            log_record.update(record.props)
        
        # Add any extra attributes from the LogRecord
        for key, value in record.__dict__.items():
            if key not in ('args', 'asctime', 'created', 'exc_info', 'exc_text', 
                           'filename', 'funcName', 'id', 'levelname', 'levelno', 
                           'lineno', 'module', 'msecs', 'message', 'msg', 'name', 
                           'pathname', 'process', 'processName', 'relativeCreated', 
                           'stack_info', 'thread', 'threadName', 'props'):
                log_record[key] = value
        
        return json.dumps(log_record)

class LogstashHandler(SocketHandler):
    def __init__(self, host, port, service_name):
        super(LogstashHandler, self).__init__(host, port)
        self.formatter = ELKLogstashFormatter(service_name)
    
    def makePickle(self, record):
        message = self.formatter.format(record) + '\n'
        return message.encode('utf-8')

def setup_elk_logging(service_name, logstash_host='localhost', logstash_port=5000, level=logging.INFO):
    """Configure Python logging to send logs to ELK Stack"""
    root_logger = logging.getLogger()
    root_logger.setLevel(level)
    
    # Remove existing handlers
    for handler in root_logger.handlers:
        root_logger.removeHandler(handler)
    
    # Add stdout handler for local debugging
    console_handler = logging.StreamHandler()
    console_formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
    console_handler.setFormatter(console_formatter)
    root_logger.addHandler(console_handler)
    
    # Add Logstash handler
    logstash_handler = LogstashHandler(logstash_host, logstash_port, service_name)
    root_logger.addHandler(logstash_handler)
    
    # Log successful setup
    logging.info(f"ELK logging setup complete for {service_name} -> {logstash_host}:{logstash_port}")
    
    return root_logger
```

### Step 15.4: Use the ELK logging in your application

Update your application to use ELK logging:

```python
# app.py
import logging
from elk_logging import setup_elk_logging
import time
import random
import functools

# Set up ELK logging
logger = setup_elk_logging(
    service_name="my-python-app",
    logstash_host="localhost",  # Change to your Logstash host
    logstash_port=5000,
    level=logging.INFO
)

# Create a logging decorator
def log_function(func):
    @functools.wraps(func)
    def wrapper(*args, **kwargs):
        logger.info(f"Calling {'{'}func.__name__{'}'}", extra={
            "function": func.__name__,
            "args": str(args),
            "kwargs": str(kwargs)
        })
        try:
            result = func(*args, **kwargs)
            logger.info(f"{'{'}func.__name__{'}'} completed successfully")
            return result
        except Exception as e:
            logger.error(f"{'{'}func.__name__{'}'} failed: {'{'} str(e) {'}'}", exc_info=True)
            raise
    return wrapper

# Example usage
@log_function
def process_item(item_id, quantity):
    logger.info("Processing item", extra={
        "item_id": item_id,
        "quantity": quantity,
        "process_time": time.time()
    })
    
    # Simulate processing
    time.sleep(random.random())
    
    if random.random() < 0.1:  # 10% chance of failure
        raise ValueError("Simulated random failure")
        
    return {"status": "processed", "item_id": item_id}

if __name__ == "__main__":
    # Process several items
    for i in range(20):
        try:
            process_item(f"ITEM-{i}", random.randint(1, 10))
        except Exception as e:
            print(f"Caught error: {e}")
```

### Step 15.5: Build and run with Docker

Create a Dockerfile for your application:

```Dockerfile
FROM python:3.9-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY *.py .

CMD ["python", "app.py"]
```

Create a `requirements.txt` file:

```
functools32>=3.2.3;python_version<"3.4"
python-json-logger>=2.0.7
```

Create a docker-compose file to run your app with ELK:

```yaml
version: '3.8'

services:
  # Your Python application
  python-app:
    build: .
    container_name: python-app
    environment:
      - LOGSTASH_HOST=logstash
      - LOGSTASH_PORT=5000
      - SERVICE_NAME=python-app
    networks:
      - elk-network
    depends_on:
      - logstash
    # Use the same external network as ELK stack

networks:
  elk-network:
    external: true
```

### Step 15.6: Accessing the logs in Kibana

1. Build and start your application:

```bash
docker-compose up -d
```

2. Access Kibana at [http://localhost:5601](http://localhost:5601)

3. Set up an index pattern:
   - Go to Management → Stack Management → Kibana → Index Patterns
   - Create a new index pattern `python-logs-*`
   - Select `timestamp` as the time field
   - Click "Create index pattern"

4. View your logs:
   - Go to Discover
   - Select your index pattern
   - You should see logs from your Python application

5. Create a dashboard:
   - Create visualizations based on log fields
   - Add visualizations to a dashboard
   - Save and share with your team

## Summary of Scenarios

This tutorial has covered the following scenarios for logging in containerized applications running in Kubernetes:

1. **Basic Function Logging**: Simple error logging for Python functions (Step 2)
2. **Advanced Decorator Logging**: Detailed function call tracking with arguments (Step 4)
3. **Centralized Configuration**: Setting up consistent logging across multiple services (Step 5)
4. **Troubleshooting Production Issues**: Using logs to diagnose problems (Step 6)
5. **Contextual Logging**: Adding business context to logs for better analysis (Step 7)
6. **Thread-Safe Logging**: Handling concurrent requests in multi-threaded applications (Step 8)
7. **Web Framework Integration**: Logging in Flask and Django applications (Step 10)
8. **Containerized Logging**: Docker-specific logging configuration (Step 11)
9. **Kubernetes Environment Logging**: Structured logging with Kubernetes metadata (Step 12)
10. **Distributed Tracing**: Tracking requests across multiple microservices (Step 13)
11. **Production Kubernetes Setup**: Best practices for logging in production K8s deployments (Step 14)
12. **ELK Stack Integration**: Centralized logging with Elasticsearch, Logstash and Kibana (Step 15)

By implementing these patterns, your team will have a robust logging system for containerized applications running in Kubernetes that enables effective monitoring, troubleshooting, and performance analysis.

## Conclusion
Using decorator functions for logging in Python aligns with enterprise-level requirements for scalable systems. By implementing decorators that log function calls, arguments, and exceptions, and combining them with named loggers, structured formats, and centralized configurations, developers can achieve robust observability. 

This approach provides several benefits:

1. **Clean separation of concerns** - Business logic remains uncluttered by logging code
2. **Consistency across the codebase** - Uniform logging format and level usage
3. **Centralized configuration** - Easy adjustment of logging behavior application-wide
4. **Enhanced debugging capabilities** - Detailed context for troubleshooting issues

Handling failures with logs ensures quick diagnosis and resolution, making this approach ideal for large-scale applications.

## Summary
This tutorial has covered the key aspects of Python logging with decorators, including:

*   Creating a logging decorator to log function calls and exceptions
*   Configuring logging for scalability using `logging.config.dictConfig`
*   Handling failures with logs for effective debugging
*   Best practices for logging in applications
*   Advanced considerations, such as custom handlers, class methods, and asynchronous logging

By following this tutorial, you've gained the knowledge to implement professional-grade logging in your Python applications using decorators.

## References

*   [Python Official Documentation: Logging](https://docs.python.org/3/library/logging.html)
*   [Python Logging Cookbook](https://docs.python.org/3/howto/logging-cookbook.html)
*   [Python Logging Best Practices by Last9](https://last9.io/blog/python-logging-best-practices/)
*   [Best Practices for Logging in Python by Better Stack](https://betterstack.com/community/guides/logging/python/)
*   [Python Logging Best Practices by SigNoz](https://signoz.io/blog/python-logging-best-practices/)
*   [Python Logging Best Practices by Middleware](https://middleware.io/blog/python-logging-best-practices/)
*   [Create an Exception Logging Decorator by GeeksforGeeks](https://www.geeksforgeeks.org/create-an-exception-logging-decorator-in-python/)
*   [Python Logging with Datadog](https://docs.datadoghq.com/logs/log_collection/python/)
*   [Structured Logging in Python](https://www.loggly.com/use-cases/json-logging-in-python/)
*   [Logging at Scale by Loggly](https://www.loggly.com/blog/logging-in-the-cloud-at-scale/)
*   [Advanced Python Logging by Uptrace](https://uptrace.dev/opentelemetry/python-logging.html)
*   [ELK Stack Overview by Elastic](https://www.elastic.co/what-is/elk-stack)
*   [Splunk Platform Overview](https://www.splunk.com/en_us/platform.html)
*   [SigNoz Open-Source Observability](https://signoz.io/)
*   [OpenTelemetry for Python](https://opentelemetry.io/docs/instrumentation/python/)
*   [Structured Logging with Python](https://www.honeybadger.io/blog/python-structured-logging/)
*   [Python Logging Best Practices](https://machinelearningmastery.com/logging-in-python/)