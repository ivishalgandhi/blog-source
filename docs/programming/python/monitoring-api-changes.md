---
sidebar_position: 2
title: "Monitoring API Data Changes in Python"
description: "Learn how to monitor API data changes using Python with requests, deepdiff, and polling libraries"
---

# Monitoring API Data Changes in Python

## Overview

When building applications that rely on external data sources, detecting changes in API responses is a common requirement. Unlike file system monitoring, where tools like `watchdog` can track changes, monitoring API data requires a different approach. This guide explores a robust solution for monitoring API data changes using Python libraries.

## Core Libraries

The monitoring solution relies on three key libraries:

| Library | Purpose | Function |
|---------|---------|----------|
| `requests` | HTTP client | Fetches data from API endpoints |
| `deepdiff` | Object comparison | Detects changes between API responses |
| `polling2` | Scheduling | Polls APIs at intervals to check for changes |

### requests

The `requests` library is the standard for making HTTP requests in Python:

```python
import requests

def fetch_data(url):
    response = requests.get(url)
    response.raise_for_status()  # Raises exception for HTTP errors
    return response.json()
```

### deepdiff

The `deepdiff` library specializes in detecting differences between complex data structures:

```python
from deepdiff import DeepDiff

# Compare two API responses
diff = DeepDiff(previous_data, current_data, ignore_order=True)
if diff:
    # Changes detected
    print(f"Changes found: {diff}")
```

### polling2

The `polling2` library simplifies periodic checking:

```python
import polling2

# Poll every 60 seconds until a condition is met
polling2.poll(
    check_for_changes,
    step=60,
    timeout=None  # Run indefinitely
)
```

## Monitoring Process

The API monitoring workflow follows these steps:

1. **Initial Fetch**: Retrieve the initial data from the API
2. **Data Storage**: Store this data for future comparison
3. **Periodic Polling**: Fetch new data at regular intervals
4. **Comparison**: Compare new data with previous data
5. **Action**: Respond to detected changes

## Complete Implementation

Here's a complete solution that ties everything together:

```python
import requests
from deepdiff import DeepDiff
import polling2

# Configuration
API_URL = "https://api.example.com/users"

def fetch_data():
    """Fetch data from the API."""
    response = requests.get(API_URL)
    response.raise_for_status()
    return response.json()

def check_for_changes():
    """Check if there are any changes in the API data."""
    global previous_data
    current_data = fetch_data()
    diff = DeepDiff(previous_data, current_data, ignore_order=True)
    
    if diff:
        print("Changes detected:", diff)
        # Update the reference data
        previous_data = current_data
        return True
    
    return False

# Fetch initial data
previous_data = fetch_data()
print("Initial data fetched. Monitoring for changes...")

# Start polling
try:
    polling2.poll(
        check_for_changes,      # Function to call
        step=60,                # Check every 60 seconds
        timeout=None            # Run indefinitely
    )
except KeyboardInterrupt:
    print("Monitoring stopped.")
```

## Advanced Implementation Using APScheduler

Since `polling2` is not actively maintained, here's an alternative implementation using `APScheduler`:

```python
from apscheduler.schedulers.blocking import BlockingScheduler
import requests
from deepdiff import DeepDiff

# Configuration
API_URL = "https://api.example.com/users"
previous_data = None

def fetch_data():
    """Fetch data from the API."""
    response = requests.get(API_URL)
    response.raise_for_status()
    return response.json()

def check_for_changes():
    """Check if there are any changes in the API data."""
    global previous_data
    current_data = fetch_data()
    diff = DeepDiff(previous_data, current_data, ignore_order=True)
    
    if diff:
        print("Changes detected:", diff)
        previous_data = current_data

# Initialize with first data fetch
previous_data = fetch_data()
print("Initial data fetched. Monitoring for changes...")

# Configure and start the scheduler
scheduler = BlockingScheduler()
scheduler.add_job(check_for_changes, 'interval', seconds=60)

try:
    scheduler.start()
except KeyboardInterrupt:
    scheduler.shutdown()
    print("Monitoring stopped.")
```

## Understanding DeepDiff Output

When changes are detected, `deepdiff` provides detailed information about what changed:

```
Changes detected: {
    'values_changed': {
        "root['users'][0]['name']": {
            'new_value': 'Jane',
            'old_value': 'John'
        }
    }
}
```

This output shows that in the first user object, the name changed from "John" to "Jane".

## Optimization Strategies

For production environments, consider these optimizations:

### 1. Efficient Data Storage

```python
import redis

# Connect to Redis
r = redis.Redis()

def store_previous_data(data):
    r.set('previous_api_data', json.dumps(data))

def get_previous_data():
    data = r.get('previous_api_data')
    return json.loads(data) if data else None
```

### 2. Error Handling with Exponential Backoff

```python
from tenacity import retry, stop_after_attempt, wait_exponential

@retry(stop=stop_after_attempt(5), wait=wait_exponential(multiplier=1, min=4, max=60))
def fetch_data_with_retry():
    """Fetch data with retry logic."""
    response = requests.get(API_URL)
    response.raise_for_status()
    return response.json()
```

### 3. Monitoring Multiple Endpoints

```python
endpoints = {
    "users": "https://api.example.com/users",
    "products": "https://api.example.com/products"
}

previous_data = {endpoint: None for endpoint in endpoints}

def check_endpoint(name, url):
    current_data = fetch_data(url)
    diff = DeepDiff(previous_data[name], current_data, ignore_order=True)
    
    if diff:
        print(f"Changes detected in {name}:", diff)
        previous_data[name] = current_data
```

## Practical Considerations

When implementing API monitoring, keep these factors in mind:

1. **API Rate Limits**: Adjust polling intervals to respect API limits
2. **Data Size**: Filter responses to reduce comparison overhead
3. **Webhooks**: When available, use webhooks instead of polling
4. **Persistence**: Store state in a database for monitoring across restarts
5. **Alerting**: Send notifications when critical changes are detected

## Summary

Monitoring API data changes in Python requires three key components:
- Fetching data with the `requests` library
- Detecting differences with `deepdiff`
- Periodic checking with `polling2` or `APScheduler`

This pattern works well for APIs without real-time notification features and can be optimized for production environments with additional error handling, persistence, and efficiency improvements.
