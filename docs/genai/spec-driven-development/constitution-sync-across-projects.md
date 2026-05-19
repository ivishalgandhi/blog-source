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

When `const-sync` runs, it propagates `~/code/constitution/constitution.md` to each agent via its preferred mechanism:

| Agent | Target path | Mechanism |
|-------|------------|-----------|
| Pi / spec-kit | `$proj/.specify/memory/constitution.md` | **`ln -sf`** — live symlink to central constitution |
| Windsurf | `$proj/.windsurfrules` | **Redirect text** — tells Cascade to read `.specify/memory/constitution.md` |
| Devin | `$proj/.devin.md` | **`cp`** — static copy of constitution content |

- **Pi** symlinks mean the constitution is always current after a `const-pull`. No re-sync needed.
- **Windsurf** receives a thin redirect file (not the constitution itself) so project-specific rules can still be layered in if you migrate to `.windsurf/rules/` later.
- **Devin** gets a static copy because `.devin.md` is Devin's sole instruction channel and there is no multi-file rules format.

The sync runs over all directories under `~/code` up to depth 2 by default.

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
| `const-bootstrap` | One-time setup: create missing `.specify/memory/`, `.windsurfrules` redirect, and `.devin.md` across all projects |
| `const-sync [opts] [dir]` | Propagate constitution to agents; see flag table below |
| `const-amend "message"` | One-shot workflow: `git add` → commit → push → `const-sync` |

#### `const-sync` flags

| Flag | Agent |
|------|-------|
| `-p` / `--pi` | Pi / spec-kit only |
| `-w` / `--windsurf` | Windsurf redirect only |
| `-d` / `--devin` | Devin copy only |
| *(none)* | All agents |

Add an optional project directory at the end to scope to a single repo.

### Example Usage

```bash
# --- Daily pull (Pi symlinks update automatically; Devin needs const-sync) ---
const-pull                    # get latest from GitLab
const-sync                    # refresh all agents across all projects

# --- Scoped sync ---
const-sync -w ~/code/workops  # Windsurf redirect only, one project
const-sync -p -d              # Pi + Devin, all projects
const-sync ~/code/workops     # All agents, single project

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

Running `const-sync` (or `const-sync -w ~/code/workops`) produces output like:

```
Syncing from /Users/vishal/code/constitution/constitution.md ...
  pi    ✓ workops
  pi    ✓ mdbook-platform
  pi    ✓ skilldex
  pi    → 3 project(s)
  wind  ✓ workops
  wind  → 1 project(s)
  devin ✓ workops
  devin → 1 project(s)
```

A count of `0` for an agent means no matching projects were found. Run `const-bootstrap` first if a new agent type was added to a project.

## Adding a New Project

When you clone a new repo into `~/code/`:

```bash
# 1. If using Pi / spec-kit (or specify init)
mkdir -p ~/code/newproject/.specify/memory

# 2. If using Windsurf, nothing needed — const-sync writes .windsurfrules

# 3. If using Devin, nothing needed — const-sync writes .devin.md

# 4. Populate them
const-sync ~/code/newproject
```

Or simply run `const-bootstrap` after cloning — it discovers git repos and creates any missing agent files, then you can scoped-sync.

:::tip specify init
Running `specify init . --here` will overwrite `.specify/memory/constitution.md` with spec-kit's template. Repair it with:

```bash
const-sync -p ~/code/newproject
```
:::

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
| Sync all agents everywhere | `const-sync` |
| Sync Windsurf only, one project | `const-sync -w ~/code/workops` |
| Sync Pi + Devin everywhere | `const-sync -p -d` |
| Amend + commit + push + sync | `const-amend "commit message"` |
| Check GitLab status | `const-status` |
| Open in browser | `const-web` |
| Re-create missing agent files | `const-bootstrap` |
| Repair after `specify init` | `const-sync -p <dir>` |
| Edit zshrc via chezmoi | `chezmoi edit --apply ~/.zshrc` |

## Dependencies

| Tool | Purpose |
|------|---------|
| `glab` | GitLab CLI for `const-status` and `const-web` |
| `git` | Push/pull for `constitution` repo and dotfiles |
| `chezmoi` | Manages `.zshrc` so functions survive across machines |
