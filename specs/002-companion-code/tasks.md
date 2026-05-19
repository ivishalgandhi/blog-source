---
description: "Task list for Patroni HA Book Companion Code"
---

# Tasks: Patroni HA Book Companion Code

**Input**: Design documents from `/specs/002-companion-code/`

**Prerequisites**: plan.md (required), spec.md (required for user stories), data-model.md, contracts/ci-contract.md, contracts/lab-outputs.md, research.md, quickstart.md

**Tests**: CI pipeline tasks included per spec requirement FR-014. No unit tests needed (this is IaC + reference code, not a deployable service).

**Organization**: Tasks grouped by user story to enable independent implementation. Each lab is independently testable per the spec's independent test criteria.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: parallelizable (different files, no incomplete dependencies)
- **[Story]**: `US1`..`US6` from spec.md; setup/foundational/polish carry no story label
- Every task includes an exact file path

## Path Conventions

- Companion code: `docs/devops/postgres-ha-patroni-book/_companion/`
- CI workflows: `.github/workflows/`
- Book prose reference (source of truth): `docs/devops/postgres-ha-patroni-book/*.mdx`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Scaffold the companion code directory structure, create Makefiles, and set up CI pipeline skeleton.

- [x] T001 Create `docs/devops/postgres-ha-patroni-book/_companion/docker/` with subdirectories for lab-03-a, lab-08-a, lab-a-a
- [x] T002 Create `docs/devops/postgres-ha-patroni-book/_companion/terraform/lab-08-b/` with modules/aws and modules/gcp subdirectories
- [x] T003 Create `docs/devops/postgres-ha-patroni-book/_companion/ansible/lab-b-a/` with roles/patroni, roles/etcd, roles/watchdog subdirectories
- [x] T004 [P] Create `docs/devops/postgres-ha-patroni-book/_companion/patroni/`, `dashboards/`, `dashboards/alerts/`, `agents/`, `chaos/` directories
- [x] T005 [P] Create a Makefile template in `.specify/templates/lab-Makefile` with setup, break, verify, recover, teardown targets (per contracts/lab-outputs.md)
- [x] T006 Add `.github/workflows/companion-ci.yml` with matrix for docker-labs, terraform-validate, agent-scaffolds, dashboards-and-alerts (per contracts/ci-contract.md)
- [x] T007 [P] Add `.env.example` files to all lab directories showing required variables without real values

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Shared components that all labs and artifacts depend on. ⚠️ No story work begins until this phase is complete.

- [ ] T008 Create `docs/devops/postgres-ha-patroni-book/_companion/patroni/config-04-ref.yml` — annotated reference patroni.yml with inline comments for every non-default parameter, sourced from Ch. 04
- [ ] T009 Create shared Docker network and volume patterns in a `docs/devops/postgres-ha-patroni-book/_companion/docker/common/` directory for reuse across Docker labs (base Postgres image tag, healthcheck patterns)
- [ ] T010 Create `docs/devops/postgres-ha-patroni-book/_companion/chaos/chaos-03-a.sh` — leader kill script with guardrails preventing accidental execution in production
- [ ] T011 [P] Create `docs/devops/postgres-ha-patroni-book/_companion/agents/shared/` with common lifecycle module implementing the 6-state action lifecycle (observed → proposed → dry-run → approved → executed → verified) with audit logging

**Checkpoint**: Foundation ready — shared patroni.yml, chaos script, and agent lifecycle module exist. Docker labs can now begin.

---

## Phase 3: User Story 1 — Reader Runs Core Deployment Lab (Priority: P1) 🎯 MVP

**Goal**: A reader can deploy a 3-node Patroni + etcd cluster, kill the leader, observe automatic failover, and tear down — all from a single `make setup` command.

**Independent Test**: Run `make setup && make break && make verify && make recover && make teardown` in `docker/lab-03-a/` and assert exit 0 at each step with cluster healthy after recovery.

- [ ] T012 [P] [US1] Create `docs/devops/postgres-ha-patroni-book/_companion/docker/lab-03-a/docker-compose.yml` — 3-node Patroni + 3-node etcd with healthchecks and isolated network
- [ ] T013 [P] [US1] Create `docs/devops/postgres-ha-patroni-book/_companion/docker/lab-03-a/patroni.yml` — cluster configuration derived from Ch. 03 (TTL=30, loop_wait=10, etcd endpoints)
- [ ] T014 [P] [US1] Create `docs/devops/postgres-ha-patroni-book/_companion/docker/lab-03-a/etcd.yml` — etcd cluster configuration (3-node, client port 2379, peer port 2380)
- [ ] T015 [US1] Create `docs/devops/postgres-ha-patroni-book/_companion/docker/lab-03-a/Makefile` with setup, break, verify, recover, teardown targets matching the lab structure contract
- [ ] T016 [US1] Create `docs/devops/postgres-ha-patroni-book/_companion/docker/lab-03-a/README.md` — prerequisites, step-by-step guide, expected output, troubleshooting
- [ ] T017 [US1] CI test: Add `lab-03-a` to the GitHub Actions matrix and verify the lab passes end-to-end in CI

**Checkpoint**: LAB-03-A is runnable end-to-end. A reader can deploy, break, verify failover, recover, and teardown successfully.

---

## Phase 4: User Story 2 — Reader Validates Backup/DR Design (Priority: P1)

**Goal**: A reader can run pgBackRest PITR (LAB-08-A) and cross-region restore (LAB-08-B) to empirically measure RTO/RPO.

**Independent Test**: LAB-08-A passes setup → backup → PITR → verify → teardown. LAB-08-B passes `terraform validate` and `terraform plan`.

### LAB-08-A (Docker — PITR)

- [ ] T018 [P] [US2] Create `docs/devops/postgres-ha-patroni-book/_companion/docker/lab-08-a/docker-compose.yml` — 3-node Patroni + etcd + pgBackRest sidecar container
- [ ] T019 [P] [US2] Create `docs/devops/postgres-ha-patroni-book/_companion/docker/lab-08-a/pgbackrest.conf` — repository configuration for local backup storage (S3-compatible minio for local testing)
- [ ] T020 [P] [US2] Create `docs/devops/postgres-ha-patroni-book/_companion/docker/lab-08-a/patroni.yml` — Patroni config with archive_command pointing to pgBackRest
- [ ] T021 [US2] Create `docs/devops/postgres-ha-patroni-book/_companion/docker/lab-08-a/Makefile` with setup, full-backup, incremental-backup, pitr-restore, verify, teardown targets
- [ ] T022 [US2] Create `docs/devops/postgres-ha-patroni-book/_companion/docker/lab-08-a/README.md` — step-by-step guide for full, incremental, and PITR operations

### LAB-08-B (Terraform — Cross-Region)

- [ ] T023 [P] [US2] Create `docs/devops/postgres-ha-patroni-book/_companion/terraform/lab-08-b/modules/aws/main.tf` — AWS VPC, EC2 instances, S3 bucket for backups
- [ ] T024 [P] [US2] Create `docs/devops/postgres-ha-patroni-book/_companion/terraform/lab-08-b/modules/gcp/main.tf` — GCP VPC, Compute Engine instances, Cloud Storage bucket for backups
- [ ] T025 [P] [US2] Create `docs/devops/postgres-ha-patroni-book/_companion/terraform/lab-08-b/variables.tf` — cloud provider selection, region, instance type, credentials path
- [ ] T026 [US2] Create `docs/devops/postgres-ha-patroni-book/_companion/terraform/lab-08-b/main.tf` — top-level module that calls either aws or gcp based on provider variable
- [ ] T027 [US2] Create `docs/devops/postgres-ha-patroni-book/_companion/terraform/lab-08-b/Makefile` with setup (terraform apply), validate (terraform plan), and teardown (terraform destroy) targets
- [ ] T028 [US2] Create `docs/devops/postgres-ha-patroni-book/_companion/terraform/lab-08-b/README.md` — prerequisites (cloud credentials), provider selection guide, cross-region restore steps
- [ ] T029 [US2] CI test: Add LAB-08-A to GitHub Actions matrix; add LAB-08-B terraform validate to CI

**Checkpoint**: Both backup/DR labs are runnable. LAB-08-A demonstrates PITR. LAB-08-B validates cross-region infrastructure.

---

## Phase 5: User Story 3 — SRE Imports Observability Stack (Priority: P2)

**Goal**: An SRE can import reference Grafana dashboards and Prometheus alert rules and verify they fire correctly.

**Independent Test**: Import DASH-06-CORE and DASH-06-LAG into Grafana; apply all ALERT-06-* rules to Prometheus; verify each alert fires when simulated.

- [ ] T030 [P] [US3] Create `docs/devops/postgres-ha-patroni-book/_companion/dashboards/dash-06-core.json` — Grafana dashboard with panels: leader status, node count, DCS connectivity, timeline history, replication lag overview. Source: Ch. 06 signals matrix.
- [ ] T031 [P] [US3] Create `docs/devops/postgres-ha-patroni-book/_companion/dashboards/dash-06-lag.json` — Grafana dashboard with panels: replication lag heatmap, slot lag, WAL generation rate, replay lag per replica. Source: Ch. 06 signals matrix.
- [ ] T032 [P] [US3] Create `docs/devops/postgres-ha-patroni-book/_companion/dashboards/alerts/alert-06-lag.yaml` — Prometheus rule with PromQL from Ch. 06, threshold, severity, runbook annotation
- [ ] T033 [P] [US3] Create `docs/devops/postgres-ha-patroni-book/_companion/dashboards/alerts/alert-06-leader-flap.yaml` — Prometheus rule with PromQL from Ch. 06
- [ ] T034 [P] [US3] Create `docs/devops/postgres-ha-patroni-book/_companion/dashboards/alerts/alert-06-wal-bloat.yaml` — Prometheus rule with PromQL from Ch. 06
- [ ] T035 [P] [US3] Create `docs/devops/postgres-ha-patroni-book/_companion/dashboards/alerts/alert-06-dcs-partition.yaml` — Prometheus rule with PromQL from Ch. 06
- [ ] T036 [P] [US3] Create `docs/devops/postgres-ha-patroni-book/_companion/dashboards/alerts/alert-06-cert-expiry.yaml` — Prometheus rule with PromQL from Ch. 06
- [ ] T037 [US3] Create `docs/devops/postgres-ha-patroni-book/_companion/dashboards/README.md` — import instructions for Grafana and Prometheus
- [ ] T038 [US3] CI test: Add dashboards-and-alerts validation to GitHub Actions (JSON parseable, YAML parseable, promtool syntax check if available)

**Checkpoint**: Dashboards import cleanly. Alert rules evaluate without syntax errors. All artifacts match Chapter 06's signals matrix.

---

## Phase 6: User Story 4 — Platform Engineer Evaluates Agentic AI Scaffolds (Priority: P2)

**Goal**: A platform engineer can install each agent scaffold, run it in dry-run mode, and verify the 6-state lifecycle and safety guardrails.

**Independent Test**: Install each agent with `pip install -e .`, run in dry-run mode, verify exit 0 and dry-run output. Inspect source to confirm lifecycle implementation.

- [ ] T039 [P] [US4] Create `docs/devops/postgres-ha-patroni-book/_companion/agents/monitoring/pyproject.toml` — Python package with pydantic-ai and litellm dependencies
- [ ] T040 [P] [US4] Create `docs/devops/postgres-ha-patroni-book/_companion/agents/monitoring/src/agent_mon/lifecycle.py` — 6-state lifecycle implementation with audit logging
- [ ] T041 [P] [US4] Create `docs/devops/postgres-ha-patroni-book/_companion/agents/monitoring/src/agent_mon/main.py` — AGENT-11-MON workflow: correlates signals, generates incident summaries, proposes severity. Defaults to dry-run.
- [ ] T042 [P] [US4] Create `docs/devops/postgres-ha-patroni-book/_companion/agents/predictive-failover/src/agent_pf/main.py` — AGENT-11-PF: detects leading indicators, proposes preemptive switchover
- [ ] T043 [P] [US4] Create `docs/devops/postgres-ha-patroni-book/_companion/agents/self-tuning/src/agent_st/main.py` — AGENT-11-ST: analyzes workload, proposes parameter adjustments
- [ ] T044 [P] [US4] Create `docs/devops/postgres-ha-patroni-book/_companion/agents/auto-remediation/src/agent_ar/main.py` — AGENT-11-AR: detects dead slots, blocking queries, stuck WAL senders; proposes recovery actions. Blast-radius containment enforced.
- [ ] T045 [P] [US4] Create `docs/devops/postgres-ha-patroni-book/_companion/agents/nl-ops/src/agent_nl/main.py` — AGENT-11-NL: answers natural language questions grounded in cluster telemetry
- [ ] T046 [US4] Create `docs/devops/postgres-ha-patroni-book/_companion/agents/shared/litellm-config.yaml` — model provider configuration template (OpenAI, Anthropic, Bedrock, local)
- [ ] T047 [US4] Create `docs/devops/postgres-ha-patroni-book/_companion/agents/README.md` — installation, dry-run usage, provider configuration, safety checklist
- [ ] T048 [US4] CI test: Add agent-scaffolds validation to GitHub Actions (pip install each, run dry-run mode, verify exit 0)

**Checkpoint**: All 5 agent scaffolds install cleanly and run in dry-run mode. The 6-state lifecycle is implemented in every scaffold. Manual-equivalent runbook references are present.

---

## Phase 7: User Story 5 — Reader Upgrades Python Runtime (Priority: P3)

**Goal**: A reader can practice a rolling Python runtime upgrade (3.8 → 3.12) using the side-by-side venv swap pattern.

**Independent Test**: Run LAB-A-A end-to-end, upgrade Python on one node at a time, verify cluster remains healthy with no split-brain.

- [ ] T049 [P] [US5] Create `docs/devops/postgres-ha-patroni-book/_companion/docker/lab-a-a/docker-compose.yml` — 3-node Patroni with Python 3.8 venv initially
- [ ] T050 [P] [US5] Create `docs/devops/postgres-ha-patroni-book/_companion/docker/lab-a-a/upgrade.sh` — side-by-side venv swap script: install Python 3.12, create new venv, symlink swap, rollback path
- [ ] T051 [US5] Create `docs/devops/postgres-ha-patroni-book/_companion/docker/lab-a-a/Makefile` with setup, upgrade-node-1, upgrade-node-2, upgrade-node-3, verify, rollback, teardown targets
- [ ] T052 [US5] Create `docs/devops/postgres-ha-patroni-book/_companion/docker/lab-a-a/README.md` — rolling upgrade procedure, rollback instructions, Python-version-as-metric-label hook
- [ ] T053 [US5] CI test: Add LAB-A-A to GitHub Actions matrix

**Checkpoint**: LAB-A-A demonstrates the venv swap pattern. Python version upgrade is verifiable per node.

---

## Phase 8: User Story 6 — Reader Observes Watchdog Behavior (Priority: P3)

**Goal**: A reader can witness the watchdog/lease pathology: partition leader from DCS, observe TTL expiry, watchdog fire, replica promotion, no split-brain.

**Independent Test**: Run LAB-B-A on Proxmox LXC or bare VMs, induce leader-to-DCS partition, observe complete sequence.

- [ ] T054 [P] [US6] Create `docs/devops/postgres-ha-patroni-book/_companion/ansible/lab-b-a/roles/watchdog/tasks/main.yml` — enable softdog kernel module, configure Patroni watchdog settings
- [ ] T055 [P] [US6] Create `docs/devops/postgres-ha-patroni-book/_companion/ansible/lab-b-a/roles/patroni/tasks/main.yml` — install Patroni, configure patroni.yml with watchdog.mode=required
- [ ] T056 [P] [US6] Create `docs/devops/postgres-ha-patroni-book/_companion/ansible/lab-b-a/roles/etcd/tasks/main.yml` — install etcd, configure 3-node cluster
- [ ] T057 [US6] Create `docs/devops/postgres-ha-patroni-book/_companion/ansible/lab-b-a/playbook.yml` — orchestrates etcd → patroni → watchdog roles
- [ ] T058 [US6] Create `docs/devops/postgres-ha-patroni-book/_companion/ansible/lab-b-a/inventory.ini` — template inventory with 3-node layout
- [ ] T059 [US6] Create `docs/devops/postgres-ha-patroni-book/_companion/ansible/lab-b-a/Makefile` with setup (ansible-playbook), break (iptables partition script), verify (patronictl + dmesg checks), recover (restore network), teardown (ansible cleanup) targets
- [ ] T060 [US6] Create `docs/devops/postgres-ha-patroni-book/_companion/ansible/lab-b-a/README.md` — prerequisites (Proxmox LXC or bare VMs, root access), setup, partition procedure, expected timeline, verification commands
- [ ] T061 [US6] Create `docs/devops/postgres-ha-patroni-book/_companion/ansible/lab-b-a/break.sh` — iptables script to partition leader from etcd only (not replicas)

**Checkpoint**: LAB-B-A playbook deploys a watchdog-enabled cluster. The break script induces the partition. Verification confirms watchdog fires and replica promotes without split-brain.

---

## Phase 9: Polish & Cross-Cutting Concerns

**Purpose**: CI hardening, documentation, drift detection, and final validation.

- [ ] T062 [P] Verify every artifact ID in `_companion-links.json` resolves to an existing file in `_companion/`
- [ ] T063 [P] Verify every Makefile target across all labs follows the lab-outputs contract (setup, break, verify, recover, teardown with timestamped output)
- [ ] T064 [P] Verify `.env` is gitignored in all lab directories and `.env.example` is present and committed
- [ ] T065 [P] Verify no secrets (AWS keys, GCP service account JSON, passwords) are committed in any companion code file
- [ ] T066 [P] Verify all Docker Compose files use pinned image tags (not `latest`) for reproducibility
- [ ] T067 Run quickstart.md validation: follow the quickstart steps on a clean environment and capture output
- [ ] T068 Verify `docusaurus.config.js` still excludes `**/_companion/**` and the build passes
- [ ] T069 [P] Update `_companion/README.md` with final directory structure and quick reference table
- [ ] T070 [P] Add CI badge to `_companion/README.md` showing companion-ci workflow status

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (P1)**: No deps; immediately
- **Foundational (P2)**: depends on Setup; blocks all lab/agent work
- **US1 (P3)**: depends on Foundational; MVP slice (LAB-03-A)
- **US2 (P4)**: depends on Foundational; can run in parallel with US1 but LAB-08-A needs LAB-03-A's docker patterns
- **US3 (P5)**: depends on Foundational; dashboards and alerts are independent files
- **US4 (P6)**: depends on Foundational + shared lifecycle module (T011)
- **US5 (P7)**: depends on Foundational; LAB-A-A is independent
- **US6 (P8)**: depends on Foundational; LAB-B-A is independent
- **Polish (P9)**: depends on all desired user stories being complete

### Within Each User Story

- Docker labs: docker-compose.yml → patroni.yml → Makefile → README → CI
- Terraform labs: modules → main.tf → variables.tf → Makefile → README → CI
- Ansible labs: roles → playbook.yml → inventory → Makefile → README
- Dashboards: JSON/YAML files → README → CI validation
- Agents: pyproject.toml → lifecycle.py → main.py → README → CI

### Parallel Opportunities

- Setup tasks T001–T004 can run in parallel
- Foundational tasks T008–T011 can run in parallel
- US1 and US2 docker-compose.yml files (T012, T018) can be drafted in parallel
- US3 dashboard JSON files (T030–T036) can all be created in parallel
- US4 agent main.py files (T041–T045) can be drafted in parallel after T010 (lifecycle module)
- US5 and US6 labs (T049–T052, T054–T058) can be drafted in parallel
- Polish tasks T062–T070 can run in parallel

---

## Parallel Example: User Story 1

```bash
# Once Foundational phase is complete, launch US1 tasks together:
Task: "Create docker-compose.yml for LAB-03-A"
Task: "Create patroni.yml for LAB-03-A"
Task: "Create etcd.yml for LAB-03-A"

# Then:
Task: "Create Makefile for LAB-03-A (depends on compose files)"
Task: "Create README for LAB-03-A (depends on compose files)"

# Finally:
Task: "Add LAB-03-A to CI matrix"
```

---

## Implementation Strategy

### MVP First (US1 only)

1. Phase 1: Setup (T001–T007)
2. Phase 2: Foundational (T008–T011)
3. Phase 3: US1 — LAB-03-A (T012–T017)
4. **STOP and VALIDATE**: A reader can deploy LAB-03-A on a clean machine and observe failover end-to-end (SC-001).
5. Ship the MVP — companion code has one runnable lab.

### Incremental Delivery

1. MVP (LAB-03-A) →
2. US2 — Backup/DR labs (T018–T029) →
3. US3 — Observability stack (T030–T038) →
4. US4 — Agent scaffolds (T039–T048) →
5. US5 — Python runtime upgrade (T049–T053) →
6. US6 — Watchdog pathology (T054–T061) →
7. Polish (T062–T070)

### Parallel Team Strategy

After Phase 2:

- Author A: US1 (LAB-03-A) → US5 (LAB-A-A)
- Author B: US2 (LAB-08-A/B) → US6 (LAB-B-A)
- Author C: US3 (dashboards + alerts) → US4 (agent scaffolds)
- Editor: runs CI validation, coordinates artifact ID registry

---

## Notes

- This is an infrastructure-as-code + reference implementation project; no application-level unit tests.
- CI is the primary validation mechanism: every lab MUST pass end-to-end in GitHub Actions.
- The book prose in `docs/devops/postgres-ha-patroni-book/*.mdx` is the source of truth for all configs, commands, and thresholds.
- Every artifact ID MUST resolve in `_companion-links.json` and `_companion/ARTIFACT-IDS.md`.
- Commit after each task or logical group; the `after_tasks` hook offers optional auto-commit.
