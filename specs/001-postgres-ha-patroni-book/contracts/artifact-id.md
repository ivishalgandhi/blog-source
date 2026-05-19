# Companion Artifact ID Contract

Stable identifiers used by the book's prose to reference companion-repo artifacts. Provides the drift-detection seam required by FR-010 and SC-007.

## Format

```
<CATEGORY>-<CHAPTER>-<SUFFIX>
```

- `<CATEGORY>` — uppercase token from the table below.
- `<CHAPTER>` — zero-padded chapter number (`00`..`12`) or single-letter appendix code (`A`, `B`, …) for appendices.
- `<SUFFIX>` — 1–3 uppercase letters, unique within `(CATEGORY, CHAPTER)`.

Examples: `LAB-03-A`, `LAB-03-B`, `AGENT-11-PF`, `DASH-06-CORE`, `ALERT-06-LAG`, `LAB-A-A` (appendix lab).

## Categories

| Category | Meaning | Companion repo path |
|----------|---------|----------------------|
| `LAB`    | Hands-on lab (Terraform / Ansible / Docker Compose / K8s) | `<tier>/lab-NN-<suffix-lower>/` |
| `AGENT`  | Agentic AI workflow reference integration | `agents/<workflow-name>/` |
| `DASH`   | Grafana dashboard JSON | `dashboards/<suffix-lower>.json` |
| `ALERT`  | Prometheus alert rule | `dashboards/alerts/<suffix-lower>.yaml` |
| `CONFIG` | Reference configuration file (e.g., `patroni.yml`) | `patroni/<suffix-lower>.yml` |
| `CHAOS`  | "Break it on purpose" chaos script | `chaos/<suffix-lower>.sh` |

## Registry

The canonical registry lives at `ARTIFACT-IDS.md` in the companion repo. Every ID referenced by the book MUST appear in the registry with:

- ID
- Path within companion repo
- Owning chapter (NN)
- Stability flag: `stable` (won't be removed within compatibility window) or `experimental` (subject to change; not referenced by P1 labs)

## Link generation

The book site generates `docs/devops/postgres-ha-patroni-book/_companion-links.json` from the registry (build-time fetch or committed manually). Prose authors reference IDs only:

```mdx
See lab <ArtifactRef id="LAB-03-A" /> in the companion repo.
```

`<ArtifactRef />` is a tiny MDX component that looks up the URL by ID and renders a link with a stable anchor. If the ID is missing from the JSON, the Docusaurus build fails (`onBrokenLinks: 'throw'` semantics), which is exactly the drift signal FR-010 demands.

## Rules

- IDs are immutable. To rename an artifact, mint a new ID and mark the old one `deprecated` in the registry for one compatibility window.
- IDs MUST NOT appear inside code blocks where they would be interpreted as code; use the MDX component or a normal markdown link backed by the JSON mapping.
- Experimental IDs MUST NOT be referenced from P1 user-story labs.
