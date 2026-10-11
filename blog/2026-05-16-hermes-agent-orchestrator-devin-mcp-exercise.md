# Exercise: Hermes Agent Orchestrator with Sub-agents + Devin MCP

## Goal
Configure Hermes as an orchestrator that dispatches parallel work three ways simultaneously: sequential reasoning, local `delegate_task` sub-agents, and Devin MCP cloud sessions. Then synthesize all results into a single report.

## Time Required
30–40 minutes

## Prerequisites
- [ ] Hermes Agent v0.13.0+ with ACP support
- [ ] Devin account with service user API key (`cog_` prefix)
- [ ] Public GitHub repository for Devin to analyze
- [ ] Zed v0.221+ or VS Code with ACP Client installed

## Architecture

```mermaid
flowchart TD
    subgraph "Zed Editor"
        TAB1[Tab: Hermes Orchestrator]
        TAB2[Tab: Devin Agent]
    end

    subgraph "Hermes Process"
        H[Hermes Agent]
        SUB1[Sub-agent Alpha]
        SUB2[Sub-agent Beta]
        MEM[Persistent Memory]
        H -.delegate_task.-> SUB1
        H -.delegate_task.-> SUB2
        H --> MEM
    end

    subgraph "Devin Cloud"
        DM[Devin MCP Server]
        DS[Devin Session]
        DC[Cloud Workers]
    end

    subgraph "Shared"
        GH[GitHub Repo]
        FS[Local Filesystem]
    end

    TAB1 -->|ACP stdio| H
    TAB2 -->|ACP stdio| DM
    H -->|tools| FS
    H -->|MCP| DM
    H -->|memory| MEM
    DM -->|HTTP| DS
    DS -->|work| DC
    DC -->|PR| GH

    style TAB1 fill:#e8e0ff,stroke:#9999cc
    style TAB2 fill:#e8e0ff,stroke:#9999cc
    style H fill:#ffffcc,stroke:#cccc00
    style SUB1 fill:#ffffff,stroke:#9999cc
    style SUB2 fill:#ffffff,stroke:#9999cc
    style DM fill:#ffffcc,stroke:#cccc00
    style DS fill:#ffffcc,stroke:#cccc00
```

## Tasks

### Task 1: Start Hermes in Orchestrator Mode

**Run:**
```shell
$ hermes acp
```

**Open two tabs in Zed:**
1. Install Hermes Agent via ACP Registry
2. Start a new Hermes conversation

**Verify:**
```
Show version
```

**Expected:** `Hermes Agent v0.13.0`

**Why this matters:** You need a persistent Hermes session to orchestrate multiple sub-agents and Devin sessions.

---

### Task 2: Verify Sub-agent Capability

**Ask Hermes:**
```
List all tools you have access to
```

**Verify `delegate_task` is listed** with description:
```
delegate_task — Spawn isolated child agents for parallel workstreams
```

**Verify sub-agent limits are reasonable:**
```
What are your sub-agent configuration limits?
```

**Expected:** `max_concurrent_children: 3`, `max_spawn_depth: 1` (or higher if configured).

**Why this matters:** If delegation is disabled or depth is 0, you cannot spawn sub-agents.

---

### Task 3: Spawn a Simple Sub-agent

**Ask Hermes:**
```
Spawn a sub-agent with goal: "Search this codebase for all files containing 'TODO' and report the file names and line numbers"
```

**What Hermes does internally:**
1. Calls `delegate_task(goal=..., context=..., toolsets=["file", "search_files"])`
2. Creates child AIAgent with fresh context
3. Child runs in its own thread
4. When done, child returns structured summary
5. Parent (Hermes) receives the result

**Expected result:**
```
Sub-agent result:
- src/auth.py: line 42: # TODO: add rate limiting
- src/db.py: line 89: # TODO: migrate to async
- tests/test_api.py: line 15: # TODO: add edge case tests
```

**Why this matters:** This is the building block. One sub-agent per independent task.

---

### Task 4: Spawn Multiple Parallel Sub-agents

**Ask Hermes:**
```
Create three parallel sub-agents:
1. Search for all TODO comments
2. Count total lines of Python code
3. List all files modified in the last 7 days

Return a combined summary.
```

**What Hermes does internally:**
```python
delebate_task(tasks=[
    {"goal": "Search for TODO comments...", "toolsets": ["file", "search_files"]},
    {"goal": "Count lines of Python code...", "toolsets": ["terminal", "file"]},
    {"goal": "List files modified in last 7 days...", "toolsets": ["terminal"]}
])
```

**Expected result:** Three independent results combined into one summary.

**Verify parallel execution:** Check the `/agents` overlay (TUI) or ask:
```
Show me all active sub-agent statuses
```

**Why this matters:** Parallel sub-agents are where Hermes gets its speed. Each runs in its own thread, isolated, with its own tool budget.

---

### Task 5: Add Devin MCP Server

**Configure:**
```shell
$ cat >> ~/.hermes/config.yaml << 'EOF'
mcp_servers:
  devin:
    url: "https://mcp.devin.ai/mcp"
    headers:
      Authorization: "Bearer cog_your_devin_api_key"
    timeout: 120
EOF
```

**Restart Hermes:**
```shell
$ hermes acp
```

**Verify tool discovery:**
```
List available tools (filter for devin)
```

**Expected:** `devin_session_create`, `devin_session_gather`, `devin_session_interact`

**Why this matters:** Devin is now available as a tool inside Hermes' orchestration logic.

---

### Task 6: Orchestrate Sub-agents + Devin Simultaneously

**Open a separate Zed Tab with Devin** (via ACP Registry → install Devin).

**Ask Hermes:**
```
Do these three things in parallel and give me a combined report:
1. (Sub-agent) Search for all TODO comments in this codebase
2. (Sub-agent) Count lines of code per language
3. (Devin session) Create a session to analyze https://github.com/YOUR_USERNAME/YOUR_REPO for deprecated API usage
```

**What happens step by step:**

```mermaid
sequenceDiagram
    autonumber
    participant U as User
    participant H as Hermes Orchestrator
    participant S1 as Sub-agent 1
    participant S2 as Sub-agent 2
    participant DM as Devin MCP Server

    U->>H: Request with 3 parallel tasks
    H->>S1: delegate_task(goal="Search TODOs")
    H->>S2: delegate_task(goal="Count LOC")
    H->>DM: devin_session_create(prompt="Analyze for deprecated APIs")
    DM-->>H: session_id: devin-abc123

    par Local Agents
        S1-->>H: TODO list result
        S2-->>H: LOC counts
    and Cloud
        DM-->>H: (Devin processing...)
    end

    H->>DM: devin_session_gather(session_id)
    DM-->>H: Devin analysis complete
    H->>H: Synthesize 3 results
    H-->>U: Combined report
```

**Expected combined report:**
```
Report:
---
Local Analysis
- 12 TODO comments found
- Python: 4,200 lines, JavaScript: 1,800 lines

Devin Cloud Analysis
- 3 deprecated APIs detected
- Pull request created: https://github.com/.../pull/42
```

**Why this matters:** This is the orchestration pattern. Hermes is the conductor. Devin and sub-agents are the orchestra. The user only talks to the conductor.

---

### Task 7: Inspect the Sub-agent Tree

**Ask Hermes:**
```
Show me all sub-agents I've spawned in this session, their goals, and their completion status
```

**Verify structure:**
```json
[{
  "subagent_id": "subagent-alpha-789",
  "parent_id": "session-main-123",
  "depth": 1,
  "goal": "Search for TODO comments",
  "status": "completed",
  "tool_count": 4
}, {
  "subagent_id": "subagent-beta-456",
  "parent_id": "session-main-123",
  "depth": 1,
  "goal": "Count LOC per language",
  "status": "completed",
  "tool_count": 2
}]
```

**Why this matters:** The sub-agent tree is Hermes' audit log. It shows what was attempted, what completed, and how many API calls each child consumed.

---

### Task 8: Persistent Memory Across Sessions

**Ask Hermes:**
```
Save to memory: "Our team uses rate limiting on all API endpoints. Check auth.py for compliance in future reviews."
```

**Verify:**
```
Search memory for "rate limiting"
```

**Expected:** The memory entry appears.

**Why this matters:** Unlike sub-agents (isolated, per-session), `memory` persists across Hermes sessions. When you restart Hermes tomorrow, it still knows your team's conventions.

## Common Pitfalls

| Symptom | Cause | Fix |
|---|---|---|
| `delegate_task` not found | Delegation disabled | Check `~/.hermes/config.yaml` delegation settings |
| Sub-agent times out silently | Auth failure or zero calls | Check `~/.hermes/logs/subagent-timeout-...` |
| Devin tools not listed | MCP server not loaded | Restart Hermes after every config change |
| 401 on Devin | Wrong API key format | Must use `cog_` prefix, not legacy `apk_` |
| Results not combined | Parent didn't wait | Use explicit `gather` or ask for synthesis |
| Two Devin tabs confused | Each ACP connection is separate | Only one tab should orchestrate via MCP |

## Stretch Goals

- [ ] **Nested orchestration:** Configure `max_spawn_depth: 2`, spawn an orchestrator sub-agent that spawns leaf sub-agents
- [ ] **Interrupt propagation:** Start a long sub-agent, ask Hermes to interrupt it, verify `/agents` shows cancellation
- [ ] **Skill delegation:** Store a team skill, have a sub-agent load it for a specialized audit
- [ ] **MCP multi-server:** Add both Devin and a browser MCP server, have sub-agents use both

## Cleanup

```shell
# Remove Devin MCP config
$ sed -i '' '/mcp_servers:/,/timeout: 120/d' ~/.hermes/config.yaml

# Clear test memory entries
# In Hermes: "Remove memory about rate limiting tests"
```

## Self-Assessment

Before publishing, you should be able to:
- [ ] Explain the difference between `delegate_task` (local) and Devin MCP (cloud)
- [ ] Run a parallel orchestration with sub-agents + Devin simultaneously
- [ ] Inspect the sub-agent tree and understand which tasks succeeded
- [ ] Explain why ACP is Editor→Agent only and not Agent→Agent
- [ ] Describe when to use sequential reasoning vs parallel sub-agents vs cloud delegation
- [ ] Explain how memory persists across sessions while sub-agents are isolated
