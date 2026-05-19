# SSH Troubleshooting Guide for Arch Linux

## Problem
SSH service is running, but connections timeout or fail.

## Check SSH Status
```bash
sudo systemctl status sshd
```

## Check if SSH Listens on Port 22
```bash
sudo ss -tlnp | grep sshd
```

If output shows `0.0.0.0:22` or `:::22`, SSH is listening on all interfaces.

## Check Firewall Rules
```bash
sudo iptables -L -n | grep 22
```

If you **don't see 22 in the rules**, add the allow rule:

```bash
sudo iptables -I INPUT -p tcp --dport 22 -j ACCEPT
```

Verify:
```bash
sudo iptables -L -n | grep 22
```

## Quick Verification
1. Ensure sshd is running: `sudo systemctl status sshd`
2. Ensure port 22 is listening: `sudo ss -tlnp | grep sshd`
3. Ensure firewall allows it: `sudo iptables -L -n | grep 22`

---

**Note**: This issue is common on minimal Arch Linux installations where the firewall blocks all incoming connections.
