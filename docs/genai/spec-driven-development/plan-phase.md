---
sidebar_position: 4
title: Phase 2 — Plan
---

# Phase 2: Plan

## What Happens

The plan phase translates the *what* and *why* from `spec.md` into the *how* — a technical architecture document (`plan.md`) with traceable rationale.

**Command:**
```bash
/speckit.plan
[optional architecture hints, e.g. "use FastAPI, psycopg2, no ORM"]
```

**What spec-kit does:**
1. Reads and understands the feature spec, user stories, and acceptance criteria
2. Checks alignment with the constitution (architectural principles)
3. Generates `plan.md` with technology choices, rationale, component design, and file structure
4. Optionally generates supporting documents: `data-model.md`, `contracts/`, `research.md`

## The Structure of plan.md

### 1. Architecture Overview
A component diagram (text-art or Mermaid) showing how the system fits together. Shows boundaries between components, not implementation details.

### 2. Component Design
For each component: purpose, inputs/outputs, key decisions. Every decision should trace back to a user story number.

### 3. File Structure
The exact directory and file layout. Generated code will match this structure.

### 4. Technology Choices with Rationale
```markdown
## Why FastAPI?
- US-1 requires REST endpoints → FastAPI's type-safe Pydantic responses
- US-4 requires concurrent checks → FastAPI's async support
- Not Django: no ORM needed (Article III of constitution)
```

### 5. Test Strategy
How tests will be structured, what test infrastructure is required (e.g., Docker Postgres), what gets unit-tested vs. integration-tested.

### 6. Security Considerations
For any feature touching auth, data, or external services.

## Real Example: Health Check Scanner Plan

```markdown
# Technical Plan: PostgreSQL Health Check Scanner

## Architecture

┌────────────────────────────────────────┐
│  cli.py (Typer)    main.py (FastAPI)   │
│         └──────────────┘              │
│              checks.py (core logic)    │
│              models.py (Pydantic)      │
└────────────────────────────────────────┘
              │
         psycopg2
              │
       PostgreSQL (Docker)

## Component Design

### checks.py
Purpose: Core health check logic, shared by API and CLI.
- check_connectivity() → HealthResult
- check_latency() → LatencyResult
- check_connections() → ConnectionResult
- run_full_scan() → ScanReport
Rationale: Single source of truth for check logic (US-1 through US-4).
No duplication between API and CLI paths.

## Why This Architecture?
- US-1–US-3 require both API and CLI → shared checks.py eliminates duplication
- Article VIII (Anti-Abstraction): no wrapper around psycopg2, use it directly
- Article IX (Integration-First): tests connect to real Docker Postgres

## File Structure
src/
├── __init__.py
├── main.py      # FastAPI routes
├── cli.py       # Typer commands
├── checks.py    # Health check logic
└── models.py    # Pydantic models (HealthResult, LatencyResult, etc.)

tests/
├── test_checks.py   # Integration tests against real Postgres
└── test_api.py      # FastAPI TestClient tests
```

## The Constitutional Compliance Check

Before generating `plan.md`, spec-kit checks your plan against the constitution's "Phase -1 Gates":

```markdown
### Pre-Implementation Gates

#### Simplicity Gate (Article VII)
- [ ] Using ≤ 3 modules?
- [ ] No future-proofing?

#### Anti-Abstraction Gate (Article VIII)
- [ ] Using framework directly?
- [ ] Single model representation?

#### Integration-First Gate (Article IX)
- [ ] Contracts defined?
- [ ] Real test environment planned?
```

These gates act as compile-time checks for architectural principles. The AI cannot proceed without passing them or documenting justified exceptions.

## Functional vs. Technical Separation

One of the hardest things in SDD is maintaining the separation between:

- **Spec** → functional: *what* the system does and *why*
- **Plan** → technical: *how* it does it

Signs you've mixed them:
- Spec mentions specific frameworks ("use FastAPI for...")
- Plan restates user stories instead of making technical decisions

When you notice this, push framework decisions to the plan and push user outcomes back to the spec.

## Supporting Documents

For larger features, `/speckit.plan` also generates:

- **`research.md`** — library comparisons, performance benchmarks, security implications
- **`data-model.md`** — entity schemas and relationships
- **`contracts/`** — API contracts (REST endpoints, CLI interfaces) that become the basis for contract tests

Review these before running `/speckit.tasks`. They feed directly into task generation.
