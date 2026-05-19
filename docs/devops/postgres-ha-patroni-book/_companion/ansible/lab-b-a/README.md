# LAB-B-A: Watchdog and Lease Pathology

Ansible-based lab demonstrating Patroni watchdog firing when a leader is partitioned from etcd. See **Appendix B — Patroni Internals Deep-Dive** for the full theoretical treatment.

> **Supported substrates:** Proxmox LXC (privileged, with `/dev/watchdog` access) or bare VMs.  
> **Docker is NOT suitable** — containers cannot safely isolate kernel panics caused by the watchdog.

---

## What You Will Learn

- How DCS lease expiry triggers watchdog-based fencing on the old leader.
- The exact timing between partition start, TTL expiry, watchdog fire, and new-leader promotion.
- Why the watchdog fires *before* the new leader promotes (the safety invariant).
- How to verify that no split-brain occurred by examining WAL timelines.

---

## Prerequisites

| Requirement | Details |
|-------------|---------|
| **Substrate** | 3 bare VMs **or** 3 privileged Proxmox LXC containers with kernel module access. |
| **Root access** | Ansible connects as root (or a user with passwordless sudo). |
| **Ansible** | 2.16 or newer. |
| **Network** | VMs/LXCs must reach each other on the IPs defined in `inventory.ini`. |
| **Kernel** | `softdog` module must be available (`modprobe softdog` succeeds). |
| **PostgreSQL** | This playbook installs PostgreSQL 18.x from the PGDG repository. |

### Pre-flight Checks (run on each target node)

```bash
# 1. softdog module loads successfully
sudo modprobe softdog
ls -la /dev/watchdog        # should show a character device

# 2. You have passwordless SSH from the Ansible control node
ssh root@10.0.0.21 echo OK
ssh root@10.0.0.22 echo OK
ssh root@10.0.0.23 echo OK
```

---

## Quick Start

### 1. Customize Inventory

Edit `inventory.ini` and replace the example IPs with your actual VM/LXC addresses:

```ini
[etcd]
etcd-1 ansible_host=YOUR_ETCD_1_IP
etcd-2 ansible_host=YOUR_ETCD_2_IP
etcd-3 ansible_host=YOUR_ETCD_3_IP

[patroni]
patroni-1 ansible_host=YOUR_PATRONI_1_IP
patroni-2 ansible_host=YOUR_PATRONI_2_IP
patroni-3 ansible_host=YOUR_PATRONI_3_IP
```

### 2. Deploy

```bash
make setup
```

This runs the full orchestration:
1. **etcd cluster** (3 nodes)
2. **Patroni + PostgreSQL 18.x** (3 nodes)
3. **Watchdog configuration** (`softdog`, `/dev/watchdog` permissions, sysctl tuning)

### 3. Verify Healthy State

```bash
make verify
```

Expected output — all 3 nodes healthy, 1 Leader + 2 Replicas.

---

## Expected Timeline (Default Parameters)

| Time | Event | How to Observe |
|------|-------|----------------|
| **T+0s** | `make break` applies iptables on the leader | Your terminal |
| **T+10-20s** | Patroni logs *"failed to update leader lock in DCS"* | `journalctl -u patroni -f` on leader |
| **T+30s** | etcd TTL expires; leader key deleted | `etcdctl get /patroni/lab-b-a/leader` from a replica |
| **T+30-32s** | Watchdog fires; old leader reboots | `dmesg \| grep -i watchdog` after reboot |
| **T+30-40s** | Replica acquires lock, promotes | `patronictl list` from a replica |
| **T+60-90s** | Old leader boots, rejoins as replica | `patronictl list` |

> Default timing: `ttl=30`, `loop_wait=10`, `watchdog.safety_margin=5`.  
> See Appendix B for the math: `safety_margin = ttl - loop_wait × 2`.

---

## Running the Break

```bash
make break
```

You will be prompted for confirmation (`YES`). A 30-second countdown runs, then the script drops traffic between the current leader and etcd (ports 2379 and 2380). **The leader will reboot.**

### What happens under the hood

1. The leader can no longer send `LeaseKeepAlive` RPCs to etcd.
2. After two failed renewals (~20s), Patroni stops petting the watchdog.
3. When `safety_margin` seconds pass without a pet, the kernel panics and reboots.
4. Simultaneously, etcd deletes the expired leader key.
5. A replica wins the election race, acquires the lock, and runs `SELECT pg_promote()`.
6. The old leader reboots, discovers it is no longer leader, and rejoins as a replica via `pg_rewind`.

### Verification commands

```bash
# New leader elected?
make verify-failover

# On the old leader (after it comes back)
ssh old-leader "dmesg | grep -i watchdog"
# Expected: "watchdog: watchdog0: watchdog did not stop!"

# Check timelines (no split-brain)
psql -h new-leader -U postgres -c "SELECT timeline_id FROM pg_control_checkpoint();"
psql -h old-leader -U postgres -c "SELECT timeline_id FROM pg_control_checkpoint();"
# Both should match.
```

---

## Recovery

```bash
make recover
```

This removes the iptables rules from all Patroni nodes, waits 30 seconds, and prints the cluster state. The old leader should appear as a Replica streaming from the new leader.

---

## Teardown

```bash
make teardown
```

Prints manual steps to stop services, flush iptables, disable systemd units, and optionally remove data directories.

---

## File Layout

```
lab-b-a/
├── inventory.ini              # Template inventory (edit IPs!)
├── playbook.yml               # Orchestrates etcd → patroni → watchdog
├── Makefile                   # setup, verify, break, verify-failover, recover, teardown
├── break.sh                   # Partition script (lab-only)
├── README.md                  # This file
├── .env.example               # Placeholder for environment variables
└── roles/
    ├── etcd/
    │   ├── handlers/main.yml
    │   └── tasks/main.yml     # Install etcd 3.5.x, systemd service, open ports
    ├── patroni/
    │   ├── handlers/main.yml
    │   ├── tasks/main.yml     # Install Patroni 4.x + PG 18.x, systemd service
    │   └── templates/
    │       ├── patroni.yml.j2 # Config with watchdog.mode: required
    │       └── patroni.service.j2
    └── watchdog/
        └── tasks/main.yml     # modprobe softdog, verify /dev/watchdog, sysctl
```

---

## Troubleshooting

### `/dev/watchdog` does not exist

- Ensure the container/VM is **privileged** (Proxmox LXC: `features: nesting=1` and `unprivileged: 0`).
- Try loading the module manually: `sudo modprobe softdog`.
- Some virtualized environments require a hypervisor watchdog device (e.g., QEMU `-watchdog i6300esb`).

### Patroni fails to start with "Cannot open /dev/watchdog"

- The `postgres` user needs read/write access to `/dev/watchdog`.
- The watchdog role attempts to add `postgres` to the `root` group as a fallback; verify with `ls -l /dev/watchdog`.

### Failover takes longer than 40s

- Check `ttl`, `loop_wait`, and `retry_timeout` in `/etc/patroni/patroni.yml`.
- Verify etcd cluster health: `etcdctl endpoint health --cluster`.
- If `safety_margin` is too small, the watchdog may fire *after* promotion, violating the safety invariant.

### Old leader does not rejoin

- Ensure `wal_log_hints = on` (or data checksums) so `pg_rewind` can repair divergent WAL.
- Check Patroni logs: `journalctl -u patroni -n 200`.
- If `pg_rewind` is disabled or impossible, the old leader will attempt a full `pg_basebackup`.

### Ansible connection failures

- Verify `ansible_user` and `ansible_ssh_private_key_file` in `inventory.ini`.
- Ensure Python 3 is installed on target nodes: `python3 --version`.

---

## Safety Notes

- **Never run `make break` in production.** It intentionally causes an unplanned failover and reboot.
- The watchdog (`mode: required`) will **panic the kernel** of the partitioned leader. There is no graceful shutdown.
- Keep a console (Proxmox VNC, VM serial console, or IPMI) open on the leader so you can observe the reboot.

---

## References

- Appendix B — *Patroni Internals Deep-Dive* (source of truth for timing, state machine, and safety invariants)
- Patroni documentation: https://patroni.readthedocs.io/
- etcd v3.5 documentation: https://etcd.io/docs/v3.5/
