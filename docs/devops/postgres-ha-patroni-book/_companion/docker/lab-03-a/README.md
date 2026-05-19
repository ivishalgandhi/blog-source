# LAB-03-A: 3-Node Patroni + etcd Cluster

Deploy a 3-node Patroni cluster with a 3-node etcd DCS, kill the leader, observe automatic failover, and recover the old leader as a replica.

> **Artifact ID**: LAB-03-A  
> **Book Reference**: Chapter 03 — Core Deployment

## Prerequisites

- Docker Engine ≥ 24.x with Docker Compose v2
- 8 GB RAM / 4 CPU cores (minimum: 6 GB RAM for Docker Desktop)
- ~2 GB free disk space for images and volumes
- No prior Patroni or PostgreSQL setup required

> **Note**: This lab is fully self-contained. It creates its own isolated Docker bridge network (`lab-03-a-net`, subnet `172.20.0.0/24`) and does not bind to host ports.

## Quickstart

Run the lab lifecycle in order:

```bash
# 1. Deploy the cluster (under 5 minutes)
make setup

# 2. Kill the leader with SIGKILL
make break

# 3. Verify automatic failover
make verify

# 4. Recover the old leader — it rejoins as a replica
make recover

# 5. Clean up everything
make teardown
```

## Expected Output

### `make setup`

Should complete in under 5 minutes and print a cluster status table with **1 Leader** and **2 Replicas**:

```text
+ Cluster: lab-03-a (#####) -------+----+-----------+
| Member    | Host         | Role    | State   | TL | Lag in MB |
+-----------+-------------+---------+---------+----+-----------+
| patroni-1 | 172.20.0.11 | Leader  | running |  1 |           |
| patroni-2 | 172.20.0.12 | Replica | running |  1 |         0 |
| patroni-3 | 172.20.0.13 | Replica | running |  1 |         0 |
+-----------+-------------+---------+---------+----+-----------+
```

If setup exceeds 5 minutes or any node stays unhealthy, check the logs with:

```bash
docker compose logs --tail=50 patroni-1
docker compose logs --tail=50 etcd-1
```

### `make break`

Identifies the current leader (usually `patroni-1` on first run), kills it with `SIGKILL`, and waits 45 seconds for the failover to complete.

### `make verify`

Confirms three conditions:

1. `patroni-1` is **no longer** the leader.
2. A **new leader** exists (either `patroni-2` or `patroni-3`).
3. At least **2 members** are in `running` state.

Example successful output:

```text
OK: New leader is patroni-2
OK: 2 members are running
VERIFY completed (exit 0)
```

### `make recover`

Restarts `patroni-1` and polls the cluster state until it rejoins as a **Replica**:

```text
+ Cluster: lab-03-a (#####) -------+----+-----------+
| Member    | Host         | Role    | State   | TL | Lag in MB |
+-----------+-------------+---------+---------+----+-----------+
| patroni-1 | 172.20.0.11 | Replica | running |  2 |         0 |
| patroni-2 | 172.20.0.12 | Leader  | running |  2 |           |
| patroni-3 | 172.20.0.13 | Replica | running |  2 |         0 |
+-----------+-------------+---------+---------+----+-----------+
```

> **Why this works**: The `use_pg_rewind: true` setting in `patroni.yml` allows the old leader to resynchronize with the new leader without a full base backup.

### `make teardown`

Stops and removes all containers, the isolated bridge network, and all named volumes. The host is returned to its pre-setup state.

## Network Topology

| Node      | IP Address  | Role                          |
|-----------|-------------|-------------------------------|
| etcd-1    | 172.20.0.2  | etcd member                   |
| etcd-2    | 172.20.0.3  | etcd member                   |
| etcd-3    | 172.20.0.4  | etcd member                   |
| patroni-1 | 172.20.0.11 | PostgreSQL 16 + Patroni       |
| patroni-2 | 172.20.0.12 | PostgreSQL 16 + Patroni       |
| patroni-3 | 172.20.0.13 | PostgreSQL 16 + Patroni       |

## Configuration Highlights

- **DCS**: etcd 3.5.13 cluster with static member discovery
- **TTL / loop_wait / retry_timeout**: 30s / 10s / 10s
- **Replication**: Async (`synchronous_mode: false`)
- **pg_rewind**: Enabled for fast old-leader rejoin
- **Replication slots**: Managed automatically by Patroni
- **Watchdog**: Disabled (`mode: off`) — Docker containers lack `/dev/watchdog`

## Troubleshooting

| Symptom                              | Cause                                    | Fix                                                                         |
|--------------------------------------|------------------------------------------|-----------------------------------------------------------------------------|
| `make setup` hangs > 5 min           | Insufficient RAM or slow disk            | Ensure Docker has ≥ 6 GB RAM allocated. Close other containers/apps.        |
| etcd nodes fail to form a cluster    | Leftover state from a previous run       | Run `make teardown` to clear volumes, then `make setup` again.            |
| Patroni healthcheck fails repeatedly | PostgreSQL initdb took too long          | Increase Docker Desktop resources or check `docker compose logs patroni-1`. |
| Failover did not occur               | Leader was not actually killed in time   | Check container state: `docker ps -a`. Rerun `make break` → `make verify`. |
| Recovery fails / old leader stuck    | pg_rewind or basebackup still in progress | Wait longer; `make recover` polls for 3 minutes. Check logs for progress.     |
| `docker compose` not found          | Docker Compose v1 installed              | Install Docker Compose v2 plugin (`docker compose version` should work).    |

## Files

```text
lab-03-a/
├── docker-compose.yml   # 3 Patroni + 3 etcd services
├── patroni-1.yml        # Patroni config for node 1
├── patroni-2.yml        # Patroni config for node 2
├── patroni-3.yml        # Patroni config for node 3
├── Makefile             # setup | break | verify | recover | teardown
├── README.md            # This file
└── .env.example         # Optional environment overrides
```
