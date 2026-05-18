---
sidebar_position: 3
title: Constitution Sync Across Projects
description: "Operational workflow for syncing a single AI constitution from a central GitLab repo to multiple agents (Pi, Windsurf, Devin) across all local projects using chezmoi-managed shell functions."
---

# Constitution Sync Across Projects

This document describes the operational workflow for maintaining a **single source-of-truth constitution** in a GitLab repository and propagating it to every local project and AI agent.

## The Problem

You have:
- One ratified constitution stored at `~/code/constitution/constitution.md`
- Multiple local projects under `~/code/`, each used by different AI agents
- Three agents reading that constitution:
  - **Pi** / spec-kit → reads from `.specify/memory/constitution.md`
  - **Windsurf** → reads from `.windsurfrules`
  - **Devin** → reads from `.devin.md`

Manually copying the file into every project is error-prone and quickly drifts. The solution is a set of shell functions managed by chezmoi.

## Repository Layout

```
~/code/constitution/
├── constitution.md          # source of truth (GitLab-backed)
└── .git/                    # remote: git@gitlab.com:codewithvishal/constitution.git
```

## Propagation Paths

When `const-sync` runs, it copies `~/code/constitution/constitution.md` to:

| Agent | Target path | Target filename |
|-------|------------|-----------------|
| Pi / spec-kit | `$proj/.specify/memory/` | `constitution.md` |
| Windsurf | `$proj/.windsurfrules` | (replaces `.windsurfrules` entirely) |
| Devin | `$proj/.devin.md` | (replaces `.devin.md` entirely) |

The sync is **non-destructive for missing files** and **overwrites existing files** with the latest constitution. It searches all directories under `~/code` up to depth 2.

## Shell Functions

These functions live in your chezmoi-managed `~/.zshrc`.

### Variable Setup

```bash
export CONSTITUTION_HOME="$HOME/code/constitution"
export CONSTITUTION_FILE="$CONSTITUTION_HOME/constitution.md"
```

### Read / Inspect

| Function | Purpose |
|----------|---------|
| `const-pull` | Pull latest `constitution.md` from GitLab |
| `const-status` | Show GitLab repo status in terminal (via `glab`) |
| `const-web` | Open the GitLab repo in browser (via `glab`) |

### Write / Propagate

| Function | Purpose |
|----------|---------|
| `const-bootstrap` | One-time setup: create missing `.specify/memory/`, `.windsurfrules`, and `.devin.md` across all projects |
| `const-sync` | Copy `constitution.md` to **all** Pi, Windsurf, and Devin targets under `~/code` |
| `const-amend "message"` | One-shot workflow: `git add` → commit → push → `const-sync` |

### Example Usage

```bash
# --- Daily pull and sync ---
const-pull      # get latest from GitLab
const-sync      # push to all projects

# --- After editing the constitution ---
cd ~/code/constitution
vim constitution.md
const-amend "add Article IX: dependency discipline"

# --- First time on a machine / after new projects ---
const-bootstrap   # create missing agent files
const-sync        # populate them
```

## Chezmoi Management

Because `~/.zshrc` is managed by chezmoi, the function block is added via:

```bash
chezmoi edit --apply ~/.zshrc
```

Paste the constitution block into the chezmoi-managed source, save, and chezmoi auto-commits and auto-pushes to your dotfiles repo.

**Never edit `~/.zshrc` directly** — always use chezmoi so the functions persist across machines.

## Bootstrap Output

Running `const-sync` produces a report like:

```
Syncing from /Users/vishal/code/constitution/constitution.md ...
  pi    ✓ workops
  pi    ✓ mdbook-platform
  pi    ✓ skilldex
  pi    → 3 project(s)
  wind  ✓ workops
  wind  → 1 project(s)
  devin → 0 project(s)
```

A count of `0` means no matching files were found. Run `const-bootstrap` first if a new agent type was added to a project.

## Adding a New Project

When you clone a new repo into `~/code/`:

```bash
# 1. If using Pi / spec-kit
mkdir -p ~/code/newproject/.specify/memory

# 2. If using Windsurf
touch ~/code/newproject/.windsurfrules

# 3. If using Devin
touch ~/code/newproject/.devin.md

# 4. Populate them
const-sync
```

Or simply run `const-bootstrap` after cloning — it discovers git repos and creates any missing agent files.

## Amendment Workflow

When you want to change the constitution:

1. Edit `~/code/constitution/constitution.md`
2. Optionally update the `## Amendment Log` section inside it
3. Run:
   ```bash
   const-amend "describe the change"
   ```

This commits and pushes the new version to GitLab, then immediately runs `const-sync` to propagate it everywhere.

## Daily Commands Cheat Sheet

| Task | Command |
|------|---------|
| Pull latest from GitLab | `const-pull` |
| Copy to all projects/agents | `const-sync` |
| Amend + commit + push + sync | `const-amend "commit message"` |
| Check GitLab status | `const-status` |
| Open in browser | `const-web` |
| Re-create missing agent files | `const-bootstrap` |
| Edit zshrc via chezmoi | `chezmoi edit --apply ~/.zshrc` |

## Dependencies

| Tool | Purpose |
|------|---------|
| `glab` | GitLab CLI for `const-status` and `const-web` |
| `git` | Push/pull for `constitution` repo and dotfiles |
| `chezmoi` | Manages `.zshrc` so functions survive across machines |
