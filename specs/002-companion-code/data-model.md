# Data Model: Patroni HA Book Companion Code

**Date**: 2026-05-18
**Feature**: specs/002-companion-code/

## Overview

This feature does not have a traditional data model (no database, no persistent state). Instead, the "entities" are the files and directories that make up the companion code. This document defines the relationships between artifacts, labs, and the book chapters that reference them.

## Entities

### Artifact

The fundamental unit of companion code. Every file or directory that the book prose references by a stable ID.

| Attribute | Description |
|-----------|-------------|
| `id` | Stable identifier in format `CATEGORY-CHAPTER-SUFFIX` (e.g., `LAB-03-A`, `DASH-06-CORE`) |
| `category` | One of: LAB, CONFIG, DASH, ALERT, AGENT, CHAOS |
| `chapter` | Chapter number (03, 04, 06, 08, 11, A, B) |
| `suffix` | 1-3 uppercase letters, unique within (category, chapter) |
| `path` | Relative path from `_companion/` root |
| `description` | Human-readable description |
| `substrates` | For LAB artifacts: list of supported substrates (docker, terraform-aws, terraform-gcp, proxmox-lxc, bare-vm-ansible) |
| `source_chapter` | Book chapter MDX file that is the source of truth for this artifact's behavior |

### Lab

A special type of Artifact that is a hands-on exercise with a defined lifecycle.

| Attribute | Description |
|-----------|-------------|
| `id` | `LAB-NN-X` or `LAB-A-X` for appendix labs |
| `phases` | Ordered list: Setup → Break → Verify → Recover → Teardown |
| `makefile_targets` | setup, break, verify, recover, teardown |
| `prerequisites` | Required software, hardware, credentials |
| `expected_duration` | Time budget for full execution |
| `break_description` | What the "break it on purpose" step simulates |
| `verify_assertion` | Exact command + expected output for the verification step |

### Agent Scaffold

A special type of Artifact that is a Python package implementing one agentic AI workflow.

| Attribute | Description |
|-----------|-------------|
| `id` | `AGENT-11-XXX` |
| `workflow_name` | Human-readable name (e.g., "Autonomous Monitoring") |
| `states` | The 6-state lifecycle: observed, proposed, dry-run, approved, executed, verified |
| `default_mode` | Always "dry-run" |
| `destructive_opt_in` | Environment variable or config flag required to enable execution |
| `audit_log` | Every state transition MUST be logged with timestamp, action, and context |
| `manual_equivalent` | Reference to Chapter 07 or Chapter 09 section that documents the manual procedure |

## Relationships

```
Book Chapter (1) --references--> (N) Artifact
  - Ch. 03 → LAB-03-A, CHAOS-03-A
  - Ch. 04 → CONFIG-04-REF
  - Ch. 06 → DASH-06-CORE, DASH-06-LAG, ALERT-06-*
  - Ch. 08 → LAB-08-A, LAB-08-B
  - Ch. 11 → AGENT-11-*
  - Appendix A → LAB-A-A
  - Appendix B → LAB-B-A

Artifact (1) --resolves_via--> (1) _companion-links.json entry
  - Each artifact ID maps to a URL in the JSON file

Lab (1) --requires--> (1) Makefile / script
  - Every lab MUST have a Makefile or shell script with the 5 lifecycle targets
```

## Validation Rules

1. Every artifact ID referenced in book prose MUST exist in `ARTIFACT-IDS.md`.
2. Every artifact ID in `ARTIFACT-IDS.md` MUST have a corresponding file or directory in `_companion/`.
3. Every LAB artifact MUST have a Makefile or script with all 5 lifecycle targets.
4. Every AGENT artifact MUST default to dry-run mode.
5. No secrets (credentials, tokens, private keys) may be committed in any artifact.
