---
sidebar_position: 2
title: "Continue.dev with Remote Ollama"
description: "Step-by-step guide to setting up Continue.dev IDE extension with a remote Ollama server for AI-assisted coding with large language models"
slug: continue-dev-remote-ollama
---

# Continue.dev with Remote Ollama: AI-Powered Coding Setup

Continue.dev is an open-source IDE extension that integrates large language models (LLMs) directly into your coding workflow in VS Code and JetBrains IDEs. It enables features like intelligent autocomplete, chat-based assistance, and AI-powered code editing.

While Continue.dev can run models locally, offloading to a remote Ollama server is ideal when your local machine lacks GPU/RAM resources, or when you want to centralize AI infrastructure across multiple devices.

:::info What You'll Build
- **Remote Ollama Server** hosting your choice of LLMs
- **Continue.dev Integration** in your local IDE
- **Network Configuration** for secure remote access
- **Multi-Model Setup** optimized for different coding tasks
:::

## Prerequisites

Before starting, ensure you have:

- **Remote Server**: Linux machine with sufficient resources (16GB+ RAM for 7B models, more for larger ones)
- **Network Access**: Local machine can reach remote server (LAN, VPN, or SSH tunnel)
- **Local IDE**: VS Code or JetBrains IDE installed
- **Basic Skills**: Command-line familiarity, YAML editing, networking basics

:::tip Resource Requirements
- **7B models**: 8-16GB RAM
- **13B models**: 16-32GB RAM  
- **30B+ models**: 32GB+ RAM, GPU highly recommended
- **70B+ models**: 64GB+ RAM, powerful GPU required
:::

## Understanding the Components

### Ollama

Ollama is a lightweight framework for running LLMs on your hardware. It provides:
- Simple API for model inference
- Support for quantized models (4-bit, 8-bit)
- Easy model management and updates
- Low overhead and efficient resource usage

### Continue.dev

Continue.dev brings AI directly into your IDE with:
- **Chat**: Ask questions about your code
- **Autocomplete**: AI-powered code suggestions
- **Edit**: Refactor and improve code with AI
- **Apply**: Execute AI-suggested changes

## Step 1: Setting Up Ollama on Remote Server

### Install Ollama

SSH into your remote server and install Ollama:

```bash
curl -fsSL https://ollama.com/install.sh | sh
```

### Pull Your Models

Download the models you want to use. Here are some recommended options:

```bash
# For chat and general assistance
ollama pull gemma2:27b

# For code-specific tasks
ollama pull qwen2.5-coder:7b

# Lightweight for autocomplete
ollama pull deepseek-coder:6.7b

# Preview/experimental models
ollama pull llama3.1:70b
```

:::tip Model Selection
- **Autocomplete**: Use smaller, faster models (6-7B parameters)
- **Chat/Edit**: Use larger, more capable models (27B-70B)
- **Balance**: 13B models offer good speed/quality tradeoff
:::

Verify installed models:

```bash
ollama list
```

### Enable Remote Access

By default, Ollama only accepts local connections. Configure it for remote access:

```bash
# Start Ollama with network binding
OLLAMA_HOST=0.0.0.0:11434 ollama serve
```

:::warning Security Note
Exposing Ollama to your network without authentication is risky. Use one of these security approaches:
- **Firewall**: Restrict access to specific IP addresses
- **VPN**: Access through Tailscale, WireGuard, or similar
- **SSH Tunnel**: Forward port 11434 through SSH (most secure for WAN)
:::

### Configure as System Service

For persistent operation, create a systemd service:

```bash
sudo nano /etc/systemd/system/ollama.service
```

Add this configuration:

```ini
[Unit]
Description=Ollama Service
After=network.target

[Service]
ExecStart=/usr/local/bin/ollama serve
Environment="OLLAMA_HOST=0.0.0.0:11434"
User=ollama
Group=ollama
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
```

:::tip Service User
Create a dedicated `ollama` user for better security:
```bash
sudo useradd -r -s /bin/false -m -d /var/lib/ollama ollama
```
:::

Enable and start the service:

```bash
sudo systemctl daemon-reload
sudo systemctl enable ollama
sudo systemctl start ollama
```

### Configure Firewall

Allow access from your local network:

```bash
# Ubuntu/Debian
sudo ufw allow from 192.168.1.0/24 to any port 11434

# Or for specific IP
sudo ufw allow from 192.168.1.100 to any port 11434
```

### Verify Remote Access

Test from your local machine:

```bash
# Replace with your server's IP
curl http://192.168.1.200:11434

# Should return: "Ollama is running"
```

Test model inference:

```bash
curl http://192.168.1.200:11434/api/generate -d '{
  "model": "gemma2:27b",
  "prompt": "Why is the sky blue?",
  "stream": false
}'
```

## Step 2: Setting Up SSH Tunnel (Optional but Recommended)

For secure access over the internet, use SSH tunneling:

```bash
# On your local machine
ssh -L 11434:localhost:11434 user@remote-server-ip

# Keep this terminal open
# Now access via http://localhost:11434
```

:::tip Persistent Tunnels
For always-on tunnels, use `autossh`:
```bash
autossh -M 0 -f -N -L 11434:localhost:11434 user@remote-server-ip
```
:::

## Step 3: Configuring Continue.dev

### Install the Extension

**VS Code:**
1. Open Extensions (Ctrl+Shift+X / Cmd+Shift+X)
2. Search for "Continue"
3. Click Install
4. Restart VS Code

**JetBrains:**
1. File → Settings → Plugins
2. Search for "Continue"
3. Install and restart IDE

### Open Configuration File

Access Continue's config file:
- **VS Code**: Ctrl/Cmd+Shift+P → "Continue: Open config.yaml"
- **File Location**: `~/.continue/config.yaml`

### Configure Remote Models

Replace the default configuration with your remote Ollama setup:

```yaml
name: Remote Ollama Config
version: 1.0.0
schema: v1
models:
  - name: Gemma 3 27B Cloud
    provider: ollama
    model: gemma3:27b-cloud
    apiBase: http://192.168.1.200:11434
    roles:
      - chat
      - edit
      - apply
  - name: Qwen 3 Coder 480B Cloud
    provider: ollama
    model: qwen3-coder:480b-cloud
    apiBase: http://192.168.1.200:11434
    roles:
      - autocomplete
      - edit
      - apply
      - chat
  - name: Gemini 3 Pro Preview
    provider: ollama
    model: gemini-3-pro-preview:latest
    apiBase: http://192.168.1.200:11434
    roles:
      - chat
      - edit
      - apply
  - name: GPT OSS 120B Cloud
    provider: ollama
    model: gpt-oss:120b-cloud
    apiBase: http://192.168.1.200:11434
    roles:
      - chat
      - edit
      - apply
```

:::note SSH Tunnel Configuration
If using SSH tunnel, use `http://localhost:11434` instead of the remote IP
:::

**Key Configuration Fields:**

- **name**: Display name in IDE
- **provider**: Always "ollama" for this setup
- **model**: Exact model tag from `ollama list`
- **apiBase**: Remote Ollama endpoint URL
- **roles**: Model capabilities
  - `chat`: Q&A and discussions
  - `autocomplete`: Code completion
  - `edit`: Code refactoring
  - `apply`: Execute suggested changes

### Advanced Configuration Options

Add these optional parameters for fine-tuning:

```yaml
models:
  - name: Custom Model
    provider: ollama
    model: gemma2:27b
    apiBase: http://192.168.1.200:11434
    contextLength: 8192  # Override default context window
    completionOptions:
      temperature: 0.2   # Lower = more deterministic
      top_p: 0.9
      maxTokens: 2048
    roles:
      - chat
```

### Enable Model Auto-Detection

For dynamic model discovery:

```yaml
models:
  - name: Auto-Detect Models
    provider: ollama
    model: AUTODETECT
    apiBase: http://192.168.1.200:11434
```

:::tip Model Roles Best Practices
- **Autocomplete**: Use fastest models (6-7B)
- **Chat**: Use balanced models (13-27B)
- **Complex Edits**: Use largest available models (70B+)
- **Multiple Roles**: Assign versatile 13B models to all roles
:::

## Step 4: Testing Your Setup

### Basic Chat Test

1. Open any code file
2. Highlight a function or code block
3. Press **Ctrl/Cmd+L** to open Continue chat
4. Ask: "Explain what this code does"

### Autocomplete Test

1. Start typing a new function
2. Wait 1-2 seconds for suggestions
3. Press **Tab** to accept, **Esc** to dismiss

### Code Edit Test

1. Highlight code to refactor
2. Press **Ctrl/Cmd+I**
3. Describe the change: "Add error handling"
4. Review and apply suggestions

### Performance Check

Monitor response times:
- **Autocomplete**: Should be < 1 second
- **Chat responses**: 2-10 seconds depending on model size
- **Code edits**: 5-30 seconds for complex changes

:::warning High Latency?
If responses are slow:
- Check network ping to server
- Try smaller/quantized models
- Verify server isn't CPU/memory constrained
- Use wired connection instead of WiFi
:::

## Troubleshooting

### Connection Issues

**Problem**: "Failed to connect to Ollama server"

**Solutions**:
```bash
# Verify Ollama is running
curl http://remote-ip:11434

# Check firewall rules
sudo ufw status

# Verify service status
systemctl status ollama

# Check Ollama logs
journalctl -u ollama -f
```

### Model Not Found

**Problem**: "Model 'xyz' not found"

**Solutions**:
```bash
# List available models on remote
ssh user@remote "ollama list"

# Pull missing model
ssh user@remote "ollama pull model-name:tag"

# Verify exact tag matches config.yaml
```

### Slow Performance

**Optimization steps**:

1. **Use Quantized Models**:
   ```bash
   # 4-bit quantization (faster, less accurate)
   ollama pull gemma2:27b-q4_0
   
   # 8-bit quantization (balanced)
   ollama pull gemma2:27b-q8_0
   ```

2. **Adjust Context Length**:
   ```yaml
   models:
     - name: Fast Model
       contextLength: 2048  # Reduce from default 4096
   ```

3. **Network Optimization**:
   - Use wired connection
   - Enable QoS for port 11434
   - Consider local caching

### API Errors

Check Continue.dev logs:
- **VS Code**: Ctrl/Cmd+Shift+P → "Continue: Open logs"
- Look for connection errors, timeouts, or API responses

### Security Issues

If you need public access, use a reverse proxy with authentication:

```nginx
# /etc/nginx/sites-available/ollama
server {
    listen 443 ssl;
    server_name ollama.yourdomain.com;
    
    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;
    
    location / {
        auth_basic "Restricted";
        auth_basic_user_file /etc/nginx/.htpasswd;
        
        proxy_pass http://localhost:11434;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

## Best Practices

### Model Selection Strategy

| Task | Recommended Size | Example Models |
|------|-----------------|----------------|
| Autocomplete | 6-7B | deepseek-coder:6.7b, starcoder:7b |
| Chat | 13-27B | gemma2:27b, llama3:13b |
| Complex Edits | 27-70B | llama3.1:70b, mixtral:8x22b |
| Code Review | 27-70B | qwen2.5-coder:32b, codellama:70b |

### Resource Management

```bash
# Monitor Ollama resource usage
htop -p $(pgrep ollama)

# Check GPU utilization (if available)
nvidia-smi

# Monitor model memory usage
ollama ps
```

### Hybrid Setup

Mix local and remote models for redundancy:

```yaml
models:
  # Fast local model for autocomplete
  - name: Local Small Model
    provider: ollama
    model: deepseek-coder:1.3b
    apiBase: http://localhost:11434
    roles:
      - autocomplete

  # Powerful remote model for complex tasks
  - name: Remote Large Model
    provider: ollama
    model: llama3.1:70b
    apiBase: http://192.168.1.200:11434
    roles:
      - chat
      - edit
```

### Multi-User Environments

For teams sharing a remote Ollama server:

```bash
# Enable concurrent requests in systemd service
Environment="OLLAMA_NUM_PARALLEL=4"
Environment="OLLAMA_MAX_QUEUE=512"
```

### Backup and Version Control

Keep your Continue config in version control:

```bash
# Backup config
cp ~/.continue/config.yaml ~/.continue/config.yaml.backup

# Or symlink to dotfiles repo
ln -s ~/dotfiles/continue-config.yaml ~/.continue/config.yaml
```

## Advanced Topics

### Custom Model Files

Create a Modelfile for custom configurations:

```dockerfile
# Modelfile
FROM gemma2:27b

PARAMETER temperature 0.2
PARAMETER top_p 0.9
PARAMETER context_length 8192

SYSTEM """You are a senior software engineer specializing in Python and Go.
Provide concise, production-ready code with proper error handling."""
```

Load it:

```bash
ollama create custom-coding-assistant -f Modelfile
```

### Docker Deployment

Run Ollama in Docker for easier management:

```yaml
# docker-compose.yml
version: '3.8'
services:
  ollama:
    image: ollama/ollama:latest
    ports:
      - "11434:11434"
    volumes:
      - ollama-data:/root/.ollama
    environment:
      - OLLAMA_HOST=0.0.0.0:11434
    restart: unless-stopped

volumes:
  ollama-data:
```

### Monitoring and Metrics

Set up basic monitoring:

```bash
# Install prometheus exporter
curl -L https://github.com/prometheus/ollama_exporter/releases/latest/download/ollama_exporter -o /usr/local/bin/ollama_exporter
chmod +x /usr/local/bin/ollama_exporter

# Run exporter
ollama_exporter --ollama.url=http://localhost:11434
```

## Alternatives and Comparisons

### When to Use This Setup

✅ **Good for:**
- You have a powerful server/workstation
- Want full control over models and data
- Need offline capabilities
- Prefer open-source solutions
- Cost-conscious (no API fees)

❌ **Consider alternatives if:**
- Need cutting-edge models (GPT-4, Claude)
- Don't have server resources
- Want zero maintenance
- Need guaranteed uptime/SLAs

### Alternative Solutions

| Solution | Pros | Cons |
|----------|------|------|
| **Local Ollama** | No network latency | Limited by local resources |
| **OpenAI API** | Best models available | Costs per token, privacy concerns |
| **Anthropic Claude** | Strong reasoning | API-only, costs |
| **LM Studio** | GUI, easy setup | Less scriptable |
| **vLLM** | High throughput | Complex setup |

## Conclusion

You now have a powerful remote AI coding assistant integrated into your IDE. This setup provides:

- **Flexibility**: Switch between multiple models for different tasks
- **Performance**: Offload computation to powerful server
- **Privacy**: Keep code on your infrastructure
- **Cost-effectiveness**: No per-token API fees
- **Scalability**: Share resources across multiple developers

Continue.dev with remote Ollama unlocks AI-powered coding without compromising on performance or privacy. Experiment with different models to find your optimal workflow.

## Additional Resources

- [Continue.dev Documentation](https://continue.dev/docs)
- [Ollama Model Library](https://ollama.com/library)
- [Continue.dev Discord Community](https://discord.gg/continue-dev)
- [Ollama GitHub Repository](https://github.com/ollama/ollama)

:::tip Keep Updated
- Update Ollama: `curl -fsSL https://ollama.com/install.sh | sh`
- Update models: `ollama pull model-name:latest`
- Update Continue.dev: Check IDE extension updates
:::

---

*Last updated: January 2026*
