# Phase 1 Data Model — Entity → On-Disk Mapping

Maps each spec entity to its concrete location, file format, and required fields.

## Chapter

- **Location**: `docs/devops/postgres-ha-patroni-book/NN-slug.mdx` (NN = `00`..`12`); appendices use `appendix-<letter>-slug.mdx` (e.g., `appendix-a-python-runtime.mdx`, `appendix-b-patroni-internals.mdx`). All chapter files are `.mdx` because the prose embeds the `<ArtifactRef />` MDX component.
- **Format**: Markdown with Docusaurus frontmatter (see `contracts/chapter-frontmatter.schema.json`).
- **Required sections** (in order):
  1. Frontmatter (`title`, `sidebar_position`, `version_support`, `anchors_user_stories`, `frs_covered`).
  2. Executive Summary (≤ 200 words).
  3. Diagrams (Mermaid inline or Excalidraw SVG embed).
  4. Body prose.
  5. Configuration Examples (fenced code blocks with explicit language tag).
  6. Hands-on Lab(s) — see `contracts/lab-structure.md`.
  7. Checklist (`- [ ]` items, every item verifiable per FR-006).
  8. Gotchas.
  9. Case Study (FAANG-like, anonymized).
  10. Version Support boundary block.
- **Relationships**: Each Chapter references ≥1 Companion Artifact by stable ID; troubleshooting Chapter (07) references Observability Signals defined in Chapter 06.

## Hands-on Lab

- **Location**: Inline section inside the relevant Chapter file; code lives in companion repo at `<tier>/lab-NN-X/` (e.g., `docker/lab-03-a/`).
- **Required fields** (see `contracts/lab-structure.md`):
  - `Artifact ID` (e.g., `LAB-03-A`) — must exist in companion repo `ARTIFACT-IDS.md`.
  - `Tier` — `local` or `cloud-portable`.
  - `Prerequisites` — explicit version pins.
  - `Setup` — copy-pasteable commands.
  - `Break-it-on-purpose` step — must have prominent guardrail callout.
  - `Verification` — observable assertion (command + expected output).
  - `Recovery procedure` — paired with break step (FR-020).
  - `Teardown` — explicit cleanup (FR-003).
- **State transitions**: `pristine → setup → broken → recovered → torn-down`. Every lab MUST drive the state machine to `torn-down` at the end.

## Troubleshooting Playbook

- **Location**: Chapter 07 (`07-troubleshooting-playbooks.md`).
- **Structure**: Each playbook is a Mermaid `flowchart TD` keyed by **observable symptom** (e.g., "Leader Flapping", "Replica Lag Spike", "WAL Bloat", "DCS Partition", "Cert Expiry").
- **Required mapping** (FR-014): each leaf of the decision tree references ≥1 Observability Signal ID (`DASH-06-X` or `ALERT-06-X`) from Chapter 06.
- **Mitigation field**: every leaf has a documented mitigation referencing either a Companion Artifact or an inline command.

## Case Study

- **Location**: Inline in each chapter + compiled into Chapter 12 (optional).
- **Required fields**:
  - Anonymized context (industry, scale, region count).
  - One transferable **pattern**.
  - One explicit **anti-pattern**.
  - Outcome (measurable: latency, MTTR, cost, RPO/RTO impact).
- **Constraint**: Not an endorsement of any vendor (FR-007).

## Companion Artifact

- **Location**: External repo `postgres-ha-patroni-companion`.
- **Registry**: `ARTIFACT-IDS.md` in companion repo root.
- **ID format**: see `contracts/artifact-id.md`.
- **Categories**: `LAB-NN-X`, `AGENT-NN-X`, `DASH-NN-X`, `ALERT-NN-X`, `CONFIG-NN-X`, `CHAOS-NN-X`.
- **Reference from book**: prose uses the stable ID, never raw URLs/commits. The site's link-check CI resolves IDs to URLs via a generated mapping file in `docs/devops/postgres-ha-patroni-book/_companion-links.json` (generated, committed).

## Agentic AI Workflow

- **Location**: Documented in Chapter 11; reference code at `agents/<workflow>/` in companion repo.
- **Required fields** (FR-005, FR-019):
  - `Workflow ID` (e.g., `AGENT-11-PF` for predictive failover).
  - `Guardrails` — allowed actions, denied actions, dry-run default.
  - `Failure modes` — enumerated.
  - `Manual equivalent` — link to a manual runbook in the same chapter or an earlier chapter.
  - `Post-mortem template` — referenced.
- **State transitions** for any agent action: `observed → proposed → dry-run → approved → executed → verified` (each transition has a logged audit event).

## Version Support Block (chapter-level)

- **Location**: Frontmatter `version_support` field + a rendered "Version Support" callout near the top of every chapter.
- **Fields**:
  - `postgres`: e.g., `["18.x", "17.x (N-1)"]`
  - `patroni`: e.g., `["latest stable (4.x)"]` — exact tag pinned in companion repo `ARTIFACT-IDS.md`.
  - `dcs`: e.g., `{"etcd": ["3.5.x"], "consul": ["1.18+"], "k8s": ["1.31+"]}`
  - `substrates`: e.g., `["proxmox-lxc", "docker", "kind", "terraform-aws", "terraform-gcp"]` — declares which lab substrates this chapter's labs cover.
  - `window_months`: `12` (FR-011).
- **Behavior**: Readers running outside the listed versions see the chapter's warning callout (rendered from the frontmatter field via a Docusaurus admonition pattern; no custom plugin required).

## Entity Relationships (summary)

```text
Chapter ──┬── owns ──> HandsOnLab(s) ──> CompanionArtifact (LAB-NN-X)
          ├── owns ──> Checklist
          ├── owns ──> CaseStudy
          ├── owns ──> VersionSupportBlock
Chapter 06 ──> ObservabilitySignal(s) (DASH-NN-X, ALERT-NN-X) ──> CompanionArtifact
Chapter 07 ──> TroubleshootingPlaybook(s) ──> ObservabilitySignal(s) [Ch. 06]
Chapter 11 ──> AgenticAIWorkflow(s) (AGENT-NN-X) ──> CompanionArtifact
                                              └──> ManualEquivalent (runbook in Ch. 07/09)
```
