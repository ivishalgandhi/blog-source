---
slug: hermes-devin-mcp-integration
title: "MCP Mechanics: How Hermes Calls Devin as a Tool Server"
authors:
  name: Vishal Gandhi
  url: https://github.com/ivishalgandhi
  image_url: https://github.com/ivishalgandhi.png
tags: [mcp, hermes-agent, devin, multi-agent, agent-delegation, model-context-protocol]
---

> "The agent that owns the plan should not be the agent that owns every tool."
> — Anthropic, *Model Context Protocol Specification*

A few months ago, I had a problem: I needed to refactor a 5,000-line Python monolith into a modular package, write tests, and document it. Hermes Agent handled the refactoring. Hermes can read files, search code, and patch changes. But writing a full test suite from scratch across fifty modules? That felt like a second full-time job. I wanted Devin for that — the agent designed for end-to-end coding tasks.

The question was: how do I get them to work together without copy-pasting code between two browser tabs?

The answer is MCP — the Model Context Protocol. Devin exposes an MCP server. Hermes can connect to it as a tool. Hermes keeps the plan. Devin handles the heavy lifting. They never talk directly. They never need to. What happens between them is strictly tool calls and results.

This post is a step-by-step guide to wiring Hermes Agent to Devin's MCP server. It is not about ACP — that protocol connects editors to agents, and it is one-way. If you are looking for editor integration, see my companion post. This one is about agents orchestrating other agents.

<!--truncate-->

## What MCP Actually Does Between Agents

MCP is a protocol for an agent to call tools on an external server. Devin runs an MCP server at `https://mcp.devin.ai/mcp`. When you add it to Hermes, the Devin server looks like just another tool — `devin_session_create`, `devin_session_interact`, and five others.

```mermaid
graph TD
    subgraph "Hermes (Agent A)"
        P[Planning Layer]
        T[Tool Calls]
    end

    subgraph "Devin (Agent B) via MCP"
        DM[Devin MCP Server]
        S[Session Engine]
        C[Cloud Workers]
    end

    P -->|"1. Plan: refactor + test"| T
    T -->|"2. devin_session_create(prompt='refactor + test')"| DM
    DM -->|"3. Forward"| S
    S -->|"4. Create session"| C
    C -->|"5. session_id"| DM
    DM -->|"6. Return session_id"| T
    T -->|"7. devin_session_gather(wait for done)"| DM
    DM -->|"8. Return results"| P

    style P fill:#e8e0ff,stroke:#9999cc
    style T fill:#ffffff,stroke:#9999cc
    style DM fill:#ffffcc,stroke:#cccc00
    style S fill:#ffffcc,stroke:#cccc00
    style C fill:#ffffcc,stroke:#cccc00
```

The flow is fire-and-forget plus polling. Hermes creates a Devin session with a prompt, gets back a session ID, waits for completion with `devin_session_gather`, and reads the results. Devin does not know about Hermes. Devin only knows it received a session creation request.

## What Devin's MCP Server Exposes

| Tool | What it does |
|---|---|
| `devin_session_create` | Creates one or more sessions. Takes `prompt`, `title`, `playbook`, `ACU limit`, `tags`. Returns `session_id` and `url`. |
| `devin_session_search` | Lists sessions with filters by tags, time, playbook, or status. |
| `devin_session_interact` | Gets status, sends messages, sleeps, terminates, reads attachments.
| `devin_session_events` | Reads structured event stream from a session (every action Devin took, with output). |
| `devin_session_gather` | Waits for multiple sessions to settle (`finished`, `error`, `suspended`). Best for sequential orchestration. |
| `list_integrations` | Lists connected integrations (GitHub, Jira, Linear, etc.). |

All tools require authentication. Devin uses service user API keys (`cog_` prefix, available at https://devin.ai/settings).

## Prerequisites

- Hermes Agent v0.13.0+ installed with ACP support (`pip install 'hermes-agent[acp]'`)
- Devin API key (`cog_xxx` — go to https://devin.ai/settings → Service Users)
- Org ID if using enterprise (available in the same settings page)

## Step 1: Configure Devin MCP Server in Hermes

Hermes reads MCP servers from `~/.hermes/config.yaml`. Add a `mcp_servers.devin` entry:

```yaml
# ~/.hermes/config.yaml
mcp_servers:
  devin:
    url: "https://mcp.devin.ai/mcp"
    headers:
      Authorization: "Bearer cog_your_devin_api_key_here"
    timeout: 120
```

Wait. Devin's MCP server is Streamable HTTP, but Hermes' MCP tool configuration also supports stdio. Which transport should you use?

The answer: HTTP is the only valid transport for Devin's hosted MCP server. Devin used to support SSE (`/sse`) but deprecated it in March 2026. The `/mcp` endpoint (Streamable HTTP) is the current standard.

## Step 2: Restart Hermes to Load the MCP Server

```shell
$ hermes acp  # or just run hermes cli if testing locally
```

When Hermes starts, it discovers MCP servers from the config and registers their tools. The `tools.mcp_tool` module handles this automatically.

## Step 3: Verify Tools Are Available

In the editor (Zed, VS Code, or Hermes CLI), ask:

```
List all tools
```

Or in terminal mode:

```shell
$ hermes tools
```

You should see `devin_session_create`, `devin_session_search`, and the rest prefixed as MCP tools.

## Step 4: Create a Devin Session

Send this through Hermes:

```
Create a Devin session with the prompt: "Review the codebase in /Users/vishal/code/blog-source for deprecated API usage and open a PR with fixes."
```

Hermes will:

1. Call `devin_session_create` with the prompt
2. Receive a `session_id` and `url`
3. Report back: `Created session devin-abc123: https://app.devin.ai/sessions/abc123`

**Wait** — what about the working directory? Devin sessions run in Devin's cloud environment, not on your local machine. If you need Devin to access local files, you must push them to a GitHub repository first, or grant Devin read access to your repo via integration. The MCP `prompt` should reference the GitHub URL.

Example corrected prompt:

```
Create a Devin session: "Clone https://github.com/ivishalgandhi/blog-source, review for deprecated API usage, and open a PR with fixes."
```

## Step 5: Gather Results

After creating the session, tell Hermes:

```
Wait for the session to finish and show me a summary of what Devin did.
```

Hermes calls `devin_session_gather` with the `session_id`. When Devin finishes (status `finished`, `error`, or `suspended`), Hermes receives structured output.

Example response:

```json
{
  "session_id": "devin-abc123",
  "status": "finished",
  "structured_output": {
    "files_modified": ["src/auth.py", "src/db.py"],
    "pull_requests": ["https://github.com/ivishalgandhi/blog-source/pull/42"],
    "summary": "Replaced deprecated `datetime.utcnow()` with `datetime.now(timezone.utc)` in 12 files."
  }
}
```

## Step 6: Multi-Session Orchestration

For parallel tasks, create multiple sessions and wait for all:

```
Create three Devin sessions:
1. "Review PR #249 for memory leaks"
2. "Write unit tests for auth.py"
3. "Update documentation for the new API"

Then wait for all three to finish.
```

Hermes calls `devin_session_create` three times, collects three session IDs, and calls `devin_session_gather` with the list.

## How This Works Inside Hermes

The MCP tool discovery is automatic. Here is the chain:

```mermaid
sequenceDiagram
    autonumber
    participant H as Hermes AIAgent
    participant T as MCP Tool Module
    participant D as Devin MCP Server

    H->>T: Startup: load_mcp_servers()
    T->>D: POST /mcp (initialize)
    D-->>T: tools/capabilities list
    T-->>H: register_tool("devin_session_create", ...)

    H->>T: prompt("Create Devin session...")
    T->>D: tool_call(devin_session_create, args)
    D->>D: Forward to Devin Cloud
    D-->>T: {"session_id": "abc123", ...}
    T-->>H: inject result into LLM context
    H->>H: decide next action
```

Hermes treats `devin_session_create` no differently than `read_file` or `terminal`. It is just another tool with a JSON schema.

## Trade-offs

| Limitation | Why it exists | Workaround |
|---|---|---|
| Devin needs GitHub access | Cloud agent, no local filesystem | Push code to repo; reference GitHub URL in prompt |
| No bidirectional chat | MCP is request/response, not streaming | Use `devin_session_interact` for follow-up messages |
| Cost attribution | Devin runs on Devin's cloud, not your machine | Set ACU limit in session creation |
| No real-time progress | `session_gather` polls | Use `devin_session_events` for live event streaming |
| Authentication per client | Tokens are not shared across MCP clients | Store `cog_` key in `~/.hermes/.env`, never in chat |

## Why Not ACP?

ACP is Editor → Agent. It lets an editor connect to one agent at a time. It does not let Agent A call Agent B's tools. If you connected Hermes and Devin via ACP, you would need an editor that simultaneously spawns both as child agents and proxies messages between them. No editor does this today.

MCP gets you agent-to-agent delegation. ACP gets you editor-to-agent integration. They solve different problems.

## Try This Now

```shell
# 1. Get Devin API key
# Go to https://devin.ai/settings → Service Users → Generate key

# 2. Add to Hermes config
cat >> ~/.hermes/config.yaml << 'EOF'
mcp_servers:
  devin:
    url: "https://mcp.devin.ai/mcp"
    headers:
      Authorization: "Bearer cog_your_key_here"
    timeout: 120
EOF

# 3. Start Hermes
hermes acp

# 4. In editor chat:
# "List available tools"
# "Create a Devin session to add type hints to this repository"
```

## Further Reading

- [Devin MCP Documentation](https://docs.devin.ai/work-with-devin/devin-mcp)
- [Devin API Reference](https://docs.devin.ai/api-reference/overview)
- [MCP Specification](https://modelcontextprotocol.com)
- [Hermes Agent MCP Support](https://hermes-agent.nousresearch.com/docs/user-guide/features/mcp)
"