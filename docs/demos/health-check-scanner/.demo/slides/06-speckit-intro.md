# Part 2 — The spec-kit Workflow

---

## What is spec-kit?

GitHub's open-source SDD toolkit — distributed as a CLI.

```bash
uvx spec-kit init      # set up your project
/speckit.specify       # idea → spec.md
/speckit.plan          # spec.md → plan.md
/speckit.tasks         # plan.md → tasks.md
```

- Works with Windsurf, Cursor, Claude, GitHub Copilot
- All artifacts live in your repo (`.specify/` folder)
- Versioned alongside code in feature branches
- Fully customisable templates

**Traditional approach:** ~12 hours of documentation work
**With spec-kit:** ~15 minutes, fully structured, traceable
