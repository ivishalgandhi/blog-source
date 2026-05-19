---
description: "Task list for Mastering PostgreSQL HA with Patroni (2026 Edition)"
---

# Tasks: Mastering PostgreSQL HA with Patroni (2026 Edition)

**Input**: Design documents from `/specs/001-postgres-ha-patroni-book/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md (all present)

**Tests**: Not requested in spec; no test-task entries generated. Lab smoke testing happens in the **companion repo's** CI and is referenced by chapter labs via stable artifact IDs (`LAB-NN-X`).

**Organization**: Tasks grouped by user story (US1..US5 from spec.md) plus an Appendix A phase. Each story's chapters are independently testable per the spec's Independent Test definitions.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: parallelizable (different file, no incomplete dependencies)
- **[Story]**: `US1`..`US5` or `APX` for Appendix A; setup/foundational/polish carry no story label
- Every task includes an exact file path

## Path Conventions

- Book prose: `docs/devops/postgres-ha-patroni-book/`
- Spec artifacts: `specs/001-postgres-ha-patroni-book/`
- Companion code lives in a **separate** GitHub repo (`postgres-ha-patroni-companion`); tasks here only reference its artifact IDs and never write its files.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Scaffold the book section under the existing Docusaurus site, enable Mermaid, and wire prose-linting.

- [x] T001 Create directory `docs/devops/postgres-ha-patroni-book/` and an empty `_diagrams/mermaid/` and `_diagrams/excalidraw/` subtree
- [x] T002 Add `docs/devops/postgres-ha-patroni-book/_category_.json` with `label: "Postgres HA with Patroni (2026)"`, `position: 4`, `collapsed: true`
- [x] T003 [P] Enable Mermaid: add `@docusaurus/theme-mermaid` to `package.json` devDependencies and register it in `docusaurus.config.js` (`markdown: { mermaid: true }`, `themes: ['@docusaurus/theme-mermaid']`)
- [x] T004 [P] Add prose-lint config: create `.vale.ini` and `styles/` at repo root (or extend if present) targeting `docs/devops/postgres-ha-patroni-book/**/*.mdx`
- [x] T005 [P] Add `cspell.json` at repo root with technical wordlist (postgres, patroni, etcd, consul, pgbackrest, wal-g, pumba, kubectl, etc.) and scope `docs/devops/postgres-ha-patroni-book/**/*.mdx`
- [x] T006 [P] Add `.markdown-link-check.json` at repo root configured to ignore the unresolved `<ArtifactRef />` component and follow external links once

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Cross-chapter primitives every user-story phase will depend on. ⚠️ No chapter work begins until this phase is complete.

- [x] T007 Create `src/components/ArtifactRef/index.js` (Docusaurus MDX component) that resolves a `LAB-NN-X` / `AGENT-NN-X` / `DASH-NN-X` ID against a JSON map and renders a link; throws a build error when the ID is missing (FR-010 drift signal)
- [x] T008 Create `docs/devops/postgres-ha-patroni-book/_companion-links.json` with the initial artifact-ID → URL map (seeded with `LAB-03-A`, `LAB-A-A` placeholders pointing at the companion repo path); register the file in `docusaurus.config.js` if needed
- [x] T009 Create `docs/devops/postgres-ha-patroni-book/index.mdx` — book landing page covering audience, prerequisites, non-goals, version-support window, "how to use this book", and link to companion repo (FR-008, FR-017)
- [x] T010 Create `docs/devops/postgres-ha-patroni-book/00-preface.mdx` — audience, conventions (callouts, ID format, diagram conventions), version-support window block, structure overview (FR-011, FR-017)
- [x] T011 [P] Add a chapter-frontmatter linter script `scripts/lint-chapter-frontmatter.mjs` that validates every `docs/devops/postgres-ha-patroni-book/*.mdx` frontmatter against `specs/001-postgres-ha-patroni-book/contracts/chapter-frontmatter.schema.json` and exits non-zero on mismatch
- [x] T012 [P] Add npm script `lint:book` in `package.json` that runs: vale, cspell, markdown-link-check on the book section, plus the frontmatter linter (T011)
- [x] T013 [P] Add npm script `build:book` in `package.json` that runs `docusaurus build` with `onBrokenLinks: 'throw'` (already enforced site-wide) and fails CI on any broken artifact-ID
- [x] T014 [P] Add `.github/workflows/book-lint.yml` running `npm run lint:book` and `npm run build:book` on PRs that touch `docs/devops/postgres-ha-patroni-book/**`

**Checkpoint**: Scaffolding ready — chapter authoring can begin in parallel across user-story phases.

---

## Phase 3: User Story 1 — Senior DBA Designs and Deploys (Priority: P1) 🎯 MVP

**Goal**: Take an experienced DBA from zero to a working multi-node Patroni cluster with documented failover, geo-distribution decision framework, and a runnable lab.

**Independent Test**: A reader using only Ch. 01–04 + Ch. 10 and the companion repo can deploy a 3-node Patroni cluster, induce a leader failure, and verify automatic failover within the chapter's stated time budget.

### Chapters anchoring US1 (Ch. 01, 02, 03, 04, 05, 10)

- [x] T015 [P] [US1] Draft Chapter 01 in `docs/devops/postgres-ha-patroni-book/01-foundations-postgres-ha.mdx` — exec summary, "what HA actually means at FAANG scale", failure model taxonomy, RPO/RTO primer, ≥1 Mermaid component diagram (in `_diagrams/mermaid/`), checklist, gotchas, anonymized case study, version-support block. Frontmatter `frs_covered: ["FR-001","FR-002"]`, `anchors_user_stories: ["US1"]`.
- [x] T016 [P] [US1] Draft Chapter 02 in `docs/devops/postgres-ha-patroni-book/02-patroni-architecture-dcs.mdx` — Patroni architecture, DCS comparison (etcd vs Consul vs K8s-native), ≥1 Excalidraw topology diagram (commit source + SVG to `_diagrams/excalidraw/`), checklist, gotchas, case study, version-support block. Frontmatter `frs_covered: ["FR-002","FR-004"]`.
- [x] T017 [US1] Draft Chapter 03 in `docs/devops/postgres-ha-patroni-book/03-deploying-patroni-cluster.mdx` — anchors **P1 lab `LAB-03-A`** (3-node Patroni + etcd, kill-leader exercise, recovery, teardown) following `contracts/lab-structure.md`; declare substrates `["proxmox-lxc","docker","kind"]`; checklist, gotchas, case study, version-support block. Frontmatter must include `lab_ids: ["LAB-03-A"]`. Depends on T015, T016 for terminology consistency.
- [x] T018 [P] [US1] Draft Chapter 04 in `docs/devops/postgres-ha-patroni-book/04-configuration-best-practices.mdx` — annotated reference `patroni.yml` (via `CONFIG-04-REF`), `pg_hba.conf` patterns, sync replication modes (`synchronous_mode`, `synchronous_node_count`), watchdog, slot strategy, checklist, gotchas, case study, version-support block.
- [x] T019 [P] [US1] Draft Chapter 05 in `docs/devops/postgres-ha-patroni-book/05-performance-tuning-ha.mdx` — checkpointer/WAL settings under HA, autovacuum on standbys, connection pooling at the proxy tier (pgbouncer/pgcat), HOT vs replication trade-offs, checklist, gotchas, case study, version-support block.
- [x] T020 [US1] Draft Chapter 10 in `docs/devops/postgres-ha-patroni-book/10-geo-distributed-patroni.mdx` — quorum placement (2-of-3 vs 3-of-5 across regions), sync vs async by region, split-brain prevention with `nofailover` tags + DCS quorum, data-sovereignty patterns (regional clusters + logical replication seams), ≥1 Excalidraw multi-region diagram, checklist, gotchas, case study, version-support block. Frontmatter `frs_covered: ["FR-004","FR-016"]`.

**Checkpoint**: US1 chapters render, `LAB-03-A` is referenced (companion repo authoring is out of scope here), `npm run lint:book` and `npm run build:book` pass.

---

## Phase 4: User Story 2 — SRE Operates and Troubleshoots (Priority: P1)

**Goal**: Working SRE reference under pressure: observability dashboards + symptom-keyed troubleshooting decision trees + zero-downtime ops runbooks.

**Independent Test**: SRE resolves ≥4/5 induced failure scenarios (DCS partition, runaway WAL, slot bloat, sync standby loss, cert expiry) using only Ch. 06 + Ch. 07.

### Chapters anchoring US2 (Ch. 06, 07, 09)

- [x] T021 [P] [US2] Draft Chapter 06 in `docs/devops/postgres-ha-patroni-book/06-observability-monitoring.mdx` — required signals matrix (Patroni REST `/cluster`, `/health`, `/patroni`, `postgres_exporter` metrics, WAL/replication slot metrics, DCS health), reference Grafana dashboards by IDs `DASH-06-CORE` and `DASH-06-LAG`, alert rules `ALERT-06-LAG`, `ALERT-06-LEADER-FLAP`, `ALERT-06-WAL-BLOAT`, `ALERT-06-DCS-PARTITION`, `ALERT-06-CERT-EXPIRY`. Frontmatter `frs_covered: ["FR-004","FR-014"]`. Coordinate terminology with T015/T016 via the shared glossary in `00-preface.mdx` (no hard dependency).
- [x] T022 [US2] Draft Chapter 07 in `docs/devops/postgres-ha-patroni-book/07-troubleshooting-playbooks.mdx` — Mermaid `flowchart TD` decision trees keyed by symptom: "Leader Flapping", "Replica Lag Spike", "WAL Bloat", "DCS Partition", "Cert Expiry". Every leaf MUST cite ≥1 signal/alert ID from Ch. 06 (FR-014) and a recovery procedure. Frontmatter `frs_covered: ["FR-013","FR-014","FR-020"]`. Depends on T021 (signal IDs must exist).
- [x] T023 [P] [US2] Draft Chapter 09 in `docs/devops/postgres-ha-patroni-book/09-zero-downtime-operations.mdx` — runbooks for major version upgrade (pg_upgrade vs logical replication), region drain, certificate rotation, switchover vs failover semantics, with paired break/recovery exercises (FR-020). Frontmatter `frs_covered: ["FR-004","FR-012","FR-020"]`.
- [x] T024 [US2] Cross-link Ch. 07 troubleshooting leaves to Ch. 09 recovery runbooks in `docs/devops/postgres-ha-patroni-book/07-troubleshooting-playbooks.mdx` (edit existing file; depends on T022, T023)

**Checkpoint**: Every Ch. 07 playbook leaf resolves to a Ch. 06 signal AND a Ch. 09 recovery runbook; lint and build pass.

---

## Phase 5: User Story 4 — Architect Backup/DR (Priority: P2)

**Goal**: Validate backup/DR design against measurable RTO/RPO with a working PITR lab.

**Independent Test**: Reader completes full+incremental, PITR-to-transaction, and cross-region restore in the lab; produces a recovery plan whose RTO/RPO is empirically measured.

### Chapter anchoring US4 (Ch. 08)

- [x] T025 [US4] Draft Chapter 08 in `docs/devops/postgres-ha-patroni-book/08-backup-dr-pitr.mdx` — decision matrix (pgBackRest vs WAL-G vs streaming + delayed standby), retention/encryption/offsite patterns, PITR lab `LAB-08-A` (full + incremental + restore to LSN + verify integrity), cross-region restore lab `LAB-08-B`, substrate list `["proxmox-lxc","docker","terraform-aws","terraform-gcp"]`, checklist with measured RTO/RPO targets, gotchas, case study, version-support block. Frontmatter `frs_covered: ["FR-004","FR-015"]`, `lab_ids: ["LAB-08-A","LAB-08-B"]`.

**Checkpoint**: US4 deliverable independently usable; references `LAB-08-A` and `LAB-08-B` resolve cleanly.

---

## Phase 6: User Story 3 — Agentic AI for Patroni (Priority: P2)

**Goal**: Reference integration of 2026 agentic AI patterns (autonomous monitoring, predictive failover, self-tuning, auto-remediation, NL ops) layered on Patroni, with explicit guardrails and manual fallbacks.

**Independent Test**: Reader deploys reference agent integration against the lab cluster, runs each documented scenario, and every agent action passes the chapter's safety checklist.

**⚠ Depends on US2 chapters** (Ch. 06 signals and Ch. 07 playbooks are referenced as the manual-equivalent runbooks per FR-019).

### Chapter anchoring US3 (Ch. 11)

- [x] T026 [US3] Draft Chapter 11 in `docs/devops/postgres-ha-patroni-book/11-agentic-ai-autonomous-ops.mdx` — patterns + guardrails for `AGENT-11-MON` (monitoring), `AGENT-11-PF` (predictive failover), `AGENT-11-ST` (self-tuning), `AGENT-11-AR` (auto-remediation), `AGENT-11-NL` (NL ops). Each workflow: state machine (`observed → proposed → dry-run → approved → executed → verified`), guardrails, failure modes, **manual equivalent runbook link** (must cite Ch. 06/07/09), post-mortem template, model-provider abstraction note (litellm), pydantic-ai reference. Frontmatter `frs_covered: ["FR-005","FR-019"]`, `agent_ids: ["AGENT-11-MON","AGENT-11-PF","AGENT-11-ST","AGENT-11-AR","AGENT-11-NL"]`. Depends on T021, T022, T023.

**Checkpoint**: Every Agentic AI workflow has a documented manual equivalent (FR-019) reachable via cross-link.

---

## Phase 7: User Story 5 — Case Studies & Anti-Patterns (Priority: P3, OPTIONAL Ch. 12)

**Goal**: Compendium of anonymized FAANG-like case studies and explicit anti-patterns; ≥1 transferable pattern + ≥1 anti-pattern per study.

**Independent Test**: A reader can extract ≥1 transferable pattern and ≥1 anti-pattern from each case study and map it to a prior chapter.

- [x] T027 [US5] Draft Chapter 12 (optional) in `docs/devops/postgres-ha-patroni-book/12-case-studies-anti-patterns.mdx` — 4–6 anonymized composites covering: multi-region quorum loss, slot-bloat outage, runaway autovacuum on a standby, mis-tuned sync replication, AI-agent misbehavior post-mortem, certificate-expiry cascade. Each study: context, pattern, anti-pattern, measured outcome (FR-007). Frontmatter `frs_covered: ["FR-007"]`.

**Note**: Ch. 12 is optional and does NOT gate publication.

---

## Phase 8: Appendices

**Goal**:
- **Appendix A**: Documented, lab-validated path for migrating Patroni's Python runtime (legacy 3.6 → 3.12) without split-brain.
- **Appendix B** (FR-021): Patroni internals reference (state machine, leader election, watchdog/fencing, DCS lease semantics) cross-linked from Ch. 02 / 06 / 07.

**Independent Tests**:
- Appendix A: Reader runs `LAB-A-A` rolling-upgrade on a 3-node Proxmox-LXC or Docker cluster, induces a leader failover mid-upgrade, verifies no split-brain.
- Appendix B: Reader runs `LAB-B-A` (watchdog/lease pathology) on Proxmox LXC or bare VMs, induces leader-to-DCS partition, observes lease expiry → standby promotion → original-leader self-fence, verifies no split-brain; and can answer "what state was each node in at each timestamp?" from the appendix alone.

- [x] T028 [APX] Draft Appendix A in `docs/devops/postgres-ha-patroni-book/appendix-a-python-runtime.mdx` — inventory step, dependency-compatibility risk matrix (psycopg2/3, kazoo, python-etcd, urllib3, ssl), three migration patterns (side-by-side venv swap, rolling node replacement, containerized cutover), `LAB-A-A` rolling-upgrade lab following `contracts/lab-structure.md` with substrates `["proxmox-lxc","docker","bare-vm-ansible"]`, Python-version-as-metric-label hook tying back to Ch. 06, anti-patterns, gotchas, version-support block. Frontmatter `lab_ids: ["LAB-A-A"]`, `anchors_user_stories: ["US2"]`, `frs_covered: ["FR-004","FR-013"]`. Depends on T021 (signal IDs).
- [x] T028b [APX] Draft Appendix B in `docs/devops/postgres-ha-patroni-book/appendix-b-patroni-internals.mdx` — Patroni state machine (states + transitions + DCS writes), leader-election semantics across etcd / Consul / K8s endpoint mode, watchdog & fencing (`softdog` vs hardware, double-leader fence path), DCS lease semantics (TTL, `loop_wait`, `retry_timeout`, renewal math), `LAB-B-A` "watchdog and lease pathology" lab following `contracts/lab-structure.md` with substrates `["proxmox-lxc","bare-vm-ansible"]` (kernel-level netns required; lab notes Docker unsuitability), observability-hook table mapping transitions back to Ch. 06 signals, anti-patterns, version-support block. Frontmatter `lab_ids: ["LAB-B-A"]`, `anchors_user_stories: ["US1","US2"]`, `frs_covered: ["FR-002","FR-013","FR-021"]`. Cross-link from Ch. 02 (T016), Ch. 06 (T021), Ch. 07 (T022) is required (FR-021).

**Checkpoint**: `LAB-A-A` and `LAB-B-A` resolve through `_companion-links.json`; Ch. 02/06/07 each link to ≥1 Appendix B section (FR-021); lint and build pass.

---

## Phase 9: Polish & Cross-Cutting Concerns

- [x] T029 [P] Audit every chapter's checklist for "it depends" escape hatches and replace with verifiable items (SC-005) across all files under `docs/devops/postgres-ha-patroni-book/*.mdx`
- [x] T030 [P] Verify every Ch. 07 playbook leaf cites ≥1 signal/alert ID from Ch. 06 (FR-014) by grepping `docs/devops/postgres-ha-patroni-book/07-troubleshooting-playbooks.mdx` for `DASH-06-` and `ALERT-06-` references and reconciling against Ch. 06
- [x] T031 [P] Verify every Ch. 11 agent workflow links to a manual-equivalent runbook (FR-019) by grepping `docs/devops/postgres-ha-patroni-book/11-agentic-ai-autonomous-ops.mdx` for cross-links to Ch. 06/07/09 anchors
- [x] T032 [P] Verify every chapter's `version_support` frontmatter declares Postgres 18.x (N) and 17.x (N-1) and `window_months: 12` by running `scripts/lint-chapter-frontmatter.mjs` (FR-011)
- [x] T033 [P] Regenerate `docs/devops/postgres-ha-patroni-book/_companion-links.json` from the companion repo's `ARTIFACT-IDS.md` once the companion repo lands; commit the refreshed file
- [x] T034 [P] Add a sidebar position pass: confirm `sidebar_position` in each chapter's frontmatter matches its `NN-` filename prefix
- [x] T035 [P] Add a final SC-007 audit: walk `docs/devops/postgres-ha-patroni-book/` chapter by chapter and confirm every lab heading uses `<ArtifactRef id="..." />` and every cited ID resolves in `_companion-links.json`
- [x] T036 Run quickstart validation per `specs/001-postgres-ha-patroni-book/quickstart.md` (local preview + full build) and capture output
- [x] T037 Update navbar/sidebar in `docusaurus.config.js` if needed so the book section is discoverable (single edit; not in parallel with any other docusaurus.config.js edits)
- [x] T038 [P] Credentials/secrets audit (Constitution Principle VII) — grep `docs/devops/postgres-ha-patroni-book/**/*.mdx` for patterns matching real-looking credentials, hostnames, IPs, or tokens (e.g., `AKIA`, `ghp_`, `BEGIN PRIVATE KEY`, `password\s*=\s*[^<]`, hard-coded internal-looking FQDNs); replace any hits with placeholders or `.env.example`-style references. Add the same grep as a CI step in `.github/workflows/book-lint.yml` (T014) so future drift fails the build.
- [x] T039 [P] Verify Appendix B (`appendix-b-patroni-internals.mdx`) is cross-linked from Ch. 02, Ch. 06, and Ch. 07 (FR-021) by grepping for `appendix-b` references in those three `.mdx` files.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (P1)** → no deps; immediately
- **Foundational (P2)** → depends on Setup; blocks all chapter work
- **US1 (P3)** → depends on Foundational; MVP slice (Ch. 01–05, 10 + `LAB-03-A` reference)
- **US2 (P4)** → depends on Foundational; can run **in parallel** with US1 but Ch. 07 (T022) depends on Ch. 06 (T021), and Ch. 11 in US3 depends on US2 chapters
- **US4 (P5)** → depends on Foundational; independent of US1/US2/US3
- **US3 (P6)** → depends on Foundational **and** US2 (manual-equivalent links per FR-019)
- **US5 (P7)** → optional; depends on Foundational; ideally drafted after US1/US2/US4 so case studies reference real patterns
- **Appendix A (P8)** → depends on Foundational and on Ch. 06 (T021) for the metric-label hook
- **Polish (P9)** → depends on all desired chapter phases being complete

### Within Each User Story

- Foundational primitives (T007–T014) MUST exist before chapter authoring
- For chapters with diagrams + lab + prose, prose can be drafted in parallel with diagram authoring as long as both land before checklist audit (T029)

### Parallel Opportunities

- Setup [P] tasks T003–T006 run in parallel
- Foundational [P] tasks T011–T014 run in parallel
- US1 chapter drafts T015, T016, T018, T019 run in parallel (T017 depends on T015/T016, T020 is independent)
- US2 Ch. 09 (T023) runs in parallel with Ch. 06 (T021); Ch. 07 (T022) follows Ch. 06; T024 follows both
- US4 (T025), US3 (T026, after US2), Appendix A (T028, after T021), and US5 (T027) chapters are independent of each other
- Polish tasks T029–T035 run in parallel

---

## Parallel Example: User Story 1

```bash
# Once Phase 2 is complete, launch US1 chapter drafts together:
Task: "Draft Chapter 01 in docs/devops/postgres-ha-patroni-book/01-foundations-postgres-ha.mdx"
Task: "Draft Chapter 02 in docs/devops/postgres-ha-patroni-book/02-patroni-architecture-dcs.mdx"
Task: "Draft Chapter 04 in docs/devops/postgres-ha-patroni-book/04-configuration-best-practices.mdx"
Task: "Draft Chapter 05 in docs/devops/postgres-ha-patroni-book/05-performance-tuning-ha.mdx"
Task: "Draft Chapter 10 in docs/devops/postgres-ha-patroni-book/10-geo-distributed-patroni.mdx"
# Then:
Task: "Draft Chapter 03 (depends on 01/02 for terminology) in 03-deploying-patroni-cluster.md"
```

---

## Implementation Strategy

### MVP First (US1 only)

1. Phase 1: Setup (T001–T006)
2. Phase 2: Foundational (T007–T014)
3. Phase 3: US1 chapters (T015–T020)
4. **STOP and VALIDATE**: a reader can deploy `LAB-03-A` from the companion repo and observe failover end-to-end (SC-001).
5. Ship the MVP — book has a runnable spine.

### Incremental Delivery

1. MVP (above) →
2. US2 chapters (T021–T024) — book becomes a working operational reference (SC-002) →
3. US4 chapter (T025) — backup/DR validated (SC-004) →
4. US3 chapter (T026) — Agentic AI layer added (SC-003) →
5. Appendix A (T028) — Python-runtime migration covered →
6. US5 chapter (T027) — case-studies compendium (optional) →
7. Polish (T029–T037).

### Parallel Team Strategy

After Phase 2:

- Author A: US1 (Ch. 01–05, 10)
- Author B: US2 (Ch. 06, 07, 09), then US3 (Ch. 11), then Appendix A
- Author C: US4 (Ch. 08), then US5 (Ch. 12)
- Editor: runs `lint:book` + `build:book` per PR; coordinates ID registry against companion repo

---

## Notes

- This is a documentation project; **no test phases generated** (spec did not request TDD; lab smoke tests live in the companion repo).
- [P] = different files, no incomplete dependencies.
- Every chapter task implicitly includes: frontmatter conforming to `contracts/chapter-frontmatter.schema.json`, ≥1 diagram, lab(s) per `contracts/lab-structure.md` where applicable, checklist (FR-006), gotchas, case study (FR-007), and version-support block (FR-011).
- Companion repo work is **out of scope** here — referenced by stable artifact IDs only (FR-009, FR-010).
- Commit after each chapter or logical group; the `after_tasks` hook offers optional auto-commit.
- Stop at any checkpoint to validate the corresponding user-story independently against its spec Independent Test.
