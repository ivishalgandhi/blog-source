# Adding MCP (Model Context Protocol) to an Existing Go CLI

> A practical guide based on how the top Go CLI projects on GitHub did it — dual transport (stdio + HTTP).

---

## Table of Contents

1. [The Goal](#1-the-goal)
2. [Reference Projects (Real Go CLIs That Expose MCP)](#2-reference-projects)
3. [Architecture Patterns (How They Did It)](#3-architecture-patterns)
4. [Option A: The 18-Line Approach (ophis + Cobra)](#4-option-a-the-18-line-approach)
5. [Option B: Manual Integration with mcp-go (mark3labs)](#5-option-b-manual-integration)
6. [Option C: Official go-sdk (modelcontextprotocol)](#6-option-c-official-go-sdk)
7. [Option D: Zero-Dependency Stdlib-Only](#7-option-d-zero-dependency-stdlib-only)
8. [Dual Transport: stdio + HTTP in One Binary](#8-dual-transport)
9. [Testing & Debugging Your MCP Server](#9-testing--debugging)
10. [Packaging & Distribution](#10-packaging--distribution)
11. [Decision Matrix](#11-decision-matrix)

---

## 1. The Goal

You have an existing Go CLI. You want to add an `mcp` subcommand so users can:

```bash
# stdio mode (for Claude Desktop, Cursor, VS Code)
mycli mcp start

# HTTP mode (for remote agents, multi-client, production)
mycli mcp serve --port 8080
```

AI clients then discover your CLI's commands as typed MCP tools.

---

## 2. Reference Projects

Real Go CLIs that added MCP support — ranked by relevance to your use case:

### 2.1 github/github-mcp-server — 30,219 stars

The definitive reference. Go binary, Cobra CLI, both stdio + HTTP.

```
Architecture:
  cmd/github-mcp-server/main.go    → Cobra root + stdioCmd + httpCmd
  pkg/github/server.go             → MCP server factory
  pkg/github/tools/                → Individual tool implementations
  pkg/inventory/                   → Tool/resource/prompt registry
```

**Key takeaway:** Uses `mcp.Server` (official go-sdk). Registers tools from an inventory. `stdio` and `serve` are separate Cobra subcommands.

```go
// From cmd/github-mcp-server/main.go
stdioCmd = &cobra.Command{
    Use:   "stdio",
    Short: "Start stdio server",
    RunE: func(_ *cobra.Command, _ []string) error {
        // ... create server, run with stdio transport
        return s.Run(ctx, &mcp.StdioTransport{})
    },
}
```

**Repo:** https://github.com/github/github-mcp-server

---

### 2.2 njayp/ophis — 80 stars

**Automatically converts ANY Cobra CLI into an MCP server.** Walks your command tree, generates JSON schemas from flags, re-invokes your binary as a subprocess.

```
What you write:
  rootCmd.AddCommand(ophis.Command(nil))

What you get:
  mycli mcp start          → stdio MCP server
  mycli mcp stream         → HTTP MCP server
  mycli mcp tools          → JSON dump of all tools
  mycli mcp claude enable  → auto-writes Claude Desktop config
  mycli mcp vscode enable  → auto-writes VS Code config
  mycli mcp cursor enable  → auto-writes Cursor config
```

**Real-world adoption:**
- **canvas-cli** — Added MCP in 18 lines of code ([PR #26](https://github.com/jjuanrivvera/canvas-cli/pull/26))
- **go-linear** — Linear SDK + CLI + MCP in one binary

**Repo:** https://github.com/njayp/ophis

---

### 2.3 luutuankiet/fs-mcp — Dual Transport by Flag

Cleanest example of dual transport in a single Go binary:

```bash
fs-mcp                  # stdio (default)
fs-mcp --http :8124     # HTTP streamable
```

No subcommand — just a flag that switches the transport. Single static binary, ~11 MB, cold-start < 10ms.

**Repo:** https://github.com/luutuankiet/fs-mcp

---

### 2.4 mark3labs/mcp-filesystem-server — 626 stars

Stdio-only, but a clean reference for tool registration pattern:

```go
func main() {
    fss, _ := filesystemserver.NewFilesystemServer(os.Args[1:])
    server.ServeStdio(fss)  // single line, stdio only
}
```

**Repo:** https://github.com/mark3labs/mcp-filesystem-server

---

### 2.5 achetronic/filesystem-mcp

Production-ready with both stdio + HTTP, OAuth, RBAC. Shows the full production pattern.

**Repo:** https://github.com/achetronic/filesystem-mcp

---

### 2.6 Additional Projects

| Project | Stars | Description | Transport |
|---------|-------|-------------|-----------|
| [cpard/github-pp-cli](https://github.com/cpard/github-pp-cli) | new | Agent-native GitHub CLI + MCP | stdio |
| [budgiedownunder/zsv-mcp](https://github.com/budgiedownunder/zsv-mcp) | new | ZSV CSV toolkit MCP wrapper | stdio |
| [HanSoBored/git-mcp-go](https://github.com/HanSoBored/git-mcp-go) | 3 | Git remote MCP, SemVer tags | stdio |
| [ad/mcp-filesystem](https://github.com/ad/mcp-filesystem) | 1 | Go port of official TS server, 3 transports | stdio + HTTP + SSE |

---

## 3. Architecture Patterns

Every project follows the same layered architecture:

```
┌──────────────────────────────────────────┐
│           YOUR CLI BINARY                 │
│                                           │
│  ┌─────────┐  ┌──────────┐  ┌─────────┐ │
│  │  mycli   │  │  mycli   │  │  mycli  │ │
│  │  build   │  │  deploy  │  │  mcp    │ │  ← Cobra commands
│  └────┬─────┘  └────┬─────┘  └────┬────┘ │
│       │              │              │      │
│       └──────────────┼──────────────┘      │
│                      │                     │
│              ┌───────▼────────┐            │
│              │  MCP Server    │            │  ← Tools registry
│              │  (tools,       │            │
│              │   resources,   │            │
│              │   prompts)     │            │
│              └───────┬────────┘            │
│                      │                     │
│         ┌────────────┼────────────┐        │
│         │            │            │        │
│    ┌────▼───┐  ┌─────▼────┐      │        │
│    │ stdio  │  │  HTTP    │   ... │        │  ← Transports
│    └────────┘  └──────────┘      │        │
└──────────────────────────────────────────┘
```

### Pattern A: Subcommand-Based (github-mcp-server style)

```bash
mycli mcp stdio     # stdio transport
mycli mcp serve     # HTTP transport
```

Best for: large projects, clear separation of concerns.

### Pattern B: Flag-Based (fs-mcp style)

```bash
mycli               # normal CLI mode
mycli --mcp         # stdio transport
mycli --mcp --http :8080  # HTTP transport
```

Best for: smaller projects, minimal UX change.

---

## 4. Option A: The 18-Line Approach (ophis + Cobra)

**Best for:** You already use Cobra. You want MCP with zero effort. You're OK with subprocess execution (your binary calls itself for each tool invocation).

### Step 1: Add the dependency

```bash
go get github.com/njayp/ophis@latest
```

### Step 2: Create `cmd/mcp.go`

```go
package cmd

import (
    "github.com/njayp/ophis"
    "github.com/spf13/cobra"
)

func init() {
    rootCmd.AddCommand(ophis.Command(nil))
}
```

That's it. Your CLI now has:

```
mycli mcp start          → stdio MCP server
mycli mcp stream         → HTTP MCP server
mycli mcp tools          → list all tools as JSON
mycli mcp claude enable  → auto-config Claude Desktop
mycli mcp vscode enable  → auto-config VS Code
mycli mcp cursor enable  → auto-config Cursor
```

### Step 3: Configure (Optional)

```go
func init() {
    config := &ophis.Config{
        ToolNamePrefix: "mycli",      // prefix all tools: "mycli_build", "mycli_deploy"
        CommandName:    "agent",      // change subcommand from "mcp" to "agent"
        Selectors: &ophis.Selectors{
            // Exclude dangerous commands
            ExcludeCommands: []string{"admin", "internal"},
            // Exclude sensitive flags
            ExcludeFlags:    []string{"token", "password"},
        },
        Middleware: func(ctx context.Context, in ophis.ToolInput, next ophis.ToolHandler) (*mcp.CallToolResult, ophis.ToolOutput, error) {
            // Add timeout to every tool call
            ctx, cancel := context.WithTimeout(ctx, 30*time.Second)
            defer cancel()
            return next(ctx, in)
        },
    }
    rootCmd.AddCommand(ophis.Command(config))
}
```

### How ophis Works (What Happens Under the Hood)

1. Walks your entire Cobra command tree recursively
2. For each runnable command, generates a JSON Schema from its flags/args
3. When an MCP client calls a tool, ophis re-invokes **your same binary** as a subprocess with reconstructed CLI args
4. Captures stdout and returns it to the MCP client
5. No shell interpretation — uses `exec.Command` directly

### Users Then Configure

```json
{
  "mcpServers": {
    "mycli": {
      "command": "mycli",
      "args": ["mcp", "start"]
    }
  }
}
```

---

## 5. Option B: Manual Integration with mcp-go (mark3labs)

**Best for:** Full control over tool definitions. You want typed Go handlers (not subprocess execution). Stdio + Streamable HTTP support.

### Step 1: Add the dependency

```bash
go get github.com/mark3labs/mcp-go@latest
```

### Step 2: Create `cmd/mcp.go`

```go
package cmd

import (
    "context"
    "fmt"
    "log"

    "github.com/mark3labs/mcp-go/mcp"
    "github.com/mark3labs/mcp-go/server"
    "github.com/spf13/cobra"
)

var (
    mcpHTTPPort string

    mcpCmd = &cobra.Command{
        Use:   "mcp",
        Short: "Start MCP server (Model Context Protocol)",
        Long:  "Expose CLI commands as MCP tools for AI agents.",
    }

    mcpStartCmd = &cobra.Command{
        Use:   "start",
        Short: "Start MCP server over stdio",
        RunE:  runMCPServerStdio,
    }

    mcpServeCmd = &cobra.Command{
        Use:   "serve",
        Short: "Start MCP server over HTTP (Streamable HTTP)",
        RunE:  runMCPServerHTTP,
    }
)

func init() {
    mcpServeCmd.Flags().StringVar(&mcpHTTPPort, "port", "8080", "HTTP port")
    mcpCmd.AddCommand(mcpStartCmd)
    mcpCmd.AddCommand(mcpServeCmd)
    rootCmd.AddCommand(mcpCmd)
}
```

### Step 3: Build the MCP Server

```go
func newMCPServer() *server.MCPServer {
    s := server.NewMCPServer(
        "mycli",           // server name
        "1.0.0",           // version
        server.WithToolCapabilities(true),
        server.WithResourceCapabilities(true, true),
        server.WithPromptCapabilities(true),
        server.WithLogging(),
        server.WithRecovery(),  // panic recovery middleware
    )

    // Register tools — one per CLI command you want to expose
    registerBuildTool(s)
    registerDeployTool(s)
    registerTestTool(s)
    // ... etc

    return s
}
```

### Step 4: Define a Tool

```go
func registerBuildTool(s *server.MCPServer) {
    tool := mcp.NewTool("build",
        mcp.WithDescription("Build the project from source"),
        mcp.WithString("target",
            mcp.Required(),
            mcp.Description("Build target (e.g., 'linux/amd64', 'darwin/arm64')"),
        ),
        mcp.WithBoolean("release",
            mcp.Description("Build in release mode"),
        ),
    )

    s.AddTool(tool, func(ctx context.Context, req mcp.CallToolRequest) (*mcp.CallToolResult, error) {
        target, _ := req.RequireString("target")
        release, _ := req.RequireBoolean("release")

        // Call your existing build logic directly (no subprocess!)
        output, err := buildProject(target, release)
        if err != nil {
            return mcp.NewToolResultError(err.Error()), nil
        }

        return mcp.NewToolResultText(output), nil
    })
}
```

### Step 5: Implement Transport Runners

```go
func runMCPServerStdio(_ *cobra.Command, _ []string) error {
    s := newMCPServer()
    return server.ServeStdio(s)
}

func runMCPServerHTTP(_ *cobra.Command, _ []string) error {
    s := newMCPServer()
    // mcp-go supports Streamable HTTP
    addr := fmt.Sprintf(":%s", mcpHTTPPort)
    return server.ServeStreamableHTTP(s, addr)
}
```

---

## 6. Option C: Official go-sdk (modelcontextprotocol)

**Best for:** Maximum spec compliance, Google-maintained, supports latest MCP 2025-11-25 spec. The same SDK github/github-mcp-server uses.

### Step 1: Add the dependency

```bash
go get github.com/modelcontextprotocol/go-sdk@latest
```

### Step 2: Create the Server

```go
package main

import (
    "context"
    "log"

    "github.com/modelcontextprotocol/go-sdk/mcp"
)

func main() {
    server := mcp.NewServer(
        &mcp.Implementation{Name: "mycli", Version: "1.0.0"},
        nil,
    )

    // Add tools
    mcp.AddTool(server, &mcp.Tool{
        Name:        "build",
        Description: "Build the project",
        InputSchema: buildInputSchema(),
    }, buildHandler)

    // Run over stdio
    if err := server.Run(context.Background(), &mcp.StdioTransport{}); err != nil {
        log.Fatal(err)
    }
}
```

### Dual Transport with Official SDK

The official SDK supports Streamable HTTP natively:

```go
// stdio
server.Run(ctx, &mcp.StdioTransport{})

// HTTP
server.Run(ctx, &mcp.StreamableHTTPTransport{
    Addr: ":8080",
})
```

**Note:** The official SDK is newer (4,300 stars) and maintained by Google. It's the future, but mcp-go (mark3labs) has more community examples and tutorials.

---

## 7. Option D: Zero-Dependency Stdlib-Only

**Best for:** Minimal dependencies, maximum portability, supply-chain security. Based on [andygeiss/mcp](https://github.com/andygeiss/mcp).

```go
// Pure Go standard library. JSON-RPC 2.0 over stdin/stdout.
// No external dependencies. Single binary.
//
// Key features:
// - MCP 2025-11-25 spec
// - Auto-derived JSON schemas via struct tags + reflection
// - Bidirectional transport
// - Cosign-signed releases, SLSA L3 provenance
```

Use as a scaffold:

```bash
go install github.com/andygeiss/mcp/cmd/scaffold@latest
scaffold --module github.com/you/mycli-mcp
```

---

## 8. Dual Transport: stdio + HTTP in One Binary

Here is the complete pattern used by top Go projects. Combine all pieces:

```go
// cmd/mcp.go
package cmd

import (
    "context"
    "fmt"
    "log"
    "os"

    "github.com/mark3labs/mcp-go/mcp"
    "github.com/mark3labs/mcp-go/server"
    "github.com/spf13/cobra"
)

var (
    mcpTransport string  // "stdio" or "http"
    mcpHTTPAddr  string

    mcpCmd = &cobra.Command{
        Use:   "mcp",
        Short: "Start as MCP server for AI agent integration",
        RunE:  runMCP,
    }
)

func init() {
    mcpCmd.Flags().StringVarP(&mcpTransport, "transport", "t", "stdio",
        "Transport: stdio or http")
    mcpCmd.Flags().StringVar(&mcpHTTPAddr, "addr", ":8080",
        "HTTP listen address (when --transport=http)")
    rootCmd.AddCommand(mcpCmd)
}

func runMCP(cmd *cobra.Command, args []string) error {
    s := newMCPServer()

    switch mcpTransport {
    case "stdio":
        return server.ServeStdio(s)
    case "http":
        fmt.Fprintf(os.Stderr, "MCP HTTP server listening on %s\n", mcpHTTPAddr)
        return server.ServeStreamableHTTP(s, mcpHTTPAddr)
    default:
        return fmt.Errorf("unknown transport: %s (use 'stdio' or 'http')", mcpTransport)
    }
}

func newMCPServer() *server.MCPServer {
    s := server.NewMCPServer(
        "mycli", "1.0.0",
        server.WithToolCapabilities(true),
        server.WithRecovery(),
    )

    // Register all your tools here
    registerAllTools(s)

    return s
}
```

### Users Then Configure

**stdio (local):**
```json
{
  "mcpServers": {
    "mycli": {
      "command": "mycli",
      "args": ["mcp"]
    }
  }
}
```

**HTTP (remote/production):**
```json
{
  "mcpServers": {
    "mycli": {
      "url": "http://mycli.internal:8080/mcp"
    }
  }
}
```

---

## 9. Testing & Debugging Your MCP Server

### MCP Inspector

```bash
# Test stdio server
npx @modelcontextprotocol/inspector mycli mcp

# Test HTTP server
npx @modelcontextprotocol/inspector --cli http://localhost:8080/mcp --transport http --method tools/list

# Call a specific tool
npx @modelcontextprotocol/inspector --cli mycli mcp \
  --method tools/call \
  --tool-name build \
  --tool-arg 'target=linux/amd64'
```

### Go Test

```go
func TestMCPServerTools(t *testing.T) {
    s := newMCPServer()

    // Verify tool registration
    tools := s.ListTools()
    if len(tools) == 0 {
        t.Fatal("no tools registered")
    }

    // Verify a specific tool exists
    found := false
    for _, tool := range tools {
        if tool.Name == "build" {
            found = true
            break
        }
    }
    if !found {
        t.Error("build tool not found")
    }
}
```

### CI Integration

```bash
# In CI: start server, call tools/list, check exit code
npx @modelcontextprotocol/inspector --cli ./mycli mcp --method tools/list
# Exit code 0 = pass
```

---

## 10. Packaging & Distribution

### GoReleaser Config (`.goreleaser.yml`)

```yaml
builds:
  - main: ./cmd/mycli
    binary: mycli
    goos: [linux, darwin, windows]
    goarch: [amd64, arm64]
    ldflags:
      - -s -w
      - -X main.version={{.Version}}
```

### Docker (for HTTP transport)

```dockerfile
FROM golang:1.24-alpine AS build
WORKDIR /app
COPY . .
RUN CGO_ENABLED=0 go build -o /mycli ./cmd/mycli

FROM alpine:3.21
COPY --from=build /mycli /usr/local/bin/mycli
EXPOSE 8080
ENTRYPOINT ["mycli", "mcp", "--transport=http", "--addr=:8080"]
```

### Homebrew

```ruby
class Mycli < Formula
  desc "My CLI tool with MCP support"
  homepage "https://github.com/you/mycli"
  url "https://github.com/you/mycli/releases/download/v1.0.0/mycli_1.0.0_darwin_arm64.tar.gz"
  sha256 "..."

  def install
    bin.install "mycli"
  end
end
```

---

## 11. Decision Matrix

| Criteria | ophis | mcp-go | official go-sdk | stdlib-only |
|----------|-------|--------|-----------------|-------------|
| **Lines of code to add** | 18 | ~200 | ~200 | ~500 |
| **Works with existing Cobra CLI** | Yes | Yes | Yes | N/A |
| **Dual transport (stdio + HTTP)** | Yes | Yes | Yes | stdio only |
| **Typed Go handlers** | No (subprocess) | Yes | Yes | Yes |
| **Tool schema auto-generation** | Yes (from flags) | Manual | Manual | Manual (reflection) |
| **Auto-config Claude/VS Code/Cursor** | Yes | No | No | No |
| **MCP spec version** | 2025-06-18 | 2025-11-25 | 2025-11-25 | 2025-11-25 |
| **Dependencies** | ophis + go-sdk | mcp-go only | go-sdk only | zero |
| **Community size** | 80 stars | Largest Go MCP SDK | 4,300 stars (Google) | 0 stars |
| **Production use** | canvas-cli, go-linear | mcp-filesystem-server (626 stars) | github-mcp-server (30K stars) | Scaffold template |
| **Best for** | "I want MCP NOW" | Full control, typed handlers | Max spec compliance, future-proof | Supply-chain security |

### Recommendation

| Your Situation | Use |
|----------------|-----|
| "I have a Cobra CLI. Just make it work." | **ophis** |
| "I want full control. Typed handlers. Production-grade." | **mcp-go** (mark3labs) |
| "I want the official Google-maintained SDK. Future-proof." | **official go-sdk** |
| "I want zero dependencies. Single static binary." | **stdlib-only** (andygeiss scaffold) |
| "I'm starting from scratch (no existing CLI)." | **mcp-go** or **official go-sdk** |

---

## Summary: The 3-Step Plan

1. **Choose your approach** from the decision matrix above
2. **Add an `mcp` subcommand** with `--transport` flag (stdio + HTTP)
3. **Test with MCP Inspector**: `npx @modelcontextprotocol/inspector mycli mcp`

Your CLI is now an MCP server. AI agents can discover and call your tools.

---

### Key Repositories

| Repo | Stars | Why It Matters |
|------|-------|----------------|
| [github/github-mcp-server](https://github.com/github/github-mcp-server) | 30K | Gold standard. Cobra + go-sdk. stdio + HTTP. |
| [mark3labs/mcp-go](https://github.com/mark3labs/mcp-go) | — | Most popular Go MCP SDK. Streamable HTTP support. |
| [modelcontextprotocol/go-sdk](https://github.com/modelcontextprotocol/go-sdk) | 4.3K | Official Google-maintained SDK. |
| [njayp/ophis](https://github.com/njayp/ophis) | 80 | 18-line MCP for any Cobra CLI. Dual transport. |
| [luutuankiet/fs-mcp](https://github.com/luutuankiet/fs-mcp) | 3 | Cleanest dual-transport by flag. Single binary. |
| [mark3labs/mcp-filesystem-server](https://github.com/mark3labs/mcp-filesystem-server) | 626 | Reference for mcp-go tool registration. |
| [achetronic/filesystem-mcp](https://github.com/achetronic/filesystem-mcp) | 4 | Production: stdio + HTTP + OAuth + RBAC. |
| [andygeiss/mcp](https://github.com/andygeiss/mcp) | 0 | Zero-dependency stdlib-only template. |
| [ad/mcp-filesystem](https://github.com/ad/mcp-filesystem) | 1 | Go port of official TS server. 3 transports. |
| [metoro-io/mcp-golang](https://github.com/metoro-io/mcp-golang) | — | Alternative Go MCP SDK with Gin support. |
| [trpc-group/trpc-mcp-go](https://github.com/trpc-group/trpc-mcp-go) | — | tRPC ecosystem MCP SDK. 3 transports. |
| [felixgeelhaar/mcp-go](https://github.com/felixgeelhaar/mcp-go) | 2 | "Gin for MCP." Typed handlers, 4 transports. |
| [voocel/mcp-sdk-go](https://github.com/voocel/mcp-sdk-go) | — | Full MCP 2025-11-25. Multi-session. |
| [viant/mcp](https://github.com/viant/mcp) | — | HTTP/SSE + stdio. Typed tool registration. |
| [spirilis/generic-go-mcp](https://github.com/spirilis/generic-go-mcp) | — | Framework: dual transport + OAuth + BoltDB. |

---

Generated from analysis of 15+ real Go CLI projects that expose MCP.