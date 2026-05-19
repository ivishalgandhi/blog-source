# Research: Network Partition Testing for PostgreSQL HA

**Date**: 2026-05-19
**Feature**: 003-network-partition-testing

## Decision: iptables Inside Docker Containers (vs. ToxiProxy)

**Decision**: Use `iptables` directly inside the Spilo containers for network partition simulation.

**Rationale**:
- ToxiProxy is elegant but adds another container and requires application-level proxy configuration (Patroni would need to connect through ToxiProxy ports, which changes the architecture being tested).
- `iptables` operates at the kernel networking layer, simulating actual network partitions without changing Patroni's connection topology. The leader and replica still connect to each other and etcd on their real IPs — packets are just dropped.
- Spilo is based on Ubuntu 22.04, which includes `iptables` by default (or can install it in a derived Dockerfile).
- Educational clarity: readers understand "we're dropping packets between these two IPs" more intuitively than "we're configuring a proxy with a toxic latency rule."

**Alternatives considered**:
- ToxiProxy: Rejected because it changes the network architecture being tested (adds proxy hops, different ports).
- Docker network disconnect: `docker network disconnect` physically removes a container from the bridge, which simulates a complete outage, not a selective partition. Too blunt for asymmetric partition scenarios.
- Linux network namespaces + `tc` (traffic control): More powerful but overkill. `iptables` DROP rules cover all three failure modes cleanly.

## Decision: 5 etcd Nodes for Both Labs

**Decision**: Use a 5-node etcd cluster as the DCS for both LAB-13-A and LAB-13-B.

**Rationale**:
- The feature's thesis is about **Patroni node count** (2 vs 3), not etcd node count. Keeping etcd at 5 nodes isolates the variable.
- The spec's user story 1 explicitly mentions "2-node Patroni + etcd cluster" where etcd is separately deployed (the common production pattern). Using 5 etcd nodes matches the "5-node etcd" claim made by colleagues in the original debate.
- A 3-node etcd cluster would lose quorum if 2 nodes fail; with 5 nodes, losing 2 still maintains quorum (3/5). This prevents etcd failures from confounding the Patroni partition test results.

**Alternatives considered**:
- 3-node etcd: Rejected because it introduces a confounding variable. If the partition test "fails," we wouldn't know if etcd quorum loss was the cause or the 2-node Patroni limitation.
- etcd inside Patroni containers: Rejected because co-locating etcd with Patroni is an anti-pattern for production (etcd needs its own disk I/O isolation) and doesn't match the architecture being debated.

## Decision: Reuse Spilo Image with Direct `patroni` Execution

**Decision**: Use `ghcr.io/zalando/spilo-16:3.2-p1` (same as LAB-03-A) but execute `patroni` directly instead of Spilo's `launch.sh`, allowing per-node patroni.yml mounts.

**Rationale**:
- Consistency with existing labs (LAB-03-A, LAB-08-A) — readers already understand this pattern.
- Direct `patroni` execution gives full control over the patroni.yml, which is necessary to configure `failsafe_mode`, `synchronous_mode`, and `restapi` endpoints.
- Spilo's `launch.sh` auto-configures etcd host discovery via environment variables, which conflicts with our explicit per-node config files.

**Alternatives considered**:
- Custom Dockerfile with vanilla Postgres + Patroni: Rejected because it adds build time and diverges from the book's established lab pattern.
- Spilo's `launch.sh` with env vars: Rejected because it abstracts away the patroni.yml that the chapter teaches readers to understand.

## Decision: Break Script Architecture (Three Scripts + recover.sh)

**Decision**: One script per failure mode (`break-clean-stop.sh`, `break-full-partition.sh`, `break-asymmetric-partition.sh`) plus a single `recover.sh` that restores all rules.

**Rationale**:
- Educational clarity: each script has a single purpose and a self-documenting name.
- Idempotency: running `recover.sh` before any `break-*.sh` is a no-op. Running it after resets all iptables rules.
- The `break-full-partition.sh` and `break-asymmetric-partition.sh` both use `iptables` but with different target IPs and chain rules, so separating them prevents confusion.

**Alternatives considered**:
- Single `break.sh` with CLI arguments: Rejected because it complicates the Makefile (more parameter passing) and makes the chapter prose harder to follow.
- Docker Compose `networks` isolation: Rejected because it's too coarse-grained — can't simulate the "both see etcd but not each other" asymmetric scenario.
