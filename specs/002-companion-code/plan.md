# Implementation Plan: Patroni HA Book Companion Code

**Branch**: `001-postgres-ha-patroni-book` | **Date**: 2026-05-18 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/002-companion-code/spec.md`

## Summary

Implement runnable companion code for the "Mastering PostgreSQL High Availability with Patroni (2026 Edition)" book. The companion code lives under `docs/devops/postgres-ha-patroni-book/_companion/` in the same repo as the book prose. It consists of 5 hands-on labs (Docker Compose, Terraform, Ansible), 1 reference config (annotated patroni.yml), 2 Grafana dashboards, 5 Prometheus alert rules, 5 Python agent scaffolds (pydantic-ai + litellm), and 1 chaos script. Every artifact is referenced by a stable ID from the book prose via the `<ArtifactRef />` MDX component. The source of truth for each artifact's behavior is the corresponding book chapter.

## Technical Context

**Language/Version**: Docker Compose v2, Terraform ≥1.7, Ansible ≥2.16, Python 3.12, Bash 5.x

**Primary Dependencies**:
- Docker Engine ≥24.x + Docker Compose v2 (all Docker-based labs)
- PostgreSQL 18.x (default) / 17.x (N-1) Docker images
- Patroni 4.x (latest stable at publication time)
- etcd 3.5.x Docker image (for DCS)
- pgBackRest 2.51+ Docker image (backup/DR labs)
- Terraform AWS provider ≥5.x, GCP provider ≥5.x (LAB-08-B)
- pydantic-ai ≥0.25 + litellm ≥1.40 (agent scaffolds)
- Prometheus ≥2.50 + Grafana ≥10.4 (observability stack)

**Storage**: N/A for this feature (companion code is files in git). Labs use ephemeral Docker volumes.

**Testing**: GitHub Actions matrix — spin up each Docker lab, run setup → break → verify → recover → teardown, assert exit 0. Terraform labs validate only (`terraform plan`, no `apply` in CI).

**Target Platform**: Linux (Ubuntu 22.04+ recommended). Docker-based labs run on any OS with Docker Desktop or Docker Engine. Terraform labs require cloud credentials. Ansible labs require SSH access to target hosts.

**Project Type**: Infrastructure-as-code + reference implementations (not a deployable service).

**Performance Goals**: LAB-03-A deploys in under 5 minutes on a machine with 8GB RAM. Full CI pipeline (all Docker labs) completes in under 15 minutes.

**Constraints**:
- Must not break the existing Docusaurus build (`_companion/` is excluded from rendering).
- All Docker labs must run on a single machine with 8GB RAM / 4 CPU cores.
- Terraform labs must not apply in CI (cost + security); only `terraform validate` and `terraform plan`.
- Agent scaffolds must default to dry-run mode; destructive actions require explicit opt-in.
- Secrets (cloud credentials, API keys) must never be committed; use `.env.example` + `.env` pattern.

**Scale/Scope**:
- 5 labs across 3 substrate types (Docker, Terraform, Ansible)
- 13 artifacts total (5 labs + 1 config + 2 dashboards + 5 alerts + 1 chaos script + 5 agent scaffolds)
- ~50–70 files total across all directories
- Companion code is not a runtime service; it is invoked by readers on-demand

## Constitution Check

*GATE: Passed before Phase 0; re-checked post-Phase 1 below.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Spec-Driven Development (NON-NEGOTIABLE) | ✅ | Spec exists at `specs/002-companion-code/spec.md`; this plan is the canonical "how". |
| II. Specs Are Technology-Agnostic | ✅ | The spec names capabilities ("Docker Compose lab", "Terraform module") rather than implementation choices; this plan names the specific tools. |
| III. Simplicity First | ✅ | Each lab is a self-contained directory with a single entry point (`docker compose up`, `terraform apply`, `ansible-playbook`). No shared library abstractions across labs. |
| IV. Surgical Changes | ✅ | All companion code is confined to `docs/devops/postgres-ha-patroni-book/_companion/`. No edits to unrelated book chapters or site infrastructure. |
| V. Think Before Coding | ✅ | The source of truth for every config and command is the corresponding book chapter. No assumptions about reader environment beyond what is stated in prerequisites. |
| VI. Goal-Driven Execution | ✅ | Every lab has measurable success criteria (deploy time, failover time, teardown completeness). CI validates each. |
| VII. Security & Zero-Trust by Default | ✅ | No secrets in repo; `.env.example` pattern. Agent scaffolds require explicit opt-in for destructive actions. Docker labs run in isolated Compose networks. |
| VIII. Observability & Reproducibility | ✅ | Every lab has a `Makefile` or script with `setup`, `break`, `verify`, `recover`, `teardown` targets. CI logs are persisted. |

**Result**: No violations. Proceed to Phase 0.

## Project Structure

### Documentation (this feature)

```text
specs/002-companion-code/
├── plan.md              # This file (/speckit-plan command output)
├── research.md          # Phase 0 output (/speckit-plan command)
├── data-model.md        # Phase 1 output (/speckit-plan command)
├── quickstart.md        # Phase 1 output (/speckit-plan command)
├── contracts/           # Phase 1 output (/speckit-plan command)
└── tasks.md             # Phase 2 output (/speckit-tasks command - NOT created by /speckit-plan)
```

### Source Code (repository root)

```text
docs/devops/postgres-ha-patroni-book/_companion/
├── docker/
│   ├── lab-03-a/
│   │   ├── docker-compose.yml
│   │   ├── patroni.yml
│   │   ├── etcd.yml
│   │   ├── Makefile
│   │   └── README.md
│   ├── lab-08-a/
│   │   ├── docker-compose.yml
│   │   ├── patroni.yml
│   │   ├── etcd.yml
│   │   ├── pgbackrest.conf
│   │   ├── Makefile
│   │   └── README.md
│   └── lab-a-a/
│       ├── docker-compose.yml
│       ├── patroni.yml
│       ├── etcd.yml
│       ├── Makefile
│       └── README.md
├── terraform/
│   └── lab-08-b/
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       ├── modules/
│       │   ├── aws/
│       │   └── gcp/
│       ├── Makefile
│       └── README.md
├── ansible/
│   └── lab-b-a/
│       ├── playbook.yml
│       ├── inventory.ini
│       ├── roles/
│       │   ├── patroni/
│       │   ├── etcd/
│       │   └── watchdog/
│       ├── Makefile
│       └── README.md
├── patroni/
│   └── config-04-ref.yml
├── dashboards/
│   ├── dash-06-core.json
│   ├── dash-06-lag.json
│   └── alerts/
│       ├── alert-06-lag.yaml
│       ├── alert-06-leader-flap.yaml
│       ├── alert-06-wal-bloat.yaml
│       ├── alert-06-dcs-partition.yaml
│       └── alert-06-cert-expiry.yaml
├── agents/
│   ├── monitoring/
│   │   ├── pyproject.toml
│   │   ├── src/
│   │   │   └── agent_mon/
│   │   │       ├── __init__.py
│   │   │       ├── lifecycle.py
│   │   │       └── main.py
│   │   └── README.md
│   ├── predictive-failover/
│   │   ├── pyproject.toml
│   │   ├── src/
│   │   │   └── agent_pf/
│   │   │       ├── __init__.py
│   │   │       ├── lifecycle.py
│   │   │       └── main.py
│   │   └── README.md
│   ├── self-tuning/
│   │   ├── pyproject.toml
│   │   ├── src/
│   │   │   └── agent_st/
│   │   │       ├── __init__.py
│   │   │       ├── lifecycle.py
│   │   │       └── main.py
│   │   └── README.md
│   ├── auto-remediation/
│   │   ├── pyproject.toml
│   │   ├── src/
│   │   │   └── agent_ar/
│   │   │       ├── __init__.py
│   │   │       ├── lifecycle.py
│   │   │       └── main.py
│   │   └── README.md
│   └── nl-ops/
│       ├── pyproject.toml
│       ├── src/
│       │   └── agent_nl/
│       │       ├── __init__.py
│       │       ├── lifecycle.py
│       │       └── main.py
│       └── README.md
├── chaos/
│   └── chaos-03-a.sh
├── ARTIFACT-IDS.md
└── README.md
```

**Structure Decision**: The `_companion/` directory is organized by artifact category (docker/, terraform/, ansible/, patroni/, dashboards/, agents/, chaos/). Each lab is self-contained with its own Compose file / Terraform module / Ansible role, Makefile, and README. This keeps labs independent (a reader can run just LAB-03-A without downloading LAB-08-B files) and makes CI parallelization straightforward.

## Complexity Tracking

> No constitution violations. All decisions justified by the spec's user stories and FR-001–FR-015.
