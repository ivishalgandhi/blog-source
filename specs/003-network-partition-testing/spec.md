# Feature Specification: Network Partition Testing for PostgreSQL HA

**Feature Branch**: `[003-network-partition-testing]`

**Created**: 2026-05-19

**Status**: Draft

**Input**: User description: "Add Chapter 13 -- Network Partition Testing for PostgreSQL HA. As an extension to the existing Mastering PostgreSQL HA with Patroni (2026 Edition) book (feature 001), add a new chapter and two companion labs that scientifically test 2-node vs 3-node Patroni clusters under controlled network partitions."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - 2-Node Partition Test (Priority: P1)

A database operator wants to understand whether a 2-node Patroni cluster truly provides high availability under realistic failure conditions. They deploy a 2-node Patroni + etcd cluster and use controlled network partition injection to test three failure modes: clean service stop, full partition (leader and replica isolated from each other but both can still reach etcd), and asymmetric partition (leader loses access to etcd but keeps running). They observe whether automatic failover occurs, whether stale reads happen on the replica, and whether split-brain is possible.

**Why this priority**: This addresses the most common misconception in production deployments -- that a 2-node cluster with a separate 5-node etcd cluster is "fully HA." The chapter settles this debate with reproducible evidence.

**Independent Test**: Can be fully tested by running LAB-13-A in Docker Compose and executing the three break scenarios. The lab delivers a pass/fail result for each scenario with captured Patroni logs and cluster state snapshots.

**Acceptance Scenarios**:

1. **Given** a healthy 2-node Patroni cluster with test data loaded, **When** the `break-clean-stop.sh` script stops the Patroni service on the leader, **Then** the replica promotes automatically within `retry_timeout + loop_wait` seconds, and `patronictl list` shows the former replica as the new leader.
2. **Given** a healthy 2-node Patroni cluster, **When** `break-full-partition.sh` drops all packets between leader and replica (both still connected to etcd), **Then** the replica does NOT promote while the leader continues running, and `pg_stat_replication` on the leader shows the replica as `streaming` but with increasing `lag`.
3. **Given** a healthy 2-node Patroni cluster, **When** `break-asymmetric-partition.sh` blocks the leader from etcd while keeping replica-to-etcd and leader-to-replica paths open, **Then** the leader self-demotes to replica (or stays primary with failsafe mode if configured), and the replica does NOT promote until the leader lock expires.

---

### User Story 2 - 3-Node Quorum Test (Priority: P2)

A database operator wants to prove that a 3-node Patroni cluster survives the same network partitions that fail on 2-node. They deploy a 3-node Patroni + etcd cluster, apply the same three failure modes, and document how Raft quorum in etcd prevents split-brain, how the remaining two nodes form a new majority and continue operations, and how rolling restarts work post-failover.

**Why this priority**: This provides the evidence-based justification for the 3-node recommendation. It directly supports the "minimum 3 for zone drop tolerance" statement from Patroni's own multi-DC documentation.

**Independent Test**: Can be fully tested by running LAB-13-B in Docker Compose and executing the same three break scenarios. The lab delivers a comparison matrix showing 2-node vs 3-node outcomes side-by-side.

**Acceptance Scenarios**:

1. **Given** a healthy 3-node Patroni cluster with test data loaded, **When** `break-clean-stop.sh` stops the leader, **Then** one of the two remaining replicas promotes automatically, and `patronictl list` shows a new leader with the third node still streaming.
2. **Given** a healthy 3-node Patroni cluster, **When** `break-full-partition.sh` isolates the leader from both replicas but all nodes still see etcd, **Then** the leader self-demotes when it cannot reach a majority of replicas via REST API, and one of the isolated replicas promotes via etcd leader race.
3. **Given** a healthy 3-node Patroni cluster, **When** a zone drop simulates losing one entire data center (one node + its local etcd), **Then** the remaining 2-node majority continues serving as primary + replica, and `patronictl list` shows the lost node as `stopped`.

---

### Edge Cases

- What happens when the partition is healed? Does the former leader rejoin as a replica via `pg_rewind`?
- How does `synchronous_mode_strict: true` change failover behavior in the asymmetric partition scenario?
- What happens when etcd itself is partitioned (e.g., 2 of 5 nodes isolated) while Patroni nodes remain connected to the remaining 3 etcd nodes?
- What is the maximum data loss window if the leader crashes during the partition before the replica promotes?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The chapter MUST explain the CAP theorem as it applies to PostgreSQL HA, specifically why CP (consistency + partition tolerance) is the correct choice for financial/transactional data.
- **FR-002**: The chapter MUST document Patroni's DCS lease model: how the leader holds a lock in etcd, how replicas watch the lock, and how the race occurs when the lock expires.
- **FR-003**: LAB-13-A MUST provide a Docker Compose environment with exactly 2 Patroni nodes and 5 etcd nodes, pre-loaded with a `partition_test` schema and test data.
- **FR-004**: LAB-13-A MUST include three chaos scripts: `break-clean-stop.sh`, `break-full-partition.sh`, and `break-asymmetric-partition.sh`, each idempotent and reversible via `recover.sh`.
- **FR-005**: LAB-13-B MUST provide a Docker Compose environment with exactly 3 Patroni nodes and 5 etcd nodes, using the same `partition_test` schema and chaos scripts as LAB-13-A.
- **FR-006**: Both labs MUST include a `verify.sh` script that captures: `patronictl list` output, PostgreSQL replication lag, etcd cluster health (`etcdctl endpoint status`), and data consistency checksums.
- **FR-007**: The chapter MUST include a results table comparing 2-node vs 3-node outcomes for all three failure modes, with columns: Scenario, 2-Node Result, 3-Node Result, Data Loss Risk, Recovery Action.
- **FR-008**: The chapter MUST cite Patroni official documentation: README (2-node "no redundancy" caveat), HA Multi DC ("minimum 3 for zone drop tolerance"), DCS Failsafe Mode, and GitHub issue #2662.
- **FR-009**: The chapter MUST include a production readiness checklist: when 2-node is acceptable (DR, cost-constrained, manual failover accepted) vs when 3-node is required (true HA, zone-drop tolerance, automated maintenance).
- **FR-010**: Both labs MUST use the standard Makefile targets: `setup`, `break`, `verify`, `recover`, `teardown`.

### Key Entities

- **Patroni Node**: A PostgreSQL instance managed by Patroni, with attributes: role (leader/replica), state (running/stopped), timeline, replication lag.
- **etcd Cluster**: The DCS holding Patroni cluster state, with attributes: member count, leader, quorum status, raft index.
- **Network Partition**: A failure scenario where nodes cannot communicate, categorized as: full partition (all paths blocked), asymmetric partition (selective path blocking), or clean stop (service termination).
- **Test Data Set**: Pre-loaded schema (`partition_test.transactions`) with known row counts and checksums, used to verify data consistency post-partition.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A reader can reproduce all three failure scenarios in LAB-13-A and LAB-13-B within 10 minutes of running `make setup`, with deterministic outcomes documented in the chapter.
- **SC-002**: The chapter's results table accurately reflects Patroni official documentation claims, with zero contradictions between the book's assertions and the upstream docs.
- **SC-003**: After running LAB-13-A and LAB-13-B, a reader can articulate the exact operational difference between "works for clean failures" and "survives zone drops automatically" in their own words.
- **SC-004**: The Docusaurus build passes with zero errors, and the new Chapter 13 appears in the sidebar navigation with correct `sidebar_position`.

## Assumptions

- Readers have already completed Chapters 1-3 and understand basic Patroni deployment (the labs reuse the same Spilo image and etcd patterns from LAB-03-A).
- Docker and Docker Compose are available on the reader's machine.
- The `iptables` command is available inside the Docker containers (Spilo base image includes it, or the Dockerfile installs it).
- Network partition simulation via `iptables` is sufficient for educational purposes; production chaos engineering would use ToxiProxy or actual network isolation.
- The feature is scoped to one chapter and two labs; extending to Kubernetes-based partition tests is out of scope for this feature.
