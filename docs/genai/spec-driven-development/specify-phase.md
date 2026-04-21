---
sidebar_position: 3
title: Phase 1 — Specify
---

# Phase 1: Specify

## What Happens

The specify phase transforms a plain-English description into a structured specification (`spec.md`) that both humans and AI can act on.

**Command:**
```bash
/speckit.specify
[your feature description in plain English]
```

**What spec-kit does automatically:**
1. Scans existing specs to determine the next feature number (001, 002, …)
2. Creates a feature branch (`001-health-scanner`)
3. Generates `spec.md` from a template, populated with your requirements
4. Creates the directory structure `.specify/001-health-scanner/`

## The Structure of spec.md

A well-formed spec has five sections:

### 1. Overview
One paragraph describing the feature and its purpose. Written in plain language, not technical jargon.

### 2. User Stories
Each story follows the standard format:

```markdown
### US-1: [Story Name]
**As a** [type of user]
**I want** [goal]
**So that** [benefit]

**Acceptance Criteria:**
- [ ] [Specific, testable outcome]
- [ ] [Another testable outcome]
```

Acceptance criteria are the contract. They become tests. Write them so you could hand them to a QA engineer and they'd know exactly what to verify.

### 3. Edge Cases
```markdown
### EC-1: [Edge Case Name]
**Given** [initial state]
**When** [action or event]
**Then** [expected outcome — not "should fail gracefully", but the exact behavior]
```

### 4. Technical Constraints
What's allowed: frameworks, libraries, patterns.  
What's not: things explicitly out of scope.

### 5. Out of Scope
Explicitly stating what you're NOT building is as important as stating what you are.

## Real Example: Health Check Scanner

```markdown
# Spec: PostgreSQL Health Check Scanner

## Overview
A Python tool that checks PostgreSQL health via REST API and CLI.
Operators can verify connectivity, detect latency degradation, and
monitor connection pool usage.

## US-1: Database Connectivity Check
**As a** platform engineer
**I want** to verify the database is reachable
**So that** I know immediately if it is down

**Acceptance Criteria:**
- [ ] GET /health/db returns {"status": "healthy"} with HTTP 200 when DB is up
- [ ] Returns {"status": "unhealthy", "error": "<reason>"} with HTTP 503 when down
- [ ] Response includes checked_at timestamp and duration_ms
- [ ] CLI: `scanner check` prints a colored status line to stdout

## EC-1: Database Unreachable
**Given** DATABASE_URL points to an unreachable host
**When** any health check runs
**Then** return status "unhealthy" — never a 500 error

## Technical Constraints
- Python 3.11+, FastAPI, Typer, psycopg2-binary
- No ORM — raw SQL only (SELECT 1, pg_stat_activity)
- Docker Compose for local Postgres

## Out of Scope
- MySQL/SQLite support
- Authentication on API endpoints
- Prometheus metrics export
```

## Tips for Writing Good Specs

- **Be specific about outputs** — "returns a status" is weak; "returns `{"status": "healthy"}` with HTTP 200" is strong
- **One user story per observable outcome** — don't combine two different behaviors into one story
- **Write edge cases for the happy-path failure modes** — what happens when the database is down? When config is missing?
- **Defer "how" to the plan phase** — the spec describes *what* and *why*, never *how*
- **Review the spec before running `/speckit.plan`** — fix ambiguities now, not after an hour of AI planning

## What AI Generates vs. What You Write

In a pure SDD workflow, AI *drafts* the spec from your description, and you *review and refine* it.

The draft will often be:
- Too verbose — simplify user stories, cut redundant criteria
- Missing edge cases — add the failure modes you know from experience
- Mixing functional and technical concerns — push implementation details to plan.md

Your expertise turns a mediocre AI draft into a precise spec.
