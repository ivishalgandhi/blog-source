# Implementation Plan: Network Partition Testing for PostgreSQL HA

**Branch**: `[003-network-partition-testing]` | **Date**: 2026-05-19 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/003-network-partition-testing/spec.md`

## Summary

Add Chapter 13 to the "Mastering PostgreSQL HA with Patroni (2026 Edition)" book, plus two Docker Compose companion labs (LAB-13-A for 2-node, LAB-13-B for 3-node) that use `iptables` chaos injection to scientifically test and document Patroni behavior under network partitions. The chapter settles the 2-node vs 3-node HA debate with reproducible, evidence-based results.

## Technical Context

**Language/Version**: MDX (Docusaurus 3.x), Docker Compose (v2), Bash 5.x, `iptables` (legacy or nftables backend)

**Primary Dependencies**: Spilo image (`ghcr.io/zalando/spilo-16:3.2-p1`), etcd 3.5, Docker Compose, `iptables` (inside containers)

**Storage**: Docker volumes for PostgreSQL data directories; ephemeral for test data (`partition_test` schema)

**Testing**: Manual execution of `make setup && make break && make verify && make recover && make teardown` for each lab; deterministic outcomes captured in chapter's results table

**Target Platform**: Linux/macOS with Docker Desktop; x86_64 and ARM64 (Spilo multi-arch)

**Project Type**: Technical book chapter + hands-on companion labs (educational infrastructure)

**Performance Goals**: Lab setup completes in under 5 minutes; each break scenario resolves within `ttl` (default 30s) + `loop_wait` (default 10s)

**Constraints**: Must reuse existing book patterns (Spilo image, per-node patroni.yml, standard Makefile targets); must not duplicate LAB-03-A infrastructure unnecessarily

**Scale/Scope**: Single feature (1 chapter + 2 labs); no database scaling concerns; containers run locally on reader's machine

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Spec-Driven Development | PASS | Feature flows through specify → plan → tasks → implement pipeline |
| II. Specs Are Technology-Agnostic | PASS | spec.md uses capability terms ("reverse proxy for chaos", "DCS lease model") without naming Docker/Spilo/iptables |
| III. Simplicity First | PASS | One chapter, two labs, three chaos scripts each. No abstractions beyond what LAB-03-A already established |
| IV. Surgical Changes | PASS | New chapter does not modify existing Chapters 1-12. Labs are new directories, not refactors of LAB-03-A |
| V. Think Before Coding | PASS | All three failure modes scoped upfront; assumptions documented (readers know Chapters 1-3) |
| VI. Goal-Driven Execution | PASS | 4 measurable success criteria; each lab has deterministic pass/fail outcomes |
| VII. Security & Zero-Trust | N/A | No auth changes, no secrets, no ingress changes |
| VIII. Observability & Reproducibility | PASS | `verify.sh` captures patronictl, etcdctl, and checksums; results table is deterministic |

## Project Structure

### Documentation (this feature)

```text
specs/003-network-partition-testing/
├── plan.md              # This file (/speckit-plan command output)
├── research.md          # Phase 0 output (/speckit-plan command)
├── data-model.md        # Phase 1 output (/speckit-plan command)
├── checklists/
│   └── requirements.md  # Spec quality checklist
└── tasks.md             # Phase 2 output (/speckit-tasks command - NOT created by /speckit-plan)
```

### Source Code (repository root)

```text
docs/devops/postgres-ha-patroni-book/
├── 13-network-partition-testing.mdx          # New chapter
├── _companion/
│   ├── docker/lab-13-a/                       # 2-node partition lab
│   │   ├── docker-compose.yml
│   │   ├── patroni-1.yml, patroni-2.yml
│   │   ├── Makefile
│   │   ├── break-clean-stop.sh
│   │   ├── break-full-partition.sh
│   │   ├── break-asymmetric-partition.sh
│   │   ├── recover.sh
│   │   ├── verify.sh
│   │   └── README.md
│   ├── docker/lab-13-b/                       # 3-node partition lab
│   │   ├── docker-compose.yml
│   │   ├── patroni-1.yml, patroni-2.yml, patroni-3.yml
│   │   ├── Makefile
│   │   ├── break-clean-stop.sh
│   │   ├── break-full-partition.sh
│   │   ├── break-asymmetric-partition.sh
│   │   ├── recover.sh
│   │   ├── verify.sh
│   │   └── README.md
│   ├── README.md                               # Updated artifact table
│   └── ARTIFACT-IDS.md                       # Updated artifact IDs
```

**Structure Decision**: The feature extends the existing book structure (feature 001). New chapter follows the same MDX patterns (frontmatter, Mermaid diagrams, admonitions). Labs follow the same `lab-NN-X/` Docker Compose + Makefile pattern established by LAB-03-A. The `_companion-links.json` and `ARTIFACT-IDS.md` receive incremental updates, not rewrites.

## Complexity Tracking

No constitution violations requiring justification. Feature is additive only.
