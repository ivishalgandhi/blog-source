# Home Multi-Device Sync Infrastructure

> Complete Syncthing setup guide for 5-node topology: M4 Mini, Mini 2, MacBook Air, UGREEN DH2300 NAS, Proxmox VMs (Ubuntu + Windows)

## Architecture Overview

### Topology: Mesh with DH2300 as Constrained Hub

```
                    ┌─────────────┐
              ┌────►│  MacBook    │
              │     │    Air      │◄────┐
              │     │ (Portable)  │     │
              │     └─────────────┘     │
              │           ▲             │
              │           │             │
        ┌─────┴────┐  ┌───┴─────┐  ┌────┴────┐
        │   M4     │  │ UGREEN  │  │ Mini 2  │
        │  Mini    │◄─┤  DH2300 │◄─┤ (Build) │
        │(Primary) │  │  (NAS)  │  │(Code)   │
        └────┬─────┘  └────┬────┘  └────┬────┘
             │             │            │
             └─────────────┼────────────┘
                           │
                    ┌──────┴──────┐
                    │  Proxmox    │
                    │   Host      │
                    └──────┬──────┘
                           │
                ┌──────────┼──────────┐
                ▼          ▼          ▼
           ┌────────┐ ┌────────┐ ┌────────┐
           │ Ubuntu │ │Windows │ │ Future │
           │   VM   │ │   VM   │ │  VMs   │
           └────────┘ └────────┘ └────────┘
```

### Node Roles

| Node | Role | Always-On | Syncthing Load |
|------|------|-----------|----------------|
| **M4 Mini** | Primary dev, sync hub | Yes | High (Send & Receive) |
| **Mini 2** | Secondary dev, sync hub | Yes | High (Send & Receive) |
| **MacBook Air** | Portable leaf | No | Medium (Send & Receive) |
| **DH2300** | Archive, backup bridge | Yes | **Constrained** (RTD1296 ARM) |
| **Proxmox VMs** | Dev/test environments | Yes | Medium |

### Device Connection Matrix

| From → To | M4 Mini | Mini 2 | DH2300 | Air | Ubuntu VM | Windows VM |
|-----------|---------|--------|--------|-----|-----------|------------|
| **M4 Mini** | — | ✓ | ✓ | ✓ | ✓ | ✓ |
| **Mini 2** | ✓ | — | ✓ | ✓ | ✓ | — |
| **DH2300** | ✓ | ✓ | — | — | — | — |
| **MacBook Air** | ✓ | ✓ | — | — | — | — |
| **Ubuntu VM** | ✓ | ✓ | — | — | — | — |
| **Windows VM** | ✓ | — | — | — | — | — |

**Key:** DH2300 only connects to M4 Mini and Mini 2. Air and VMs bridge through the Macs.

---

## Hardware Constraints: UGREEN DH2300

### Specifications
- **CPU:** Realtek RTD1296 (ARM Cortex-A53 1.4GHz, quad-core)
- **RAM:** 2GB DDR4
- **Storage:** Your disks
- **OS:** UGREEN OS (Linux-based)
- **Docker:** **Not available** (base model)

### Performance Implications
- Hash calculation is slow on large files
- Limited RAM — aggressive scanning causes OOM
- No Docker — must use Entware/SSH installation
- Not suitable for high-churn folders (active-projects)
- Suitable for: archive, documents, low-churn sync

### Monitoring: When to Switch to Archive Mode

```bash
# SSH into DH2300 and check

top  # If syncthing consistently >50% CPU for >10 min

# Check for OOM kills
dmesg | grep -i "out of memory\|killed process"

# Disk performance
iostat -x 5 3  # If %util >90% consistently

# Syncthing logs
tail -f /opt/var/log/syncthing.log  # Check for hash errors, database compaction warnings
```

**Switch triggers:**
- Any folder stuck at "Scanning" >30 minutes
- Load average &gt;4.0 for sustained periods
- "Database is locked" or "out of memory" errors
- Sync speed &lt;100 KB/s with no network issues

---

## DH2300 Syncthing Installation (Entware)

### Step 1: Enable SSH
1. UGREEN OS Web UI → Settings → Security → Enable SSH
2. Or use debug mode if SSH not exposed in UI
3. Note the IP or use Tailscale: `ssh root@dh2300.tailnet.ts.net`

### Step 2: Install Entware
```bash
# SSH into DH2300
ssh root@dh2300.tailnet.ts.net

# Download and install Entware (ARM64 for RTD1296)
wget -O - http://bin.entware.net/aarch64-k3.10/installer/generic.sh | /bin/sh

# Add to PATH
export PATH=/opt/bin:/opt/sbin:$PATH
echo 'export PATH=/opt/bin:/opt/sbin:$PATH' >> /etc/profile
```

### Step 3: Install Syncthing
```bash
# Update package list and install
opkg update
opkg install syncthing

# Create data directory on your storage volume
mkdir -p /mnt/sda1/syncthing-data
mkdir -p /mnt/sda1/sync/{active,archive}

# Generate initial config
/opt/bin/syncthing generate --config=/opt/etc/syncthing --data=/mnt/sda1/syncthing-data
```

### Step 4: Configure Web UI Authentication
```bash
# Set username and password (replace YOUR_PASSWORD)
/opt/bin/syncthing cli --config=/opt/etc/syncthing config gui username set admin
/opt/bin/syncthing cli --config=/opt/etc/syncthing config gui password set YOUR_PASSWORD

# Get Device ID (save this for other nodes)
/opt/bin/syncthing --config=/opt/etc/syncthing --data=/mnt/sda1/syncthing-data device-id
```

### Step 5: Create Auto-Start Script
```bash
cat > /opt/etc/init.d/S99syncthing << 'EOF'
#!/bin/sh

NAME="syncthing"
DAEMON="/opt/bin/syncthing"
CONFIG="/opt/etc/syncthing"
DATA="/mnt/sda1/syncthing-data"
PIDFILE="/var/run/syncthing.pid"

case "$1" in
  start)
    echo "Starting $NAME..."
    $DAEMON serve --config=$CONFIG --data=$DATA --no-browser --no-restart > /dev/null 2>&1 &
    echo $! > $PIDFILE
    ;;
  stop)
    echo "Stopping $NAME..."
    if [ -f $PIDFILE ]; then
      kill $(cat $PIDFILE) 2>/dev/null
      rm -f $PIDFILE
    else
      killall syncthing 2>/dev/null
    fi
    ;;
  restart)
    $0 stop
    sleep 2
    $0 start
    ;;
  status)
    if [ -f $PIDFILE ] && kill -0 $(cat $PIDFILE) 2>/dev/null; then
      echo "$NAME is running"
    else
      echo "$NAME is not running"
    fi
    ;;
  *)
    echo "Usage: $0 {start|stop|restart|status}"
    exit 1
esac

exit 0
EOF

chmod +x /opt/etc/init.d/S99syncthing
```

### Step 6: Start Syncthing
```bash
/opt/etc/init.d/S99syncthing start

# Verify
/opt/etc/init.d/S99syncthing status

# Access Web UI (replace with your NAS IP)
# http://dh2300.tailnet.ts.net:8384
```

---

## DH2300 Performance Configuration

### Web UI Settings (Critical for RTD1296)

| Category | Setting | Recommended Value | Default |
|----------|---------|-------------------|---------|
| **GUI** | Listen Address | `127.0.0.1:8384` | `0.0.0.0:8384` |
| **Connections** | Max recv rate (KiB/s) | `5000` (5 MB/s) | `0` (unlimited) |
| **Connections** | Max send rate (KiB/s) | `5000` (5 MB/s) | `0` (unlimited) |
| **Connections** | Max outstanding requests | `4` | `16` |
| **Connections** | Connection limit | `10` | `0` (unlimited) |
| **Advanced** | Database tuning | `small` | `auto` |

### Folder Configuration (DH2300)

| Folder | Path | Type | Versioning | Rescan Interval | Watch |
|--------|------|------|------------|-----------------|-------|
| active-projects | `/mnt/sda1/sync/active/projects` | Send & Receive | Staggered (7d, 5) | 3600s | **No** |
| active-src | `/mnt/sda1/sync/active/src` | Send & Receive | Staggered (7d, 5) | 3600s | **No** |
| active-foss | `/mnt/sda1/sync/active/foss` | Send & Receive | Staggered (7d, 5) | 3600s | **No** |
| active-notes | `/mnt/sda1/sync/active/notes` | Send & Receive | Staggered (7d, 5) | 3600s | **No** |
| archive | `/mnt/sda1/sync/archive` | Send & Receive | Staggered (30d, 10) | 7200s | **No** |
| documents | `/mnt/sda1/sync/documents` | Send & Receive | Simple (3) | 3600s | **No** |

**Note:** "Watch for changes" (inotify) is **disabled** on DH2300 to save CPU. Periodic scans only.

---

## Directory Structure (All Machines)

### Unified Layout

```
~/
├── active/                      # Syncthing synced (all nodes)
│   ├── projects/               # Main code repositories
│   │   ├── work/              # Employer/client projects
│   │   ├── personal/          # Your projects
│   │   └── experiments/       # Playground/learning
│   ├── src/                   # Libraries you maintain/fork
│   ├── foss/                  # Open source clones
│   ├── notes/                 # Obsidian/Logseq/wiki
│   ├── documents/             # PDFs, contracts, etc.
│   ├── dotfiles/              # Selective config files
│   └── .stignore              # Root ignore file (recursive)
│
├── archive/                    # Syncthing synced (NAS-heavy)
│   ├── old-projects/
│   ├── resources/             # Ebooks, courses
│   └── backups/               # Manual backups
│
└── local/                      # NOT synced
    ├── tmp/
    ├── downloads/
    ├── cache/
    └── large-assets/          # Videos, disk images
```

### Migration Commands (Run on each Mac)

```bash
# 1. Create unified structure
mkdir -p ~/active/{projects,src,foss,notes,documents,archive} ~/local

# 2. Migrate existing directories (adjust paths as needed)
# Move ~/code contents
if [ -d ~/code ] && [ ! -L ~/code ]; then
    mv ~/code/* ~/active/projects/ 2>/dev/null
    rmdir ~/code 2>/dev/null
fi
ln -sf ~/active/projects ~/code

# Move ~/src contents
if [ -d ~/src ] && [ ! -L ~/src ]; then
    mv ~/src/* ~/active/src/ 2>/dev/null
    rmdir ~/src 2>/dev/null
fi
ln -sf ~/active/src ~/src

# Move ~/foss contents
if [ -d ~/foss ] && [ ! -L ~/foss ]; then
    mv ~/foss/* ~/active/foss/ 2>/dev/null
    rmdir ~/foss 2>/dev/null
fi
ln -sf ~/active/foss ~/foss

# 3. Verify structure
echo "Active directories:"
ls -la ~/active/
echo ""
echo "Symlinks:"
ls -la ~/code ~/src ~/foss 2>/dev/null
```

---

## Syncthing Configuration by Node

### M4 Mini (Primary Hub)

**Installation:**
```bash
brew install syncthing
brew services start syncthing
```

**Configuration:**
- **Device Name:** `m4-mini`
- **Device Addresses:** `tcp://m4-mini.tailnet.ts.net:22000, dynamic`
- **Listen Addresses:** `default, tcp://0.0.0.0:22000, quic://0.0.0.0:22000`
- **Global Discovery:** Enabled
- **Local Discovery:** Enabled

**Folder Settings:**

| Folder | Path | Type | Versioning | Watch |
|--------|------|------|------------|-------|
| active-projects | `~/active/projects` | Send & Receive | Simple (3) | Yes |
| active-src | `~/active/src` | Send & Receive | Simple (3) | Yes |
| active-foss | `~/active/foss` | Send & Receive | Simple (3) | Yes |
| active-notes | `~/active/notes` | Send & Receive | Simple (5) | Yes |
| archive | `~/archive` | Send & Receive | Simple (3) | Yes |

### Mini 2 (Secondary Hub)

**Configuration:**
- **Device Name:** `mini-2`
- **Device Addresses:** `tcp://mini-2.tailnet.ts.net:22000, dynamic`
- Same folder config as M4 Mini

### MacBook Air (Portable)

**Configuration:**
- **Device Name:** `macbook-air`
- **Device Addresses:** `tcp://macbook-air.tailnet.ts.net:22000, dynamic`
- **Max recv/send rate:** Optional limit for battery (e.g., 10000 KB/s)

**Extra `.stignore.local` (not synced):**
```gitignore
# ~/active/.stignore.local — MacBook Air only
# Large build outputs not needed portable
ios-build/
android-build/
.gradle/
DerivedData/
.ccache/

# Virtual machines in projects
*.vmdk
*.qcow2
*.vdi
*.iso

# Uncomment if desperate for space:
# node_modules/
# target/
```

### Proxmox VMs

**Ubuntu VM:**
```bash
# Install
sudo apt install syncthing
sudo systemctl enable --now syncthing@$USER.service

# Config
# Device Name: ubuntu-vm
# Device Addresses: tcp://ubuntu-vm.tailnet.ts.net:22000, tcp://10.0.0.x:22000
```

**Windows VM:**
- Install from: https://syncthing.net/downloads/
- Device Name: `windows-vm`
- Consider "Receive Only" for most folders to minimize conflicts

---

## Stignore Patterns

### Root `.stignore` (place at `~/active/.stignore`)

```gitignore
// =============================================================================
// Syncthing Ignore Patterns — Root level for ~/active/
// These patterns apply recursively to all subdirectories
// =============================================================================

// -----------------------------------------------------------------------------
// PLATFORM FILES — macOS, Windows, Linux
// -----------------------------------------------------------------------------
**/.DS_Store
**/.fseventsd
**/.Spotlight-V100
**/.Trashes
**/.Trash-*
**/Thumbs.db
**/ehthumbs.db
**/[Dd]esktop.ini
**/$RECYCLE.BIN
**/.nfs*

// -----------------------------------------------------------------------------
// EDITOR FILES — Temporary and workspace
// -----------------------------------------------------------------------------
**/*~
**/*.swp
**/*.swo
**/.#*
**/#*#
**/.idea/workspace.xml
**/.idea/tasks.xml
**/.idea/dictionaries/
**/.idea/shelf/
**/.vscode/settings.json.local
**/.vscode/extensions/
**/.vscode/*.log
**/.vs/

// -----------------------------------------------------------------------------
// BUILD ARTIFACTS — Language specific
// -----------------------------------------------------------------------------
// Node.js
**/node_modules
**/npm-debug.log*
**/yarn-debug.log*
**/yarn-error.log*

// Python
**/__pycache__
**/*.pyc
**/*.pyo
**/.venv
**/.virtualenv
**/.pytest_cache
**/.mypy_cache
**/.ruff_cache
**/.tox
**/*.egg-info
**/.eggs
**/*.egg

// Rust
**/target
**/Cargo.lock

// Go
**/vendor/

// Java/Gradle
**/.gradle
**/build
**/out

// C/C++
**/*.o
**/*.a
**/*.so
**/*.dylib
**/*.dll
**/*.exe
**/.ccache

// .NET
**/bin
**/obj
**/*.stackdump

// Web frameworks
**/.next
**/.nuxt
**/.turbo
**/.parcel-cache
**/.cache
**/dist

// iOS/Xcode
**/DerivedData
**/*.pbxuser
**/*.mode1v3
**/*.mode2v3
**/*.perspectivev3
**/*.xcworkspace/xcuserdata

// Android
**/.gradle
**/local.properties

// -----------------------------------------------------------------------------
// DATABASE AND STATE FILES
// -----------------------------------------------------------------------------
**/*.db
**/*.sqlite
**/*.sqlite3
**/*.db-journal
**/.env.local
**/.env.*.local
**/.env.development
**/.env.production
**/.vagrant
**/.vagrant.d
**/.terraform

// -----------------------------------------------------------------------------
// TESTING AND COVERAGE
// -----------------------------------------------------------------------------
**/coverage
**/.coverage
**/htmlcov
**/.nyc_output
**/.scannerwork

// -----------------------------------------------------------------------------
// LOGS
// -----------------------------------------------------------------------------
**/*.log
**/logs
**/*.log.[0-9]*

// -----------------------------------------------------------------------------
// LARGE MEDIA (if in project folders)
// -----------------------------------------------------------------------------
**/*.mp4
**/*.mov
**/*.mkv
**/*.avi
**/*.wav
**/*.mp3
**/*.iso
**/*.dmg
**/*.img
**/*.qcow2
**/*.vmdk
**/*.vdi

// -----------------------------------------------------------------------------
// GIT INTERNALS (sync repos but not locks/temp)
// -----------------------------------------------------------------------------
**/.git/index.lock
**/.git/*.lock
**/.git/config.lock
**/.git/refs/remotes/*/HEAD.lock

// -----------------------------------------------------------------------------
// SYNCTHING ITSELF
// -----------------------------------------------------------------------------
**/.stfolder
**/.stignore.local
**/.syncthing.*.tmp
**/*.sync-conflict*

// -----------------------------------------------------------------------------
// CLOUD STORAGE DROPPINGS (if any)
// -----------------------------------------------------------------------------
**/.dropbox
**/.dropbox.attr
**/desktop.ini
```

### Per-Machine `.stignore.local`

Create `~/active/.stignore.local` on each machine (not synced) for machine-specific excludes:

**M4 Mini:**
```gitignore
# Build outputs only on M4
# (none typically — this is primary dev)
```

**Mini 2:**
```gitignore
# CI/build specific
jenkins-workspace/
build-server-cache/
```

**MacBook Air:**
```gitignore
# Space-saving exclusions
ios-build/
android-build/
**/node_modules
**/target
```

---

## Tailscale Integration

### Device Addresses Format

Add these in each device's "Remote Devices" → "Edit" → "Addresses" field:

| Device | Addresses |
|--------|-----------|
| M4 Mini | `tcp://m4-mini.tailnet.ts.net:22000, dynamic` |
| Mini 2 | `tcp://mini-2.tailnet.ts.net:22000, dynamic` |
| DH2300 | `tcp://dh2300.tailnet.ts.net:22000, dynamic` |
| MacBook Air | `tcp://macbook-air.tailnet.ts.net:22000, dynamic` |
| Ubuntu VM | `tcp://ubuntu-vm.tailnet.ts.net:22000, tcp://10.0.0.50:22000` |
| Windows VM | `tcp://windows-vm.tailnet.ts.net:22000, tcp://10.0.0.51:22000` |

**Why both?** Tailscale for reliability, local IPs for speed when on same Proxmox host.

### Firewall Rules

Ensure these ports are allowed:
- **22000/tcp** — Syncthing protocol (primary)
- **22000/udp** — QUIC transport
- **21027/udp** — Local discovery (optional, LAN only)
- **8384/tcp** — Web UI (localhost only recommended)

---

## Conflict Handling

### Versioning Configuration

| Folder | NAS (DH2300) | Macs (Mini/Air) | VMs |
|--------|--------------|-----------------|-----|
| active-* | Staggered (7d, 5 versions) | Simple (3 versions) | Simple (3) or None |
| archive | Staggered (30d, 10 versions) | Simple (3) | None |
| notes | Staggered (30d, 10 versions) | Simple (5 versions) | Simple (3) |

### Conflict Resolution Workflow

1. **Detection:** Syncthing creates `file.sync-conflict-20260115-143022.txt`
2. **Location:** Same directory as original file
3. **Resolution:**
   ```bash
   # Find all conflicts
   find ~/active -name "*.sync-conflict*" -ls

   # Use diff tool to compare
   # macOS: FileMerge (opendiff), Kaleidoscope, or vimdiff
   opendiff file.txt file.sync-conflict-20260115-143022.txt

   # After merging, delete conflict file
   rm file.sync-conflict-*.txt
   ```
4. **Propagation:** Syncthing deletes conflict file from all nodes

### Minimizing Conflicts

- **Commit often** (you mentioned this — excellent)
- **Pause folders** on Air before long offline sessions
- **Use "Receive Only"** on VMs for one-way sync
- **Avoid editing same file** on multiple machines simultaneously

---

## Emergency: Switching DH2300 to Archive Mode

If DH2300 cannot handle active sync:

### Step 1: Stop Syncthing on DH2300
```bash
ssh root@dh2300.tailnet.ts.net
/opt/etc/init.d/S99syncthing stop
```

### Step 2: Reconfigure as SMB Archive (M4 Mini)

```bash
# On M4 Mini
# Mount DH2300
mkdir -p /Volumes/DH2300
mount_smbfs //admin@dh2300.tailnet.ts.net/active /Volumes/DH2300

# Create folder in Syncthing pointing to mounted path
# Folder type: Send Only (from other Macs to NAS)
# Or use cron instead of Syncthing:
```

### Step 3: Cron-based Archive (Simple)
```bash
# On M4 Mini, crontab -e
0 * * * * rsync -az --delete --exclude='.st*' --exclude='*.sync-conflict*' ~/active/archive/ /Volumes/DH2300/archive/
0 2 * * * rsync -az --delete ~/active/projects/ /Volumes/DH2300/projects-backup/
```

### Step 4: Update Other Nodes
- Remove DH2300 from "active-*" folder sharing
- Keep only M4 Mini + Mini 2 as sync hubs
- DH2300 becomes passive backup target

---

## Monitoring & Maintenance

### Health Check Commands

**Check sync status (any node):**
```bash
# Using syncthing CLI
syncthing cli show system
syncthing cli show connections
syncthing cli show folder-status

# Check for errors
syncthing cli show errors
```

**Check DH2300 specifically:**
```bash
ssh root@dh2300.tailnet.ts.net

# System load
uptime
# Should be <2.0 for RTD1296

# Syncthing process
ps | grep syncthing
# Should show syncthing running

# Disk space
df -h

# Memory usage
free -m
# Available should be >200MB
```

### Weekly Maintenance

1. **Check for conflicts:**
   ```bash
   find ~/active -name "*.sync-conflict*" 2>/dev/null
   ```

2. **Review DH2300 performance:**
   - Web UI → Logs → "Performance" warnings
   - If "database compaction" warnings appear, schedule restart

3. **Restart Syncthing on DH2300** (weekly cron optional):
   ```bash
   # Add to DH2300 crontab: 0 4 * * 0 /opt/etc/init.d/S99syncthing restart
   ```

---

## Quick Reference: First-Time Setup Checklist

### Phase 1: DH2300 Preparation
- [ ] Enable SSH on DH2300
- [ ] Install Entware
- [ ] Install Syncthing
- [ ] Configure Web UI auth
- [ ] Start Syncthing service
- [ ] Apply performance settings (rate limits, small DB)
- [ ] Note Device ID

### Phase 2: Mac Migration (each Mac)
- [ ] Create `~/active/` directory structure
- [ ] Migrate `~/code`, `~/src`, `~/foss` contents
- [ ] Create symlinks for backward compatibility
- [ ] Place `.stignore` at `~/active/.stignore`
- [ ] Create `.stignore.local` (Air only)
- [ ] Install Syncthing (`brew install syncthing`)
- [ ] Start service (`brew services start syncthing`)
- [ ] Open Web UI, set device name

### Phase 3: Device Pairing
- [ ] M4 Mini: Add DH2300 as device
- [ ] Mini 2: Add DH2300 as device
- [ ] DH2300: Accept both Macs
- [ ] M4 Mini ↔ Mini 2: Verify direct sync
- [ ] Add MacBook Air to M4 Mini and Mini 2
- [ ] Add Proxmox VMs to M4 Mini (and Mini 2 for Ubuntu)

### Phase 4: Folder Sharing
- [ ] M4 Mini: Create folders, share with DH2300, Mini 2, Air, VMs
- [ ] Verify DH2300 accepts folders with correct paths
- [ ] Verify `.stignore` excludes are working (check `.stfolder` exists, ignored files don't)
- [ ] Test edit on M4 Mini → appears on Mini 2 and DH2300

### Phase 5: Validation
- [ ] Create test file on Air, verify syncs to all nodes
- [ ] Create conflict intentionally, verify conflict file created
- [ ] Check DH2300 load: `uptime` should be &lt;2.0 after initial sync
- [ ] Verify Tailscale connectivity: `tailscale status` on all nodes

---

## Troubleshooting

### Issue: DH2300 shows "Disconnected"
- Check Tailscale: `tailscale ping dh2300`
- SSH to DH2300: `/opt/etc/init.d/S99syncthing status`
- Check logs: `tail /opt/var/log/syncthing.log`

### Issue: Sync stuck at 0%
- Check `.stignore` patterns — file might be ignored
- Check DH2300 disk space: `df -h`
- Restart Syncthing on affected nodes

### Issue: High CPU on DH2300
- Reduce scan interval to 7200s or higher
- Enable "Max recv rate" limit
- Check for large files being hashed

### Issue: Conflicts constantly
- Ensure consistent `.stignore` across nodes
- Check file modification times (clock sync)
- Consider "Receive Only" for problematic folders

---

## Document History

- **Created:** 2026-04-11
- **Topology:** 5-node mesh (2 Macs hub, 1 portable leaf, 1 constrained NAS, 2 VMs)
- **Hardware constraint:** UGREEN DH2300 (RTD1296 ARM, 2GB RAM, no Docker)
- **Primary sync method:** Syncthing via Entware on DH2300
- **Fallback method:** Archive-only mode with SMB + rsync
