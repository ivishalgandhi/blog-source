---
sidebar_position: 6
title: "Enabling TUN Device for Tailscale in LXC Containers"
description: "Complete guide to configuring TUN device access for Tailscale and VPN software in LXC containers on Proxmox"
slug: lxc-tailscale-tun-setup
---

# Enabling TUN Device for Tailscale in LXC Containers

This guide explains how to enable Tailscale (and other VPN software) in LXC containers by configuring TUN device access on Proxmox hosts.

:::info Prerequisites
- Root access to the Proxmox host
- SSH access to both the Proxmox host and LXC container
- Basic familiarity with LXC containers and systemd
:::

## Overview

## Understanding TUN Devices

### What is a TUN Device?

**TUN (Network TUNnel)** is a virtual network kernel device that operates at Layer 3 (network layer). It allows user-space programs to interact with network traffic as if they were physical network interfaces.

:::tip Think of it this way
A TUN device is like a "software network adapter" that exists only in the kernel. Programs can read and write network packets to it as if it were a real Ethernet card, but it's completely virtual.
:::

Think of it as a "fake" network adapter that exists only in software. When a program writes data to a TUN device, it appears as if the data came from a real network interface. When the kernel sends data to a TUN device, a program can read it.

### Why Do VPNs Need TUN Devices?

VPN software like Tailscale, WireGuard, and OpenVPN use TUN devices to:

1. **Create virtual network interfaces** - The VPN creates a new network interface (like `tailscale0`) that appears alongside your regular `eth0`
2. **Route encrypted traffic** - Traffic destined for VPN peers gets routed through this virtual interface
3. **Decrypt incoming packets** - Encrypted packets from the VPN are decrypted and injected back into the network stack
4. **Operate in userspace** - The VPN daemon runs as a regular process but can still handle network packets

Without TUN device access, VPN software cannot create these virtual interfaces and therefore cannot function.

### Why Don't LXC Containers Have TUN by Default?

**Security and isolation.** LXC containers are designed to be lightweight and secure by limiting what kernel devices and capabilities they can access.

:::warning Security Consideration
Allowing TUN device access:
- Gives containers the ability to manipulate network routing
- Could potentially be used to break out of container isolation
- Requires elevated privileges

Therefore, TUN access must be explicitly granted by the host administrator.
:::

---

## Problem

When trying to start Tailscale in an LXC container, you'll see errors like:

```bash
root@docs:~# tailscale up
failed to connect to local tailscaled; it doesn't appear to be running (sudo systemctl start tailscaled ?)

root@docs:~# systemctl status tailscaled
× tailscaled.service - Tailscale node agent
     Loaded: loaded
     Active: failed (Result: exit-code)
```

When checking logs with `journalctl`:
```bash
journalctl -u tailscaled.service
# Shows: Operation not permitted, TUN device missing
```

### Root Cause

The container lacks access to `/dev/net/tun`, which is required for creating virtual network interfaces.

:::danger Common Error Messages
```bash
failed to connect to local tailscaled
dial unix /var/run/tailscale/tailscaled.sock: connect: no such file or directory
Operation not permitted
```
:::

---

## Solution: Configure TUN Device Access

### Prerequisites

- Root access to the Proxmox host
- Container ID of your LXC container
- SSH access or console access to the Proxmox host

### Step 1: Identify Your Container

SSH to the Proxmox host:

```bash
ssh root@pve
```

List all containers to find yours:

```bash
pct list
```

Output:
```
VMID       Status     Lock         Name                
102        running                 pihole              
300        running                 docs
```

Verify it's the correct container:

```bash
pct config 300 | grep hostname
# Output: hostname: docs
```

### Step 2: View Current Configuration

Check the current container configuration:

```bash
cat /etc/pve/lxc/300.conf
```

You'll see something like:
```ini
arch: amd64
cores: 1
hostname: docs
memory: 512
net0: name=eth0,bridge=vmbr0,hwaddr=BC:24:11:28:9E:57,ip=dhcp,type=veth
ostype: debian
rootfs: data-containers:subvol-300-disk-0,size=8G
swap: 512
unprivileged: 1
```

### Step 3: Add TUN Device Access

Add the following two lines to enable TUN device access:

```bash
echo -e "lxc.cgroup2.devices.allow: c 10:200 rwm\nlxc.mount.entry: /dev/net dev/net none bind,create=dir" >> /etc/pve/lxc/300.conf
```

**What these lines do:**

:::note Configuration Explained
- **`lxc.cgroup2.devices.allow: c 10:200 rwm`**
  - Grants the container permission to access character device 10:200 (the TUN device)
  - `c` = character device
  - `10:200` = major:minor device numbers for TUN
  - `rwm` = read, write, and mknod permissions

- **`lxc.mount.entry: /dev/net dev/net none bind,create=dir`**
  - Bind-mounts the host's `/dev/net` directory into the container
  - `create=dir` automatically creates the directory if it doesn't exist
  - This makes the TUN device available inside the container
:::

Verify the configuration was added:

```bash
cat /etc/pve/lxc/300.conf
```

Should now show:
```ini
arch: amd64
cores: 1
hostname: docs
memory: 512
net0: name=eth0,bridge=vmbr0,hwaddr=BC:24:11:28:9E:57,ip=dhcp,type=veth
ostype: debian
rootfs: data-containers:subvol-300-disk-0,size=8G
swap: 512
unprivileged: 1
lxc.cgroup2.devices.allow: c 10:200 rwm
lxc.mount.entry: /dev/net dev/net none bind,create=dir
```

### Step 4: Restart the Container

The configuration changes only take effect after a restart:

```bash
pct stop 300
sleep 2
pct start 300
```

Wait a few seconds for the container to fully start.

### Step 5: Verify TUN Device in Container

SSH into the container:

```bash
ssh root@192.168.1.96  # Or your container's IP
```

Check if the TUN device exists:

```bash
ls -la /dev/net/tun
```

Expected output:
```
crw-rw-rw- 1 nobody nogroup 10, 200 Dec 22 03:25 /dev/net/tun
```

✅ The device exists and is accessible!

:::tip Quick Device Test
Try to read from it:
```bash
cat /dev/net/tun
# Output: cat: /dev/net/tun: File descriptor in bad state
```

This error is **good** - it means the device exists and responds. The "bad state" is normal because nothing has opened it yet.
:::

### Step 6: Start Tailscale Service

Now start the Tailscale daemon:

```bash
systemctl start tailscaled
```

Check the status:

```bash
systemctl status tailscaled
```

Expected output:
```
● tailscaled.service - Tailscale node agent
     Loaded: loaded (/usr/lib/systemd/system/tailscaled.service; enabled)
     Active: active (running) since Thu 2026-01-01 18:29:25 UTC; 2s ago
       Docs: https://tailscale.com/kb/
   Main PID: 86 (tailscaled)
     Status: "Needs login: "
      Tasks: 7
     Memory: 22M
     CGroup: /system.slice/tailscaled.service
             └─86 /usr/sbin/tailscaled --state=/var/lib/tailscale/tailscaled.state
```

✅ Service is running!

Enable it to start on boot:

```bash
systemctl enable tailscaled
```

### Step 7: Complete Tailscale Authentication

Now you can log in to Tailscale:

```bash
tailscale up
```

This will output a URL for authentication:
```
To authenticate, visit:

        https://login.tailscale.com/a/abc123def456
```

Open that URL in your browser, authenticate, and you're done!

Verify connection:

```bash
tailscale status
```

Expected output showing your devices:
```
100.64.1.1    docs                 linux   -
100.64.1.2    laptop               linux   -
```

---

## Verification Commands

### Check TUN Device

```bash
# Verify device exists
ls -la /dev/net/tun

# Check device type and permissions
file /dev/net/tun
# Output: /dev/net/tun: character special (10/200)
```

### Monitor Tailscale with journalctl

```bash
# View recent logs
journalctl -u tailscaled.service -n 30

# Follow logs in real-time
journalctl -u tailscaled.service -f

# Check for TUN-related errors
journalctl -u tailscaled.service | grep -i "tun\|device\|permission"
```

### Test Network Connectivity

```bash
# Ping another device on your Tailscale network
tailscale ping laptop

# Check which Tailscale interface was created
ip link show | grep tailscale
# Output: 5: tailscale0: <POINTOPOINT,MULTICAST,NOARP,UP,LOWER_UP> ...
```

---

## Troubleshooting

### Issue: TUN Device Still Missing After Restart

**Check:**
```bash
# On Proxmox host
cat /etc/pve/lxc/300.conf | grep "lxc.cgroup2\|lxc.mount"
```

**Solution:** Ensure both lines were added correctly and restart the container again.

### Issue: "Operation Not Permitted" When Creating TUN

**Problem:** You're trying to create the device from inside the container.

**Solution:** This must be done from the Proxmox host by modifying the container config. You cannot `mknod` from within an unprivileged container.

### Issue: Tailscaled Starts but Can't Create Interface

**Check:**
```bash
journalctl -u tailscaled.service | grep -i error
```

**Common causes:**
- SELinux or AppArmor blocking access
- Insufficient container capabilities

**Solution:** May need to add additional capabilities:
```bash
# On Proxmox host
echo "lxc.cap.keep: net_admin" >> /etc/pve/lxc/300.conf
pct restart 300
```

### Issue: Changes Don't Persist After Container Recreation

If you recreate the container from a template, you'll need to reapply these settings.

**Solution:** Create a template or script:

```bash
#!/bin/bash
# fix-lxc-tun.sh
CTID=$1
if [ -z "$CTID" ]; then
    echo "Usage: $0 <container-id>"
    exit 1
fi

grep -q "lxc.cgroup2.devices.allow: c 10:200 rwm" /etc/pve/lxc/${CTID}.conf || \
    echo "lxc.cgroup2.devices.allow: c 10:200 rwm" >> /etc/pve/lxc/${CTID}.conf

grep -q "lxc.mount.entry: /dev/net" /etc/pve/lxc/${CTID}.conf || \
    echo "lxc.mount.entry: /dev/net dev/net none bind,create=dir" >> /etc/pve/lxc/${CTID}.conf

echo "TUN device access enabled for container $CTID"
echo "Restart the container to apply changes: pct restart $CTID"
```

Make it executable and use it:
```bash
chmod +x fix-lxc-tun.sh
./fix-lxc-tun.sh 300
```

---

## Applies to Other VPN Software

This same configuration works for:

:::info Compatible VPN Software
- **WireGuard**
- **OpenVPN**
- **Zerotier**
- **Nebula**
- Any other VPN software that requires TUN/TAP devices
:::

---

## Security Considerations

### Is This Safe?

**Generally yes**, but understand the implications:

✅ **Safe for trusted containers** - If you control what runs in the container, this is fine.

⚠️ **Elevated privileges** - The container can now:
- Create virtual network interfaces
- Manipulate routing tables
- Potentially intercept traffic

❌ **Not for untrusted workloads** - Don't grant TUN access to containers running untrusted code.

### Best Practices

:::tip Security Best Practices
1. **Limit to specific containers** - Only enable for containers that need VPN access
2. **Use unprivileged containers** - Keep `unprivileged: 1` in your config
3. **Network segmentation** - Use separate VLANs for containers with TUN access
4. **Monitor access** - Regularly check `journalctl` for suspicious activity
5. **Firewall rules** - Configure `iptables` or `nftables` to restrict container network access
:::

---

## Alternative: Userspace Networking

If you cannot modify the host configuration, some VPN software supports userspace networking (no TUN required):

```bash
# Tailscale with userspace networking
tailscale up --netfilter-mode=off
```

:::caution Limitations
- May have reduced performance
- Some features may not work
- Not all VPN software supports this
:::

---

## Summary

To enable Tailscale in LXC:

1. Add TUN device access to container config on Proxmox host
2. Restart the container
3. Verify `/dev/net/tun` exists
4. Start `tailscaled` service
5. Complete authentication with `tailscale up`

:::note Key Configuration
The key configuration lines to add to `/etc/pve/lxc/CONTAINER_ID.conf`:
```ini
lxc.cgroup2.devices.allow: c 10:200 rwm
lxc.mount.entry: /dev/net dev/net none bind,create=dir
```

Use `journalctl -u tailscaled.service` to monitor and troubleshoot issues.
:::

---

## References

- [Tailscale on LXC Containers](https://tailscale.com/kb/1130/lxc-unprivileged)
- [LXC Container Configuration](https://linuxcontainers.org/lxc/manpages/man5/lxc.container.conf.5.html)
- [TUN/TAP Interface Documentation](https://www.kernel.org/doc/Documentation/networking/tuntap.txt)
- [journalctl Troubleshooting Guide](./journalctl-troubleshooting-guide.md)
