---
title: "Git Workflow for Multiple Developers: Incorporating Changes from Another Branch"
description: "A step-by-step guide to managing Git repositories when multiple developers work on different features"
sidebar_position: 2
---

# Git Workflow for Multiple Developers: Incorporating Changes from Another Branch

This tutorial demonstrates how to manage a Git repository when multiple developers work on different features, with one developer merging their changes before another finishes. It focuses on ensuring Developer 1’s feature branch includes Developer 2’s logging changes.

## Step 1: Set Up the Repository
- Clone the repository:
  ```bash
  git clone https://example.com/project.git
  cd project
  ```
- Verify you’re on the main branch:
  ```bash
  git checkout main
  ```

## Step 2: Developer 1 Starts Working on Feature Enhancement
- Create a feature branch:
  ```bash
  git checkout -b feature/dashboard
  ```
- Make changes and commit:
  ```bash
  echo "Dashboard: New UI component" > dashboard.txt
  git add dashboard.txt
  git commit -m "Add dashboard UI component"
  ```

## Step 3: Developer 2 Starts Working on Logging
- Create a feature branch:
  ```bash
  git checkout -b feature/logging
  ```
- Make changes and commit:
  ```bash
  echo "Logging: Added user action tracking" > logging.txt
  git add logging.txt
  git commit -m "Add user action logging"
  ```

## Step 4: Developer 2 Merges Logging into Main
- Switch to main:
  ```bash
  git checkout main
  ```
- Merge the logging branch:
  ```bash
  git merge feature/logging
  ```
- Push to remote:
  ```bash
  git push origin main
  ```

## Step 5: Developer 1 Incorporates Main Changes into Their Feature Branch
- Switch to feature branch:
  ```bash
  git checkout feature/dashboard
  ```
- Pull and rebase:
  ```bash
  git pull --rebase origin main
  ```
- Resolve conflicts (if any):
  - Edit conflicting files.
  - Stage resolved files:
    ```bash
    git add <resolved-file>
    ```
  - Continue rebase:
    ```bash
    git rebase --continue
    ```
  - Abort if needed:
    ```bash
    git rebase --abort
    ```

## Step 6: Developer 1 Finishes Their Work
- Continue development and commit:
  ```bash
  echo "Dashboard: Added interactive elements" >> dashboard.txt
  git add dashboard.txt
  git commit -m "Add interactive dashboard elements"
  ```
- Merge into main:
  ```bash
  git checkout main
  git pull origin main
  git merge feature/dashboard
  git push origin main
  ```

## Best Practices
- **Regular Rebasing**: Periodically run `git pull --rebase origin main` to stay updated.
- **Team Communication**: Coordinate to minimize conflicts.
- **Descriptive Commits**: Use clear branch names and commit messages.
- **Pull Requests**: Use pull requests for code reviews before merging.