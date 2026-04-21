# Step 2: `/speckit.plan`

**Input:** `spec.md` + your architecture hints

**Output:** `plan.md` with:
- Architecture overview and component diagram
- Technology choices with documented rationale
- Data models and API contracts
- File structure
- Security considerations and test strategy

Every technical decision **traces back** to a specific user story.

---

## What plan.md looks like

```markdown
# Technical Plan: Health Check Scanner

## Architecture
FastAPI app + Typer CLI sharing a checks.py core module.
Docker Compose provides Postgres for local development.

## Why FastAPI?
- US-1 requires REST endpoints → FastAPI's type-safe responses
- US-4 requires async scan → FastAPI handles concurrent checks
- Pydantic models enforce the HealthResult schema from the spec

## File Structure
src/
├── main.py      # FastAPI app (serves US-1, US-2, US-3, US-4)
├── cli.py       # Typer CLI (serves US-1, US-4 from terminal)
├── checks.py    # Core logic (shared by API and CLI)
└── models.py    # Pydantic models
```
