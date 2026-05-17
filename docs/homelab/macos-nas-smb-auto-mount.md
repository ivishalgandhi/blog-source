---
sidebar_position: 2
title: macOS NAS SMB Auto-Mount
description: Auto-mount UGREEN NAS shares at boot using LaunchAgent and smbfs on macOS
---

# macOS NAS SMB Auto-Mount

> Guide to automatically mount UGREEN NAS (or any SMB) shares on macOS at login, with recovery steps for a new machine.

## What This Does

- **Runs every 60 seconds** via `launchd` (`com.vishal.nasmount`)
- **Idempotent** — skips shares already mounted
- **Pulls password from macOS Keychain** — no plaintext secrets
- **Mounts 6 shares** into `/Volumes/nas/`:
  - `docker`
  - `Backups`
  - `personal_folder`
  - `cloud_drive`
  - `Documents`
  - `Media`

## Files

| File | Purpose | Backup |
|------|---------|--------|
| `~/bin/mount-nas.sh` | Main mount script | ✅ Chezmoi → GitLab |
| `~/Library/LaunchAgents/com.vishal.nasmount.plist` | LaunchAgent definition | ✅ Chezmoi → GitLab |
| Keychain entry (`security`) | NAS password | ❌ Manual setup on new Mac |

## Prerequisites

- NAS is online at `192.168.1.107`
- SMB shares are created and accessible with username `vishal`
- macOS has write access to `/Volumes/`

## New Mac Setup

### 1. Restore Dotfiles

```bash
chezmoi init git@gitlab.com:codewithvishal/dotfiles.git
chezmoi apply
```

This restores:
- `~/bin/mount-nas.sh`
- `~/Library/LaunchAgents/com.vishal.nasmount.plist`

### 2. Add Password to Keychain

:::warning Critical Step
Without this, the script runs but fails silently with `No route to host` (exit 68) because `@` in the password breaks the SMB URL parser.
:::

```bash
# Replace with your actual NAS password
security add-internet-password \
  -a vishal \
  -s 192.168.1.107 \
  -w

# When prompted, type your password and press Enter
```

To verify:

```bash
security find-internet-password -s 192.168.1.107 -a vishal -w
```

### 3. Create Mount Point

```bash
mkdir -p /Volumes/nas
```

### 4. Load the LaunchAgent

```bash
launchctl load ~/Library/LaunchAgents/com.vishal.nasmount.plist
```

Verify it loaded:

```bash
launchctl list | grep nasmount
```

You should see the label (not just `- 0` or `- 68`).

### 5. Test the Script Manually

```bash
~/bin/mount-nas.sh
echo $?
```

Expected: exit code `0`

Verify mounts:

```bash
mount | grep /Volumes/nas
df -h | grep nas
```

## Script Details

### URL-Encoding Fix

:::tip Why This Exists
The NAS password contains `@` and possibly `:`. `mount_smbfs` parses the SMB URL `//user:pass@host/share` and mistakes `@` in the password for the host separator. The script handles this by encoding `@` → `%40` and `:` → `%3A`.
:::

From the script:

```bash
PASS=$(security find-internet-password -s "$NAS_IP" -a "$NAS_USER" -w 2>/dev/null)

# URL-encode @ and : in password for SMB URL
PASS="${PASS//@/%40}"
PASS="${PASS//:/%3A}"

mount_smbfs "//${NAS_USER}:${PASS}@${NAS_IP}/${share}" "$mp"
```

Do **not** remove this encoding. It was added because the script failed for months with exit code 68.

## Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| `exit 68` from script | `No route to host` — password `@` mis-parsed | Ensure URL-encoding is in script |
| `exit 71` from script | Mount point does not exist | `mkdir -p /Volumes/nas/<share>` |
| `mount_smbfs: ... No route to host` | Wrong host parsed from password | Verify `@` is encoded as `%40` |
| Shares not showing after reboot | LaunchAgent not loaded | Run `launchctl load` again |
| LaunchAgent shows `- 68` | Script fails every 60s | Check `/tmp/nasmount.error` |
| Mount point has old local files | Directory was non-empty when unmounted | Move files out, run script again |

### Check Logs

```bash
cat /tmp/nasmount.error
cat /tmp/nasmount.log
```

### Full Reset

```bash
# Unload agent
launchctl unload ~/Library/LaunchAgents/com.vishal.nasmount.plist 2>/dev/null

# Unmount all shares
for d in docker Backups personal_folder cloud_drive Documents Media; do
  sudo umount "/Volumes/nas/$d" 2>/dev/null
done

# Clear mount point (move any local files first!)
mv /Volumes/nas/Media/*.png ~/Desktop/ 2>/dev/null

# Reload agent
launchctl load ~/Library/LaunchAgents/com.vishal.nasmount.plist

# Test manually
~/bin/mount-nas.sh
```

## Changing Password

```bash
# Delete old entry
security delete-internet-password -s 192.168.1.107 -a vishal

# Add new entry
security add-internet-password -a vishal -s 192.168.1.107 -w
```

No script change needed — it reads from Keychain dynamically.

## Recovering from Lost Machine

If this M4 Mac dies:

1. **Restore dotfiles** via chezmoi (restores script + LaunchAgent)
2. **Add Keychain password** manually (step 2 above)
3. **Load LaunchAgent** (step 4 above)
4. **Run script once** to verify (step 5 above)

Shares appear under `/Volumes/nas/` within 60 seconds.

## References

- `man mount_smbfs`
- `man launchctl`
- `man security`

---

*Document created: 2026-05-17*
