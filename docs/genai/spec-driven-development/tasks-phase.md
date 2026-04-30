---
sidebar_position: 5
title: Phase 3 — Tasks
---

# Phase 3: Tasks

## What Happens

The tasks phase converts `plan.md` (and supporting design documents) into an **executable, ordered task list** (`tasks.md`) that an AI coding agent can work through systematically.

**Command:**
```bash
/speckit.tasks
```

**Inputs:** `plan.md` (required), `data-model.md`, `contracts/`, `research.md` (if present)

**What spec-kit generates:**
- Ordered tasks with unique IDs (T01, T02, …)
- Explicit dependencies between tasks
- Parallel task markers (`[P]`) for tasks that can run concurrently
- Acceptance criteria per task (derived from the spec)
- Status tracking checkboxes

## The Structure of tasks.md

```markdown
## [T01] Set up project structure
**Description:** Create directory layout from plan.md
**Acceptance Criteria:**
- [ ] src/ directory with __init__.py
- [ ] tests/ directory
- [ ] requirements.txt with pinned versions
**Verification:** `tree src/` matches plan.md file structure
**Depends on:** none
**Status:** 🔄 READY

---

## [T02] Write Pydantic models
**Description:** Create models.py with HealthResult, LatencyResult, etc.
**Depends on:** T01
**Status:** 🔄 READY

---

## [T03] Write failing tests for check_connectivity   ← ALWAYS BEFORE T04
**Description:** Per Article II, tests before implementation.
**Acceptance Criteria:**
- [ ] test_connectivity_healthy passes against real Postgres
- [ ] test_connectivity_unreachable asserts status="unhealthy"
- [ ] Tests FAIL before T04 is implemented
**Depends on:** T02
**Status:** 🔄 READY

---

## [T04] Implement check_connectivity
**Description:** Write checks.py:check_connectivity()
**Depends on:** T03
**Status:** 🔄 READY

---

## [T05] Write failing tests for check_latency   [P]
**Depends on:** T02
**Note:** [P] — can run in parallel with T03/T04

---

## [T06] Implement check_latency   [P]
**Depends on:** T05
```

## The Test-First Guarantee

Notice that for every implementation task (T04, T06, …), there is a corresponding test task (T03, T05, …) that **must come before it** in the dependency chain.

This is enforced by the constitution's Article II and built into spec-kit's task templates. The AI cannot skip to implementation without first generating tests.

```
T03 (write tests) → T04 (implement) → tests go GREEN ✅
T05 (write tests) → T06 (implement) → tests go GREEN ✅
```

## Parallel Execution

Tasks marked `[P]` are safe to run concurrently. Spec-kit identifies parallel groups:

```
Group A (sequential):
  T01 → T02 → T03 → T04

Group B (parallel with Group A after T02):
  T02 → T05 → T06
  T02 → T07 → T08

Group C (requires A and B complete):
  T09 → T10 → T11
```

In Windsurf, you can run parallel task groups by opening multiple Cascade sessions on the same branch.

## Status Tracking

Tasks use emoji status markers that get updated as work progresses:

| Status | Meaning |
|--------|---------|
| 🔄 READY | Not yet started, dependencies met |
| ⏳ IN PROGRESS | Currently being executed |
| ✅ COMPLETED | Done and verified |
| ❌ BLOCKED | Waiting on a dependency |

## Real Example: Health Check Scanner Tasks

```markdown
| Task | Description | Depends | Status |
|------|-------------|---------|--------|
| T01 | Project structure | — | ✅ Done |
| T02 | Pydantic models | T01 | ✅ Done |
| T03 | Tests: connectivity | T02 | ✅ Done |
| T04 | Impl: connectivity | T03 | ⏳ In Progress |
| T05 | Tests: latency | T02 | 🔄 Ready |
| T06 | Impl: latency | T05 | ❌ Blocked |
| T07 | Tests: connections | T02 | 🔄 Ready |
| T08 | Impl: connections | T07 | ❌ Blocked |
| T09 | FastAPI routes | T04, T06, T08 | ❌ Blocked |
| T10 | Typer CLI commands | T04, T06, T08 | ❌ Blocked |
| T11 | Integration test: full scan | T09, T10 | ❌ Blocked |
```

## Executing Tasks with Windsurf

Once `tasks.md` is generated and reviewed:

1. Open Windsurf Cascade
2. Reference the tasks.md file
3. Say: "Execute T01 from tasks.md"
4. Cascade works through the task, checks off acceptance criteria
5. Review the changes before moving to T02

Alternatively, for a workflow-driven approach, your Windsurf workflow can iterate through `tasks.md` automatically.

## When Tasks Go Wrong

If an AI agent doesn't follow a task correctly:

- **Check the acceptance criteria** — are they specific enough? Vague criteria = vague implementation
- **Check the constitution** — did a principle get violated? Add a gate to the task
- **Don't patch the code** — fix the task description or the spec and regenerate

The whole point of SDD is that fixing the artifact (not the code) is the primary mode of course-correction.
