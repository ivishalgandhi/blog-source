# Exercise: Agent Client Protocol (ACP) Editor Integration

## Goal
Launch Hermes Agent as an ACP server and connect it to an editor (VS Code or Zed) via the Agent Client Protocol, confirming bidirectional JSON-RPC communication and tool execution.

## Time Required
25–35 minutes

## Prerequisites
- [ ] Python 3.11+ installed (`python --version`)
- [ ] `pip` or `uv` package manager
- [ ] OpenAI or Anthropic API key (free tier is fine)
- [ ] macOS / Linux / WSL terminal (Windows native shell not supported for stdio ACP)
- [ ] Zed v0.221+ **OR** VS Code with ACP Client extension installed

## Setup Commands

```shell
# 1. Create isolated project directory
$ mkdir -p ~/acp-lab && cd ~/acp-lab

# 2. Create virtual environment
$ python -m venv .venv && source .venv/bin/activate

# 3. Install Hermes Agent with ACP support
(.venv) $ pip install 'hermes-agent[acp]'

# 4. Verify installation
(.venv) $ hermes acp --check
Hermes ACP check OK
(.venv) $ hermes acp --version
0.13.0
```

## Architecture

```mermaid
graph TD
    subgraph "Your Machine"
        ACP[Hermes ACP Server]
        CFG["~/.hermes/config.yaml"]
        ENV["~/.hermes/.env"]
        M1[GitHub MCP]
        M2[File System]
    end

    subgraph "Editor"
        VSC[VS Code ACP Client]
        ZED[Zed Agent Panel]
    end

    subgraph "AI Provider"
        OAI[OpenAI API]
        ANT[Anthropic API]
    end

    VSC -->|stdio JSON-RPC| ACP
    ZED -->|stdio JSON-RPC| ACP
    ACP -->|MCP| M1
    ACP -->|tools| M2
    ACP -->|HTTP| OAI
    ACP -->|HTTP| ANT
    CFG --- ACP
    ENV --- ACP

    style ACP fill:#ffffcc,stroke:#cccc00
    style VSC fill:#e8e0ff,stroke:#9999cc
    style ZED fill:#e8e0ff,stroke:#9999cc
    style OAI fill:#ffffff,stroke:#9999cc
    style ANT fill:#ffffff,stroke:#9999cc
```

## Tasks

### Task 1: Configure AI Provider
**Run:**
```shell
(.venv) $ hermes model
```

**Expected output:** Interactive prompts for:
```
Select provider [1] OpenAI [2] Anthropic [3] ...
Enter API key: sk-...
Select model: gpt-4o / claude-sonnet-4.5
```

**Verify:**
```shell
(.venv) $ cat ~/.hermes/.env
OPENAI_API_KEY=sk-...
# or
ANTHROPIC_API_KEY=sk-ant-...
```

**Why this matters:** ACP mode inherits Hermes' runtime credentials. Without this, the ACP server will start but fail when the agent tries to call the LLM.

---

### Task 2: Test ACP Handshake
**Run:**
```shell
(.venv) $ echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":1,"clientInfo":{"name":"test","version":"1.0.0"}}}' | hermes acp
```

**Expected output (first 5 lines):**
```
{"jsonrpc":"2.0","id":1,"result":{"protocol_version":...
```

**Verify:** The response contains `agent_info`, `agent_capabilities`, and `auth_methods`.

**Why this matters:** The handshake is the first thing every ACP client performs. If this fails, nothing else works.

---

### Task 3: Start ACP Server in Foreground
**Run:**
```shell
(.venv) $ hermes acp
```

**Expected output:**
```
2026-05-16 13:34:35 [INFO] acp_adapter.entry: Loaded env from /Users/vishal/.hermes/.env
2026-05-16 13:34:35 [INFO] acp_adapter.entry: Starting hermes-agent ACP adapter
```

**Verify:** The process stays alive. It is waiting for stdin JSON-RPC messages.

**Why this matters:** ACP servers are foreground processes. The editor spawns and manages them.

---

### Task 4: Connect from Zed or VS Code

**Option A — Zed (v0.221+):**
1. Open Zed → Agent Panel
2. Click "+" → "ACP Registry"
3. Search "Hermes Agent" → Install
4. Start a new Hermes Agent thread
5. Send message: "List files in the current directory"

**Option B — VS Code:**
1. Install "ACP Client" extension
2. Open Command Palette → ACP: Add Agent
3. Name: `Hermes Agent`
4. Command: `hermes`
5. Args: `["acp"]`
6. Open ACP Chat panel → send message: "List files in the current directory"

**Expected behavior:** Agent responds with a file listing (via `read_file` or `terminal` tool).

**Verify:** Check the ACP server terminal — you should see `prompt` and `tool_call` JSON-RPC messages logged to stderr.

**Why this matters:** This is the entire value proposition. One agent, any editor, no custom integration.

---

### Task 5: Inspect ACP Registry Entry
**Run:**
```shell
(.venv) $ curl -s https://cdn.agentclientprotocol.com/registry/v1/latest/registry.json | jq '[(.agents | map(select(.name | contains("Hermes"))))[].name, (.agents | map(select(.name | contains("Hermes"))))[].version]'
"Hermes Agent"
"0.13.0"
```

**Verify:** `version` matches your local installation.

**Why this matters:** The registry auto-updates hourly. If your local version lags, you may hit protocol version mismatches.

---

### Task 6: Explore ACP Message Flow

Open the ACP server terminal. Send this through the editor chat:

```
Search for all TODO comments in the codebase
```

**Expected output (stderr logs):**
```
[INFO] acp_adapter.server: prompt received
[INFO] acp_adapter.session: new_session cwd=/Users/.../acp-lab
[tool_call] search_files pattern="TODO"
[tool_result] matches=...
```

**Why this matters:** Understanding the JSON-RPC traffic under the hood lets you debug protocol-level issues yourself.

## Common Pitfalls & Fixes

| Symptom | Cause | Fix |
|---|---|---|
| `hermes acp: command not found` | ACP extra not installed | `pip install 'hermes-agent[acp]'` |
| `Initialize from unknown` then silent exit | API key not set | Run `hermes model` or set key in `~/.hermes/.env` |
| Zed shows "Agent failed to start" | `uv` not installed for registry install | `curl -LsSf https://astral.sh/uv/install.sh | sh` |
| VS Code "Connection refused" | ACP server not running | Start `hermes acp` in foreground first |
| Agent cannot read files | CWD mismatch | Ensure you open the editor from the project directory |
| `/ask` not working | Editor does not support ACP slash commands | Update to latest Zed/VS Code ACP Client |

## Stretch Goals

- [ ] **Multi-session test:** Open two editor tabs → start two separate Hermes threads → observe concurrent JSON-RPC sessions
- [ ] **MCP integration:** Add a local MCP server (e.g., filesystem-server) to `~/.hermes/config.yaml` and observe ACP pass it through
- [ ] **Protocol inspection:** Use `websocat` or `nc` to send raw JSON-RPC to a running ACP server and log the responses

## Cleanup

```shell
# Deactivate virtual environment
$ deactivate

# Remove project directory
$ rm -rf ~/acp-lab
```

## Task 7: Connect Hermes to Devin via MCP

**Prerequisite:** Devin API key from https://devin.ai/settings

**Add Devin MCP server to Hermes:**

```shell
$ cat >> ~/.hermes/config.yaml << 'EOF'
mcp_servers:
  devin:
    url: "https://mcp.devin.ai/mcp"
    headers:
      Authorization: "Bearer cog_your_devin_api_key"
    timeout: 60
EOF
```

**Verify connection:**

```shell
(.venv) $ hermes acp  # In editor chat, ask: "List available tools"
```

**Expected:** `devin_session_create`, `devin_session_interact`, `devin_session_search` appear in the tool list alongside Hermes' built-in tools.

**Try:**
```
Create a Devin session to analyze this codebase's TODO comments
```

**Why this matters:** MCP is the bridge layer. ACP connects editor to agent; MCP connects agent to external tools — including other agents like Devin. This is how you build multi-agent workflows, not through ACP agent-to-agent.

## Self-Assessment

Before publishing the accompanying blog, verify you can:
- [ ] Run every setup command from a fresh virtual environment
- [ ] Hit every verification checkpoint
- [ ] Explain why stdio transport is the ACP default
- [ ] Identify at least one trade-off (e.g., ACP does not handle inline completions)
- [ ] Describe how ACP relates to MCP and A2A
- [ ] Name the three companies that govern ACP today
- [ ] Create a Devin session through Hermes MCP integration
