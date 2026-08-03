# Headroom Token Compression Proxy: Pi, Hermes, and Ollama Integration Guide

**Date:** August 2, 2026
**Author:** Vishal Gandhi
**System:** M4 (Headroom + Ollama) + M5 (Hermes CLI) + M2 (Pi Agent + Cursor GUI)

---

## Overview

This guide documents how to integrate [Headroom](https://github.com/headroomlabs-ai/headroom) token compression proxy between AI coding agents and a local Ollama instance running on a remote Mac mini M4 server. The setup supports multiple agents — Pi, Hermes, and Cursor GUI — routing traffic through Headroom for token savings and request analytics.

**What we achieved:**
- Pi agent → Headroom → Ollama (cache-only optimization, bug #846 workaround)
- Hermes agent → Headroom → Ollama (active token compression, 30%+ reduction on large contexts)
- Headroom proxy accessible via Tailscale from multiple machines (M2, M5, M4 itself)

---

## Architecture

```mermaid
sequenceDiagram
    participant Pi as Pi Agent (M2)
    participant Hermes as Hermes Agent (M5)
    participant Headroom as Headroom Proxy<br/>(M4:8787)
    participant Ollama as Ollama Server<br/>(M4:11434)
    participant Cloud as Ollama Cloud

    Pi->>Headroom: OpenAI API Request
    Hermes->>Headroom: OpenAI API Request
    Headroom->>Ollama: Forward to /v1/chat/completions
    Ollama->>Cloud: Pull model weights (kimi, gemma, qwen)
    Cloud-->>Ollama: Model weights
    Ollama-->>Headroom: Response + usage tokens
    Headroom-->>Pi: Compressed response (cache-only)
    Headroom-->>Hermes: Compressed response (active)

    note over Headroom: Token compression +<br/>cache alignment happens here

    %% Cursor is blocked
    CursorGUI as Cursor GUI
    CursorGUI-xHeadroom: BLOCKED<br/>(api2.cursor.sh walled garden)
```

---

## Infrastructure

| Machine | Role | Tailscale IP |
|---------|------|-------------|
| M4 (Mac mini) | Headroom proxy + Ollama server | `100.106.57.79` |
| M5 (MacBook) | Hermes agent (daily driver) | Via Tailscale DNS `m4` |
| M2 (Mac mini) | Pi agent | Via Tailscale DNS `m4` |

---

## Part 1: Headroom Proxy Setup on M4

### Step 1.1: Run Headroom Docker Container

The official Headroom image runs in Docker. For remote access from other machines, bind to `0.0.0.0:8787` (not `127.0.0.1:8787`).

```bash
# For Anthropic upstream (Claude models)
docker run -d --name headroom --restart unless-stopped \
  -p 0.0.0.0:8787:8787 \
  -v headroom-data:/home/nonroot/.headroom \
  headroom:local

# For Ollama upstream (local models)
docker run -d --name headroom --restart unless-stopped \
  -p 0.0.0.0:8787:8787 \
  -v headroom-data:/home/nonroot/.headroom \
  -e OPENAI_TARGET_API_URL=http://host.docker.internal:11434/v1 \
  headroom:local
```

**Critical:** The `-e OPENAI_TARGET_API_URL` env var sets the upstream. Headroom defaults to `https://api.anthropic.com` (Anthropic) if not overridden.

### Step 1.2: Verify Health

```bash
curl -s http://127.0.0.1:8787/health | python3 -m json.tool
```

Expected output shows `"status": "healthy"` and the correct upstream URL in the `upstream` check.

### Step 1.3: Check Stats

```bash
curl -s http://127.0.0.1:8787/stats | grep -E "api_requests|requests_compressed|primary_model"
```

After first request, you should see `api_requests > 0`.

---

## Part 2: Pi Agent Configuration

### Step 2.1: Locate Pi Config

Pi stores its model provider config in:

```bash
~/.pi/agent/models.json
```

### Step 2.2: Original Config (Direct Ollama)

```json
{
  "providers": {
    "ollama": {
      "api": "openai-completions",
      "apiKey": "f2f5abd7f67b40f08275f876ad413759.r5y2UvpY9MNg6w231hlwN9-J",
      "baseUrl": "http://localhost:11434/v1",
      "models": [
        {"id": "kimi-k2-thinking:cloud"},
        {"id": "qwen2.5-coder:7b"},
        {
          "_launch": true,
          "contextWindow": 262144,
          "id": "kimi-k2.6:cloud",
          "input": ["text", "image"],
          "reasoning": true
        },
        {
          "_launch": true,
          "contextWindow": 262144,
          "id": "kimi-k2.7-code:cloud",
          "input": ["text", "image"],
          "reasoning": true
        }
      ]
    }
  }
}
```

### Step 2.3: Modified Config (Through Headroom)

Change `baseUrl` from direct Ollama to Headroom proxy:

```bash
sed -i.bak 's|"baseUrl": "http://localhost:11434/v1"|"baseUrl": "http://127.0.0.1:8787/v1"|' ~/.pi/agent/models.json
```

Updated `models.json`:

```json
{
  "providers": {
    "ollama": {
      "api": "openai-completions",
      "apiKey": "f2f5abd7f67b40f08275f876ad413759.r5y2UvpY9MNg6w231hlwN9-J",
      "baseUrl": "http://127.0.0.1:8787/v1",
      ...
    }
  }
}
```

### Step 2.4: Test Pi

```bash
pi --print "Hello from Pi through Headroom to Ollama"
```

### Known Limitation: Pi + Headroom Bug (#846)

There is a [known open issue](https://github.com/headroomlabs-ai/headroom/issues/846) where Headroom's token compression causes Pi to malfunction when content is compressed. Pi gets confused and does not realize the file was compressed.

**Workaround:** Headroom automatically runs in `cache` mode for Pi (not `compress` mode), which avoids the bug while still providing prefix caching and request analytics. You get pass-through proxy benefits without compression.

---

## Part 3: Hermes Agent Configuration

### Step 3.1: Locate Hermes Config

Hermes stores config at:

```bash
~/.hermes/config.yaml
```

### Step 3.2: Original Config (Direct Ollama)

```yaml
model:
  api_key: 1d6efd750fb94fce9965b339a705244c.AYuGT_WyT7RDNrIPKbxG2CSf
  api_mode: chat_completions
  base_url: http://m4:11434/v1
  default: kimi-k2.6:cloud
  provider: m4:11434-2

providers:
  m4:11434-2:
    api: http://m4:11434/v1
    api_key: 1d6efd750fb94fce9965b339a705244c.AYuGT_WyT7RDNrIPKbxG2CSf
    default_model: qwen3.5:cloud
    name: M4:11434
```

### Step 3.3: Modified Config (Through Headroom)

```bash
# Update model base_url
sed -i.bak 's|base_url: http://m4:11434/v1|base_url: http://m4:8787/v1|' ~/.hermes/config.yaml

# Update provider API endpoint
sed -i.bak 's|api: http://m4:11434/v1|api: http://m4:8787/v1|' ~/.hermes/config.yaml
```

Updated `config.yaml`:

```yaml
model:
  api_key: 1d6efd750fb94fce9965b339a705244c.AYuGT_WyT7RDNrIPKbxG2CSf
  api_mode: chat_completions
  base_url: http://m4:8787/v1
  default: kimi-k2.6:cloud
  provider: m4:11434-2

providers:
  m4:11434-2:
    api: http://m4:8787/v1
    ...
```

### Step 3.4: Verify Hermes Through Headroom

Send a message in the Hermes UI, then check Headroom stats on M4:

```bash
curl -s http://127.0.0.1:8787/stats | grep -E "api_requests|requests_compressed|primary_model"
```

### Step 3.5: Actual Results

After running Hermes and Pi through Headroom, the stats show compression at work:

#### Overall Metrics

| Metric | Value |
|--------|-------|
| `api_requests` | **82** |
| `requests_compressed` | **59** (72%) |
| `total_tokens_removed` | **27.9K** |
| `total_input_tokens` | **6.13M** |
| `best_detail` | **42,053 → 19,879 tokens** (53% reduction) |
| `savings_usd` | **~/bin/bash.08** |

#### By Model

| Model | Requests | Tokens Saved | Savings % | Est. Cost |
|-------|----------|--------------|-----------|-----------|
| `kimi-k2.6:cloud` | 66 | 22.6K | 0.58% | /bin/bash.068 |
| `kimi-k2.7-code:cloud` | 5 | 16 | 0.10% | /bin/bash.00005 |
| `passthrough:models` | 11 | 0 | 0.00% | /bin/bash.00 |

#### By Client Agent

Headroom identifies clients by their API agent signature. In our setup:

| Client | Requests | Models Used | Compression Mode |
|--------|----------|-------------|-----------------|
| **openai** (Hermes + Pi) | 82 | kimi-k2.6, kimi-k2.7-code | Active for Hermes, cache-only for Pi |

**Key insight:** The bulk of savings comes from Hermes using `kimi-k2.6:cloud` — large context requests trigger compression. Pi routes through the same proxy but stays in cache-only mode due to bug #846.

---

## Part 4: Cursor GUI (Known Limitation)

### The Problem

Cursor's "frontier models" (cursor-grok, composer, claude-opus-5, kimi-k3, etc.) route exclusively through Cursor's proprietary API at `api2.cursor.sh`. Headroom cannot intercept this traffic.

`cursor-agent` CLI hardcodes its backend and ignores `ANTHROPIC_BASE_URL` / `OPENAI_BASE_URL` environment variables.

### What Works

If you bring your own API key (Anthropic, OpenAI, or OpenRouter), you can configure the Cursor GUI to route through Headroom:

**Cursor Settings → Models:**
- **Anthropic Base URL:** `http://100.106.57.79:8787`
- **OpenAI Base URL:** `http://100.106.57.79:8787/v1`

Then select models that use **your** API key (not Cursor's built-in models).

**What does NOT work:**
- Cursor proprietary models (cursor-grok, composer, etc.) — always bypass Headroom
- `cursor-agent` CLI — hardcoded to `api2.cursor.sh`

### Open GitHub Issues

| Issue | Status | Description |
|-------|--------|-------------|
| [#2724](https://github.com/headroomlabs-ai/headroom/issues/2724) | Open | Cursor CLI / Agent support |
| [#846](https://github.com/headroomlabs-ai/headroom/issues/846) | Open | Pi agent compression bug |
| [#712](https://github.com/headroomlabs-ai/headroom/issues/712) | Open | Hermes agent CLI wrapper |
| [#526](https://github.com/headroomlabs-ai/headroom/issues/526) | Open | Hermes agent support |

---

## Part 5: Network Accessibility

### Step 5.1: Bind to All Interfaces

By default, Docker binds to `127.0.0.1:8787`, which is only accessible on the host machine. For remote access via Tailscale:

```bash
# WRONG — only local access
docker run -p 127.0.0.1:8787:8787 ...

# CORRECT — accessible from all interfaces
docker run -p 0.0.0.0:8787:8787 ...
# or simply:
docker run -p 8787:8787 ...
```

### Step 5.2: Verify Remote Access

From another machine on Tailscale:

```bash
curl -s http://100.106.57.79:8787/health
```

Should return the same healthy JSON as localhost on M4.

---

## Part 6: Troubleshooting

### Stats show `requests_compressed: 0`

**Normal for small prompts.** Headroom's `kompress` backend only activates when there is compressible content (long tool outputs, fetched pages, large context blocks). A simple `pi --print "hello"` won't trigger compression.

**Test with real coding context:**
```bash
cd ~/code/some-project && pi --print "Refactor this" @src/main.ts
```

### Kompress backend shows `unhealthy`

This is **expected** by design. The `KompressCompressor` loads lazily — the 274MB ONNX model (`chopratejas/kompress-v2-base`) only loads on the first real compression request. Before that, `backend: null` and `is_ready: False` are normal.

### Pi fails with compressed responses

This is bug #846. Headroom should automatically fall back to `cache` mode for Pi. If not, set Pi's `baseUrl` directly to Ollama and skip Headroom for Pi-only workflows.

---

## Part 7: Summary

| Tool | Through Headroom | By Model | Compression | Status |
|------|-----------------|--------|-------------|--------|
| **Pi** | ✅ Yes (with workaround) | kimi-k2.6, kimi-k2.7-code | Cache-only (bug #846) | Working |
| **Hermes** | ✅ Yes | kimi-k2.6 (66 reqs), kimi-k2.7-code (5 reqs) | ✅ Active (53% best) | Working |
| **Cursor GUI** | ⚠️ Partial (own API key only) | N/A (walled garden) | Depends on model | Limited |
| **cursor-agent CLI** | ❌ No | N/A | N/A | Blocked by design |

**The chain that works:**
```
Pi → Headroom (cache) → Ollama (M4)
Hermes → Headroom (compress) → Ollama (M4)
```

---

## Files Modified

| File | Change |
|------|--------|
| `~/.pi/agent/models.json` | `baseUrl`: `localhost:11434` → `127.0.0.1:8787` |
| `~/.hermes/config.yaml` | `base_url` and `api`: `m4:11434` → `m4:8787` |
| Docker container `headroom` | Re-created with `-e OPENAI_TARGET_API_URL=http://host.docker.internal:11434/v1` |

---

## References

- [Headroom GitHub](https://github.com/headroomlabs-ai/headroom)
- [Pi Agent](https://github.com/earendil-works/pi-mono)
- [Hermes Agent](https://github.com/ivishalgandhi/hermes-agent)
- [Ollama](https://ollama.com/)
- [Tailscale](https://tailscale.com/)
