# PostgreSQL Node Reboot Guide — Standalone, Patroni & repmgr

A comprehensive, research-backed guide covering PostgreSQL node reboots across standalone instances, Patroni-managed clusters, and repmgr-managed clusters. Includes shutdown mode internals, systemd behavior, split-brain prevention, and step-by-step runbooks.

---

## 1. Standalone PostgreSQL — Do You Need to Stop the Service?

**Short answer:** You don't *have to* manually stop PostgreSQL before a `systemctl reboot`, but it's **best practice** to do so for full control and verification.

### 1.1 How systemd Handles PostgreSQL on Reboot

When you run `systemctl reboot` (or `reboot` / `shutdown -r`), systemd orchestrates a clean shutdown of all services:

1. systemd sends **SIGTERM** to all running service units.
2. The `postgresql.service` unit's `ExecStop` directive invokes `pg_ctl stop -m fast` (the default since PostgreSQL 9.5).
3. PostgreSQL performs a **fast shutdown**:
   - Terminates all client connections immediately
   - Rolls back in-flight transactions
   - Performs a checkpoint (flushes dirty buffers to disk)
   - Writes a clean shutdown record to WAL
4. systemd waits up to `TimeoutStopSec` (default: 90 seconds) for the service to exit.
5. If the timeout expires, systemd sends **SIGKILL** — equivalent to an immediate/crash shutdown.

> **Key takeaway:** systemd *will* handle a graceful stop automatically. But if your database is large or has heavy write activity, the checkpoint during shutdown may exceed `TimeoutStopSec`, causing an unclean kill.

### 1.2 PostgreSQL Shutdown Modes Explained

PostgreSQL supports three shutdown modes via `pg_ctl stop -m <mode>`:

| Mode | Behavior | When to Use |
|---|---|---|
| **smart** | Waits for all clients to disconnect voluntarily. No new connections are accepted. Does not terminate existing sessions. | Rarely used in practice — can hang indefinitely if a client doesn't disconnect. |
| **fast** (default since PG 9.5) | Terminates all active connections, rolls back in-progress transactions, performs a checkpoint, exits cleanly. | **Recommended for most reboots.** This is what systemd typically invokes. |
| **immediate** | Aborts all server processes without a clean shutdown. No checkpoint is written. Equivalent to a crash — recovery is required on next startup. | Emergency only. Equivalent to pulling the power plug. Use only when `fast` mode hangs. |

> **Source:** [PostgreSQL pg_ctl documentation](https://www.postgresql.org/docs/current/app-pg-ctl.html), [EDB blog on shutdown modes](https://www.enterprisedb.com/blog/postgresql-shutdown)

### 1.3 Why You Might Still Stop It Manually

- **Controlled connection draining** — notify applications, wait for active queries to finish, or use `pg_terminate_backend()` selectively before killing all connections at once.
- **Pre-shutdown checkpoint** — run `CHECKPOINT;` manually so the `fast` shutdown checkpoint is near-instant instead of flushing a large backlog of dirty buffers.
- **TimeoutStopSec safety** — if you have a very large `shared_buffers` (e.g., 64 GB+), the shutdown checkpoint may exceed 90 seconds. Manually stopping lets you observe and handle this.
- **Log verification** — confirm logs show `database system is shut down` *before* the OS goes down, giving you certainty there will be no crash recovery on reboot.
- **WAL archiving backlog** — if `archive_command` is configured, PostgreSQL won't complete shutdown until all pending WAL files are archived. A large backlog can delay shutdown significantly.

### 1.4 Recommended Steps (Standalone)

```bash
# 1. (Optional) Stop application traffic / drain connections
# Disable the node in your load balancer, or:
sudo -u postgres psql -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE pid <> pg_backend_pid();"

# 2. Check for WAL archiving backlog (if archive_mode is on)
sudo -u postgres psql -c "SELECT count(*) FROM pg_ls_archive_statusdir() WHERE name LIKE '%.ready';"

# 3. Run a manual checkpoint to minimize shutdown time
sudo -u postgres psql -c "CHECKPOINT;"

# 4. Stop PostgreSQL explicitly
sudo systemctl stop postgresql

# 5. Verify clean shutdown in logs
sudo journalctl -u postgresql --no-pager -n 30 | grep -i "shut down"
# You should see: "database system is shut down"

# 6. Reboot the node
sudo systemctl reboot
```

### 1.5 Tuning `TimeoutStopSec` for Large Databases

If your database has very large `shared_buffers`, consider increasing the stop timeout:

```ini
# /etc/systemd/system/postgresql.service.d/override.conf
[Service]
TimeoutStopSec=300
```

Then reload: `sudo systemctl daemon-reload`

This gives PostgreSQL up to 5 minutes to complete its shutdown checkpoint instead of the default 90 seconds.

---

## 2. Patroni-Managed Clusters (Multi-Node HA)

Patroni wraps PostgreSQL with automatic **leader election**, **failover**, and **replica management** via a Distributed Configuration Store (DCS) such as etcd, Consul, or ZooKeeper.

### 2.1 Understanding Patroni's Architecture

Key concepts relevant to reboots:

- **Leader lock** — the primary holds a lease (TTL) in the DCS. If it fails to renew, replicas initiate a leader race.
- **`loop_wait`** — how often (in seconds) each Patroni node checks the DCS and its PostgreSQL state.
- **`ttl`** — the leader lease duration. If not renewed within this window, the leader is considered dead.
- **Failover timeline** — when the primary disappears, the new leader is typically elected within `ttl` seconds (default 30s), so failover takes roughly 10–30 seconds.

### 2.2 Rebooting a Replica Node

Rebooting a replica is straightforward and has **no impact on write availability**:

1. The primary continues serving reads and writes.
2. Patroni marks the replica as unavailable in the DCS.
3. On boot, Patroni restarts PostgreSQL and reconnects to the primary via streaming replication.
4. The replica catches up from the last received WAL position.

**Best practice for single replica reboot:**

```bash
# Verify cluster state first
patronictl -c /etc/patroni/patroni.yml list

# Reboot the replica
sudo systemctl reboot

# After reboot, verify it rejoined
patronictl -c /etc/patroni/patroni.yml list
```

**If doing rolling reboots of multiple replicas**, use pause mode to prevent unnecessary leader elections:

```bash
# Pause cluster management (prevents automatic failover)
patronictl -c /etc/patroni/patroni.yml pause
# Output: Success: cluster management is paused

# Reboot replica nodes one at a time, verifying each rejoins
sudo systemctl reboot   # on replica-1
# Wait for replica-1 to return and catch up...
patronictl -c /etc/patroni/patroni.yml list

# Resume cluster management when done
patronictl -c /etc/patroni/patroni.yml resume
```

### 2.3 Patroni Pause Mode — What It Does and Doesn't Do

Patroni's pause mode (maintenance mode) is critical for planned maintenance. From the [official Patroni docs](https://patroni.readthedocs.io/en/latest/pause.html):

**What happens in pause mode:**
- DCS member keys are still updated (health info is still visible)
- The leader lock is still renewed by the primary
- Manual switchover/failover and reinitialize are still allowed
- If a node with the leader lock is manually demoted, Patroni releases the lock (does not re-promote)

**What does NOT happen:**
- Patroni will **not** start PostgreSQL if it's stopped
- Patroni will **not** stop PostgreSQL when Patroni itself is stopped
- Patroni will **not** automatically promote a replica if the primary goes down
- Patroni will **not** trigger scheduled actions
- Parallel primaries are warned about but not automatically resolved

> **Warning:** Pause mode means no automatic failover. If the primary crashes while paused, you must manually intervene.

### 2.4 Rebooting the Primary / Leader Node

**Never just reboot the primary.** Always perform a planned switchover first.

#### Option A: Immediate Switchover (Recommended)

```bash
# 1. Verify cluster health and replication lag
patronictl -c /etc/patroni/patroni.yml list

# 2. Perform switchover to a specific candidate
patronictl -c /etc/patroni/patroni.yml switchover \
  --master <current_leader> \
  --candidate <preferred_replica> \
  --force

# 3. Verify the new leader is promoted
patronictl -c /etc/patroni/patroni.yml list
# Wait until the old leader shows as "Replica" and the new leader shows as "Leader"

# 4. Now reboot the old leader (it's now a replica)
sudo systemctl reboot

# 5. After reboot, verify it rejoined as a replica
patronictl -c /etc/patroni/patroni.yml list
```

#### Option B: Scheduled Switchover

You can schedule the switchover for a specific time (useful for maintenance windows):

```bash
patronictl -c /etc/patroni/patroni.yml switchover \
  --master <current_leader> \
  --candidate <preferred_replica> \
  --scheduled "2025-03-15T02:00:00+00:00"
```

To cancel a scheduled switchover:

```bash
patronictl -c /etc/patroni/patroni.yml flush <cluster_name> switchover
```

#### Option C: Using the REST API Directly

Patroni also exposes switchover via its REST API (port 8008 by default):

```bash
# Switchover to any healthy standby
curl -s http://localhost:8008/switchover -XPOST \
  -d '{"leader":"postgresql1"}'

# Switchover to a specific node
curl -s http://localhost:8008/switchover -XPOST \
  -d '{"leader":"postgresql1","candidate":"postgresql2"}'
```

#### What Happens If You Just Reboot the Primary (Unplanned)

1. Patroni on the primary stops renewing the leader lock in the DCS.
2. After `ttl` seconds (default: 30), the lock expires.
3. Remaining replicas detect the expired lock and initiate a **leader race**.
4. The replica with the least replication lag (subject to `maximum_lag_on_failover`) wins the election and is promoted.
5. Other replicas reconfigure to follow the new primary.
6. **Total outage window:** typically 10–30 seconds, depending on `ttl` and `loop_wait` settings.
7. **Data loss risk:** With `synchronous_mode: true`, zero data loss. With async replication, transactions committed on the old primary but not yet replicated may be lost.

### 2.5 Rolling Reboot of Entire Patroni Cluster

Step-by-step runbook for rebooting every node with minimal downtime:

```bash
# Step 1: Verify cluster health
patronictl -c /etc/patroni/patroni.yml list
# Ensure all nodes are running, replication lag is 0

# Step 2: Pause cluster management
patronictl -c /etc/patroni/patroni.yml pause

# Step 3: Reboot replicas one at a time
# For each replica:
#   a. Reboot the replica node
#   b. Wait for it to come back online
#   c. Verify it reconnected and caught up:
patronictl -c /etc/patroni/patroni.yml list

# Step 4: Resume briefly for switchover
patronictl -c /etc/patroni/patroni.yml resume

# Step 5: Switchover primary to a healthy replica
patronictl -c /etc/patroni/patroni.yml switchover \
  --master <current_leader> \
  --candidate <preferred_replica> \
  --force

# Step 6: Pause again
patronictl -c /etc/patroni/patroni.yml pause

# Step 7: Reboot the old primary (now a replica)
sudo systemctl reboot

# Step 8: Verify it rejoined
patronictl -c /etc/patroni/patroni.yml list

# Step 9: Resume cluster management
patronictl -c /etc/patroni/patroni.yml resume

# Step 10: (Optional) switchover back to original primary
patronictl -c /etc/patroni/patroni.yml switchover \
  --master <new_leader> \
  --candidate <original_leader> \
  --force
```

### 2.6 Split-Brain Prevention: Watchdog and DCS Failsafe Mode

Patroni has two advanced mechanisms to prevent split-brain scenarios:

#### Watchdog (Hardware/Software)

From the [Patroni watchdog docs](https://patroni.readthedocs.io/en/latest/watchdog.html):

- A watchdog device will **forcefully reset the entire system** if Patroni fails to send a keepalive heartbeat within the configured timeframe.
- This prevents scenarios where Patroni crashes or hangs but PostgreSQL keeps accepting writes as a stale primary.
- By default, the watchdog is set to expire 5 seconds before the TTL expires. With defaults (`loop_wait=10`, `ttl=30`), the HA loop gets at least 15 seconds to complete.
- Watchdog is activated only when a node is promoted to primary and disabled on demotion.
- **Watchdog is disabled in pause mode** — another reason to be careful during maintenance.

```yaml
# patroni.yml — watchdog configuration
watchdog:
  mode: required  # required | automatic | off
  device: /dev/watchdog
  safety_margin: 5
```

#### DCS Failsafe Mode

From the [Patroni DCS failsafe docs](https://patroni.readthedocs.io/en/latest/dcs_failsafe_mode.html):

- When the DCS becomes unavailable, Patroni normally demotes the primary (assumes network partition — worst case).
- With `failsafe_mode` enabled, the primary can **continue running** if it can reach all known cluster members via the Patroni REST API.
- This prevents unnecessary demotions when the DCS is simply down but the cluster network is healthy.
- If even one replica is unreachable, the primary is still demoted (it might be a real network partition).

```yaml
# Enable via dynamic configuration
patronictl -c /etc/patroni/patroni.yml edit-config
# Set: failsafe_mode: true
```

### 2.7 Key Patroni Settings That Affect Reboot Behavior

| Parameter | Default | Impact |
|---|---|---|
| `ttl` | 30 | Leader lease timeout in seconds. After this expires without renewal, replicas start a leader race. |
| `loop_wait` | 10 | Seconds between Patroni's HA loop iterations. Affects how quickly state changes are detected. |
| `retry_timeout` | 10 | Seconds Patroni retries DCS operations before giving up. |
| `maximum_lag_on_failover` | 1048576 (1 MB) | Maximum replication lag (in bytes) for a replica to be eligible for promotion. |
| `synchronous_mode` | false | If true, only the synchronous standby can be promoted — guarantees zero data loss. |
| `failsafe_mode` | false | If true, primary stays up during DCS outages as long as all replicas are reachable. |
| `watchdog.mode` | automatic | Controls watchdog activation: `required` (won't promote without watchdog), `automatic` (use if available), `off`. |
| `primary_start_timeout` | 300 | Seconds to wait for the primary to start before triggering failover. |

### 2.8 Patroni `restart` vs OS Reboot

Patroni provides its own restart mechanism that is **different from an OS reboot**:

```bash
# Restart just PostgreSQL on a specific node (Patroni stays running)
patronictl -c /etc/patroni/patroni.yml restart <cluster_name> <node_name>

# Restart with conditions
patronictl -c /etc/patroni/patroni.yml restart <cluster_name> <node_name> \
  --pending --force
```

This is useful when you need to apply PostgreSQL configuration changes (e.g., `shared_buffers`) that require a restart but don't need a full OS reboot. Patroni handles the restart gracefully — for the primary, it will demote first, restart, and then re-evaluate leadership.

---

## 3. repmgr-Managed Clusters (Multi-Node HA)

repmgr provides **replication management** and **automatic failover** via the `repmgrd` daemon. Unlike Patroni, repmgr does not use a DCS — it relies on direct node-to-node communication and an optional witness node.

### 3.1 Understanding repmgr's Architecture

- **repmgr** — CLI tool for setting up and managing replication (register, clone, promote, follow, switchover).
- **repmgrd** — a daemon that continuously monitors the cluster and triggers automatic failover when configured.
- **Witness node** — an optional lightweight node that helps standbys determine whether the primary is truly down or if there's a network partition.
- **No DCS dependency** — failover decisions are made by `repmgrd` based on direct connectivity checks, which means there's no centralized leader lock.

### 3.2 Rebooting a Standby Node

Rebooting a standby is straightforward and has **no impact on write availability**:

1. `repmgrd` on other nodes detects the standby is unavailable.
2. On boot, PostgreSQL starts and automatically reconnects to the primary via streaming replication.
3. The standby catches up from the last received WAL position.

```bash
# Verify cluster state before reboot
repmgr cluster show

# Reboot the standby
sudo systemctl reboot

# After reboot, verify it reconnected
repmgr cluster show

# If the node was unregistered (rare), re-register it
repmgr standby register --force
```

### 3.3 Rebooting the Primary Node

#### Option A: Planned Switchover (Recommended)

The `repmgr standby switchover` command must be run **on the standby you want to promote**, not on the primary. It requires passwordless SSH between the promotion candidate and the current primary.

```bash
# 1. Pre-flight checks on the standby you want to promote
repmgr standby switchover --siblings-follow --dry-run
# This verifies:
#   - SSH connectivity to the primary
#   - Replication lag is within replication_lag_critical threshold
#   - pg_rewind is available (if needed)
#   - WAL archiving is not backlogged (warns if > archive_ready_warning files)

# 2. If dry-run passes, execute the switchover
repmgr standby switchover --siblings-follow
# This:
#   - Pauses repmgrd on all nodes (prevents competing failover)
#   - Shuts down PostgreSQL on the current primary
#   - Promotes the standby to primary
#   - Reconfigures the old primary as a standby (using pg_rewind if needed)
#   - With --siblings-follow: tells other standbys + witness to follow the new primary

# 3. Verify the switchover completed
repmgr cluster show

# 4. Now reboot the old primary (it's now a standby)
sudo systemctl reboot

# 5. After reboot, verify it rejoined as standby
repmgr cluster show
```

#### Key `repmgr.conf` Settings for Switchover

```ini
# Maximum replication lag (seconds) before switchover is aborted
replication_lag_critical=10

# Maximum seconds to wait for the old primary to shut down
shutdown_check_timeout=60

# Number of WAL files in archive backlog before warning
archive_ready_warning=16
```

#### Option B: What Happens If You Just Reboot the Primary (Unplanned)

If `repmgrd` is running with `failover=automatic`:

1. `repmgrd` on each standby detects the primary is unreachable.
2. Each standby retries connection `reconnect_attempts` times, waiting `reconnect_interval` seconds between retries.
3. **Total detection time** = `reconnect_attempts × reconnect_interval` (e.g., 6 × 10 = 60 seconds with defaults).
4. After exhausting retries, the eligible standby with the highest `priority` executes `promote_command`.
5. Other standbys execute `follow_command` to reconfigure and follow the new primary.
6. The witness node (if present) helps break ties when standbys disagree about primary availability (`primary_visibility_consensus`).

**Risks of unplanned failover:**
- **Downtime** = detection time + promotion time (typically 30–90 seconds total).
- **Data loss** if replication is asynchronous and the standby is lagging.
- **Old primary returns as a second primary (split-brain)** — mitigated by `repmgr node rejoin --force-rewind` on the old primary after it comes back.

### 3.4 Configuring `repmgrd` for Automatic Failover

The following settings in `repmgr.conf` are **required** for automatic failover:

```ini
# Enable automatic failover
failover=automatic

# Command to promote the standby (executed on the winning standby)
promote_command='/usr/bin/repmgr standby promote -f /etc/repmgr.conf --log-to-file'

# Command to follow the new primary (executed on remaining standbys)
# %n is replaced with the new primary's node ID
follow_command='/usr/bin/repmgr standby follow -f /etc/repmgr.conf --log-to-file --upstream-node-id=%n'
```

> **Important:** Do NOT add `--siblings-follow` to `promote_command` when using repmgrd — repmgrd handles sibling coordination separately via `follow_command`.

### 3.5 Preventing Split-Brain with repmgr

repmgr lacks a DCS-based leader lock, so split-brain prevention requires additional configuration:

#### Witness Node

A witness node is a lightweight PostgreSQL instance that doesn't participate in replication but helps standbys make better failover decisions:

```bash
# Register a witness on a separate server
repmgr witness register -h <primary_host>
```

#### `primary_visibility_consensus`

When set to `true`, a standby will only proceed with failover if **no other standbys (or the witness)** have recently seen the primary:

```ini
primary_visibility_consensus=true
```

This prevents the scenario where only one standby lost connectivity to the primary (asymmetric network partition) and unilaterally promotes itself.

#### `failover_validation_command`

An external script that is called before failover to implement custom validation logic:

```ini
# %n=node_id, %a=node_name, %v=visible_nodes, %u=shared_upstream, %t=total_nodes
failover_validation_command='/usr/local/bin/validate-failover.sh %v %t'
```

The script can check external indicators (e.g., can the node reach the application network?) and return non-zero to abort failover.

#### Fencing with PgBouncer

repmgr can integrate with PgBouncer to **fence the old primary** during failover, preventing stale writes:

```ini
# Redirect PgBouncer to the new primary during failover
service_start_command='pg_ctl ... start'
service_stop_command='pg_ctl ... stop'
service_restart_command='pg_ctl ... restart'
service_reload_command='pg_ctl ... reload'
```

### 3.6 Handling the Old Primary After Unplanned Reboot

When the old primary comes back online after an unplanned failover, it thinks it's still the primary. You must rejoin it as a standby:

```bash
# Option A: Use pg_rewind (fast, minimal data transfer)
repmgr node rejoin -d 'host=<new_primary> dbname=repmgr' --force-rewind

# Option B: Re-clone from scratch (if pg_rewind fails or isn't available)
repmgr standby clone -h <new_primary> -U repmgr -d repmgr --force
repmgr standby register --force
```

> `pg_rewind` requires `wal_log_hints=on` or data checksums to be enabled on the cluster.

### 3.7 Rolling Reboot of Entire repmgr Cluster

```bash
# Step 1: Verify cluster health
repmgr cluster show
# Ensure all nodes are running, replication lag is minimal

# Step 2: Check replication lag on all standbys
sudo -u postgres psql -c "SELECT client_addr, state, sent_lsn, write_lsn, flush_lsn, replay_lsn FROM pg_stat_replication;"

# Step 3: Reboot standbys one at a time
# For each standby:
#   a. (Optional) Temporarily stop repmgrd to prevent false failover triggers
#   b. Reboot the standby node
#   c. Wait for it to come back and catch up
#   d. Verify: repmgr cluster show

# Step 4: Switchover primary to a healthy standby
# Run on the standby you want to promote:
repmgr standby switchover --siblings-follow --dry-run
repmgr standby switchover --siblings-follow

# Step 5: Reboot the old primary (now a standby)
sudo systemctl reboot

# Step 6: Verify full cluster health
repmgr cluster show

# Step 7: (Optional) Switchover back to the original primary
# Run on the original primary node:
repmgr standby switchover --siblings-follow
```

### 3.8 Key repmgr Settings That Affect Reboot Behavior

| Parameter | Default | Impact |
|---|---|---|
| `reconnect_attempts` | 6 | Number of times repmgrd retries connecting to the primary before initiating failover. |
| `reconnect_interval` | 10 | Seconds between reconnection attempts. Total detection time = attempts × interval. |
| `failover` | manual | Set to `automatic` for repmgrd to auto-promote. Without this, manual intervention is required. |
| `promote_command` | — | Full command path for `repmgr standby promote`. Must be set for automatic failover. |
| `follow_command` | — | Full command path for `repmgr standby follow`. Must include `--upstream-node-id=%n`. |
| `priority` | 100 | Higher value = higher promotion priority. Set to `0` to permanently exclude a node from promotion. |
| `primary_visibility_consensus` | false | If true, requires all standbys/witness to confirm primary is down before failover. |
| `replication_lag_critical` | — | Maximum lag (seconds) before `repmgr standby switchover` aborts. |
| `shutdown_check_timeout` | 60 | Seconds to wait for primary to shut down during switchover. |
| `failover_validation_command` | — | External script for custom failover validation. Must be identical on all nodes. |

---

## 4. Comparison Summary

| Scenario | Patroni | repmgr |
|---|---|---|
| **Architecture** | DCS-based (etcd/Consul/ZK) leader election | Daemon-based (repmgrd) with optional witness node |
| **Replica reboot** | Transparent, auto-rejoin | Transparent, auto-rejoin |
| **Primary reboot (planned)** | `patronictl switchover` → reboot | `repmgr standby switchover --siblings-follow` → reboot |
| **Primary reboot (unplanned)** | Auto-failover via DCS lease expiry (~10–30s) | Auto-failover via repmgrd retry exhaustion (~30–90s) |
| **Data loss risk** | Zero with `synchronous_mode: true` | Possible if async and standby is lagging |
| **Split-brain prevention** | DCS leader lock + watchdog + failsafe mode | Witness node + `primary_visibility_consensus` + PgBouncer fencing |
| **Cluster pause** | `patronictl pause` (native, built-in) | Stop `repmgrd` on all nodes (no built-in pause) |
| **Old primary rejoin** | Automatic (Patroni uses pg_rewind internally) | Manual: `repmgr node rejoin --force-rewind` |
| **Restart without OS reboot** | `patronictl restart` (Postgres only) | `systemctl restart postgresql` |
| **Scheduled switchover** | Native: `--scheduled` flag or REST API | Not supported natively |

---

## 5. General Best Practices

### Before Any Reboot

- **Always switchover before rebooting the primary** — never rely on auto-failover for planned maintenance.
- **Check replication lag** before rebooting any node:
  ```sql
  -- On the primary: check all standbys
  SELECT client_addr, state, sent_lsn, write_lsn, flush_lsn, replay_lsn,
         pg_wal_lsn_diff(sent_lsn, replay_lsn) AS replay_lag_bytes
  FROM pg_stat_replication;

  -- On a standby: check local replay
  SELECT pg_last_wal_receive_lsn(), pg_last_wal_replay_lsn(),
         pg_last_xact_replay_timestamp();
  ```
- **Check WAL archiving backlog** if `archive_mode` is on:
  ```sql
  SELECT count(*) FROM pg_ls_archive_statusdir() WHERE name LIKE '%.ready';
  ```

### During Reboot

- **Coordinate with the application layer** — drain connections via your load balancer or connection pooler (PgBouncer / Pgpool-II) before shutting down.
- **Reboot one node at a time** — never reboot multiple replicas simultaneously, or you risk losing quorum / promotion candidates.
- **Verify each node rejoins** before proceeding to the next.

### After Reboot

- **Verify cluster health:**
  ```bash
  # Patroni
  patronictl -c /etc/patroni/patroni.yml list

  # repmgr
  repmgr cluster show
  repmgr cluster crosscheck
  ```
- **Check replication is streaming** (not stuck in archive recovery):
  ```sql
  SELECT status, conninfo FROM pg_stat_wal_receiver;  -- on standby
  ```
- **Monitor WAL replay** on standbys before rebooting the next node.

### Infrastructure-Level Recommendations

- **Use a connection pooler** (PgBouncer) in front of PostgreSQL — it can transparently reroute connections during failover and buffer connection storms on restart.
- **Test your failover regularly** in non-production environments. Document expected failover times.
- **Enable `wal_log_hints` or data checksums** — required for `pg_rewind`, which both Patroni and repmgr use to efficiently resync old primaries.
- **Set `synchronous_commit` and `synchronous_standby_names`** if zero data loss is required. Understand the write performance trade-off.
- **Monitor with alerting** — track replication lag, WAL archiving backlog, and DCS health (for Patroni) continuously.

---

## 6. Quick-Reference Decision Tree

```
Is it a PLANNED reboot?
├── YES
│   ├── Is this node the PRIMARY?
│   │   ├── YES → Switchover first, then reboot (now a replica)
│   │   └── NO  → Just reboot (primary keeps serving)
│   └── Are you rebooting MULTIPLE nodes?
│       ├── YES → Pause cluster mgmt, reboot replicas one-by-one,
│       │         switchover primary, reboot old primary, resume
│       └── NO  → Single reboot as above
└── NO (UNPLANNED reboot / crash)
    ├── Was it a REPLICA?
    │   └── No action needed — it will auto-rejoin on boot
    └── Was it the PRIMARY?
        ├── Patroni → Auto-failover via DCS (~10-30s)
        ├── repmgr  → Auto-failover via repmgrd (~30-90s)
        └── After old primary boots:
            ├── Patroni → Auto-rejoins as replica (pg_rewind)
            └── repmgr  → Run: repmgr node rejoin --force-rewind
```

---

## References

- [PostgreSQL pg_ctl documentation](https://www.postgresql.org/docs/current/app-pg-ctl.html) — shutdown modes (smart, fast, immediate)
- [EDB — PostgreSQL Shutdown](https://www.enterprisedb.com/blog/postgresql-shutdown) — default mode change in PG 9.5
- [Patroni Pause/Resume Mode](https://patroni.readthedocs.io/en/latest/pause.html) — maintenance mode behavior
- [Patroni REST API](https://patroni.readthedocs.io/en/latest/rest_api.html) — switchover/failover/restart endpoints
- [Patroni Watchdog Support](https://patroni.readthedocs.io/en/latest/watchdog.html) — split-brain prevention via hardware/software watchdog
- [Patroni DCS Failsafe Mode](https://patroni.readthedocs.io/en/latest/dcs_failsafe_mode.html) — preventing unnecessary demotions during DCS outages
- [DBI Services — Patroni Operations](https://www.dbi-services.com/blog/patroni-operations-switchover-and-failover/) — switchover, failover, and maintenance examples
- [repmgr standby switchover](https://www.repmgr.org/docs/current/repmgr-standby-switchover.html) — switchover command reference
- [repmgrd Configuration](https://www.repmgr.org/docs/current/repmgrd-basic-configuration.html) — automatic failover configuration
- [EDB — Automating Failover with repmgr](https://www.enterprisedb.com/blog/how-automate-postgresql-12-replication-and-failover-repmgr-part-2) — end-to-end repmgr setup
