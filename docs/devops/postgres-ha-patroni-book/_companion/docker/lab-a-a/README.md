# LAB-A-A: Python Runtime Rolling Upgrade

**Source of truth:** Appendix A — Python Runtime Migration (`appendix-a-python-runtime.mdx`)

This lab demonstrates a zero-downtime rolling upgrade of Patroni's Python runtime from **3.8 to 3.12** using the side-by-side virtual-environment swap pattern. Each node carries both Python versions; the active runtime is controlled by a symlink (`/opt/patroni/venv`) that is atomically switched during the upgrade window.

---

## Prerequisites

- Docker Engine ≥ 24.x
- Docker Compose v2
- 8 GB RAM / 4 CPU cores (for the 3-node cluster + etcd)
- Bash 5.x and Make

---

## Architecture

| Service | Role | Description |
|---------|------|-------------|
| `etcd` | DCS | Single-node etcd for distributed consensus |
| `patroni1` | PostgreSQL + Patroni | Node 1 — initially Python 3.8 venv |
| `patroni2` | PostgreSQL + Patroni | Node 2 — initially Python 3.8 venv |
| `patroni3` | PostgreSQL + Patroni | Node 3 — initially Python 3.8 venv |

The custom image (`Dockerfile`) is based on `ubuntu:22.04` and contains:

- PostgreSQL 16
- `python3.8` + `python3.8-venv` + `python3.8-dev`
- `python3.12` + `python3.12-venv` + `python3.12-dev`
- `/opt/venv38` — pre-installed with Patroni 4.x + `psycopg2-binary`
- `/opt/patroni/venv` — symlink pointing to the active venv (initially `venv38`)

---

## Quick Start

### 1. Deploy the cluster (Python 3.8)

```bash
make setup
```

This builds the image and starts a 3-node Patroni cluster with one etcd node.

### 2. Verify initial state

```bash
make verify-python
```

Expected output:

```text
=== patroni1 ===
Python 3.8.x
=== patroni2 ===
Python 3.8.x
=== patroni3 ===
Python 3.8.x
```

### 3. Check cluster health

```bash
make verify
```

You should see one leader and two followers in a `running` state.

---

## Rolling Upgrade Procedure

Upgrade **followers first, leader last** to minimize failover risk.

### Step 1 — Upgrade Node 1 (follower)

```bash
make upgrade-node-1
```

What happens:
1. `upgrade.sh` execs into the running container.
2. Creates `/opt/venv312` and installs Patroni + dependencies.
3. Swaps the symlink `/opt/patroni/venv -> /opt/venv312`.
4. Restarts the container so Patroni starts under Python 3.12.

### Step 2 — Verify cluster health

```bash
make verify
```

Confirm all three nodes are still `running` and Node 1 now reports Python 3.12.

### Step 3 — Upgrade Node 2 (follower)

```bash
make upgrade-node-2
```

### Step 4 — Upgrade Node 3 (leader)

Before upgrading the leader, consider demoting it first to avoid a brief unavailability window:

```bash
docker compose exec patroni1 /opt/patroni/venv/bin/patronictl switchover --master patroni3 --candidate patroni1 --force
```

Then upgrade the former leader:

```bash
make upgrade-node-3
```

> **Production tip:** The appendix recommends `patronictl pause` before touching the leader; in this Docker lab the container restart is fast enough that a controlled switchover is the cleaner demonstration.

---

## Final Verification

```bash
make verify
```

Expected results:

- **Cluster status:** All 3 nodes show `running`.
- **Python version:** Every node reports `Python 3.12.x`.
- **DCS:** Etcd is reachable and the leader lock is stable.

---

## Rollback

If any node misbehaves after the upgrade, revert it instantly by swapping the symlink back to the original venv:

```bash
# Rollback a single node
./upgrade.sh patroni2 rollback

# Rollback all nodes
make rollback
```

Because the old `/opt/venv38` is never deleted, rollback is sub-second and requires only a container restart.

---

## Teardown

```bash
make teardown
```

Stops all containers and **removes volumes**, giving you a clean slate for the next run.

---

## How It Works (Side-by-Side Venv Swap)

1. **Install target Python** alongside the existing one inside the same OS image.
2. **Create a new venv** (`venv312`) and install **identical dependency versions** into it.
3. **Stop Patroni** (container restart) so the old interpreter is fully released.
4. **Swap symlink** `ln -sfn /opt/venv312 /opt/patroni/venv` — atomic on Linux.
5. **Start Patroni** (container restart) — the entrypoint resolves the symlink at boot and launches the new runtime.
6. **Verify** the node rejoins the cluster and replication catches up.

This pattern keeps the old venv intact, giving you an instant rollback path without re-installation.

---

## Makefile Reference

| Target | Action |
|--------|--------|
| `make setup` | Build image and start the full stack |
| `make verify-python` | Print the active Python version on each node |
| `make upgrade-node-1` | Upgrade Node 1 to Python 3.12 |
| `make upgrade-node-2` | Upgrade Node 2 to Python 3.12 |
| `make upgrade-node-3` | Upgrade Node 3 to Python 3.12 |
| `make verify` | Show `patronictl list` + Python versions |
| `make rollback` | Revert all nodes to Python 3.8 |
| `make teardown` | Destroy containers and volumes |

---

## Files

| File | Purpose |
|------|---------|
| `Dockerfile` | Multi-Python Ubuntu image with PostgreSQL 16 and both venvs |
| `entrypoint.sh` | Boot-time symlink resolution and Patroni foreground launch |
| `patroni.yml` | Shared Patroni configuration (etcd DCS, auth, Postgres params) |
| `docker-compose.yml` | 3-node Patroni + single-node etcd topology |
| `upgrade.sh` | Side-by-side venv swap script (upgrade or rollback per node) |
| `Makefile` | Convenient targets for setup, upgrade, verify, rollback, teardown |
| `README.md` | This file |
