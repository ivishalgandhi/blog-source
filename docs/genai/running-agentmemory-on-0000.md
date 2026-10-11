# Running AgentMemory on 0.0.0.0

This document explains how to run agentmemory on `0.0.0.0` to make it accessible from other devices on your network.

## Prerequisites

- agentmemory installed (via npm: `npm install -g @agentmemory/agentmemory`)
- Access to modify the agentmemory configuration files

## Changes Made to Configuration

### 1. Updated iii-config.yaml

Edit file: `/opt/homebrew/lib/node_modules/@agentmemory/agentmemory/dist/iii-config.yaml`

**Changes:**
- Changed HTTP server host from `127.0.0.1` to `0.0.0.0` (port 3111)
- Changed Streams server host from `127.0.0.1` to `0.0.0.0` (port 3112)
- Updated CORS allowed origins to include `0.0.0.0` addresses

### 2. Updated viewer server binding

Edit file: `/opt/homebrew/lib/node_modules/@agentmemory/agentmemory/dist/src-D5arboxc.mjs`

**Changes:**
- Line ~18876: Changed viewer server listen address from `127.0.0.1` to `0.0.0.0` (port 3113)

## Command to Start AgentMemory

Use this command to start agentmemory with external access:

```bash
VIEWER_ALLOWED_ORIGINS="http://localhost:3111,http://localhost:3113,http://127.0.0.1:3111,http://127.0.0.1:3113,http://0.0.0.0:3111,http://0.0.0.0:3113,http://192.168.1.192:3111,http://192.168.1.192:3113" VIEWER_ALLOWED_HOSTS="localhost:3113,127.0.0.1:3113,0.0.0.0:3113,192.168.1.192:3113" agentmemory
```

### Environment Variables Explained

- `VIEWER_ALLOWED_ORIGINS`: CORS origins allowed to access the viewer
- `VIEWER_ALLOWED_HOSTS`: Host headers the viewer will accept
- Replace `192.168.1.192` with your machine's actual IP address

## Making it Permanent

Add to your shell profile (`~/.zshrc` or `~/.bash_profile`):

```bash
export VIEWER_ALLOWED_ORIGINS="http://localhost:3111,http://localhost:3113,http://127.0.0.1:3111,http://127.0.0.1:3113,http://0.0.0.0:3111,http://0.0.0.0:3113,http://192.168.1.192:3111,http://192.168.1.192:3113"
export VIEWER_ALLOWED_HOSTS="localhost:3113,127.0.0.1:3113,0.0.0.0:3113,192.168.1.192:3113"
```

After adding, reload your profile:
```bash
source ~/.zshrc  # or source ~/.bash_profile
```

Then you can start agentmemory with just:
```bash
agentmemory
```

## Access Points

Once running, you can access agentmemory from any device on your network:

- **REST API**: `http://YOUR_IP:3111`
  - Example: `http://192.168.1.192:3111`
- **Viewer**: `http://YOUR_IP:3113`
  - Example: `http://192.168.1.192:3113`
- **Streams**: `ws://YOUR_IP:3112`
  - Example: `ws://192.168.1.192:3112`

## Security Considerations

Since the server is now exposed to your network:

1. **Set a secret token**: Add `AGENTMEMORY_SECRET=your-secret-here` to your `~/.agentmemory/.env` file to require authentication for API access.

2. **Firewall**: Consider using a firewall to restrict access if needed.

3. **Don't expose to internet**: Do not expose this directly to the internet without proper security measures (VPN, authentication, rate limiting, etc.).

## Troubleshooting

### If the viewer doesn't start
- Check if port 3113 is already in use: `lsof -i :3113`
- Check the logs: `agentmemory --verbose`

### If you get 403 Forbidden
- Ensure `VIEWER_ALLOWED_HOSTS` includes your IP/host combination
- Check that `VIEWER_ALLOWED_ORIGINS` includes your origin

### If you get connection refused
- Verify the service is listening on all interfaces: `lsof -i -P -n | grep 311[1-3]`
- You should see `*:3111`, `*:3112`, `*:3113` (not `127.0.0.1:*`)

## Updating Your IP Address

If your machine's IP address changes (e.g., DHCP renewal), update the environment variables with the new IP address and restart agentmemory.
