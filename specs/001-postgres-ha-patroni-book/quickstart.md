# Quickstart — Authoring a Chapter

Step-by-step for an author adding or editing a chapter of the book.

## 1. Locate the book

```
docs/devops/postgres-ha-patroni-book/
```

Each chapter is `NN-slug.mdx` where `NN` matches `sidebar_position` in frontmatter. Appendices use `appendix-<letter>-slug.mdx`. The `.mdx` extension is required so the `<ArtifactRef />` MDX component renders.

## 2. Copy the chapter scaffold

There is no global template file yet; use the existing `00-preface.mdx` as the canonical scaffold once it lands. Until then, hand-create:

```mdx
---
title: <chapter title>
sidebar_position: <NN>
description: <one-sentence summary>
version_support:
  postgres: ["18.x", "17.x (N-1)"]
  patroni: ["latest stable (4.x)"]
  dcs: { etcd: ["3.5.x"], k8s: ["1.31+"] }
  window_months: 12
anchors_user_stories: ["US1"]
frs_covered: ["FR-002", "FR-004"]
substrates: ["proxmox-lxc", "docker", "kind"]
lab_ids: ["LAB-03-A"]
tags: [postgres, patroni, ha]
---

# <chapter title>

## Executive Summary

<≤ 200 words>

## Diagrams

<Mermaid inline or Excalidraw SVG embed>

## Body

...

## Lab <ArtifactRef id="LAB-03-A" /> — <short title>

<follow contracts/lab-structure.md>

## Checklist

- [ ] <verifiable item>
- [ ] <verifiable item>

## Gotchas

- ...

## Case Study — <industry, scale>

- Pattern: ...
- Anti-pattern: ...
- Outcome: ...

## Version Support

:::info
This chapter supports Postgres 17.x and 16.x (N-1), Patroni 4.x; window 12 months from publication.
:::
```

Validate the frontmatter against `specs/001-postgres-ha-patroni-book/contracts/chapter-frontmatter.schema.json`.

## 3. Add diagrams

- **Mermaid**: inline fenced block:

  ```mdx
  ```mermaid
  sequenceDiagram
      participant App
      participant HAProxy
      participant LeaderPG
      App->>HAProxy: SQL
      HAProxy->>LeaderPG: forward
  ```
  ```
  Ensure `@docusaurus/theme-mermaid` is enabled in `docusaurus.config.js` (one-time site-level enablement; not per-chapter).
- **Excalidraw**: commit `_diagrams/excalidraw/<name>.excalidraw` (source) **and** the exported `_diagrams/excalidraw/<name>.svg`. Reference SVG in MDX:

  ```mdx
  ![multi-region topology](./_diagrams/excalidraw/multi-region.svg)
  ```

## 4. Reference companion artifacts by ID

Never paste raw URLs in prose. Use the MDX component:

```mdx
Walk through lab <ArtifactRef id="LAB-03-A" /> in the companion repo.
```

If `LAB-03-A` is missing from `_companion-links.json`, the build fails — that's the FR-010 drift signal working as designed.

## 5. Local preview

From repo root:

```bash
npm install        # first time only
npm run start      # Docusaurus dev server, hot reload
```

## 6. Lint and build before pushing

```bash
npx markdown-link-check docs/devops/postgres-ha-patroni-book/<your-chapter>.md
npx cspell "docs/devops/postgres-ha-patroni-book/**/*.md"
# vale if installed
npm run build      # full Docusaurus build; onBrokenLinks throws
```

## 7. Commit

Stay within `docs/devops/postgres-ha-patroni-book/` (Principle IV — Surgical Changes). One chapter per PR ideally.

## 8. Companion code (if your chapter introduces a new lab or agent)

- Open a PR in `postgres-ha-patroni-companion` adding the artifact under the path dictated by `contracts/artifact-id.md`.
- Register the new ID in `ARTIFACT-IDS.md` (status: `stable` or `experimental`).
- Add a lab smoke test under `.github/workflows/` so CI runs the documented break + verification.
- After companion repo merges, regenerate `_companion-links.json` here and commit.

## 9. Definition of done for a chapter

A chapter is done when:

- Frontmatter validates against the schema.
- All sections from `data-model.md` "Chapter" entry are present and non-empty.
- Every checklist item is independently verifiable (SC-005).
- Every lab follows `contracts/lab-structure.md`.
- Every troubleshooting entry (if Ch. 07) references ≥1 observability signal from Ch. 06 (FR-014).
- Every agent workflow (if Ch. 11) has a documented manual equivalent (FR-019).
- Companion CI is green for any referenced lab.
- `npm run build` passes with `onBrokenLinks: 'throw'`.
