# Part 5 — Practical Guidance

---

## Be honest about the tradeoffs

SDD is powerful but not a silver bullet. From Martin Fowler's research:

- **"Sledgehammer for a nut"** — for a small bug, a full spec workflow is overkill
- **"False sense of control"** — AI doesn't always follow all instructions perfectly
- **"Reviewing markdown is harder than reviewing code"** — spec-kit creates *many* files

> "An effective SDD tool would cater to an iterative approach — and small work packages
> almost seem counter to the idea of SDD."

---

## When to use SDD

| Situation | Use SDD? |
|-----------|----------|
| New feature (3–8 points) | Yes — spec-first pays off |
| Greenfield project | Yes — absolutely |
| Small bug fix (< 1 point) | No — overkill, just write the fix |
| Major refactor | Yes — spec the outcome, not the steps |
| Prototype / spike | Maybe — spec-first then throw away |
| Emergency hotfix | No — fix first, spec retrospectively |

**Start with Level 1 (spec-first). Earn Level 2 (spec-anchored).**
