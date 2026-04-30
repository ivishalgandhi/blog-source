# Why Now?

Three forces converging:

- **AI crossed a threshold** — LLMs can reliably translate natural language specs into working code
- **Complexity is exponential** — modern systems have dozens of services; manual alignment fails
- **Pace of change demands it** — pivots are normal; re-generating from spec beats manual rewrites

> With SDD, a change in requirements triggers a **systematic regeneration**, not a manual
> search-and-fix through the codebase.

---

## Vibe Coding (Code-First) vs. Spec-Driven (Intent-First)

| | Vibe Coding | Spec-Driven |
|---|---|---|
| **Source of truth** | Latest code state | Structured specification |
| **Control** | Successive prompting | Explicit validation gates |
| **Failure mode** | Silent architectural drift | Visible test failures |
| **Change management** | Manual search-and-fix | Regenerate from spec |

> *"Why did it build that? That's not what I meant."*
> — every developer who has ever vibe-coded
