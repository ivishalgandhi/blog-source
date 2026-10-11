---
sidebar_position: 1
title: Setting up DuckDB Quack Server
description: Step-by-step guide to install DuckDB Quack extension and run it as a client-server database using uv
---

# Setting up DuckDB Quack Server

:::info

DuckDB `v1.5.2` (Variegata) introduced the Quack extension — a client-server protocol that turns DuckDB into a general-purpose database system. This guide documents the **exact steps** that worked on macOS with `uv` as the package manager.

:::

## Prerequisites

| Requirement | Version | Notes |
|------------|---------|-------|
| Python | ≥3.10 | DuckDB 1.5.x requires Python 3.10+ |
| Package Manager | `uv` | This guide uses `uv` exclusively |
| DuckDB CLI | v1.5.2 | `brew install duckdb` |

## Step 1: Create a Project with uv

```bash
# Create project directory
cd ~/projects
mkdir quack-agent-pipeline
cd quack-agent-pipeline

# Initialize uv virtual environment with Python 3.11
uv venv .venv --python python3.11
source .venv/bin/activate

# Install DuckDB
uv pip install "duckdb>=1.5.2"
```

:::warning

Do **not** use the system Python (macOS ships with 3.9.6). DuckDB 1.5.x requires Python ≥3.10. If you get:

```
ERROR: Requires-Python >=3.10.0
```

You are using the wrong Python. Point `uv` to a newer version with `--python python3.11`.

:::

## Step 2: Install the Quack Extension

The Quack extension is distributed via `core_nightly` and is **not** included in the base DuckDB distribution.

```python
import duckdb

con = duckdb.connect("pipeline.db")
con.execute("INSTALL quack FROM core_nightly")
con.execute("LOAD quack")
```

:::tip

The extension is downloaded from DuckDB's nightly repository. If you see a network error, verify that `core_nightly` is accessible:

```python
con.execute("SELECT * FROM duckdb_extensions() WHERE extension_name = 'quack'")
```

:::

## Step 3: Start the Quack Server

Quack turns DuckDB into a **table function** (not a scalar procedure). The server URI must start with `quack:`.

```python
# Server setup
TOKEN = "quack_2026"  # Must be ≥4 characters

result = con.execute(
    "SELECT * FROM quack_serve('quack:0.0.0.0:9494', token => '', allow_other_hostname => true)"
).fetchone()

print(result)
# ('quack:0.0.0.0:9494', 'http://0.0.0.0:9494', '...')
```

:::danger Common Pitfalls

### Pitfall 1: Positional arguments don't work

```python
# ❌ WRONG — BinderError
con.execute("CALL quack_serve('0.0.0.0', false, false, '')")

# ✅ CORRECT — Use => named parameters
con.execute("CALL quack_serve('quack:0.0.0.0:9494', token => '', allow_other_hostname => true)")
```

### Pitfall 2: Empty token rejected

```python
# ❌ WRONG — Token must be ≥4 characters
con.execute("... token => '' ...")

# ✅ CORRECT
con.execute("... token => 'quack' ...")
```

### Pitfall 3: Bare hostname without protocol prefix

```python
# ❌ WRONG — URI must start with quack:
con.execute("CALL quack_serve('0.0.0.0:9494', ...)")

# ✅ CORRECT
con.execute("CALL quack_serve('quack:0.0.0.0:9494', ...)")
```

### Pitfall 4: Table vs scalar function

`quack_serve` returns a **table** (not `None`). Call it with `SELECT * FROM`, not as a bare `CALL`:

```python
# ✅ CORRECT
result = con.execute("SELECT * FROM quack_serve(...)")

# ❌ WRONG in some contexts
con.execute("CALL quack_serve(...)")  # May work but returns nothing
```

:::

## Step 4: Connect from a Client

```python
# Client (same machine or remote)
client = duckdb.connect()
client.execute("INSTALL quack FROM core_nightly")
client.execute("LOAD quack")

# Create the secret with the server token
client.execute("CREATE SECRET (TYPE quack, TOKEN 'quack_2026')")

# Attach the remote database
client.execute("ATTACH 'quack:localhost:9494' AS remote")

# Query remote tables
result = client.execute("SELECT count(*) FROM remote.my_table").fetchone()
print(f"Remote rows: {result[0]}")
```

## Step 5: Full Working Example

```python
"""Quack server + client in one script."""
import duckdb
import threading
import time

DB_PATH = "pipeline.db"
HOST = "quack:0.0.0.0:9494"
TOKEN = "quack_2026"

def start_server():
    con = duckdb.connect(DB_PATH)
    con.execute("INSTALL quack FROM core_nightly")
    con.execute("LOAD quack")
    con.execute(
        f"SELECT * FROM quack_serve('{HOST}', token => '{TOKEN}', allow_other_hostname => true)"
    )
    # Block to keep server alive
    while True:
        time.sleep(60)

def run_client():
    client = duckdb.connect()
    client.execute("INSTALL quack FROM core_nightly")
    client.execute("LOAD quack")
    client.execute(f"CREATE SECRET (TYPE quack, TOKEN '{TOKEN}')")
    client.execute("ATTACH 'quack:localhost:9494' AS remote")

    result = client.execute("SELECT count(*) FROM remote.test_table").fetchone()
    print(f"Remote table rows: {result[0]}")

# Start server in background
server_thread = threading.Thread(target=start_server, daemon=True)
server_thread.start()
time.sleep(2)  # Give server time to bind

# Connect client
run_client()
```

## Step 6: Docker-Free Deployment Pattern

Quack needs no Docker, no separate binary, no config file. For headless deployment:

```bash
# Using nohup for background longevity
cd ~/projects/quack-agent-pipeline
source .venv/bin/activate
nohup python quack_server.py > quack.log 2>&1 &
```

Or use `launchd` on macOS for automatic startup:

```xml
<!-- ~/Library/LaunchAgents/com.vishal.quack.plist -->
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" ...>
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.vishal.quack</string>
    <key>ProgramArguments</key>
    <array>
        <string>/Users/vishal/.local/bin/uv</string>
        <string>run</string>
        <string>--python</string>
        <string>3.11</string>
        <string>python</string>
        <string>quack_server.py</string>
    </array>
    <key>WorkingDirectory</key>
    <string>/Users/vishal/projects/quack-agent-pipeline</string>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
</dict>
</plist>
```

## Troubleshooting

### "Invalid DuckDB Quack RPC URI, needs to start with 'quack:'"

You passed a bare hostname. Prefix with `quack:`.

### "Quack server token must be at least 4 characters long"

Use a non-empty token of at least 4 characters.

### "Only localhost is allowed as a Quack RPC hostname by default"

Add `allow_other_hostname => true` if binding to `0.0.0.0`.

### "Could not set lock on file ... Conflicting lock is held"

Another process is holding the `.duckdb` file. Check with:

```bash
lsof ~/projects/quack-agent-pipeline/pipeline.db
```

## References

- [DuckDB Quack Documentation](https://duckdb.org/quack/)
- [Quack Extension Source](https://github.com/duckdb/duckdb/tree/main/extension/quack)
- [uv Documentation](https://docs.astral.sh/uv/)
- DuckDB CLI: `duckdb --version` → `v1.5.2 (Variegata)`
