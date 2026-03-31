---
id: taskwarrior
title: Taskwarrior - CLI Task Management
sidebar_label: Taskwarrior
sidebar_position: 2
---

# Taskwarrior - CLI Task Management

Taskwarrior is a powerful command-line task management tool that helps you organize, track, and manage your tasks efficiently.

## Installing Taskwarrior 3.4.1 on WSL Ubuntu

This guide walks you through installing Taskwarrior version 3.4.1 on Windows Subsystem for Linux (WSL) running Ubuntu. Since this specific version may not be available in Ubuntu's default repositories, we'll build it from source.

### Prerequisites

- WSL with Ubuntu installed (e.g., Ubuntu 20.04, 22.04, or 24.04).
- Basic familiarity with terminal commands.

### Step-by-Step Installation

#### 1. Update Package List

Ensure your package list is up-to-date to avoid dependency issues.

```bash
sudo apt-get update
```

#### 2. Install Required Dependencies

Install tools and libraries needed to build Taskwarrior, including Git, CMake, Make, a C++ compiler, and UUID development files.

```bash
sudo apt-get install git cmake make g++ uuid-dev
```

#### 3. Clone the Taskwarrior Repository

Clone the official Taskwarrior repository from GitHub.

```bash
git clone https://github.com/GothenburgBitFactory/taskwarrior.git taskwarrior.git
```

#### 4. Navigate to the Repository

Move into the cloned directory.

```bash
cd taskwarrior.git
```

#### 5. Checkout Version 3.4.1

Switch to the specific 3.4.1 release tag to ensure the correct version.

```bash
git checkout v3.4.1
```

#### 6. Create and Enter Build Directory

Create a build directory for an out-of-source build and navigate into it.

```bash
mkdir build
cd build
```

#### 7. Configure the Build

Use CMake to configure the build process, optimizing for a release build.

```bash
cmake -S .. -B . -DCMAKE_BUILD_TYPE=Release
```

#### 8. Build Taskwarrior

Compile the source code to generate the Taskwarrior binary.

```bash
cmake --build .
```

#### 9. Install Taskwarrior

Install the compiled binary system-wide, typically to /usr/local/bin.

```bash
sudo cmake --install .
```

#### 10. Verify Installation

Run Taskwarrior to confirm it's installed. On first run, it may prompt you to set up a configuration file.

```bash
task
```

### Troubleshooting

- **Dependency Errors**: If the build fails, check CMake output for missing dependencies and install them using apt-get.
- **Command Not Found**: Ensure /usr/local/bin is in your PATH. Add it with:
  ```bash
  echo 'export PATH=$PATH:/usr/local/bin' >> ~/.bashrc
  source ~/.bashrc
  ```
- **Version Mismatch**: Verify you checked out v3.4.1 using git status.

## Adding Taskwarrior Autocompletion

If the Taskwarrior bash completion script wasn't installed during the source build, you can download it directly from the Taskwarrior GitHub repository and set it up.

### Steps to Enable Autocompletion

#### 1. Download the Completion Script

Fetch the bash completion script for Taskwarrior 3.4.1 and save it to your home directory:

```bash
wget https://raw.githubusercontent.com/GothenburgBitFactory/taskwarrior/v3.4.1/scripts/bash/task.sh -O ~/.task_completion.sh
```

#### 2. Move the Script to the Completion Directory

Move the downloaded script to the system's bash completion directory:

```bash
sudo mv ~/.task_completion.sh /usr/share/bash-completion/completions/task
```

#### 3. Source the Script

Enable autocompletion in the current session:

```bash
source /usr/share/bash-completion/completions/task
```

#### 4. Make It Persistent

Add the sourcing command to ~/.bashrc for future sessions:

```bash
echo 'source /usr/share/bash-completion/completions/task' >> ~/.bashrc
source ~/.bashrc
```

#### 5. Test Autocompletion

Type `task ad` and press Tab. It should complete to `task add` or display available options.

### Notes

- Ensure the bash-completion package is installed: `sudo apt-get install bash-completion`.
- Verify that ~/.bashrc includes:
  ```bash
  if [ -f /etc/bash_completion ]; then
      . /etc/bash_completion
  fi
  ```
- The download method is useful if the script wasn't included during installation or if you need to update it manually.

## Multiline Annotation Script for Taskwarrior

Taskwarrior's default annotation feature only supports single-line annotations. The following script enables multiline annotations by launching your preferred text editor.

### Features
- Add multi-line annotations to your tasks using your preferred editor
- Add single-line annotations as always (via CLI arguments) or using the editor

### Installation

1. Create a file named `tan` (taskwarrior annotation) in your PATH, e.g., `/usr/local/bin/tan`:

```bash
sudo nano /usr/local/bin/tan
```

2. Copy and paste the following script:

```bash
#!/usr/bin/env bash
#
# Helper for adding annotations to TaskWarrior tasks.
# Features:
# - Add multi-line annotations to your tasks using your preferred editor.
# - Add single-line annotations as always (via cli arguments) or using the editor.
#
# Copyright (C) 2021 Rafael Cavalcanti <https://rafaelc.org/dev>
# Copyright (C) 2016 djp <djp@cutter>
#
# Distributed under terms of the MIT license.
#

set -euo pipefail

trap 'echo An error ocurred.' ERR
trap '[[ -n ${annot_file:-} ]] && rm -f "$annot_file"' EXIT

# Constants
readonly script_name="$(basename "$0")"
readonly editor="${EDITOR:-vi}"

usage() {
    echo "Usage: $script_name filter [annotation]"
    echo "Filter must be provided in only one argument, quote if needed."
    exit 1
}

# Read arguments
[[ $# -eq 0 ]] && usage
readonly filter="$1"
shift
annot="$*"

# Check if any task exists
if ! task info "$filter" > /dev/null 2>&1; then
    echo "No tasks found."
    exit 1
fi

# Use annotation from CLI if provided
if [[ -n "$annot" ]]; then
    task $filter annotate "$annot"
    exit 0
fi

# Use annotation from editor
# Add file extension to get syntax highlighting
readonly annot_file="$(mktemp).md"
$editor "$annot_file"

if [[ "$(wc -l "$annot_file" | cut -d ' ' -f 1)" -gt 1 ]]; then
    annot="\n$(cat "$annot_file")"
else
    annot="$(cat "$annot_file")"
fi

# Print annotation if error saving, otherwise the user will lose it
if ! task $filter annotate "$annot"; then
    echo "Error annotating task. Here is your annotation:"
    echo
    echo "$annot"
fi
```

3. Make the script executable:

```bash
sudo chmod +x /usr/local/bin/tan
```

### Usage

1. To add a multiline annotation to a task with ID 1:

```bash
tan 1
```

This will open your default editor where you can write a multiline annotation.

2. To add a single-line annotation directly from the command line:

```bash
tan 1 "This is a single line annotation"
```

### Note
- The script uses your `$EDITOR` environment variable. If not set, it defaults to `vi`.
- The script requires Bash and standard Unix utilities.

### Citation
This script is sourced from [Rafael Cavalcanti's Gist](https://gist.githubusercontent.com/rc2dev/9ad4847a5a6fb829f616529fe7311b91/raw/4cc8e908efa324b4d35990f7a4e167376324c683/tan) and is distributed under the MIT license.
