# Implementation Plan: Mastering PostgreSQL HA with Patroni (2026 Edition)

**Branch**: `001-postgres-ha-patroni-book` | **Date**: 2026-05-18 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/001-postgres-ha-patroni-book/spec.md`

## Summary

Author a senior-practitioner reference book on Postgres HA with Patroni, published as a section of the existing Docusaurus blog under `docs/devops/postgres-ha-patroni-book/`, with all hands-on lab code, IaC, dashboards, and AI-agent reference integrations living in a **separate companion GitHub repository** referenced from the prose by stable artifact IDs (e.g., `LAB-03-A`). Web is the primary output; PDF/EPUB is a deferred secondary build via Pandoc. Diagrams are Mermaid for sequence/flow/state and Excalidraw (source + exported SVG) for architecture. Labs ship two tiers: local (Docker Compose + kind) and cloud-portable (Terraform/Ansible across AWS/GCP/Azure). CI lints prose in this repo; companion repo runs lab smoke tests (3-node Patroni → induced failover → assert promotion) on PR. The agentic AI chapter uses a model-agnostic agent layer with explicit guardrails and a documented manual fallback per workflow (FR-019).

## Technical Context

**Language/Version**: Markdown / MDX authored against Docusaurus 3.x (existing site); companion code is reader-runnable, not maintained in this repo.

**Primary Dependencies (book site)**: Docusaurus 3.x (already configured), `@docusaurus/theme-mermaid` for Mermaid, Excalidraw for source-form architecture diagrams (committed `.excalidraw` + exported `.svg`). No new runtime deps beyond what the blog already uses.

**Primary Dependencies (companion repo, external)**: **Postgres 18.x (current baseline)** with **17.x as N-1**, **latest stable Patroni** (4.x line; track upstream tags at publication time and pin in companion repo's `ARTIFACT-IDS.md`), etcd 3.5.x, Consul 1.18+, Kubernetes 1.31+ (kind/k3d for local), Terraform ≥1.7 modules for AWS/GCP/Azure, Ansible ≥2.16 roles, `pgBackRest` + `WAL-G` for backup, Prometheus + Grafana + Loki + `postgres_exporter` for observability, `pumba` / `kubectl-chaos` for fault injection, `pydantic-ai` + `litellm` as the model-agnostic agent reference layer. **Lab substrates are deliberately flexible**: each lab MUST work on at least one of {Proxmox LXC, plain Docker / Docker Compose, kind/k3d, bare VMs via Terraform/Ansible}, and the lab declares which substrates it supports in its header.

**Storage**: N/A for the book itself (static site). Companion labs use Postgres; book stores prose, diagrams, and chapter metadata as files in git.

**Testing**:
- Book site: `vale` (prose lint), `markdown-link-check` (link integrity), `cspell` (spelling), Docusaurus build (`onBrokenLinks: 'throw'` already enforced).
- Companion repo (out of scope for this plan's CI but referenced by it): GitHub Actions matrix per chapter — spin up kind cluster, deploy Patroni via Helm/Ansible, induce documented failure, assert promotion, capture RTO/RPO into a fixtures file checked against the chapter's stated bounds.

**Target Platform**: Web (GitHub Pages, served from `ivishalgandhi.github.io`); PDF/EPUB deferred.

**Project Type**: Documentation site (existing Docusaurus blog) + external companion code repo.

**Performance Goals**: Book site build < 60s; reader-perceived page load < 1s on broadband (Docusaurus default budget); lab "leader-kill → promotion verified" demonstrable in under 10 minutes for the P1 lab.

**Constraints**:
- Must not regress the existing blog's build (`onBrokenLinks: 'throw'`).
- Prose must reference companion artifacts by **stable IDs**, never by line numbers or commit SHAs in body text, so drift is detectable (FR-010).
- Version-support window: 12 months from publication; matrix-tested against N (Postgres 18.x) and N-1 (Postgres 17.x), latest stable Patroni at publication time (FR-011).
- Hybrid/multi-cloud + on-prem: every lab MUST list ≥1 working substrate from {Proxmox LXC, Docker/Compose, kind/k3d, bare VMs via Terraform/Ansible across ≥2 of AWS/GCP/Azure}; cloud labs MUST cover ≥2 of {AWS, GCP, Azure} or be marked on-prem-only with rationale.
- AI chapter degrades gracefully: every agent workflow has a documented manual equivalent (FR-019).

**Scale/Scope**: 11 chapters (12th optional as case-study compendium) + 2 appendices (A: Patroni Python runtime mgmt 3.6 → 3.12 migration; B: Patroni internals deep-dive — state machine, leader election, watchdog, DCS leases), ~80–130 pages prose-equivalent, ~10–16 distinct labs (incl. `LAB-A-A` Python rolling-upgrade, `LAB-B-A` watchdog/lease failure-mode exploration), ~7–10 Mermaid + ~6–8 Excalidraw diagrams, ~5–8 reusable Grafana dashboards. Appendices do not count toward the spec's 10–12 chapter cap (FR-001). All book pages are authored in `.mdx` so the `<ArtifactRef />` MDX component renders cleanly.

## Constitution Check

*GATE: Passed before Phase 0; re-checked post-Phase 1 below.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Spec-Driven Development (NON-NEGOTIABLE) | ✅ | Spec exists at `specs/001-postgres-ha-patroni-book/spec.md`; this plan is the canonical "how". |
| II. Specs Are Technology-Agnostic | ✅ | The spec names technologies only as **content topics of the book**, not as implementation choices for delivering the book. This plan is where stack choices live. |
| III. Simplicity First | ✅ | Web-only output for v1; PDF/EPUB deferred. No new site infrastructure — reuse the existing Docusaurus blog. Companion code lives in a separate repo to keep this repo focused. |
| IV. Surgical Changes | ✅ | All book prose confined to `docs/devops/postgres-ha-patroni-book/`. AGENTS.md plan reference updated in-place between SPECKIT markers. No edits to unrelated chapters. |
| V. Think Before Coding | ✅ | All 8 reader-flagged decisions resolved in research.md with rationales and rejected alternatives. |
| VI. Goal-Driven Execution | ✅ | Each chapter has measurable success criteria inherited from spec SC-001..SC-008. |
| VII. Security & Zero-Trust by Default | ✅ | Agentic AI chapter mandates guardrails, dry-run mode, manual fallback, and blast-radius controls. Lab credentials use placeholders + `.env.example` only. |
| VIII. Observability & Reproducibility | ✅ | Every troubleshooting playbook is traceable to ≥1 observability signal (FR-014); every lab is reproducible from companion repo with stated version pins. |

**Result**: No violations. Proceed to Phase 0.

## Project Structure

### Documentation (this feature)

```text
specs/001-postgres-ha-patroni-book/
├── plan.md              # This file
├── spec.md              # Feature specification
├── research.md          # Phase 0: 8 decisions resolved
├── data-model.md        # Phase 1: entity → file mapping
├── quickstart.md        # Phase 1: how to author a chapter
├── contracts/
│   ├── chapter-frontmatter.schema.json
│   ├── artifact-id.md           # Stable ID format for companion artifacts
│   └── lab-structure.md         # Required sections inside a lab
├── checklists/
│   └── requirements.md  # Already exists (passed validation)
└── tasks.md             # Phase 2 — created by /speckit-tasks
```

### Book Content (under existing Docusaurus site)

```text
docs/devops/postgres-ha-patroni-book/
├── _category_.json                       # Docusaurus category (label, position)
├── index.mdx                             # Book landing page, audience, non-goals, how to use
├── 00-preface.mdx                        # Audience, prerequisites, conventions, version-support window
├── 01-foundations-postgres-ha.mdx
├── 02-patroni-architecture-dcs.mdx
├── 03-deploying-patroni-cluster.mdx      # Anchors P1 lab (LAB-03-A)
├── 04-configuration-best-practices.mdx
├── 05-performance-tuning-ha.mdx
├── 06-observability-monitoring.mdx
├── 07-troubleshooting-playbooks.mdx
├── 08-backup-dr-pitr.mdx
├── 09-zero-downtime-operations.mdx
├── 10-geo-distributed-patroni.mdx
├── 11-agentic-ai-autonomous-ops.mdx
├── 12-case-studies-anti-patterns.mdx     # Optional 12th chapter
├── appendix-a-python-runtime.mdx         # Patroni Python runtime mgmt (3.6 → 3.12 migration)
├── appendix-b-patroni-internals.mdx      # Patroni internals deep-dive (state machine, election, watchdog, DCS leases)
└── _diagrams/                            # Shared diagrams; per-chapter `_diagrams/` allowed too
    ├── mermaid/
    └── excalidraw/                       # .excalidraw source + exported .svg
```

### Companion Repository (separate GitHub repo, referenced by stable IDs)

```text
postgres-ha-patroni-companion/            # NOT in this repo
├── README.md
├── ARTIFACT-IDS.md                       # Canonical registry, e.g. LAB-03-A → terraform/lab-03-a/
├── terraform/
│   └── lab-NN-X/{aws,gcp,azure}/
├── ansible/
│   └── roles/{patroni,etcd,consul,pgbackrest,wal-g,observability}/
├── docker/
│   └── lab-NN-X/                         # docker-compose for local-tier labs
├── k8s/
│   └── lab-NN-X/                         # manifests + kind/k3d scripts
├── patroni/                              # Reference patroni.yml per topology
├── dashboards/                           # Grafana JSON
├── chaos/                                # "break it on purpose" scripts (pumba, kubectl-chaos)
├── agents/                               # 2026 Agentic AI reference integrations
│   ├── monitoring/
│   ├── predictive-failover/
│   ├── self-tuning/
│   ├── auto-remediation/
│   └── nl-ops/
└── .github/workflows/                    # Lab smoke tests, version matrix
```

**Structure Decision**: **Hybrid — book prose in this Docusaurus repo under `docs/devops/postgres-ha-patroni-book/`; all runnable code in a separate `postgres-ha-patroni-companion` GitHub repo.** Rationale: keeps the blog repo lightweight (no Terraform/K8s artifacts polluting prose history), aligns with FR-009 ("companion GitHub repository"), and lets companion CI run heavy lab smoke tests without slowing blog builds. Stable artifact IDs (e.g., `LAB-03-A`, `AGENT-11-PF`) registered in `ARTIFACT-IDS.md` provide the drift-detection seam required by FR-010.

## Complexity Tracking

> No constitution violations to justify. Table intentionally empty.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| — | — | — |

## Phase 0 Output

See [`research.md`](./research.md). All 8 decisions resolved; no remaining `NEEDS CLARIFICATION`.

## Phase 1 Outputs

- [`data-model.md`](./data-model.md) — Entities → on-disk file layout.
- [`contracts/chapter-frontmatter.schema.json`](./contracts/chapter-frontmatter.schema.json) — Required Docusaurus frontmatter.
- [`contracts/artifact-id.md`](./contracts/artifact-id.md) — Stable artifact ID format (`LAB-NN-X`, `AGENT-NN-X`, `DASH-NN-X`).
- [`contracts/lab-structure.md`](./contracts/lab-structure.md) — Required sections inside any lab section in any chapter.
- [`quickstart.md`](./quickstart.md) — How to author/preview/build a chapter, lint, and add a diagram.
- `AGENTS.md` updated between `<!-- SPECKIT START -->` markers to point at this plan.

## Post-Design Constitution Re-Check

Re-evaluated after Phase 1 artifacts written:

- No new dependencies added beyond existing Docusaurus + Mermaid theme (already in site config).
- All chosen tech remains in `plan.md` only; `spec.md` remains tech-agnostic (Principle II preserved).
- Companion repo split keeps Principle IV (surgical changes) intact — heavy lab artifacts never enter the blog repo.

**Result**: Constitution Check still passes post-design. Ready for `/speckit-tasks`.
