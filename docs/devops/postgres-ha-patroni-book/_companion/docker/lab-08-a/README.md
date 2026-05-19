# LAB-08-A — Full Backup and Point-in-Time Recovery (Docker)

**Source of truth**: Chapter 08 — `08-backup-dr-pitr.mdx`  
**Supported substrates**: Docker / Docker Compose  
**What you'll learn**:
- How to create a pgBackRest stanza and perform full + incremental backups.
- How Patroni's timeline management interacts with PITR.
- How to restore to a precise timestamp or LSN after logical data corruption.
- How to verify restore success with a row-count assertion.

---

## Prerequisites

| Component | Version |
|---|---|
| Docker | 25.x+ |
| Docker Compose | v2 |
| Host resources | 2 CPU cores, 4 GB RAM, 10 GB disk |

> **Note**: The lab pins Spilo (`ghcr.io/zalando/spilo-16:3.2-p1`) and etcd (`v3.5.13`) images for reproducibility. Adjust `PGVERSION` in `docker-compose.yml` if you require a different Postgres version.

## Architecture

```text
  etcd1 ──┐
  etcd2 ──┼── DCS (etcd cluster)
  etcd3 ──┘

  patroni1 (Leader) ──┐
  patroni2 (Replica) ──┼── Patroni cluster (Spilo image)
  patroni3 (Replica) ──┘     each mounts pgbackrest.conf

  pgbackrest sidecar ── stanza-create / backup / restore / info
                       shares patroni1-data volume + pgbackrest.conf

  minio ── S3-compatible object store (local backup repository)
           http://localhost:9000 (API) / 9001 (Console)
```

All services run on an isolated Docker network (`lab-08-a`, subnet `172.20.8.0/24`).

## Files

| File | Purpose |
|---|---|
| `docker-compose.yml` | 3-node Patroni + 3-node etcd + minio + pgBackRest sidecar |
| `patroni.yml` | Reference Patroni config (`archive_command` / `restore_command`) |
| `pgbackrest.conf` | pgBackRest S3 (minio) repository configuration |
| `Makefile` | `setup`, `full-backup`, `incremental-backup`, `pitr-restore`, `verify`, `teardown` |
| `.env.example` | Template for sensitive env vars (not needed for local minio) |

---

## Quick Start

### 1. Setup

```bash
make setup
```

This will:
1. Start etcd, minio, Patroni, and the pgbackrest sidecar.
2. Wait ~30 seconds for a leader election.
3. Create the pgBackRest stanza (`lab-08-a`).
4. Take an initial full backup.

**Verify clean state**:

```bash
make verify
# Expected: patronictl shows 1 Leader + 2 Replicas
#           pgbackrest info shows at least one full backup
```

### 2. Seed Test Data

```bash
make seed-data
```

Creates an `orders` table and inserts 10,000 rows.

**Record the pre-corruption state**:

```bash
docker compose exec patroni1 psql -U postgres -c "
  SELECT count(*) AS row_count FROM orders;
  SELECT pg_current_wal_lsn() AS safe_lsn;
"
```

Save both values — you will need them in the verification step.

### 3. Take an Incremental Backup

```bash
make incremental-backup
```

### 4. Simulate Corruption (Break It on Purpose)

> **DANGER**: Run this only on the lab cluster. The following commands permanently delete rows. Never run destructive commands against production.

```bash
docker compose exec patroni1 psql -U postgres -c "
  DELETE FROM orders;
  SELECT count(*) FROM orders;
"
# Should return 0
```

Record the LSN immediately after the delete (for the PITR target):

```bash
docker compose exec patroni1 psql -U postgres -c "
  SELECT pg_current_wal_lsn() AS corruption_lsn;
"
```

### 5. Point-in-Time Restore

Stop the corrupted nodes and restore to the **safe LSN** recorded in Step 2:

```bash
# Example with LSN target (replace with your actual safe_lsn value):
make pitr-restore PITR_TARGET='--target-lsn=0/12345678'
```

Other valid target styles:

```bash
# Timestamp target
make pitr-restore PITR_TARGET='--target-time="2024-01-15 14:23:00+00"'

# Transaction ID target
make pitr-restore PITR_TARGET='--target-xid=12345'
```

The restore process:
1. Stops all Patroni containers.
2. Runs `pgbackrest restore` from the sidecar into `patroni1-data`.
3. Starts `patroni1` — Postgres replays WAL and promotes at the target.
4. Starts `patroni2` and `patroni3` — Patroni reinitializes them from the restored leader.

### 6. Verify Recovery

```bash
make verify
```

Check the row count on the restored leader:

```bash
docker compose exec patroni1 psql -U postgres -c "
  SELECT count(*) AS row_count FROM orders;
"
# Expected: 10000 (matches the pre-corruption snapshot)
```

### 7. Teardown

```bash
make teardown
```

Removes **all** containers, networks, and named volumes created by this lab.

---

## Manual Commands (without Make)

If you prefer to run each step explicitly:

```bash
# Infrastructure
docker compose up -d

# Wait for leader
sleep 30
docker compose exec patroni1 patronictl -c /etc/patroni/patroni.yml list

# Stanza
docker compose exec pgbackrest pgbackrest --stanza=lab-08-a stanza-create
docker compose exec pgbackrest pgbackrest --stanza=lab-08-a check

# Full backup
docker compose exec pgbackrest pgbackrest --stanza=lab-08-a --type=full backup

# Incremental backup
docker compose exec pgbackrest pgbackrest --stanza=lab-08-a --type=incr backup

# Backup info
docker compose exec pgbackrest pgbackrest --stanza=lab-08-a info

# Restore (stop cluster first)
docker compose stop patroni1 patroni2 patroni3
docker compose run --rm pgbackrest pgbackrest --stanza=lab-08-a restore \
  --target-lsn='<SAFE_LSN>' --target-action=promote --type=lsn
docker compose start patroni1
```

---

## What This Tells You About Production

- **Backups from standby**: This lab runs backups from the sidecar attached to `patroni1-data`. In production, configure `backup-standby=y` in `pgbackrest.conf` and point `pg2-host` at a healthy replica to avoid checkpoint pressure on the leader.
- **Record safe LSNs**: Always record a known-good LSN (or use `pg_create_restore_point('before_migration')`) before destructive operations.
- **Timeline management**: Patroni auto-increments the Postgres timeline on every failover. pgBackRest handles multi-timeline WAL transparently when `--target-timeline=latest` is used (the default).
- **MinIO != production S3**: This lab uses MinIO for local, zero-cost testing. For production, replace the `repo1-*` S3 settings with real AWS/GCS/Azure credentials and enable TLS (`repo1-s3-verify-tls=y`).

---

## Troubleshooting

| Symptom | Fix |
|---|---|
| `stanza-create` fails with "unable to find postgres data directory" | Verify `pg1-path` in `pgbackrest.conf` matches the actual PGDATA path inside the Spilo container. Run `SHOW data_directory;` from psql. |
| Patroni shows `archive_command failed` | Ensure minio is healthy (`docker compose ps minio`) and `pgbackrest.conf` S3 credentials match minio's `MINIO_ROOT_USER` / `MINIO_ROOT_PASSWORD`. |
| Replicas fail to rejoin after PITR | They may be on an older timeline. Run `docker compose stop patroni2 patroni3`, `docker compose rm patroni2 patroni3`, then `docker compose up -d patroni2 patroni3` so Patroni reinitializes them from the leader. |
