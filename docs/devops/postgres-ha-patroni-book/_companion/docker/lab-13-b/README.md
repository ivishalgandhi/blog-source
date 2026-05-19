# LAB-13-B: 3-Node Patroni + 5-Node etcd — Quorum Recovery Test

Prove that a 3-node Patroni cluster survives the same network partitions that fail on 2-node.

> **Artifact ID**: LAB-13-B  
> **Book Reference**: Chapter 13 — Network Partition Testing

## Prerequisites

- Docker Engine >= 24.x with Docker Compose v2
- 8 GB RAM / 4 CPU cores (Docker Desktop minimum)
- ~3 GB free disk space
- `iptables` available inside Docker containers (`NET_ADMIN` cap granted)

## Quickstart

```bash
# 1. Deploy the cluster
make setup

# 2. Run a break scenario (choose one)
make break-clean-stop        # Scenario 1: clean service stop
make break-full-partition    # Scenario 2: isolate leader from replicas
make break-asymmetric        # Scenario 3: leader loses etcd

# 3. Verify cluster state
make verify

# 4. Recover
make recover

# 5. Clean up
make teardown
```

## What This Lab Proves

| Scenario | 3-Node Result | Key Observation |
|----------|-------------|-----------------|
| **Clean stop** | One replica promotes, third stays replica | Full redundancy after failover |
| **Full partition** | Leader self-demotes, replicas elect new leader | Quorum of 2 > 1 |
| **Asymmetric** | Leader self-demotes when DCS lost | Replicas see leader gone and race |

## Network Topology

| Node | IP Address | Role |
|------|-----------|------|
| etcd-1 | 172.22.0.2 | etcd member |
| etcd-2 | 172.22.0.3 | etcd member |
| etcd-3 | 172.22.0.4 | etcd member |
| etcd-4 | 172.22.0.5 | etcd member |
| etcd-5 | 172.22.0.6 | etcd member |
| patroni-1 | 172.22.0.11 | PostgreSQL 16 + Patroni |
| patroni-2 | 172.22.0.12 | PostgreSQL 16 + Patroni |
| patroni-3 | 172.22.0.13 | PostgreSQL 16 + Patroni |

## Files

```text
lab-13-b/
├── docker-compose.yml          # 3 Patroni + 5 etcd services
├── patroni-1.yml               # Patroni config for node 1
├── patroni-2.yml               # Patroni config for node 2
├── patroni-3.yml               # Patroni config for node 3
├── break-clean-stop.sh         # Scenario 1: leader service stop
├── break-full-partition.sh     # Scenario 2: full network partition
├── break-asymmetric-partition.sh # Scenario 3: asymmetric partition
├── verify.sh                   # Capture cluster state, logs, checksums
├── Makefile                    # setup | break-* | verify | recover | teardown
├── README.md                   # This file
└── .env.example                # Optional environment overrides
```
