---
sidebar_position: 3
title: Understanding Underscore Functions in Python
description: A deep dive into Python's underscore functions with real-world examples from [jirax](https://github.com/ivishalgandhi/jirax)
---

# Understanding Underscore Functions in Python

Python uses underscores in variable and function names to convey special meaning to programmers. While these naming conventions aren't enforced by the interpreter, they serve as important signals about how code should be used. This article explores the different types of underscore patterns in Python, with real-world examples from the [jirax](https://github.com/ivishalgandhi/jirax) project.

## Types of Underscore Patterns in Python

### 1. Single Leading Underscore: `_variable` or `_function()`

A single leading underscore indicates that a variable or function is intended for internal use. This is a convention that tells other programmers "this is not part of the public API" and "use at your own risk, as it may change without notice."

#### Real-world Example from [jirax](https://github.com/ivishalgandhi/jirax): `_get_nested_attr()`

In the [jirax](https://github.com/ivishalgandhi/jirax) project, the `_get_nested_attr()` function is used internally to safely retrieve nested attributes from Jira issue objects:

```python
def _get_nested_attr(obj: Any, attr_path: str, default: Any = None) -> Any:
    """
    Safely retrieve a nested attribute from an object using a dot-separated path.
    Example: _get_nested_attr(issue, "fields.reporter.displayName")
    """
    attrs = attr_path.split('.')
    current_obj = obj
    for attr in attrs:
        if isinstance(current_obj, dict): # For raw dicts from API sometimes
            current_obj = current_obj.get(attr)
        elif hasattr(current_obj, 'raw') and isinstance(current_obj.raw, dict) and attr in current_obj.raw:
            # jira-python often stores raw data in .raw
            current_obj = current_obj.raw[attr]
        elif hasattr(current_obj, attr): # For Issue objects and their fields
            current_obj = getattr(current_obj, attr)
        else: # Attribute not found
            return default
        
        if current_obj is None: # If at any point we get None, return default
            return default
    return current_obj
```

This function is marked with a leading underscore because:

1. It's an implementation detail not meant to be called directly by users of the [jirax](https://github.com/ivishalgandhi/jirax) package
2. It handles the complexity of Jira's nested data structures, which could change in future API versions
3. It's used by other functions within the module but isn't part of the public interface

### 2. Single Trailing Underscore: `variable_` or `function_()`

A single trailing underscore is used to avoid naming conflicts with Python keywords:

```python
class_ = "Python 101"  # Avoids conflict with 'class' keyword
```

### 3. Double Leading Underscore: `__variable` or `__function()`

Double leading underscores trigger name mangling in class attributes. Python will rename these attributes to include the class name, making them harder to access from outside the class.

### 4. Double Leading and Trailing Underscores: `__variable__` or `__function__()`

These are reserved for special methods in Python, like `__init__`, `__str__`, and `__repr__`. They're also called "dunder" methods (double underscore).

### 5. Single Underscore: `_`

A single underscore is commonly used as a throwaway variable name for values you don't intend to use:

```python
# Unpacking a tuple but only caring about the first value
first, _ = (1, 2)

# In a loop where the index isn't used
for _ in range(5):
    print("Hello")
```

## Deep Dive: `_get_computed_value()` in [jirax](https://github.com/ivishalgandhi/jirax)

Another excellent example from [jirax](https://github.com/ivishalgandhi/jirax) is the `_get_computed_value()` function, which handles complex field transformations:

```python
def _get_computed_value(issue: Issue, source_key: str, config: Dict, run_date_str: str, jira_client: JIRA) -> Any:
    """
    Compute values for special fields that require more complex logic.
    'source_key' is the part after "_computed.", e.g., "sprint", "epicname".
    """
    field_name = source_key # source_key is already the part after _computed.

    jira_opts = config.get("jira_options", {})

    if field_name == "sprint":
        sprint_custom_field_id = jira_opts.get("sprint_custom_field", "customfield_10020")
        sprints_data = _get_nested_attr(issue, f"fields.{sprint_custom_field_id}", [])
        if sprints_data and isinstance(sprints_data, list):
            sprint_names = []
            for sprint_entry_text in sprints_data:
                # Sprint field often contains strings like:
                # "com.atlassian.greenhopper.service.sprint.Sprint@...[id=123,rapidViewId=45,state=CLOSED,name=My Sprint Name,startDate=...,endDate=...]"
                if isinstance(sprint_entry_text, str):
                    name_match = next((part for part in sprint_entry_text.split(',') if 'name=' in part), None)
                    if name_match:
                        sprint_names.append(name_match.split('name=')[1].split(',')[0]) # Extract name
                # Sometimes it might be an object if fetched differently (less common with *all fields)
                elif hasattr(sprint_entry_text, 'name'):
                     sprint_names.append(sprint_entry_text.name)
            return ", ".join(sprint_names) if sprint_names else None
        return None
    # Additional field handling logic...
```

This function:

1. Is marked with a leading underscore to indicate it's an internal implementation detail
2. Handles complex field transformations that would be too specific to expose in a public API
3. Contains domain-specific logic for Jira fields like sprints, epics, and custom fields
4. Uses the previously defined `_get_nested_attr()` function, showing how internal helpers work together

## Best Practices for Using Underscore Functions

Based on the examples from [jirax](https://github.com/ivishalgandhi/jirax), here are some best practices for using underscore functions:

### When to Use Underscore Functions

1. **Helper Functions**: When a function serves as a utility for other functions but doesn't need to be part of the public API
2. **Implementation Details**: When a function implements a specific algorithm or data transformation that users shouldn't depend on
3. **Complex Logic Encapsulation**: When you want to hide complex logic behind a simpler interface

### Benefits of Using Underscore Functions

1. **Code Organization**: They help organize code by clearly separating internal utilities from the public interface
2. **API Stability**: They allow you to change implementation details without breaking backward compatibility
3. **Documentation Clarity**: They signal to other developers which parts of the code are meant to be used directly

### Example: How [jirax](https://github.com/ivishalgandhi/jirax) Uses Underscore Functions

In [jirax](https://github.com/ivishalgandhi/jirax), the public function `extract_issue_data()` uses the internal `_get_nested_attr()` and `_get_computed_value()` functions to process Jira issues:

```python
def extract_issue_data(issues: List[Issue], jira: JIRA, config: Dict):
    """Extract data from Jira issues according to the configured field mappings."""
    # Implementation uses _get_nested_attr and _get_computed_value internally
    # but exposes a cleaner, more stable interface to users
```

This pattern allows [jirax](https://github.com/ivishalgandhi/jirax) to:

1. Present a clean, stable API to users
2. Handle complex Jira data structures internally
3. Evolve the implementation details as needed without breaking user code

## Conclusion

Underscore functions in Python are a powerful convention for indicating internal implementation details. As demonstrated by the [jirax](https://github.com/ivishalgandhi/jirax) project, they help create more maintainable code by clearly separating public APIs from internal utilities.

When designing your own Python packages, consider using underscore functions for implementation details that users shouldn't depend on directly. This will give you more flexibility to evolve your code while maintaining a stable public interface.
