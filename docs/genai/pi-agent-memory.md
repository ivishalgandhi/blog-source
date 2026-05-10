---
sidebar_position: 1
title: Pi Agent Memory with pi-hermes-memory
description: How to set up persistent cross-session memory for the Pi coding agent
---

# Pi Agent Memory with pi-hermes-memory

:::info
**What you'll learn:**
- Why Pi forgets everything between sessions by default
- How to install and configure `pi-hermes-memory`
- How memory files are structured (MEMORY.md, USER.md, skills)
- How to bootstrap without a running Pi session
- Best practices: single source of truth for user profile
:::

## The Problem

Pi (the `pi-coding-agent` by mariozechner) starts each session with zero context. Every preference, infrastructure detail, and lesson learned is lost when the session ends. This wastes time re-establishing context.

## The Solution: pi-hermes-memory

`pi-hermes-memory` is a Pi extension that ports the memory system from Nous Research's Hermes agent. It provides:

| Feature | What it does |
|---|---|
| **Persistent Memory** | Facts, preferences, corrections survive across sessions |
| **Session Search** | SQLite FTS5 search across all past conversations |
| **Failure Memory** | Categorized memories: failures, corrections, insights, conventions |
| **Procedural Skills** | Reusable how-to docs saved automatically |
| **Auto-Consolidation** | Merges entries when core memory fills up |
| **Secret Scanning** | Blocks API keys/tokens from being persisted |

## Installation

```bash
pi install npm:pi-hermes-memory
```

Then restart Pi or run `/reload`.

## Memory Architecture

```
~/.pi/agent/memory/
├── MEMORY.md          # Agent's notes — env facts, project conventions, tool quirks
├── USER.md            # User profile — name, preferences, habits
├── sessions.db        # SQLite database (session history + extended memory)
└── skills/
    └── *.md           # Reusable procedures
```

### Core vs Extended Memory

| Tier | File | Injected? | Limit |
|---|---|---|---|
| Core Memory | `MEMORY.md` | Always | 5,000 chars |
| User Profile | `USER.md` | Always | 5,000 chars |
| Skills | `skills/*.md` | Index + on demand | Unlimited |
| Extended | `sessions.db` | Searchable only | Unlimited |

## Bootstrapping Without Tools

If you install the extension but haven't restarted Pi yet, the memory directory doesn't exist. Create it manually so the extension discovers it on next launch:

```bash
mkdir -p ~/.pi/agent/memory/skills
```

### Thin USER.md (Pointer Pattern)

If you already maintain a canonical profile elsewhere (e.g., Hermes on another machine), don't duplicate it. Use a thin pointer:

```markdown
§
Canonical user profile lives on M4 Mac at ~/.hermes/memories/USER.md.
Read via SSH when needed. Hermes is the source of truth.
§
Pi-specific preferences only below.
```

This prevents drift — update the profile in one place.

### MEMORY.md (Operational Facts)

Store infrastructure details Pi needs for tool calls:

```markdown
§
PVE host at 192.168.1.157 (LAN). Prefer LAN over Tailscale for automation.
§
User prefers gogcli for Google Workspace. gogcli v0.12.0 at ~/.local/bin/gogcli.
§
Work style: proactive checks, verify dates/times before presenting schedules.
```

### Creating a Skill

Skills are markdown files with frontmatter in `~/.pi/agent/memory/skills/`:

```markdown
---
name: chezmoi-workflow
description: Daily dotfiles backup using chezmoi
version: 1
created: 2026-05-10
updated: 2026-05-10
---
## When to Use
When user asks about dotfiles, backup, or new machine setup.

## Context
- Source dir: ~/.local/share/chezmoi
- Remote: git@gitlab.com:codewithvishal/dotfiles.git
- Config: autoCommit + autoPush

## Procedure
1. Edit: `chezmoi edit --apply ~/.zshrc`
2. Add: `chezmoi add ~/.newfile`
3. Auto-commit/push happens automatically
```

## Commands

Once Pi restarts with the extension loaded:

| Command | Purpose |
|---|---|
| `/memory-index-sessions` | Bulk-import past sessions into search DB |
| `/memory-insights` | Show everything in MEMORY.md and USER.md |
| `/memory-skills` | List all saved skills |
| `/memory-consolidate` | Manually merge entries to free space |
| `/memory-interview` | Pre-fill user profile with Q&A |

## Chezmoi Integration

Since `~/.pi/agent/memory/` lives inside `~/.pi/` (which is tracked by chezmoi), decide what to sync:

| File | Track? | Why |
|---|---|---|
| `MEMORY.md` | ✅ Yes | Plain text, useful across machines |
| `USER.md` | ✅ Yes | Thin pointer, no secrets |
| `skills/*.md` | ✅ Yes | Reusable knowledge |
| `sessions.db` | ❌ No | SQLite, machine-specific, actively written |

Add to `~/.local/share/chezmoi/.chezmoiignore`:

```
pi/agent/memory/sessions.db
pi/agent/memory/sessions.db-*
```

## Background Review Cost

Every ~10 turns (or 15 tool calls), the extension spawns a child `pi -p` process to review the conversation and extract memories. This costs one LLM API call per review cycle. For most usage, that's a few cents per session — cheap for persistent context.

## Alternatives Considered

| Extension | Best For | Why Not Chosen |
|---|---|---|
| `pi-memory` (jayzeng) | Semantic search fans | Needs `qmd` (Bun), no auto-learning loop |
| `pi-agent-memory` (claude-mem) | Multi-engine users | Requires claude-mem worker (Bun+uv+port 37777) |
| `@db0-ai/pi` | Simple auto-extraction | Less mature, no failure memory |

`pi-hermes-memory` wins for Pi-native zero-infrastructure operation with the richest feature set.

## References

- [pi-hermes-memory GitHub](https://github.com/chandra447/pi-hermes-memory)
- [Hermes Agent (upstream)](https://github.com/NousResearch/hermes-agent)
- [Pi Coding Agent](https://github.com/mariozechner/pi-mono)
