---
sidebar_position: 5
title: "Mastering journalctl: Comprehensive Troubleshooting Guide"
description: "Complete guide to using journalctl for system troubleshooting, log analysis, and real-world debugging scenarios in Linux"
slug: journalctl-troubleshooting-guide
---

# Mastering journalctl: A Comprehensive Guide to Troubleshooting in Linux

Welcome to this in-depth guide on using `journalctl`, the powerful command-line tool for managing and querying system logs in Linux environments that use systemd. If you're a system administrator, developer, or just a curious Linux user, understanding `journalctl` is essential for troubleshooting issues like service failures, kernel errors, or application crashes.

:::info Prerequisites
- Linux distribution with systemd (Ubuntu 16.04+, Fedora, Arch, etc.)
- Root/sudo privileges for system-wide logs
- Basic command-line familiarity
:::

## What is journalctl and Why Use It?

`journalctl` is part of systemd, the system and service manager that has become the standard in most Linux distributions. Unlike traditional logging systems (e.g., syslog), systemd's journal stores logs in a binary format, making them efficient, indexed, and searchable.

**Key advantages for troubleshooting:**
- **Structured Logs**: Logs include metadata like timestamps, process IDs, and priority levels
- **Centralized**: Aggregates logs from the kernel, services, and users
- **Persistent or Volatile**: Can be stored in memory or on disk for longer retention
- **Security**: Logs are tamper-resistant and can be filtered by user permissions

**Quick system check:**
```bash
systemctl status
```
If this works, your system uses systemd.

## Basic Usage: Viewing Logs

### Viewing All Logs
```bash
journalctl
```
- Paginates output (like `less`)
- Use arrow keys to scroll, `/` to search, `q` to quit

### Viewing Logs in Reverse (Newest First)
```bash
journalctl -r
```
Great for quickly seeing recent events.

### Following Logs in Real-Time
```bash
journalctl -f
```
- Similar to `tail -f`
- Press Ctrl+C to stop
- Useful for watching a service as you test it

### Limiting Output
```bash
# Show last 50 lines
journalctl -n 50

# Jump to the end
journalctl -e
```

## Filtering Logs for Targeted Troubleshooting

### By Time

Specify ranges with `--since` and `--until`:

```bash
# Specific date range
journalctl --since "2026-01-01 00:00:00" --until "2026-01-01 12:00:00"

# Relative time
journalctl --since yesterday
journalctl --since "2 hours ago"
journalctl --since "10 minutes ago"

# Current boot
journalctl -b

# Previous boot
journalctl -b -1
```

### By Service (Unit)

Focus on a specific systemd unit:

```bash
# View nginx logs
journalctl -u nginx.service

# Combine with time
journalctl -u nginx.service --since "2 hours ago"

# Multiple services
journalctl -u nginx.service -u mysql.service
```

**Tip:** List all services with `systemctl list-units --type=service`

### By Priority Level

Systemd log priorities:
- **0 (emerg)**: Emergency - system is unusable
- **1 (alert)**: Alert - action must be taken immediately
- **2 (crit)**: Critical - critical conditions
- **3 (err)**: Error - error conditions
- **4 (warning)**: Warning - warning conditions
- **5 (notice)**: Notice - normal but significant
- **6 (info)**: Informational messages
- **7 (debug)**: Debug-level messages

```bash
# Show errors and higher
journalctl -p err

# Range from errors to warnings
journalctl -p err..warning

# Only critical
journalctl -p crit
```

### By Process ID (PID)
```bash
journalctl _PID=1234
```

### By User or Group
```bash
# Filter by UID
journalctl _UID=1000

# By system user
journalctl _SYSTEMD_UNIT=sshd.service
```

### Advanced Field Matching
```bash
# View all available fields (verbose)
journalctl -o verbose

# Filter by message content
journalctl MESSAGE="Permission denied"

# Multiple fields
journalctl _COMM=sshd _EXE=/usr/sbin/sshd
```

### Combining Filters

Mix and match for powerful queries:

```bash
# Follow Apache errors from the last day
journalctl -u apache2.service -p err --since "1 day ago" -f

# SSH failed login attempts today
journalctl -u sshd.service --since today | grep "Failed password"

# Critical kernel messages from previous boot
journalctl -b -1 -k -p crit
```

## Formatting Output for Better Readability

Use `-o` to change output format:

```bash
# Default human-readable
journalctl -o short

# Full details with all metadata
journalctl -o verbose

# JSON format for scripting
journalctl -o json

# Pretty JSON
journalctl -o json-pretty

# Just messages, no metadata
journalctl -o cat
```

**Example:** Export service logs as JSON:
```bash
journalctl -u myservice -o json-pretty > myservice_logs.json
```

## Exporting and Managing Logs

### Saving Logs to a File
```bash
# Text format
journalctl -u myservice > myservice_logs.txt

# Binary format
journalctl --output=export > export.bin

# Specific time range
journalctl --since "2026-01-01" --until "2026-01-02" > daily_logs.txt
```

### Vacuuming (Cleaning) Journals

Journals can grow large. Clean by size or time:

```bash
# Keep only last 2 weeks
sudo journalctl --vacuum-time=2weeks

# Keep only 100MB
sudo journalctl --vacuum-size=100M

# Keep only last 5 files
sudo journalctl --vacuum-files=5
```

**Check journal disk usage:**
```bash
journalctl --disk-usage
```

### Configuring Persistence

Edit `/etc/systemd/journald.conf`:
```ini
[Journal]
Storage=persistent
SystemMaxUse=500M
SystemMaxFileSize=100M
```

Restart journald:
```bash
sudo systemctl restart systemd-journald
```

## Advanced Troubleshooting Techniques

### Boot Issues

For kernel boot logs:
```bash
# Current boot kernel messages
journalctl -b -0 -k

# Previous boot (useful after crashes)
journalctl -b -1 -k

# List all boots
journalctl --list-boots
```

### Verifying Journal Integrity
```bash
# Check for corruption
sudo journalctl --verify

# Rotate journals
sudo journalctl --rotate
```

### Integration with Other Tools

**With grep:**
```bash
journalctl -u ssh | grep "Failed password"
```

**With jq (for JSON parsing):**
```bash
journalctl -o json | jq '.MESSAGE'
```

**With systemctl:**
```bash
# Quick status
systemctl status myservice

# Detailed logs
journalctl -u myservice -n 100
```

## Real-World Troubleshooting Scenarios

### Scenario 1: Web Server Won't Start

**Problem:** Apache/Nginx fails to start after configuration change.

```bash
# Step 1: Check status
systemctl status apache2.service

# Step 2: View recent error logs
journalctl -u apache2.service -e -p err

# Step 3: Follow logs while attempting restart
journalctl -u apache2.service -f
# In another terminal: sudo systemctl restart apache2

# Step 4: Check for port conflicts
journalctl -u apache2.service | grep -i "bind\|port\|address"
```

**Common findings:**
- Port 80/443 already in use
- Configuration syntax errors
- Missing SSL certificates
- Permission issues on document root

### Scenario 2: SSH Login Failures

**Problem:** Unable to SSH into server, need to identify cause.

```bash
# View all SSH authentication failures
journalctl -u sshd.service | grep "Failed password"

# Count failed attempts per IP
journalctl -u sshd.service --since today | grep "Failed password" | awk '{print $(NF-3)}' | sort | uniq -c | sort -rn

# Check for specific user
journalctl -u sshd.service | grep "Failed password for invalid user admin"

# Real-time monitoring
journalctl -u sshd.service -f
```

**What to look for:**
- Brute force attempts (many failures from same IP)
- Invalid usernames
- Publickey authentication failures
- Connection refused/timeout issues

### Scenario 3: System Slowdown After Boot

**Problem:** System is slow, need to identify what's taking time during boot.

```bash
# Boot time analysis
systemd-analyze blame

# Critical chain
systemd-analyze critical-chain

# View boot logs with timing
journalctl -b | less

# Check for timeout errors
journalctl -b | grep -i "timeout\|failed\|error"

# Services that took longest
journalctl -b | grep "Startup finished in"
```

**Follow-up investigation:**
```bash
# Check specific slow service
journalctl -u slow-service.service -b

# Look for dependencies
systemctl list-dependencies slow-service.service
```

### Scenario 4: Disk Space Issues

**Problem:** System running out of space, journals might be the culprit.

```bash
# Check journal disk usage
journalctl --disk-usage

# Find large log entries
journalctl --since "1 day ago" -o verbose | grep -i "size"

# Identify chattiest services (log volume)
for service in $(systemctl list-units --type=service --state=running --no-pager | awk '{print $1}' | grep service); do
    echo "$service: $(journalctl -u $service --since "1 hour ago" | wc -l) lines"
done | sort -t: -k2 -rn | head -10

# Clean up
sudo journalctl --vacuum-size=100M
```

### Scenario 5: Database Crashes

**Problem:** PostgreSQL/MySQL crashed unexpectedly.

```bash
# Check for OOM (Out of Memory) killer
journalctl -k | grep -i "killed process\|out of memory"

# Database service logs around crash time
journalctl -u postgresql.service --since "2 hours ago" -p err

# Kernel logs for hardware issues
journalctl -k -p err --since "2 hours ago"

# Check for disk I/O errors
journalctl | grep -i "i/o error\|disk error"
```

**Analysis:**
```bash
# Memory pressure before crash
journalctl -k --since "3 hours ago" | grep -i "memory"

# Related service failures
journalctl --since "2 hours ago" -p err
```

### Scenario 6: Network Service Intermittent Failures

**Problem:** API service works sometimes, fails randomly.

```bash
# Pattern detection - errors over time
journalctl -u myapi.service --since "24 hours ago" -p warning | grep -o "^[A-Z][a-z][a-z] [0-9][0-9] [0-9][0-9]:[0-9][0-9]" | uniq -c

# Correlate with network issues
journalctl -u NetworkManager --since "24 hours ago" | grep -i "disconnected\|timeout"

# Check for resource exhaustion
journalctl | grep -i "too many open files\|resource temporarily unavailable"

# Time-based correlation
journalctl --since "2026-01-01 14:30:00" --until "2026-01-01 14:35:00" | grep -i "error\|failed\|timeout"
```

### Scenario 7: Container/Docker Issues

**Problem:** Docker containers failing to start.

```bash
# Docker service logs
journalctl -u docker.service -n 100

# Specific container logs (if using systemd units)
journalctl -u docker-mycontainer.service

# Kernel logs for cgroup/namespace issues
journalctl -k | grep -i "cgroup\|namespace\|oom"

# Follow docker events
journalctl -u docker.service -f
```

### Scenario 8: Failed System Updates

**Problem:** System update failed, package manager errors.

```bash
# APT/DNF logs
journalctl --since "1 day ago" | grep -i "apt\|dpkg\|dnf\|yum"

# Unattended upgrades
journalctl -u unattended-upgrades.service

# Check for held packages or conflicts
journalctl | grep -i "held\|conflict\|broken"

# Boot issues after update
journalctl -b -1 -p err
```

### Scenario 9: User Session Problems

**Problem:** User cannot log into desktop environment.

```bash
# User-specific logs (run as that user)
journalctl --user -n 50

# GNOME/KDE session issues
journalctl --user -u gnome-session
journalctl --user -u plasma-session

# Display manager logs
journalctl -u gdm.service
journalctl -u lightdm.service

# Authentication issues
journalctl | grep -i "pam\|authentication\|session"
```

### Scenario 10: Monitoring Cronjob Execution

**Problem:** Cron job not running or failing silently.

```bash
# Cron service logs
journalctl -u cron.service --since today

# Find specific job execution
journalctl | grep CRON | grep "yourscript"

# Watch for next execution
journalctl -u cron.service -f

# Check for errors in user crons
journalctl --since today | grep "cron\[" | grep -i "error\|fail"
```

### Scenario 11: Tailscale/VPN Daemon Won't Start in LXC

**Problem:** Tailscale (or other VPN) fails to start in LXC container with "failed to connect to local tailscaled" error.

```bash
# Check if tailscaled attempted to start
journalctl -u tailscaled.service -n 50

# Look for TUN/TAP device errors
journalctl -u tailscaled.service | grep -i "tun\|tap\|device\|permission denied"

# Check kernel messages for device availability
journalctl -k | grep -i "tun"

# Watch tailscaled startup in real-time
journalctl -u tailscaled.service -f
# In another terminal: sudo systemctl start tailscaled
```

**Common findings:**
- TUN device not available (`/dev/net/tun` missing)
- Permission denied on TUN device
- LXC container lacking device access

**Verification after fix:**
```bash
# Verify TUN device exists
ls -la /dev/net/tun

# Check if tailscaled is now running
systemctl status tailscaled

# View startup logs
journalctl -u tailscaled.service --since "1 minute ago"

# Confirm socket creation
ls -la /var/run/tailscale/tailscaled.sock
```

**LXC Fix (on host):**
Edit `/etc/pve/lxc/CONTAINER_ID.conf` and add:
```ini
lxc.cgroup2.devices.allow: c 10:200 rwm
lxc.mount.entry: /dev/net dev/net none bind,create=dir
```

Then restart container and monitor:
```bash
journalctl -u tailscaled.service -f
```

## Common Pitfalls and Tips

:::warning Common Issues
- **No Logs?** Check if journal is persistent: `ls /var/log/journal/`. If not, edit `/etc/systemd/journald.conf` and set `Storage=persistent`
- **Permission Denied:** Run with `sudo` for system-wide logs
- **Time Zones:** Journals use UTC by default; use `--utc` flag
- **Binary Corruption:** Use `sudo journalctl --verify` to check integrity
- **Performance:** Use filters to avoid slow queries on large journals
:::

**Pro Tips:**
1. Create aliases for common queries in `~/.bashrc`:
   ```bash
   alias jtoday='journalctl --since today'
   alias jerr='journalctl -p err -b'
   alias jfollow='journalctl -f'
   ```

2. Use `watch` for periodic checking:
   ```bash
   watch -n 2 'journalctl -u myservice -n 10'
   ```

3. Combine with `systemctl` for comprehensive troubleshooting:
   ```bash
   systemctl status myservice && journalctl -u myservice -n 50
   ```

## Quick Reference Card

| Command | Description |
|---------|-------------|
| `journalctl` | View all logs |
| `journalctl -f` | Follow logs in real-time |
| `journalctl -b` | Logs from current boot |
| `journalctl -b -1` | Logs from previous boot |
| `journalctl -u SERVICE` | Logs for specific service |
| `journalctl -p err` | Error-level logs and above |
| `journalctl -k` | Kernel messages only |
| `journalctl --since "1 hour ago"` | Logs from last hour |
| `journalctl --disk-usage` | Check journal disk usage |
| `journalctl --vacuum-size=100M` | Clean journals to 100MB |
| `journalctl -o json-pretty` | Output as formatted JSON |
| `journalctl --verify` | Check journal integrity |

## Conclusion

`journalctl` transforms troubleshooting from a chore into an efficient process. By mastering filters and options, you can pinpoint issues quickly and keep your Linux system running smoothly. Practice these scenarios in a test environment to build muscle memory.

:::tip Next Steps
- Experiment with filters on your test VM
- Create custom aliases for your most-used queries
- Set up log forwarding for critical services
- Review `man journalctl` for additional options
:::

## References

- [systemd Journal Documentation](https://www.freedesktop.org/software/systemd/man/systemd-journald.service.html)
- [Red Hat: Using journalctl](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/configuring_basic_system_settings/assembly_troubleshooting-problems-using-log-files_configuring-basic-system-settings)
- `man journalctl` and `man journald.conf` on your system
