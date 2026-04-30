# Step 3: `/speckit.tasks`

**Input:** `plan.md` + supporting design docs

**Output:** `tasks.md` — an executable, ordered task list

```markdown
## [T01] Set up project structure          [depends: none]
## [T02] Write Pydantic models              [depends: T01]
## [T03] Write tests for check_connectivity [depends: T02]  ← TEST FIRST
## [T04] Implement check_connectivity       [depends: T03]
## [T05] Write tests for check_latency     [depends: T02]  [P] ← parallel
## [T06] Implement check_latency           [depends: T05]  [P]
```

`[P]` marks tasks safe to run in parallel.
Windsurf executes tasks one by one, checking off as it goes.

---

## The full artifact chain

```
.specify/
└── 001-health-scanner/
    ├── spec.md          ← what to build & why  (human-reviewed)
    ├── plan.md          ← how to build it       (human-reviewed)
    ├── tasks.md         ← step-by-step tasks    (AI executes)
    ├── research.md      ← library comparisons   (auto-generated)
    ├── data-model.md    ← entity schemas        (auto-generated)
    └── contracts/       ← API contracts         (auto-generated)
        └── openapi.md
```

**Traditional approach:** ~12 hours of documentation work
**With spec-kit:** ~15 minutes, fully structured, traceable
