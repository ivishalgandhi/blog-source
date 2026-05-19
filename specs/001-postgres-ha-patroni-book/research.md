# Phase 0 Research — Decisions

All 8 reader-flagged decisions resolved. No remaining `NEEDS CLARIFICATION`.

---

## D1. Single repo vs split (book + companion)

- **Decision**: Split. Book prose lives in this Docusaurus repo (`docs/devops/postgres-ha-patroni-book/`); all runnable code in a separate GitHub repo `postgres-ha-patroni-companion`.
- **Rationale**: Spec FR-009 explicitly calls for a companion repo. Splitting keeps the blog repo's history focused on prose; companion CI can run heavy lab smoke jobs without slowing blog builds; blog deploys (GitHub Pages) stay unaffected by Terraform/K8s code churn.
- **Alternatives considered**:
  - *Monorepo subdir under blog repo* — rejected: pollutes blog git history with multi-GB lab artifacts and slows blog CI.
  - *Embed companion as git submodule* — rejected: submodules are friction for readers cloning the book and add no value over plain external link references.

## D2. Output formats

- **Decision**: Web-only (Docusaurus) for v1. PDF/EPUB deferred to v2 via Pandoc.
- **Rationale**: Principle III (Simplicity). Web covers ≥90% of the audience (the book is already public via the blog), is searchable, supports Mermaid natively, and avoids the layout maintenance burden of LaTeX/Pandoc templates. Defer PDF/EPUB until there is reader demand.
- **Alternatives considered**:
  - *Pandoc PDF + EPUB from day 1* — rejected: layout/figure handling for Mermaid + Excalidraw in print is non-trivial and gates publication.
  - *Web + Asciidoctor PDF* — rejected: would require dual-source authoring; violates Principle III.

## D3. Diagram tool standard

- **Decision**: **Mermaid** for sequence, flowchart, state, and C4-lite (component) diagrams. **Excalidraw** for cluster/architecture/topology diagrams; commit both the `.excalidraw` source and the exported `.svg`.
- **Rationale**: Mermaid renders directly in Docusaurus via the official theme and stays diffable in PRs. Excalidraw is necessary where the topology has hand-positioned regions/availability-zones that Mermaid can't lay out cleanly; committing both source and SVG keeps the SVG self-rendering even if the Excalidraw editor changes.
- **Alternatives considered**:
  - *Mermaid only* — rejected: produces messy auto-layouts for multi-region topology diagrams.
  - *PlantUML* — rejected: needs a server/Java; adds infra not present in this site.
  - *Hand-drawn / raster only* — rejected: undiffable; fails Principle VIII (reproducibility).

## D4. Lab baseline runtime

- **Decision**: **Flexible substrate model** — each lab declares ≥1 supported substrate from a curated set, instead of mandating a single runtime. Supported substrates:
  1. **Proxmox LXC** — preferred for readers running a homelab; lightweight, fast multi-node Patroni on a single host.
  2. **Docker / Docker Compose** — default for fast, ephemeral, non-K8s labs.
  3. **kind / k3d** — for Kubernetes-operator labs and CI smoke tests.
  4. **Bare VMs via Terraform + Ansible** — for cloud-portable labs spanning ≥2 of {AWS, GCP, Azure} (FR-008).
  Each lab's header lists which substrates it supports. CI smoke-tests the kind substrate by default (cheapest, deterministic); other substrates are reader-runnable but not gated by CI.
- **Rationale**: Spec mandates hybrid/multi-cloud + on-prem (FR-008) and explicit air-gapped readability (edge case). A flexible substrate model lets the same lab serve a homelab reader (Proxmox LXC), a laptop reader (Docker/kind), and an enterprise reader (Terraform + cloud) without three forked codepaths. Patroni itself doesn't care about the substrate — only the network topology and DCS deployment differ — which makes per-lab substrate plurality cheap.
- **Alternatives considered**:
  - *Single mandated substrate (e.g., kind only)* — rejected: blocks homelab/on-prem readers explicitly called out in the spec.
  - *Cloud only* — rejected: blocks air-gapped and cost-sensitive readers; violates FR-008.
  - *Vagrant VMs* — rejected: slower, heavier, declining ecosystem in 2026.
  - *k3d-only for K8s* — kept as an acceptable equivalent to kind in lab docs; kind is the CI default for community standardization.

## D5. CI scope

- **Decision**: **Split CI**.
  - *This (blog) repo*: prose lint (vale), spelling (cspell), link integrity (markdown-link-check), and a full Docusaurus build with `onBrokenLinks: 'throw'` (already configured). No code execution.
  - *Companion repo*: per-PR lab smoke tests via GitHub Actions — for each touched lab, spin up a kind cluster, deploy Patroni, induce the chapter's documented failure, assert the documented promotion behavior, and record measured RTO/RPO into a fixtures file checked against bounds.
- **Rationale**: Prose drift and link rot are caught here without dragging heavy compute into blog CI. Companion CI guarantees FR-007 (reproducibility) and SC-007 ("zero undocumented manual steps") at the source-of-truth for code.
- **Alternatives considered**:
  - *All CI in one repo* — rejected: blog CI would balloon to many minutes per push; bad DX for unrelated blog content.
  - *No CI on companion* — rejected: drift between prose and code would be the most common reader-visible bug; this is the seam FR-010 demands.

## D6. AI agent reference framework + LLM provider abstraction

- **Decision**: **Reference framework: `pydantic-ai`** (model-agnostic, lightweight, typed). **Provider abstraction: `litellm`** so readers can swap among OpenAI/Anthropic/Bedrock/local models without code changes. Every agentic workflow in Chapter 11 ships with:
  1. A documented **guardrail policy** (allowed actions, dry-run mode by default).
  2. A **manual-equivalent runbook** (FR-019) so readers in AI-restricted environments still get value.
  3. A **post-mortem template** for misbehaving-agent scenarios.
- **Rationale**: `pydantic-ai` is small enough that the *patterns* — not the framework — are the lesson, which keeps the chapter relevant if the framework landscape shifts. `litellm` gives provider portability so the book doesn't bake in a single vendor (consistent with non-goal: "no vendor-cloud-only solutions").
- **Alternatives considered**:
  - *LangGraph* — rejected as default: heavier abstraction footprint; reader has to learn LangGraph before learning the actual operations patterns. Mentioned in chapter as a viable alternative.
  - *OpenAI Agents SDK* — rejected as default: vendor-locked surface; mentioned as alternative.
  - *Custom from scratch* — rejected: would dilute the book's focus away from Patroni operations.

## D7. Version pin policy + compatibility window

- **Decision**: **Pinned baseline (2026 publication)**: **Postgres 18.x (N)** with **Postgres 17.x (N-1)**, **latest stable Patroni** at publication (currently 4.x line; exact tag pinned in companion repo `ARTIFACT-IDS.md` so the book never drifts from CI), etcd 3.5.x, Consul 1.18+, Kubernetes 1.31+ on kind 0.24+. **Compatibility window**: 12 months from publication; companion CI runs the version matrix against N (Postgres 18.x) and N-1 (Postgres 17.x) of Postgres and N of Patroni. Each chapter's frontmatter declares its `version_support` block; readers running outside the window are warned in-page.
- **Rationale**: Postgres 18 is the current major line for 2026 publication; pinning to it keeps the book current at launch, and including 17.x as N-1 covers the most common "I'm one major behind" reader scenario. "Latest stable Patroni" rather than a fixed minor avoids the book lying to readers between Patroni's frequent point releases — the companion repo pins the exact tag in CI so reproducibility is preserved (FR-011, SC-007). 12-month window matches Postgres's major-release cadence.
- **Alternatives considered**:
  - *No version pinning* — rejected: makes labs unreproducible.
  - *Pin to a single point version* — rejected: too brittle; readers will hit minor version mismatches constantly.
  - *Test against all minor versions in window* — rejected: CI cost not justified.

## D8. Chapter outline (final 10–12 titles)

- **Decision**: **11 mandatory chapters + 1 optional case-study compendium = 12 total**, fitting the spec's 10–12 chapter range.

| # | Title | Anchor user story | Primary spec FRs covered |
|---|-------|-------------------|--------------------------|
| 00 | Preface — Audience, Conventions, Version Support | — | FR-008, FR-011, FR-017 |
| 01 | Foundations of Postgres HA at Scale | US1 | FR-001, FR-002 |
| 02 | Patroni Architecture & DCS Choices (etcd / Consul / K8s) | US1 | FR-002, FR-004 |
| 03 | Designing & Deploying a Patroni Cluster (P1 lab) | US1 | FR-003, FR-004, FR-012 |
| 04 | Configuration Best Practices | US1 | FR-004 |
| 05 | Performance Tuning Under HA Constraints | US1 | FR-004 |
| 06 | Observability & Monitoring for Patroni Fleets | US2 | FR-004, FR-014 |
| 07 | Troubleshooting Playbooks | US2 | FR-013, FR-014, FR-020 |
| 08 | Backup, DR, and PITR at Enterprise Scale | US4 | FR-004, FR-015 |
| 09 | Zero-Downtime Operations | US2 | FR-004, FR-012, FR-020 |
| 10 | Geo-Distributed Patroni: Quorum, Latency, Sovereignty | US1 | FR-004, FR-016 |
| 11 | Agentic AI for Autonomous Patroni Operations (2026) | US3 | FR-005, FR-019 |
| 12 | Case Studies & Anti-Patterns (FAANG-like composites) — *optional* | US5 | FR-007 |
| A  | **Appendix A** — Managing the Python Runtime for Patroni (legacy 3.6 → 3.12 migration) | US2 | FR-004, FR-013 |
| B  | **Appendix B** — Patroni Internals Deep-Dive (state machine, leader election, watchdog, DCS lease semantics) | US1, US2 | FR-002, FR-013 |

- **Rationale**: Maps every spec user story (US1–US5) and every FR to at least one chapter. Ordering is reading-flow: foundations → architecture → deploy → operate → recover → distribute → automate. The optional Ch. 12 is a "patterns/anti-patterns" compendium so readers who want narrative-style learning have a landing spot without forcing every chapter to repeat case studies.
- **Alternatives considered**:
  - *Merge Ch. 6 + Ch. 7* (observability + troubleshooting) — rejected: spec FR-013 and FR-014 are distinct deliverables; combining hurts referenceability under pressure (US2).
  - *Move Ch. 11 (AI) earlier* — rejected: AI chapter assumes operational foundations; readers must finish Ch. 1–10 to evaluate agent actions critically.
  - *Drop the optional Ch. 12* — kept optional because case studies are P3 (US5) and shouldn't gate publication.
  - *Add Python-runtime content as a chapter* — rejected: would push the count to 13 and break spec FR-001 (10–12 chapters). It also reads as **operational hygiene** rather than core HA design — appendix is the right shape.
  - *Fold Python-runtime content into Ch. 04 (Configuration)* — rejected: would bury a migration topic (3.6 → 3.12) inside a config chapter; readers searching "Python upgrade" wouldn't find it.

### Appendix A — Managing the Python Runtime for Patroni

- **Why it exists**: Patroni is a Python application. Many legacy enterprises still run Patroni on Python 3.6 (or older) inherited from RHEL 7 / Ubuntu 18.04 baselines; the Patroni 4.x line and modern dependency stack require Python 3.9+. A documented runtime-migration path is operationally critical and currently underserved by upstream docs.
- **Coverage**:
  1. Inventory: detecting current Python version per node, virtualenv vs system Python, pip-pinned vs OS-package-managed dependencies, and the Patroni service unit's interpreter path.
  2. Risk matrix: cross-Python-version dependency compatibility (psycopg2/psycopg3, ydiff, urllib3, kazoo, python-etcd), TLS/SSL library changes (`ssl` module hardening across versions), and behavior differences that touch Patroni (`asyncio`, `subprocess`, signal handling).
  3. Migration patterns:
     - *Side-by-side venv swap* (preferred): build Patroni 4.x venv on 3.12, validate against a standby, switch the systemd unit, drain leader, repeat.
     - *Rolling node replacement* (for OS upgrades that bundle the Python bump): pgBackRest-seeded new node, attach as replica, fail over, decommission old.
     - *Containerized cutover* (where the host is frozen): run Patroni in a container with its own Python 3.12 while the host stays on 3.6, with explicit DCS connectivity considerations.
  4. Lab `LAB-A-A` — start a 3-node cluster with Patroni on Python 3.6, perform a rolling 3.12 upgrade, induce a leader failover mid-migration, and verify no split-brain.
  5. Observability hooks: Python version exported as a metric label so the observability chapter (Ch. 06) can alert on "node running unsupported Python".
  6. Anti-patterns: in-place `yum/apt` Python replacement on the live leader, mixing system pip and venv pip, and pinning to EOL Python "because it works".
- **Substrate coverage**: Proxmox LXC, Docker/Compose, and bare VMs via Ansible (kind not relevant — operator pattern uses Patroni's container image and side-steps host Python entirely; appendix says so explicitly).
- **Anchored user story**: US2 (SRE operating an existing fleet).

### Appendix B — Patroni Internals Deep-Dive

- **Why it exists**: Ch. 02 covers Patroni architecture at the level a designer needs to choose a DCS and topology. Ch. 06 covers observability signals. Neither dives into the **internals** that determine *why* a cluster behaves the way it does under stress: the Patroni state machine, the leader-election protocol, the watchdog interaction with systemd / `softdog`, DCS lease semantics (TTL, refresh, loss-of-lease promotion paths), and the precise ordering of `bootstrap`/`replica`/`leader` transitions. Senior DBAs and SREs repeatedly hit production incidents whose root cause is a misread of these internals (e.g., promoting a stale standby because TTL was tuned without understanding the renewal cadence).
- **Coverage**:
  1. **State machine** — full enumeration of Patroni's HA states (`initializing`, `running`, `replica`, `leader`, `paused`, `stopped`, `creating replica`, `pending restart`), the transitions between them, and what each transition writes to the DCS.
  2. **Leader election** — the race semantics in etcd vs Consul vs Kubernetes endpoint mode: who can promote, ordering guarantees, what happens on a partial DCS partition, and why `synchronous_mode_strict` changes the rules.
  3. **Watchdog & fencing** — `softdog` vs hardware watchdog, kernel ordering, what happens when the watchdog fires *after* a successful promotion elsewhere (the "double-leader → fence" path that prevents split-brain).
  4. **DCS lease semantics** — TTL, `loop_wait`, `retry_timeout`, `ttl` interaction, renewal cadence, and the math behind safe tuning (`ttl > loop_wait + retry_timeout * 2 + N` is the rule of thumb; appendix derives why).
  5. **Lab `LAB-B-A`** — *"watchdog and lease pathology"*: induce a network partition isolating the leader from the DCS but not from clients, observe DCS expiry → watchdog fire → standby promotion → original leader self-fences, verify no split-brain occurred. Tools: `iptables`/`tc` for partition, `dmesg` for watchdog trace.
  6. **Observability hooks** — list the metric labels and log lines that map each state machine transition back to Ch. 06 signals, so a reader can debug an incident by reading the appendix and Ch. 06 side-by-side.
  7. **Anti-patterns** — TTL tuning by gut feel, disabling the watchdog "because it's noisy", running Patroni with the wrong systemd `Type=` (loses watchdog notifications), assuming K8s pod restarts are equivalent to lease loss (they're not).
- **Substrate coverage**: Proxmox LXC and bare VMs via Ansible (the watchdog/lease pathology lab requires kernel-level network manipulation that doesn't work reliably in unprivileged Docker containers; lab notes this explicitly).
- **Anchored user stories**: US1 (deeper understanding of the architecture the DBA deployed) and US2 (SRE incident-time reference for "why did this fail this way").
- **Why an appendix, not a chapter**: Preserves the spec's 10–12 chapter cap (FR-001). Also content-shaped correctly — readers consume it as a *reference*, not as part of the linear reading flow. Earlier chapters (02, 06, 07) cross-link to specific Appendix B sections instead of embedding 30+ pages of internals up front.
