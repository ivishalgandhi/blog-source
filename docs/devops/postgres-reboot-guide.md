# PostgreSQL Node Reboot Guide — Standalone, Patroni & repmgr

A comprehensive guide covering PostgreSQL node reboots across standalone instances, Patroni-managed clusters, and repmgr-managed clusters.

---

## 1. Standalone PostgreSQL — Do You Need to Stop the Service?

**Short answer:** You don't *have to* manually stop PostgreSQL before a reboot, but it's **best practice** to do so.

### What `systemctl reboot` Does Automatically

- Linux sends **SIGTERM** to all services managed by systemd during shutdown.
- The `postgresql.service` unit has an `ExecStop` directive that calls `pg_ctl stop -m fast` (or similar), which:
  - Disconnects clients
  - Rolls back in-flight transactions
  - Writes a clean shutdown checkpoint to WAL
- So systemd **will** handle a graceful Postgres stop for you.

### Why You Might Still Stop It Manually First

- **Controlled connection draining** — you can set `pg_isready` checks, wait for active queries to finish, or use `pg_terminate_backend()` selectively.
- **Checkpoint control** — run `CHECKPOINT;` manually to reduce recovery time if systemd's stop timeout is tight.
- **Verification** — confirm logs show a clean shutdown *before* the OS goes down.

### Recommended Steps (Standalone)

```bash
# 1. (Optional) Drain connections / stop application traffic

# 2. Manual checkpoint
sudo -u postgres psql -c "CHECKPOINT;"

# 3. Stop Postgres explicitly
sudo systemctl stop postgresql

# 4. Verify clean shutdown in logs
sudo journalctl -u postgresql --no-pager -n 20

# 5. Reboot
sudo systemctl reboot
```

---

## 2. Patroni-Managed Clusters (Multi-Node HA)

Patroni wraps PostgreSQL with automatic **leader election**, **failover**, and **replica management** via a DCS (etcd / Consul / ZooKeeper).

### Rebooting a Replica Node

No special action needed — Patroni will mark it as unavailable; the primary continues serving. On boot, Patroni restarts Postgres and re-syncs via streaming replication.

**Best practice:** Pause Patroni first to prevent unnecessary leader elections if you're doing rolling reboots:

```bash
# On any node — pause auto-failover
patronictl -c /etc/patroni/patroni.yml pause

# Reboot the replica
sudo systemctl reboot

# After it's back and healthy
patronictl -c /etc/patroni/patroni.yml resume
```

### Rebooting the Primary / Leader Node

**Always trigger a planned switchover first** — this is the safest approach:

```bash
# Switchover to a healthy replica
patronictl -c /etc/patroni/patroni.yml switchover \
  --master <current_leader> \
  --candidate <preferred_replica> \
  --force

# Wait for new leader to be promoted
patronictl -c /etc/patroni/patroni.yml list

# Now reboot the old leader (now a replica)
sudo systemctl reboot
```

If you just reboot without switchover, Patroni will detect leader loss and **auto-failover** to a sync replica — but this causes a brief outage (~10–30s depending on DCS TTL and `loop_wait` settings).

### Rolling Reboot of Entire Patroni Cluster

```text
1. patronictl pause              → prevents election churn
2. Reboot replicas one by one    → wait for each to rejoin
3. patronictl switchover          → move primary to a healthy replica
4. Reboot the old primary
5. (Optional) switchover back
6. patronictl resume
```

### Key Patroni Settings That Affect Reboot Behavior

| Parameter | Impact |
|---|---|
| `ttl` | Leader lease timeout — shorter = faster failover but more sensitive |
| `loop_wait` | How often Patroni checks DCS — affects detection speed |
| `retry_timeout` | How long Patroni retries DCS before giving up |
| `maximum_lag_on_failover` | Replicas lagging more than this won't be promoted |
| `synchronous_mode` | If enabled, only the sync replica can be promoted — ensures zero data loss |

---

## 3. repmgr-Managed Clusters (Multi-Node HA)

repmgr provides **replication management** and **automatic failover** via the `repmgrd` daemon.

### Rebooting a Standby Node

Straightforward — repmgr will detect the node is down. On boot, PostgreSQL restarts and reconnects to the primary for streaming replication.

Run `repmgr standby register --force` if the node was unregistered.

### Rebooting the Primary Node

**Planned switchover (recommended):**

```bash
# On the standby you want to promote — dry-run first
repmgr standby switchover --siblings-follow --dry-run

# If dry-run passes, execute for real
repmgr standby switchover --siblings-follow

# Now reboot the old primary (now a standby)
sudo systemctl reboot
```

**If you just reboot** and `repmgrd` is running with `failover=automatic`:

- `repmgrd` on standby nodes detects primary failure.
- After `reconnect_attempts × reconnect_interval` seconds, the most eligible standby promotes itself.
- Other standbys follow the new primary.
- **Risk:** brief downtime + potential data loss if async replication was lagging.

### Rolling Reboot of Entire repmgr Cluster

```text
1. Reboot standbys one at a time → verify replication catches up after each
2. repmgr standby switchover     → move primary to a healthy standby
3. Reboot old primary
4. (Optional) switchover back
5. Verify: repmgr cluster show
```

### Key repmgr Settings That Affect Reboot Behavior

| Parameter | Impact |
|---|---|
| `reconnect_attempts` | How many times repmgrd retries primary before failover |
| `reconnect_interval` | Seconds between retries |
| `failover` | `automatic` or `manual` — controls if repmgrd auto-promotes |
| `promote_command` | Command repmgrd runs to promote a standby |
| `follow_command` | Command repmgrd runs to make standbys follow new primary |
| `priority` | Which standby gets promoted first (higher = preferred) |

---

## 4. Comparison Summary

| Scenario | Patroni | repmgr |
|---|---|---|
| **Replica reboot** | Transparent, auto-rejoin | Transparent, auto-rejoin |
| **Primary reboot (planned)** | `patronictl switchover` → reboot | `repmgr standby switchover` → reboot |
| **Primary reboot (unplanned)** | Auto-failover via DCS lease expiry | Auto-failover via repmgrd (if `failover=automatic`) |
| **Data loss risk** | Zero with `synchronous_mode` | Possible if async and standby is lagging |
| **Typical failover time** | 10–30s | 30–60s (depends on reconnect settings) |
| **Cluster pause** | `patronictl pause` (native) | Stop `repmgrd` on all standbys |

---

## 5. General Best Practices

- **Always switchover before rebooting the primary** — never rely on auto-failover for planned maintenance.
- **Check replication lag** before rebooting:
  ```sql
  SELECT pg_last_wal_receive_lsn(), pg_last_wal_replay_lsn();
  ```
- **Verify cluster health** after each node comes back.
- **Coordinate with application layer** — drain connections or use a connection pooler (PgBouncer) that can reroute.
- **Test your failover regularly** in non-production environments.
- **Monitor WAL replay** on standbys before rebooting the next node in a rolling reboot.
