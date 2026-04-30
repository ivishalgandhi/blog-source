# Part 4 — Live Demo

## PostgreSQL Health Check Scanner

We're going to build a **PostgreSQL health check tool** from scratch, spec-first, in 15 minutes.

**What we'll use:**
- `uvx spec-kit` — generates the spec/plan/tasks artifacts
- Windsurf Cascade — executes the tasks
- Docker Compose — provides a live Postgres instance

**The rule:** No code written until `spec.md` is reviewed and approved.

---

## Demo plan — 15 minutes

| Step | Action | Tool |
|------|--------|------|
| 1 | Start Postgres | `docker compose up -d` |
| 2 | Init spec-kit | `uvx spec-kit init` |
| 3 | Generate spec | `/speckit.specify` in Cascade |
| 4 | Review spec.md | Human review gate |
| 5 | Generate plan | `/speckit.plan` in Cascade |
| 6 | Review plan.md | Human review gate |
| 7 | Generate tasks | `/speckit.tasks` in Cascade |
| 8 | Execute | Cascade works through T01–T08 |
| 9 | Verify | `uvicorn` + `scanner check` live |
