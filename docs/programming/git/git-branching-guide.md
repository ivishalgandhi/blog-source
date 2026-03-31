---
sidebar_position: 1
title: Git Branching Guide
description: A comprehensive guide to Git branching, switching branches, and working across multiple devices
---

# Git Branching Guide

Git branching is a powerful feature that allows you to work on different versions of your codebase simultaneously. This guide covers essential branching operations, with a focus on switching between branches, working with remote branches, and maintaining workflow consistency across multiple computers.

## Understanding Git Branches

A branch in Git is simply a lightweight movable pointer to a commit. The default branch in Git is called `main` (or `master` in older repositories). When you create a new branch, Git creates a new pointer to the same commit you're currently on.

```bash
# List all branches (local only)
git branch

# List all branches with additional details (last commit)
git branch -v

# List all remote branches
git branch -r

# List all branches including remote branches
git branch -a

# View tracking relationships between local and remote branches
git branch -vv
```

### Real-World Example: Feature Branch in [jirax](https://github.com/ivishalgandhi/jirax)

In the [jirax](https://github.com/ivishalgandhi/jirax) project, I used a feature branch to implement a significant enhancement: moving column names from hardcoded values in Python code to configurable settings in a TOML file.

Here's the branch structure:

```
* c3197ac (feature/column-names-in-config) Implement custom column ordering from TOML config file
* 4a80f8a Move column names to config.toml instead of hardcoding in .py file
* c5b7d53 (main) Remove debug output statements for cleaner console output
```

The feature branch `feature/column-names-in-config` was created to:

1. Move hardcoded column names from the Python file to the configuration file
2. Implement custom column ordering based on the configuration
3. Keep these changes isolated until they were fully tested

This branching strategy allowed me to:
- Continue working on the feature without affecting the stable main branch
- Make multiple commits to refine the implementation
- Test the changes thoroughly before merging
- Keep a clean commit history that clearly shows the purpose of each change

The branch modified two key files:
- `config.example.toml`: Added new configuration options for column names and ordering
- `jirax/jirax.py`: Updated the code to read column names from the config file instead of using hardcoded values

This is a perfect example of how feature branches enable parallel development streams, allowing you to work on new features without disrupting the main codebase.

## Creating and Switching Branches

### The Modern Way: `git switch`

Git introduced the `switch` command in version 2.23 to make branch operations more intuitive.

```bash
# Create and switch to a new branch
git switch -c new-feature

# Switch to an existing branch
git switch main
```

### The Traditional Way: `git checkout`

Before `git switch`, the `checkout` command was used for switching branches.

```bash
# Create and switch to a new branch
git checkout -b new-feature

# Switch to an existing branch
git checkout main
```

## Working with Remote Branches

Remote branches are references to the state of branches on your remote repositories. Understanding the relationship between local and remote branches is crucial for effective collaboration.

### Understanding Remote vs. Local Branches

1. **Local branches** exist only on your machine
2. **Remote branches** exist on the remote repository (like GitHub, GitLab)
3. **Remote-tracking branches** are local references that represent the state of remote branches

When you clone a repository, Git creates a local branch (typically `main`) and a remote-tracking branch (`origin/main`). These branches don't automatically stay in sync - you need to explicitly communicate with the remote to update them.

### Fetching Remote Branches

```bash
# Fetch all branches from remote
git fetch origin

# Fetch a specific branch
git fetch origin feature-branch
```

### Git Fetch vs. Git Pull

The difference between `git fetch` and `git pull` is one of the most important concepts to understand in Git.

#### Git Fetch

```bash
git fetch [remote] [branch]
```

What `git fetch` does:

1. Downloads new data from the remote repository
2. Updates your remote-tracking branches
3. **Does NOT** modify your working directory or local branches
4. **Does NOT** automatically merge or rebase changes into your local branches

Example workflow:
```bash
# Download updates from remote
git fetch origin

# See what changes exist between your local main and origin/main
git log main..origin/main

# Decide what to do with those changes
```

#### Can You Undo a Git Fetch?

Unlike many Git operations, `git fetch` doesn't change your working directory or local branches, so there's technically nothing to "undo" in your actual code. However, you can reset the state of your remote-tracking branches if needed:

```bash
# First, find the previous state of the remote-tracking branch in the reflog
git reflog show origin/main

# Example output:
# 5a3f8bc (origin/main@{0}) fetch: fast-forward
# 72baf52 (origin/main@{1}) fetch: fast-forward

# Reset the remote-tracking branch to its previous state
git update-ref refs/remotes/origin/main 72baf52
```

In practice, it's rarely necessary to undo a fetch because:
1. It doesn't modify your working directory or local branches
2. You can simply choose not to merge or rebase the fetched changes
3. You can always fetch again to get the latest state

If you fetched changes you don't want to integrate, just don't run `git merge` or `git pull`.

#### Git Pull

```bash
git pull [remote] [branch]
```

What `git pull` does:

1. Runs `git fetch` to download data from the remote repository
2. **Immediately** integrates those changes into your current local branch
3. By default, it performs a merge, but can be configured to rebase instead

Behind the scenes, `git pull` is equivalent to:
```bash
git fetch
git merge origin/current-branch  # or git rebase if configured
```

This means if you need to undo a `git pull`, you're actually undoing the merge or rebase that happened after the fetch:

```bash
# Undo a pull that was a merge (the default)
git reset --hard ORIG_HEAD

# Undo a pull that was a rebase
# First find the previous state in reflog
git reflog
# Then reset to the commit before the rebase
git reset --hard HEAD@{1}  # Adjust the number as needed
```

#### Choosing Between Fetch and Pull

| Use `git fetch` when you want to | Use `git pull` when you want to |
|----------------------------------|--------------------------------|
| See changes before integrating them | Quickly update your branch with remote changes |
| Review commits before merging | You're confident there are no conflicts |
| Maintain more control over the integration process | Simplify your workflow |
| Update multiple branches before deciding what to do | You only need to update your current branch |

### Checking Out Remote Branches

When you want to work on a branch that exists only on the remote:

```bash
# First, fetch all remote branches
git fetch origin

# Create a local branch that tracks the remote branch
git switch -c feature-branch origin/feature-branch

# Alternatively, using checkout
git checkout -b feature-branch origin/feature-branch

# Shorthand if the branch names match
git checkout --track origin/feature-branch
```

### Verifying Remote Branches

Before starting work, it's often good to verify which remote branches exist:

```bash
# List all remote branches
git branch -r

# Show details about a remote branch
git remote show origin
```

## Working Across Multiple Computers

When you work on different machines, keeping your Git workflow consistent is crucial.

### Best Practices for Multi-Device Git Workflow

1. **Always Pull Before Starting Work**

   ```bash
   git pull origin your-branch
   ```

2. **Push Regularly**

   ```bash
   git push origin your-branch
   ```

3. **Use Branch Tracking**

   Set up branch tracking to simplify push/pull operations:

   ```bash
   # Set upstream tracking
   git branch --set-upstream-to=origin/feature-branch feature-branch

   # After this, you can simply use:
   git pull
   git push
   ```

4. **Stash Changes When Switching Devices**

   If you need to switch computers before committing:

   ```bash
   # On computer 1: Save your work in progress
   git stash save "WIP: Feature description"
   git push origin your-branch

   # On computer 2: Get the latest changes and your stashed work
   git pull origin your-branch
   git stash list # Check if stash was pushed with the branch
   git stash apply # Apply the stashed changes
   ```

   Note: Git stashes are not automatically pushed to remote repositories. Consider using commits with clear "WIP" (Work In Progress) messages instead.

### Using Git Worktrees for Multiple Branches

If you're working on multiple branches simultaneously, Git worktrees can help:

```bash
# Create a new worktree for a branch
git worktree add ../project-feature-branch feature-branch

# Now you have two working directories, each on a different branch
```

## Resolving Branch Switching Issues

Sometimes you might encounter issues when trying to switch branches:

### Dealing with Uncommitted Changes

```bash
# If you have uncommitted changes that conflict with the branch you're switching to
git stash
git switch other-branch
git stash pop # When you switch back
```

### Checking for Unpushed Commits

Before switching computers, check if you have any unpushed commits:

```bash
# Show commits that haven't been pushed to the remote
git log origin/your-branch..your-branch
```

## Advanced Branch Management

### Cleaning Up Old Branches

```bash
# Delete a local branch
git branch -d old-branch

# Delete a remote branch
git push origin --delete old-branch

# Prune tracking branches that no longer exist on remote
git fetch --prune
```

### Renaming Branches

```bash
# Rename the current branch
git branch -m new-name

# Rename a specific branch
git branch -m old-name new-name
```

## Checking Branch Status

### Viewing Differences Between Branches

```bash
# Show what commits are in branch-a that aren't in branch-b
git log branch-b..branch-a

# Show difference between local branch and its remote tracking branch
git log origin/main..main  # Shows local commits not yet pushed

# View changes that would be pulled from remote
git log main..origin/main  # Shows remote commits not in local branch
```

### Checking If You Need to Push or Pull

```bash
# See if your branch is ahead, behind, or both
git status -sb

# More detailed view of what commits differ
git fetch
git log --oneline --graph --all -10
```

## Conclusion

Effective branch management is essential for a smooth Git workflow, especially when working across multiple devices. By following these practices, you can ensure your work remains consistent and synchronized regardless of which computer you're using.

Remember the key steps:
1. Fetch and pull before starting work (understanding the difference between the two)
2. Push changes regularly
3. Set up proper branch tracking
4. Use stash or WIP commits when switching devices
5. Regularly clean up unused branches
6. Use appropriate branch viewing commands to understand your repository state

These habits will help you maintain a clean and efficient Git workflow across all your development environments.
