---
id: python-threading
title: Python Threading Guide
sidebar_label: Threading
description: A comprehensive guide to threading in Python
keywords:
  - python
  - threading
  - concurrency
  - threadpoolexecutor
---

# Python Threading Guide

## Introduction

Threading is a technique for running multiple operations concurrently within a single process. In Python, threading is particularly useful for I/O-bound tasks where operations spend significant time waiting for external resources (network requests, file operations, etc.). This guide covers Python's threading capabilities, from basic thread creation to advanced thread management with the `concurrent.futures` module.

## Threading vs Multiprocessing: When to Use Each

- **Threading**: Use for I/O-bound tasks (network requests, file operations, database queries)
- **Multiprocessing**: Use for CPU-bound tasks (complex calculations, data processing)

> **Why the difference?**  
> Due to Python's Global Interpreter Lock (GIL), only one thread can execute Python code at once. This means threading doesn't provide true parallelism for CPU-bound tasks, but it's very effective for I/O-bound tasks where threads spend time waiting.

## Basic Threading: Using the `threading` Module

### Creating and Starting Threads

The most basic way to use threads is with the `threading.Thread` class:

```python
import threading
import time

def do_something():
    print('Sleeping 5 seconds')
    time.sleep(5)
    print('Done sleeping')

# Create thread objects
thread1 = threading.Thread(target=do_something)
thread2 = threading.Thread(target=do_something)

# Start threads
thread1.start()
thread2.start()
```

### Waiting for Threads with `join()`

The `join()` method allows the main thread to wait for the completion of other threads:

```python
# Start threads
thread1.start()
thread2.start()

# Wait for threads to complete
thread1.join()
thread2.join()

print('All threads completed')
```

### Passing Arguments to Thread Functions

You can pass arguments to the target function using the `args` parameter (for positional arguments) or `kwargs` (for keyword arguments):

```python
def do_something(seconds):
    print(f'Sleeping {seconds} seconds')
    time.sleep(seconds)
    print('Done sleeping')

# Pass arguments as a list
thread = threading.Thread(target=do_something, args=[2])
# Or as a tuple
thread = threading.Thread(target=do_something, args=(2,))
```

### Creating Multiple Threads

You can create and manage multiple threads with a list:

```python
threads = []

# Create and start 10 threads
for _ in range(10):
    thread = threading.Thread(target=do_something, args=[2])
    thread.start()
    threads.append(thread)

# Wait for all threads to complete
for thread in threads:
    thread.join()
```

## Advanced Threading: `concurrent.futures`

The `concurrent.futures` module provides a high-level interface for asynchronously executing callables, introduced in Python 3.2.

### ThreadPoolExecutor

The `ThreadPoolExecutor` manages a pool of worker threads, distributing tasks to available threads as they become available:

```python
import concurrent.futures
import time

def do_something(seconds):
    print(f'Sleeping {seconds} second')
    time.sleep(seconds)
    return f'Done sleeping {seconds}'

# Using context manager to ensure cleanup
with concurrent.futures.ThreadPoolExecutor() as executor:
    seconds = [5, 4, 3, 2, 1]
    results = executor.map(do_something, seconds)
    
    for result in results:
        print(result)
```

### The `submit()` Method and Futures

The `submit()` method schedules a function to be executed and returns a `Future` object representing the execution:

```python
with concurrent.futures.ThreadPoolExecutor() as executor:
    # Schedule execution and get Future objects
    f1 = executor.submit(do_something, 5)
    f2 = executor.submit(do_something, 4)
    
    # Future.result() blocks until the result is available
    print(f1.result())
    print(f2.result())
```

### Processing Completed Futures with `as_completed()`

The `as_completed()` function yields futures as they complete, which is useful when you want to process results as soon as they're ready:

```python
with concurrent.futures.ThreadPoolExecutor() as executor:
    seconds = [5, 4, 3, 2, 1]
    futures = [executor.submit(do_something, sec) for sec in seconds]
    
    for future in concurrent.futures.as_completed(futures):
        print(future.result())
```

### Comparing `map()` and `submit()`

- **`map()`**: Simpler syntax, results are returned in the same order as inputs
- **`submit()`**: More flexible, allows using `as_completed()` to process results as they finish

## Thread Execution Visualization

### Sequential Execution

In sequential execution, each function call must complete before the next one begins, resulting in the total execution time being the sum of all individual execution times.

```mermaid
sequenceDiagram
    participant Main
    participant Function1
    participant Function2
    participant Function3
    
    Main->>Function1: Call function
    activate Function1
    Note over Function1: Processing (1 second)
    Function1-->>Main: Return result
    deactivate Function1
    
    Main->>Function2: Call function
    activate Function2
    Note over Function2: Processing (1 second)
    Function2-->>Main: Return result
    deactivate Function2
    
    Main->>Function3: Call function
    activate Function3
    Note over Function3: Processing (1 second)
    Function3-->>Main: Return result
    deactivate Function3
    
    Note over Main,Function3: Total execution time: 3 seconds
```

### Concurrent Execution

With concurrent execution using threads, multiple functions can run simultaneously. For I/O-bound tasks, this significantly reduces the total execution time.

```mermaid
sequenceDiagram
    participant Main
    participant Thread1
    participant Thread2
    participant Thread3
    
    Main->>Thread1: Start thread
    activate Thread1
    Main->>Thread2: Start thread
    activate Thread2
    Main->>Thread3: Start thread
    activate Thread3
    
    Note over Thread1: Processing (1 second)
    Note over Thread2: Processing (1 second)
    Note over Thread3: Processing (1 second)
    
    Thread1-->>Main: Thread complete
    deactivate Thread1
    Thread2-->>Main: Thread complete
    deactivate Thread2
    Thread3-->>Main: Thread complete
    deactivate Thread3
    
    Main->>Main: Join all threads
    
    Note over Main,Thread3: Total execution time: ~1 second
```

## Timing Thread Execution

To measure execution time, use `time.perf_counter()`:

```python
import time
import concurrent.futures

start = time.perf_counter()

# Thread execution code here...

finish = time.perf_counter()
print(f'Finished in {round(finish-start, 2)} second(s)')
```

## Practical Example: Downloading Images with Threads

For I/O-bound tasks like downloading multiple images, threads can significantly improve performance:

```python
import requests
import time
import concurrent.futures

img_urls = [
    'https://images.unsplash.com/photo-1516117172878-fd2c41f4a759',
    'https://images.unsplash.com/photo-1532009324734-20a7a5813719',
    'https://images.unsplash.com/photo-1524429656589-6633a470097c',
    'https://images.unsplash.com/photo-1530224264768-7ff8c1789d79',
    'https://images.unsplash.com/photo-1564135624576-c5c88640f235',
    'https://images.unsplash.com/photo-1541698444083-023c97d3f4b6',
    'https://images.unsplash.com/photo-1522364723953-452d3431c267',
    'https://images.unsplash.com/photo-1513938709626-033611b8cc03',
    'https://images.unsplash.com/photo-1507143550189-fed454f93097',
    'https://images.unsplash.com/photo-1493976040374-85c8e12f0c0e'
]

def download_image(img_url):
    img_bytes = requests.get(img_url).content
    img_name = img_url.split('/')[3]
    img_name = f'{img_name}.jpg'
    with open(img_name, 'wb') as img_file:
        img_file.write(img_bytes)
        print(f'{img_name} was downloaded...')

start = time.perf_counter()

with concurrent.futures.ThreadPoolExecutor() as executor:
    executor.map(download_image, img_urls)
    
finish = time.perf_counter()
print(f'Finished in {round(finish-start, 2)} second(s)')
```

## Thread Synchronization

When threads access shared resources, synchronization is necessary to prevent race conditions.

### Using Locks

```python
import threading
import time

counter = 0
lock = threading.Lock()

def increment_counter():
    global counter
    with lock:  # Automatically acquires and releases the lock
        local_counter = counter
        time.sleep(0.1)  # Simulate some processing
        counter = local_counter + 1
        print(f'Counter: {counter}')

threads = []
for _ in range(10):
    thread = threading.Thread(target=increment_counter)
    threads.append(thread)
    thread.start()

for thread in threads:
    thread.join()

print(f'Final counter: {counter}')
```

### Other Synchronization Primitives

Python's `threading` module provides several synchronization primitives:

1. **Semaphore**: Limits access to a shared resource to a fixed number of threads
   ```python
   semaphore = threading.Semaphore(value=2)  # Allow 2 threads at once
   ```

2. **Event**: Signals between threads
   ```python
   event = threading.Event()
   # In one thread
   event.set()  # Signal the event
   # In another thread
   event.wait()  # Wait for the event
   ```

3. **Condition**: More complex signaling between threads
   ```python
   condition = threading.Condition()
   # Notify waiting threads
   with condition:
       condition.notify_all()
   ```

4. **Queue**: Thread-safe queue for producer-consumer patterns
   ```python
   from queue import Queue
   task_queue = Queue()
   task_queue.put(item)  # Producer
   item = task_queue.get()  # Consumer
   ```

## The Global Interpreter Lock (GIL)

The Global Interpreter Lock (GIL) is a fundamental and often debated feature of CPython, the default and most widely used implementation of Python. It's a mutex (mutual exclusion lock) that restricts the execution of Python bytecode to only one thread at a time within a single CPython interpreter process.

### What is the GIL?

```mermaid
graph TD
    A[Python Interpreter] --> B[Global Interpreter Lock]
    C[Thread 1] -->|Acquires| B
    D[Thread 2] -->|Waits for| B
    E[Thread 3] -->|Waits for| B
    B -->|Controls access to| F[Python Objects]
    B -->|Ensures thread-safety for| G[Memory Management]
```

- The GIL functions like a "traffic light for threads" in your program
- Only one thread can execute Python bytecode at any given moment
- When one thread holds the GIL, all other Python threads must wait, even if they're ready to run
- The GIL is specific to CPython (the standard Python implementation) and isn't present in all Python implementations (like Jython or IronPython)

### Why the GIL Exists

The GIL was introduced in Python's early days primarily to make CPython thread-safe:

- **Memory Management**: CPython uses reference counting for memory management, which tracks how many references point to an object and automatically frees memory when the count drops to zero
- **Thread Safety**: Without a lock like the GIL, multiple threads could simultaneously update these reference counts, leading to race conditions, crashes, or corrupted data
- **Implementation Simplicity**: The GIL provides a simple way to prevent such issues, making the implementation of the interpreter and C extensions simpler

### How the GIL Works in Practice

- **Thread Execution**: When a Python program uses multiple threads, the GIL ensures that only one thread can be actively running Python code
- **Automatic Release**: The GIL is typically released by the currently running thread every 5 milliseconds (ms) by default in Python 3.7 to 3.10, allowing other threads a chance to acquire it and run
- **GIL During I/O Operations**: Most I/O operations release the GIL, which is why threading is beneficial for I/O-bound tasks
- **Impact of Long-Running Operations**:
  - **Blocking Extension Code**: If a thread calls a long-running, "blocking" extension code (e.g., C library calls) that doesn't explicitly release the GIL, other Python threads remain blocked
  - **Explicit GIL Release**: Non-Python code, particularly C extensions, can explicitly release the GIL during long-running operations, allowing other Python threads to run concurrently

### Impact on Different Concurrency Models

#### Multithreading

- **I/O-Bound Tasks**: Threading is highly beneficial for tasks that spend most of their time waiting for external resources
- **CPU-Bound Tasks**: Threading offers little to no performance improvement for tasks that require heavy computation, as only one thread can execute Python bytecode at a time

#### Multiprocessing

- Creates separate processes, each with its own Python interpreter and GIL
- Allows programs to fully leverage multiple CPU cores and achieve true parallelism
- Best choice for CPU-bound tasks

#### Asyncio

- Runs on a single thread with its own event loop
- Coroutines explicitly cooperate by awaiting I/O operations, giving control back to the event loop
- Avoids the overhead of context switching between threads

### Python 3.13: The Game-Changing "No-GIL" Mode

Python 3.13 introduces a significant innovation: an experimental "no-GIL" or "free-threaded" version of Python, resulting from the acceptance of [PEP 703](https://peps.python.org/pep-0703/).

```mermaid
graph TD
    A[Python 3.13] --> B{Installation Options}
    B --> C[Standard Build with GIL]
    B --> D[No-GIL Build]
    C --> E["py 3.13 (Windows)"]
    D --> F["py 3.13t (Windows)"]
    D --> G[Build with --disable-gil flag]
    
    H[Check in code] --> I["import sys\nsys._is_gil_enabled()"]
```

#### Purpose and Impact on Parallelism

- Enables Python programs to use threading for CPU-based parallelism
- Allows CPU-bound work to run at full speed on different threads
- For I/O-bound activities, the no-GIL build shows no performance difference compared to builds with the GIL

#### How to Access

- During installation of Python 3.13, users can choose to download the free-threaded binaries
- On Windows, this provides two Python 3.13 instances:
  - Regular build with the GIL (launched with `py 3.13`)
  - No-GIL build (launched with `py 3.13t`)
- Developers can explicitly build CPython without the GIL using the `--disable-gil` flag
- In code, check if the GIL is enabled with: `import sys; print(sys._is_gil_enabled())`

#### Technical Implementation

- Reference counters are updated using atomic operations to ensure thread safety
- The cyclic garbage collector has been updated to handle threads safely
- These changes enable thread-safe memory management without the need for the GIL

#### Important Considerations

- The free-threaded build is delivered as a separate binary for testing purposes
- Code that wasn't thread-safe before won't automatically become thread-safe in the no-GIL build
- Developers still need to implement mechanisms like locks or queues for thread safety where shared state is involved
- The atomic operations introduce some overhead, potentially slowing down single-threaded programs marginally
- Currently intended for experimentation, not production use

#### Performance Implications

- Threading can achieve performance comparable to or even slightly faster than multiprocessing for CPU-bound activities
- High-level abstractions for threading, such as thread pools, are recommended to see performance improvements

### Bypassing and Avoiding the GIL

To overcome the GIL's limitations for CPU-bound tasks, developers can:

1. **Use multiprocessing**: The primary way to achieve true parallelism in Python by running code in separate processes
2. **Leverage C Extensions**: Libraries like NumPy or TensorFlow perform heavy computations outside of the GIL's control
3. **Consider the no-GIL mode**: In Python 3.13+, experiment with the free-threaded build for CPU-bound tasks
4. **Alternative Python Implementations**: Consider Jython, IronPython (no GIL), or PyPy (optimized performance)
5. **Use asyncio for I/O-bound tasks**: Often preferred over threading due to efficiency and lower overhead

With these strategies, Python developers can work effectively with or around the GIL to create responsive, scalable applications.

## Best Practices

1. **Use thread pools** (`ThreadPoolExecutor`) instead of manually creating threads
2. **Prefer `with` statement** for context management
3. **Use thread synchronization** when accessing shared resources
4. **Keep the GIL in mind** - threading is best for I/O-bound tasks
5. **Consider using asyncio** for newer code if appropriate
6. **Be careful with thread termination** - threads should exit cleanly
7. **Benchmark your code** - measure the actual performance improvement from threading

## Common Pitfalls

1. **Race conditions** - Use proper synchronization for shared resources
2. **Deadlocks** - Be careful when acquiring multiple locks
3. **Thread leakage** - Always join threads or use context managers
4. **Over-threading** - Too many threads can cause overhead
5. **Using threading for CPU-bound tasks** - Consider multiprocessing instead
6. **Thread safety** - Be careful with non-thread-safe libraries

## Multiprocessing in Python

Multiprocessing involves running multiple processes, each with its own Python interpreter and memory space. This allows for true parallelism, making multiprocessing ideal for CPU-bound tasks that need to bypass the Global Interpreter Lock (GIL).

### Basic Multiprocessing

```python
import multiprocessing
import time

def worker(name):
    print(f"Worker {name} starting")
    time.sleep(2)  # Simulate some work
    print(f"Worker {name} finished")

if __name__ == '__main__':  # This guard is important for Windows
    processes = []
    for i in range(5):
        p = multiprocessing.Process(target=worker, args=(i,))
        processes.append(p)
        p.start()
    
    for p in processes:
        p.join()  # Wait for all processes to finish
```

### Process Pools with `concurrent.futures`

Similar to thread pools, you can use `ProcessPoolExecutor` for managing a pool of worker processes:

```python
import concurrent.futures
import time

def cpu_bound_task(number):
    return sum(i * i for i in range(number))

if __name__ == '__main__':
    numbers = [10000000 + x for x in range(8)]
    
    start = time.perf_counter()
    
    with concurrent.futures.ProcessPoolExecutor() as executor:
        results = executor.map(cpu_bound_task, numbers)
    
    finish = time.perf_counter()
    print(f'Finished in {round(finish-start, 2)} second(s)')
```

### Process vs Thread Visualization

```mermaid
graph TD
    subgraph "Process 1"
    A[Memory Space]
    B[Python Interpreter]
    C[System Resources]
    
    subgraph "Threads"
    D[Thread 1]
    E[Thread 2]
    F[Thread 3]
    end
    
    G[Shared Memory]
    
    D --> G
    E --> G
    F --> G
    end
    
    subgraph "Process 2"
    H[Memory Space]
    I[Python Interpreter]
    J[System Resources]
    
    subgraph "Threads"
    K[Thread 1]
    L[Thread 2]
    end
    
    M[Shared Memory]
    
    K --> M
    L --> M
    end
```

The diagram above illustrates that:
- Each process has its own memory space, Python interpreter, and system resources
- Threads exist within a process
- Threads within the same process share memory
- Different processes have separate memory spaces

## Asynchronous Programming with Asyncio

Asyncio is a Python library for writing concurrent code using the `async/await` syntax. It's designed for I/O-bound tasks and uses an event loop to manage and schedule tasks.

### Key Concepts in Asyncio

1. **Coroutines**: Functions defined with `async def`. These are the building blocks of asyncio.
2. **Event Loop**: The core of asyncio that manages the execution of tasks.
3. **Tasks**: Wrappers around coroutines that are scheduled on the event loop.
4. **await**: Pauses the execution of a coroutine, yielding control back to the event loop.

### Basic Asyncio Example

```python
import asyncio

async def task(name):
    print(f"Task {name} starting")
    await asyncio.sleep(2)  # Simulate an I/O-bound operation
    print(f"Task {name} finished")
    return f"Result from {name}"

async def main():
    # Run multiple coroutines concurrently
    results = await asyncio.gather(
        task("A"),
        task("B"),
        task("C")
    )
    print(results)

# In Python 3.7+
asyncio.run(main())
```

### Event Loop Visualization

```mermaid
graph TD
    A[Event Loop] -->|Schedule| B[Task A]
    A -->|Schedule| C[Task B]
    A -->|Schedule| D[Task C]
    B -->|await| A
    C -->|await| A
    D -->|await| A
```

### Creating and Managing Tasks

```python
import asyncio

async def my_coroutine():
    await asyncio.sleep(2)
    return "Done"

async def main():
    # Create a task and start it immediately
    task = asyncio.create_task(my_coroutine())
    
    # Do other work while the task runs
    print("Doing something else while waiting...")
    
    # Wait for the task to complete
    result = await task
    print(f"Task result: {result}")

asyncio.run(main())
```

### Handling CPU-Bound Tasks in Asyncio

Asyncio is not well-suited for CPU-bound tasks because they can block the event loop. However, you can offload CPU-bound tasks to a separate thread or process:

```python
import asyncio
import time

def cpu_bound_task(n):
    time.sleep(n)  # Simulating a CPU-bound task
    return n * n

async def main():
    # Offload to a separate thread
    result = await asyncio.to_thread(cpu_bound_task, 2)
    print(f"Result: {result}")

asyncio.run(main())
```

### Comparing Concurrency Models

```mermaid
graph TD
    A[Concurrency Models] --> B[Threading]
    A --> C[Multiprocessing]
    A --> D[Asyncio]
    
    B -->|Best for| E[I/O-Bound Tasks]
    B -->|Limited by| F[GIL]
    
    C -->|Best for| G[CPU-Bound Tasks]
    C -->|Features| H[True Parallelism]
    
    D -->|Best for| I[Many I/O Operations]
    D -->|Uses| J[Event Loop]
```

## When to Use Each Approach

1. **Multithreading**:
   - Best for I/O-bound tasks like network operations or file I/O
   - Use when you need shared state between threads
   - Not ideal for CPU-bound tasks due to the GIL

2. **Multiprocessing**:
   - Ideal for CPU-bound tasks that need true parallelism
   - Use when you need to bypass the GIL
   - Best for heavy computational workloads

3. **Asyncio**:
   - Excellent for I/O-bound tasks with many concurrent operations
   - Ideal for building high-performance network servers
   - More readable and maintainable than callback-based approaches
   - Not suitable for CPU-bound tasks without offloading

## Further Resources

- [Python Threading Documentation](https://docs.python.org/3/library/threading.html)
- [concurrent.futures Documentation](https://docs.python.org/3/library/concurrent.futures.html)
- [Real Python's Threading Guide](https://realpython.com/intro-to-python-threading/)
- [Python Multiprocessing vs Threading](https://realpython.com/python-concurrency/)
- [Python Asyncio Tutorial](https://realpython.com/async-io-python/)
- [Python Cookbook: Concurrency](https://www.oreilly.com/library/view/python-cookbook-3rd/9781449357337/)
- [Fluent Python: Concurrency Chapter](https://www.oreilly.com/library/view/fluent-python/9781491946237/)

## Next Steps

After mastering these concurrency models, consider exploring:
- **Hybrid approaches** combining asyncio with threads or processes
- **Distributed computing** frameworks like Dask or Celery
- **Thread-safe data structures** in the `queue` and `collections.concurrent` modules
- **Advanced synchronization patterns** like producer-consumer and thread pools
