---
sidebar_position: 4
title: Leveraging TOML for Configuration in Python
description: How to use TOML for clean, hierarchical configuration in Python applications with real-world examples from jirax
---

# Leveraging TOML for Configuration in Python

Configuration management is a critical aspect of any software project. In the [jirax](https://github.com/ivishalgandhi/jirax) project, I chose TOML (Tom's Obvious, Minimal Language) as the configuration format for its readability, simplicity, and hierarchical structure. This article explores how TOML is leveraged in jirax and provides practical examples of implementing TOML-based configuration in Python applications.

## Why TOML for Configuration?

TOML offers several advantages over other configuration formats:

1. **Human-readable**: TOML is designed to be easy to read and write
2. **Hierarchical structure**: Supports nested configurations with sections and subsections
3. **Strong data typing**: Clearly distinguishes between strings, numbers, booleans, and arrays
4. **No indentation issues**: Unlike YAML, TOML doesn't rely on indentation for structure
5. **Less verbose than JSON**: More concise and doesn't require quotes around every key

## Real-World Example: jirax Configuration

In the jirax project, TOML is used to manage all configuration aspects of the application, from API credentials to field mappings and display preferences.

### Example Configuration File

Here's a simplified version of the `config.example.toml` file from jirax:

```toml
# Jirax Configuration File Example

[jira]
# Your Jira instance URL
server = ""
# Authentication type - either "basic" or "bearer"
auth_type = "basic"
# Whether to verify SSL certificates
verify_ssl = true
# Connection timeout in seconds
timeout = 60

# For Basic Authentication (default):
token = ""
email = ""

[extraction]
# Default project to extract from if no project is specified
default_project = ""
# Default max results to fetch
max_results = 1000
# Default output directory for extractions
output_directory = "./exports"

[display]
# Show preview before exporting
preview = true
# Number of rows to show in preview
preview_rows = 5

[columns]
# Column names for CSV export
Sprint = "Sprint"
Key = "Key"
Issue_Type = "Issue Type"
Priority = "Priority"
Summary = "Summary"
Epic_Name = "Epic Name"
Assignee = "Assignee"
Status = "Status"
```

This configuration file demonstrates TOML's hierarchical structure with sections for different aspects of the application.

## Loading TOML in Python

The jirax project uses Python's `toml` package to parse configuration files. Here's how the configuration is loaded:

```python
import toml
from collections import OrderedDict

def load_config():
    """Load configuration from TOML file, prioritizing local, then user, then defaults."""
    default_config = {
        "jira": {"server": "", "token": "", "email": "", "auth_type": "basic", "verify_ssl": True},
        "extraction": {"default_project": "", "max_results": 1000, "output_directory": "./exports"},
        "display": {"preview": True, "preview_rows": 5},
        # More default configuration...
    }

    final_config = {
        "jira": default_config["jira"].copy(),
        "extraction": default_config["extraction"].copy(),
        "display": default_config["display"].copy(),
        # More sections...
    }

    # Check for configuration files in priority order
    config_file_to_load = None
    if LOCAL_CONFIG_PATH.exists():
        config_file_to_load = LOCAL_CONFIG_PATH
    elif CONFIG_PATH.exists():
        config_file_to_load = CONFIG_PATH

    if config_file_to_load:
        try:
            # Load configuration from TOML file
            loaded_from_file = toml.load(config_file_to_load)
            
            # Merge configuration from file with defaults
            for key, value_from_file in loaded_from_file.items():
                if key == "fields_setup" and isinstance(value_from_file, dict):
                    # Preserve order for fields setup
                    final_config["fields_setup"] = OrderedDict(value_from_file.items())
                elif key in final_config and isinstance(final_config[key], dict) and isinstance(value_from_file, dict):
                    # Merge nested dictionaries
                    update_nested_dict(final_config[key], value_from_file)
                else:
                    # Assign new or non-dict top-level items
                    final_config[key] = value_from_file
        except Exception as e:
            # Handle configuration loading errors
            print(f"Error loading config file: {e}")

    return final_config
```

This implementation demonstrates several best practices:

1. **Default configuration**: Providing sensible defaults for all settings
2. **Configuration hierarchy**: Checking multiple locations for configuration files
3. **Graceful error handling**: Continuing with defaults if configuration loading fails
4. **Deep merging**: Properly merging nested configuration sections

## Configuration Priority in jirax

The jirax project implements a thoughtful configuration priority system:

1. **Command-line arguments**: Highest priority, overrides all other settings
2. **Local configuration file**: `./config.toml` in the current directory
3. **User configuration file**: `~/.jirax/config.toml` in the user's home directory
4. **Default values**: Hardcoded in the application

This approach provides flexibility while maintaining sensible defaults.

## Moving from Hardcoded Values to TOML Configuration

One of the significant improvements in jirax was moving column names from hardcoded values in Python code to the TOML configuration file. This change demonstrates the evolution of a project toward more configurable and maintainable code.

### Before: Hardcoded Column Names

```python
# Old approach with hardcoded column names
fields_setup = OrderedDict([
    ("IssueKey", {"display_name": "Key", "source": "key"}),
    ("IssueSummary", {"display_name": "Summary", "source": "fields.summary"}),
    ("IssueType", {"display_name": "Issue Type", "source": "fields.issuetype.name"}),
    # More hardcoded fields...
])
```

### After: Column Names in TOML Configuration

```toml
# New approach with configuration in TOML
[columns]
Sprint = "Sprint"
Key = "Key"
Issue_Type = "Issue Type"
Priority = "Priority"
Summary = "Summary"
Epic_Name = "Epic Name"
```

```python
# Code now reads column names from configuration
columns_config = config.get("columns", {})
for internal_name, display_name in columns_config.items():
    # Use configuration values instead of hardcoded names
    # ...
```

This change made jirax more flexible and user-friendly, allowing users to customize column names without modifying the code.

## Advanced TOML Usage in jirax

### Dynamic Field Mapping

The jirax project uses TOML for dynamic field mapping between Jira API responses and CSV output:

```toml
[fields_setup]
IssueKey = { display_name = "Key", source = "key" }
IssueSummary = { display_name = "Summary", source = "fields.summary" }
IssueType = { display_name = "Issue Type", source = "fields.issuetype.name" }
Status = { display_name = "Status", source = "fields.status.name" }
Sprint = { display_name = "Sprint", source = "_computed.sprint" }
```

This approach allows for:

1. **Flexible field mapping**: Connecting any Jira field to any CSV column
2. **Computed fields**: Special handling for fields that require processing (prefixed with `_computed.`)
3. **Custom display names**: Showing user-friendly names in the CSV output

### TOML in Package Configuration

The jirax project also uses TOML for package configuration in `pyproject.toml`:

```toml
[project]
name = "jirax"
version = "0.1.0"
description = "A CLI tool for extracting Jira issues to CSV"
readme = "README.md"
authors = [
    {name = "Vishal Gandhi", email = "igandhivishal@gmail.com"}
]
license = {text = "MIT"}
requires-python = ">=3.8"
dependencies = [
    "jira==3.5.1",
    "click==8.1.7",
    "rich==13.6.0",
    "toml==0.10.2",
]

[project.scripts]
jirax = "jirax.jirax:cli"
```

This demonstrates how TOML can be used consistently throughout a project for different types of configuration.

## Best Practices for TOML Configuration

Based on the jirax implementation, here are some best practices for using TOML in Python projects:

1. **Provide example configuration**: Include a well-documented `config.example.toml` file
2. **Use type hints**: Leverage Python's type hints for configuration structures
3. **Implement configuration validation**: Validate configuration values to catch errors early
4. **Support multiple configuration locations**: Allow users to place configuration files in different locations
5. **Merge configurations intelligently**: Properly merge nested configuration sections
6. **Document configuration options**: Provide clear documentation for all configuration options
7. **Use sensible defaults**: Always have reasonable default values for all settings

## Conclusion

TOML provides an excellent balance of readability, flexibility, and structure for configuration files in Python applications. The jirax project demonstrates how TOML can be leveraged to create a highly configurable application with clean, hierarchical configuration.

By moving configuration from hardcoded values to TOML files, jirax became more maintainable and user-friendly. This approach can be applied to any Python project to improve flexibility and separation of concerns.

Whether you're building a simple script or a complex application, consider TOML for your configuration needs. Its combination of human-readability and structured data makes it an excellent choice for configuration files in Python projects.
