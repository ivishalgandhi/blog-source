---
slug: hermes-agent-orchestrator-devin-mcp
title: "Using Hermes Agent as an Orchestrator: Internal Sub-agents + External Devin Cloud"
authors:
  name: Vishal Gandhi
  url: https://github.com/ivishalgandhi
  image_url: https://github.com/ivishalgandhi.png
tags: [hermes-agent, devin, mcp, multi-agent, agent-orchestration, sub-agents, delegate-task]
---

> "The agent that owns the plan should not be the agent that owns every tool."
> — Anthropic, *Model Context Protocol Specification*

I was reviewing a pull request last week. It touched authentication, database migration, and frontend changes across three repositories. I needed to check if the migration was backward-compatible, verify the auth flow against our team's conventions, and ensure the frontend error handling matched our patterns. Three unrelated tasks, all tied to one PR.

I opened Hermes in my editor. I could have asked it to do everything sequentially, one task at a time. That would take forty minutes and burn through the context window. Instead, I used three things simultaneously:

1. **`delegate_task`** — Hermes spawned a sub-agent to check database compatibility
2. **`delegate_task`** — Another sub-agent to audit auth patterns against our team skill
3. **`devin_session_create`** via MCP — Devin took the heavy frontend task and ran it in its cloud workers

Hermes stayed as the orchestrator. It dispatched the work, waited for all three results, and synthesized a single PR review comment. Devin never knew about Hermes. The sub-agents never knew about each other. What connected them was one agent that knew what needed doing.

This post is about building that pattern: Hermes as the orchestration layer, with `delegate_task` for local parallel work and Devin's MCP server for cloud tasks that need more compute or isolation.

<!--truncate-->

## Two Different Parallelism Primitives

Hermes gives you two ways to parallelize work. They are not interchangeable.

### Primitive 1: `delegate_task` (Local Sub-agents)

`delegate_task` spawns child AIAgent instances with isolated context, restricted toolsets, and their own terminal sessions. Each child gets a fresh conversation. Only the final summary enters the parent's context.

| Property | `delegate_task` |
|---|---|
| Location | Your local machine |
| Isolation | Fresh conversation, no parent history |
| Toolsets | Restricted (you choose what each child gets) |
| Persistence | None — child dies when task finishes |
| Cost | Your LLM API key |
| Use case | Fast parallel tasks (code search, file analysis, testing) |

### Primitive 2: MCP (`devin_session_create`) — Cloud Delegation

MCP connects Hermes to external tool servers. Devin's MCP server at `https://mcp.devin.ai/mcp` exposes session management tools. Hermes calls them like any other tool.

| Property | Devin MCP |
|---|---|
| Location | Devin's cloud workers |
| Isolation | Full Devin session with its own plan/execute loop |
| Toolsets | Whatever Devin decides to use |
| Persistence | Devin session persists in their platform |
| Cost | Devin credits (ACU) |
| Use case | Heavy tasks (full PR creation, cross-repo refactoring, long-running work) |

```mermaid
flowchart TD
    subgraph "Hermes (Orchestrator)"
        direction TB
        H[Hermes Agent]
        T1[sub-agent 1: Code review]
        T2[sub-agent 2: Pattern audit]
        H -.delegate_task.-> T1
        H -.delegate_task.-> T2
    end

    subgraph "Devin (Cloud Worker)"
        direction TB
        D[Devin Session]
        W[Cloud VM]
        D --> W
    end

    H -->|MCP: devin_session_create| D
    T1 -->|Result| H
    T2 -->|Result| H
    D -->|MCP result| H

    PR["📝 Final PR Review Comment"] <--> H

    style H fill:#e8e0ff,stroke:#9999cc
    style T1 fill:#ffffff,stroke:#9999cc
    style T2 fill:#ffffff,stroke:#9999cc
    style D fill:#ffffcc,stroke:#cccc00
    style W fill:#ffffcc,stroke:#cccc00
```

## What Devin's MCP Server Exposes

| Tool | What it does |
|---|---|
| `devin_session_create` | Creates session with prompt, playbook, tags, ACU limit |
| `devin_session_search` | Lists sessions with filters |
| `devin_session_interact` | Status, messages, terminate, archive |
| `devin_session_events` | Full event stream (everything Devin did) |
| `devin_session_gather` | Wait for multiple sessions to finish |
| `devin_playbook_manage` | CRUD for playbooks |
| `devin_knowledge_manage` | CRUD for knowledge base entries |
| `devin_schedule_manage` | Recurring schedules with cron |
| `list_integrations` | GitHub, Jira, Linear, etc. |

Requires a Devin service user API key (`cog_` prefix).

## Real Workflow: PR Review Orchestration

Here is the exact workflow for the PR I described:

```mermaid
sequenceDiagram
    autonumber
    participant U as User (in Zed)
    participant H as Hermes
    participant S1 as Sub-agent A
    participant S2 as Sub-agent B
    participant DM as Devin MCP
    participant DC as Devin Cloud

    U->>H: "Review PR #249"
    H->>S1: delegate_task: "Analyze db/migration.sql for backward compat"
    H->>S2: delegate_task: "Audit auth.py against team skill security-patterns"
    H->>DM: devin_session_create("Review frontend changes in PR #249")
    DM->>DC: Create Devin session
    DC-->>DM: session_id: devin-abc123
    DM-->>H: session_id + url

    par Parallel Execution
        S1-->>H: "Migration is backward compatible. No breaking changes."
        S2-->>H: "Auth patterns match skill. One minor suggestion."
    and Devin Cloud
        DC-->>DM: (async work: browser testing, visual diff)
    end

    H->>DM: devin_session_gather(session_id)
    DM-->>H: "Frontend: 3 visual regressions, 1 accessibility issue"
    H->>H: Synthesize all three results
    H-->>U: "PR #249 Review: ✅ DB compat, ✅ Auth audit, ⚠️ 3 visual regressions"
```

Hermes did not wait for each task sequentially. It launched all three, waited for the slowest (Devin), and reported a summary.

## Setting Up the Orchestrator

### Step 1: Configure Devin MCP in Hermes

```yaml
# ~/.hermes/config.yaml
mcp_servers:
  devin:
    url: "https://mcp.devin.ai/mcp"
    headers:
      Authorization: "Bearer cog_your_devin_api_key"
    timeout: 120
```

Store the key in `~/.hermes/.env`:
```shell
$ echo 'DEVIN_API_KEY=cog_abc123' >> ~/.hermes/.env
```

### Step 2: Verify Tool Discovery

```shell
$ hermes acp
# In editor: "List available tools"
```

Expected: `devin_session_create`, `devin_session_gather`, `delegate_task` all listed.

### Step 3: Test Parallel Dispatch

Ask in the editor:
```
Check if this codebase has any open TODO comments, audit auth.py for security patterns, and create a Devin session to find unused CSS across the project.
```

Hermes will:
1. Call `delegate_task` for TODO analysis
2. Call `delegate_task` for auth audit
3. Call `devin_session_create` for CSS cleanup
4. Wait for all three
5. Synthesize results

### Step 4: Inspect the Sub-agent Tree

In Hermes TUI, run:
```shell
/agents
```

Or ask:
```
Show me all active sub-agents
```

You will see:
```json
[{
  "subagent_id": "subagent-xyz789",
  "parent_id": "session-abc123",
  "depth": 1,
  "goal": "Analyze db/migration.sql for backward compat",
  "model": "openrouter/gemini-3-flash-preview",
  "status": "running",
  "tool_count": 3
}]
```

## Trade-offs of the Three Approaches

| Approach | Speed | Isolation | Persistence | Cost | Best For |
|---|---|---|---|---|---|
| Sequential (one agent, all tasks) | Slowest | Low | Per session | Lowest | Simple tasks, ≤3 steps |
| `delegate_task` only | Fast | Fresh context each | None per child | API tokens | Parallel local analysis |
| `delegate_task` + Devin MCP | Moderate | Full cloud isolation | Devin persists | API + Devin credits | Mixed local + cloud workload |

## What ACP Has Nothing to Do With This

This orchestration pattern works whether Hermes is running:
- Via ACP in Zed/VS Code
- Via CLI in a terminal
- Via gateway in Discord
- Via cron as a scheduled job

ACP is only the transport between editor and Hermes. The orchestration logic — `delegate_task`, MCP calls, result synthesis — lives inside Hermes regardless of how the user connects.

## Try This Now

```shell
# 1. Verify Hermes has delegation enabled
# (it is on by default; check ~/.hermes/config.yaml)

# 2. Add Devin MCP server
$ cat >> ~/.hermes/config.yaml << 'EOF'
mcp_servers:
  devin:
    url: "https://mcp.devin.ai/mcp"
    headers:
      Authorization: "Bearer cog_your_key"
    timeout: 120
EOF

# 3. Restart Hermes
$ hermes acp

# 4. In editor:
# "Delegate three parallel tasks: search for TODOs, audit auth patterns,
#  and create a Devin session to analyze test coverage"
```

## Further Reading

- [Hermes Delegation Docs](https://hermes-agent.nousresearch.com/docs/user-guide/features/delegation)
- [Devin MCP Docs](https://docs.devin.ai/work-with-devin/devin-mcp)
- [MCP Specification](https://modelcontextprotocol.com)
