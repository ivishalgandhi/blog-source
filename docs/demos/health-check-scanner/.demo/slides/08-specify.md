# Step 1: `/speckit.specify`

**Input:** A plain English description of what you want to build.

**Output:** `spec.md` with:
- Numbered user stories in "As a … I want … So that …" format
- Acceptance criteria in GIVEN / WHEN / THEN format
- Edge cases and constraints
- Technical constraints (what's out of scope)

```bash
# You type:
/speckit.specify PostgreSQL health check scanner with FastAPI and CLI

# spec-kit creates:
.specify/001-health-scanner/spec.md
```

---

## What spec.md looks like

```markdown
# Spec: PostgreSQL Health Check Scanner

## US-1: Database Connectivity Check
**As a** platform engineer
**I want** to verify the database is reachable
**So that** I know immediately if it is down

**Acceptance Criteria:**
- [ ] GET /health/db returns {"status": "healthy"} when DB is up
- [ ] Returns 503 with error message when DB is down
- [ ] Response includes checked_at timestamp and duration_ms

## EC-1: Database Unreachable
**Given** DATABASE_URL points to an unreachable host
**When** any health check runs
**Then** return status "unhealthy" — never a 500
```
