# Feature Specification: Patroni HA Book Companion Code

**Feature Branch**: `002-companion-code`

**Created**: 2026-05-18

**Status**: Draft

**Input**: User description: "Implement runnable companion code for the Patroni HA book at docs/devops/postgres-ha-patroni-book/_companion/. The book chapters (Ch. 03, 04, 06, 08, 11, Appendix A, Appendix B) contain the exact step-by-step instructions, configs, PromQL queries, and code sketches. This feature extracts those into working files. 5 Labs: LAB-03-A (Docker Compose 3-node Patroni+etcd — deploy, kill leader, failover, recover), LAB-08-A (Docker Compose pgBackRest PITR), LAB-08-B (Terraform AWS+GCP cross-region restore), LAB-A-A (Docker Python 3.8→3.12 rolling upgrade), LAB-B-A (Ansible watchdog/lease pathology — NOT Docker). 1 Config: CONFIG-04-REF annotated patroni.yml from Ch. 04. 2 Dashboards: DASH-06-CORE and DASH-06-LAG Grafana JSON from Ch. 06. 5 Alert rules: ALERT-06-LAG, ALERT-06-LEADER-FLAP, ALERT-06-WAL-BLOAT, ALERT-06-DCS-PARTITION, ALERT-06-CERT-EXPIRY — PromQL from Ch. 06. 5 Agent scaffolds: AGENT-11-MON/PF/ST/AR/NL — Python packages using pydantic-ai + litellm with 6-state lifecycle from Ch. 11. 1 Chaos script: CHAOS-03-A. CI: GitHub Actions matrix — spin up each Docker lab, run setup/break/verify/recover/teardown, assert exit 0. Source of truth for every artifact: the corresponding book chapter MDX file. Read those to extract configs, commands, and PromQL. Tech: Docker Compose, Terraform (AWS+GCP), Ansible, Python 3.12, pydantic-ai, litellm, pgBackRest, PostgreSQL 18.x/17.x, Patroni 4.x, etcd 3.5.x."

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Reader Runs Core Deployment Lab (Priority: P1)

A reader who has just finished Chapter 03 of the book wants to validate their understanding by deploying the exact cluster described in the chapter. They clone the repo, navigate to the companion code directory, and run a single command that stands up a working 3-node Patroni cluster with etcd. They then follow the "Break it on purpose" exercise to kill the leader, observe automatic failover, verify the promotion, and run teardown — all without consulting external documentation.

**Why this priority**: This is the foundational lab that validates the entire book's deployment story. If this lab does not work, Chapters 04–11 lose their anchor. It is the highest-value reader outcome and the most frequently executed lab.

**Independent Test**: A reader can, using only the book's Chapter 03 instructions and the companion code, deploy a 3-node cluster, induce leader failure, and verify automatic failover within the chapter's stated time budget. The lab MUST run on a clean machine with only Docker installed.

**Acceptance Scenarios**:

1. **Given** a reader with Docker installed and no prior Patroni setup, **When** they run `docker compose up` in the LAB-03-A directory, **Then** a 3-node Patroni cluster with 3-node etcd is running and healthy within 5 minutes.
2. **Given** the running cluster, **When** the reader executes the documented "break" command (killing the leader container), **Then** a replica promotes to leader within the chapter's stated RTO, and `patronictl list` shows the new leader.
3. **Given** a completed failover, **When** the reader runs the recovery commands, **Then** the old leader rejoins as a replica and the cluster returns to a healthy 3-node state.
4. **Given** a finished exercise, **When** the reader runs teardown, **Then** all containers, volumes, and networks are removed and the host is returned to its pre-setup state.

---

### User Story 2 — Reader Validates Backup/DR Design (Priority: P1)

An architect who has read Chapter 08 wants to empirically verify that their chosen backup strategy meets stated RTO/RPO targets. They run the pgBackRest PITR lab to perform a full backup, an incremental backup, and a point-in-time recovery to a specific transaction. They then run the cross-region restore lab to validate disaster recovery across cloud regions.

**Why this priority**: Backup/DR is a frequent audit and compliance trigger. The lab provides the empirical evidence that backs up the chapter's claims. Without working labs, the chapter's decision matrix is theoretical.

**Independent Test**: A reader can complete LAB-08-A (full + incremental + PITR) and LAB-08-B (cross-region restore) end-to-end and produce a one-page recovery plan whose claimed RTO/RPO is empirically measured.

**Acceptance Scenarios**:

1. **Given** a clean environment with Docker, **When** the reader runs LAB-08-A setup, **Then** a 3-node Patroni cluster with pgBackRest configured is running and the initial full backup completes successfully.
2. **Given** the running cluster with data loaded, **When** the reader performs an incremental backup and then a PITR to a specific timestamp, **Then** the restored cluster contains exactly the data expected at that timestamp (verified by query).
3. **Given** Terraform and cloud credentials, **When** the reader runs LAB-08-B setup in region A and then initiates cross-region restore to region B, **Then** the restored cluster in region B is accepting connections with the same data as region A at restore time.

---

### User Story 3 — SRE Imports Observability Stack (Priority: P2)

An SRE who has read Chapter 06 wants to operationalize the observability signals described in the chapter. They import the reference Grafana dashboards and Prometheus alert rules into their existing monitoring infrastructure and verify that the alerts fire correctly against a running Patroni cluster.

**Why this priority**: Observability is critical for operating Patroni in production, but it is a "readiness" activity that typically happens after the cluster is deployed. It is P2 because it depends on the deployment lab (Story 1) but can be developed in parallel.

**Independent Test**: An SRE can import DASH-06-CORE and DASH-06-LAG into Grafana, import all ALERT-06-* rules into Prometheus, and verify that each alert rule fires when the corresponding failure condition is simulated.

**Acceptance Scenarios**:

1. **Given** a running Grafana instance and the dashboard JSON files, **When** the SRE imports DASH-06-CORE and DASH-06-LAG, **Then** both dashboards display meaningful data panels for leader status, replication lag, and DCS connectivity without manual query editing.
2. **Given** a running Prometheus + Alertmanager and the alert YAML files, **When** the SRE applies the alert rules, **Then** each rule evaluates without syntax errors and produces alerts when the threshold condition is met.
3. **Given** the imported dashboards and a running lab cluster, **When** the SRE simulates the failure condition for ALERT-06-LAG (e.g., stalls replication), **Then** the alert fires within the evaluation interval and appears in Alertmanager.

---

### User Story 4 — Platform Engineer Evaluates Agentic AI Scaffolds (Priority: P2)

A platform engineer who has read Chapter 11 wants to understand how the documented agent workflows could be implemented in their environment. They review the Python scaffolds for each agent type (monitoring, predictive failover, self-tuning, auto-remediation, NL ops), run the dry-run mode to observe the proposed actions without executing them, and verify that the safety guardrails are in place.

**Why this priority**: The Agentic AI chapter is the book's 2026 differentiator, but it is P2 because the scaffolds are reference implementations — they demonstrate patterns and guardrails rather than production-ready agents.

**Independent Test**: A platform engineer can install each agent scaffold, run it in dry-run mode against the lab cluster, and confirm that every proposed action traverses the documented 6-state lifecycle (observed → proposed → dry-run → approved → executed → verified).

**Acceptance Scenarios**:

1. **Given** the AGENT-11-AR scaffold installed with Python 3.12, **When** the engineer runs it in dry-run mode against a cluster with a dead replication slot, **Then** the agent detects the slot, proposes dropping it, and stops at the dry-run gate without executing the action.
2. **Given** the AGENT-11-PF scaffold, **When** the engineer simulates DCS latency degradation in the lab, **Then** the agent detects the leading indicator trend and proposes a preemptive switchover with a confidence score.
3. **Given** any agent scaffold, **When** the engineer inspects the source code, **Then** the 6-state lifecycle is clearly implemented with audit logging at each transition, and the manual-equivalent runbook is referenced in comments.

---

### User Story 5 — Reader Upgrades Python Runtime (Priority: P3)

A DBA who has read Appendix A wants to perform a rolling Python runtime upgrade on their production Patroni cluster without downtime. They use the LAB-A-A lab to practice the side-by-side venv swap pattern on an ephemeral cluster, verifying that the old leader can be upgraded and rejoin without split-brain.

**Why this priority**: Python runtime migration is a niche but critical operation for long-running clusters. It is P3 because it is an appendix-level concern and does not gate the core deployment story.

**Independent Test**: A reader can run LAB-A-A end-to-end, upgrade Python on one node at a time, and verify the cluster remains healthy with no split-brain throughout the process.

**Acceptance Scenarios**:

1. **Given** a 3-node cluster running Patroni on Python 3.8, **When** the reader follows the rolling upgrade procedure, **Then** each node is upgraded to Python 3.12 sequentially with the cluster remaining available.
2. **Given** a mid-upgrade state with one node on Python 3.12 and two on 3.8, **When** a failover is induced, **Then** the cluster promotes successfully and the Python version disparity does not affect correctness.

---

### User Story 6 — Reader Observes Watchdog Behavior (Priority: P3)

A senior engineer who has read Appendix B wants to witness the watchdog/lease pathology described in the appendix. They use LAB-B-A to partition the leader from DCS, observe the TTL expiry, watch the watchdog fire and reboot the node, and verify that the replica promotes without split-brain.

**Why this priority**: This is a deep-dive internals lab for readers who want to understand WHY Patroni behaves as it does. It is P3 because it requires bare VMs or LXC (not Docker) and is therefore less accessible.

**Independent Test**: A reader can run LAB-B-A on Proxmox LXC or bare VMs, induce a leader-to-DCS partition, and observe the complete sequence: lease expiry → watchdog fire → reboot → replica promotion → no split-brain.

**Acceptance Scenarios**:

1. **Given** a 3-node cluster with softdog enabled on Proxmox LXC, **When** the reader partitions the leader from etcd, **Then** the leader reboots within the safety margin timeout and a replica promotes.
2. **Given** the post-partition cluster, **When** the reader checks WAL timelines on all nodes, **Then** all nodes show the same timeline (no split-brain occurred).

---

### Edge Cases

- What happens when a reader runs the lab on a machine with insufficient RAM or disk? (The prerequisites section must state minimum resources.)
- How does the system handle cloud credentials that are expired or missing for Terraform labs? (Terraform plan should fail fast with a clear error, not hang.)
- What happens if Docker is not installed or the Docker daemon is not running? (Setup scripts should detect this and exit with a helpful message.)
- How are agent scaffolds protected against accidental execution in production? (Dry-run mode must be the default; destructive actions require explicit opt-in.)
- What happens if a reader interrupts a lab mid-execution (Ctrl+C)? (Teardown must be robust and handle partial state.)

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: LAB-03-A MUST provide a Docker Compose file that deploys a 3-node Patroni cluster with a 3-node etcd cluster, with patroni.yml and etcd configuration derived from Chapter 03.
- **FR-002**: Every Docker-based lab MUST include a `Makefile` or shell script with `setup`, `break`, `verify`, `recover`, and `teardown` targets that match the lab structure contract.
- **FR-003**: LAB-08-A MUST configure pgBackRest for full and incremental backups, and provide a PITR command that restores to a specific timestamp or LSN with data integrity verification.
- **FR-004**: LAB-08-B MUST provide Terraform modules for AWS and GCP that deploy a source Patroni cluster, configure cross-region backup, and support restore to a target region.
- **FR-005**: LAB-A-A MUST provide a rolling Python upgrade procedure using the side-by-side venv swap pattern, with rollback instructions.
- **FR-006**: LAB-B-A MUST provide an Ansible playbook for bare VMs or Proxmox LXC that enables softdog, deploys Patroni, and includes the iptables partition + observation steps.
- **FR-007**: CONFIG-04-REF MUST be an annotated patroni.yml where every parameter has an inline comment explaining its purpose, recommended value, and cross-reference to the relevant book chapter section.
- **FR-008**: DASH-06-CORE and DASH-06-LAG MUST be valid Grafana dashboard JSON files that import without modification and display panels matching the signals described in Chapter 06.
- **FR-009**: All ALERT-06-* alert rules MUST use the exact PromQL expressions and thresholds documented in Chapter 06, and evaluate correctly in a Prometheus + Alertmanager environment.
- **FR-010**: Each AGENT-11-* scaffold MUST implement the 6-state action lifecycle (observed → proposed → dry-run → approved → executed → verified) with audit logging at each state transition.
- **FR-011**: Each agent scaffold MUST default to dry-run mode and require explicit configuration to execute destructive actions.
- **FR-012**: Each agent scaffold MUST include a comment referencing the manual-equivalent runbook from Chapter 07 or Chapter 09.
- **FR-013**: CHAOS-03-A MUST be a shell script that safely kills the Patroni leader container by name, with guardrails preventing accidental execution against non-lab environments.
- **FR-014**: The CI pipeline MUST run every Docker-based lab end-to-end (setup → break → verify → recover → teardown) on every PR that touches companion code, and fail if any step returns non-zero.
- **FR-015**: The ARTIFACT-IDS.md registry MUST remain the single source of truth for all artifact IDs; the `_companion-links.json` in the book prose MUST be generated from or manually kept in sync with this registry.

### Key Entities

- **Lab**: A hands-on exercise with 9 required sections per the lab structure contract. Identified by `LAB-NN-X` artifact ID. Lives in a substrate-specific directory (docker/, terraform/, ansible/).
- **Artifact**: Any companion file referenced by the book prose. Categories: LAB, CONFIG, DASH, ALERT, AGENT, CHAOS. Identified by stable `CATEGORY-CHAPTER-SUFFIX` ID.
- **Agent Scaffold**: A Python package implementing one agentic AI workflow. Has a typed interface (pydantic-ai), a litellm provider configuration, and a 6-state lifecycle implementation.
- **Dashboard**: A Grafana dashboard JSON file with panels, variables, and queries matching Chapter 06's signals matrix.
- **Alert Rule**: A Prometheus/Alertmanager YAML rule group with PromQL expressions, thresholds, severity labels, and runbook annotations.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A reader with only Docker installed can run LAB-03-A setup and have a healthy 3-node cluster in under 5 minutes.
- **SC-002**: LAB-03-A failover time (from leader kill to replica promotion) is under the 40-second threshold stated in Chapter 03, measured by CI.
- **SC-003**: All 5 Docker-based labs pass CI end-to-end (setup → break → verify → recover → teardown) with 100% success rate on every PR.
- **SC-004**: All 2 Grafana dashboards import into a fresh Grafana instance without manual query editing and display at least 8 panels each.
- **SC-005**: All 5 alert rules evaluate without syntax errors and fire correctly when their trigger condition is simulated in the lab.
- **SC-006**: Every agent scaffold can be installed with `pip install -e .` and run in dry-run mode without errors against the lab cluster.
- **SC-007**: The annotated patroni.yml (CONFIG-04-REF) has an inline comment for every non-default parameter explaining its purpose and recommended value.
- **SC-008**: The CI pipeline completes in under 15 minutes for all Docker-based labs combined.

## Assumptions

- Readers have Docker and Docker Compose installed for Docker-based labs.
- Readers have Terraform ≥1.7 and cloud credentials for Terraform-based labs.
- Readers have Ansible ≥2.16 and SSH access to target hosts for Ansible-based labs.
- Python 3.12 is the baseline for agent scaffolds and LAB-A-A.
- PostgreSQL 18.x and 17.x are the supported versions; labs default to 18.x.
- Patroni 4.x (latest stable at publication time) is the baseline.
- The book prose in `docs/devops/postgres-ha-patroni-book/` is the authoritative source of truth for all configs, commands, and thresholds.
- The companion code lives under `docs/devops/postgres-ha-patroni-book/_companion/` and is excluded from Docusaurus rendering.
