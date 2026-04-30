# Rules = Constitution

Both define **immutable principles** the AI must always follow.

```
# .windsurfrules                            # constitution.md

## Code Style                               ## Article III: Simplicity
- No abstractions for single-use code       - No abstractions for single-use code
- Match existing style                      - Maximum 3 top-level modules
- Minimal changes only                      - Junior engineer understands in 5 min

## Testing                                  ## Article II: Test-First
- Always write tests before implementation  - Tests written before implementation
- Tests must fail before implementation     - Tests must fail (Red) before code
```

**The constitution is your team's rules file — agreed upon, version-controlled, AI-enforced.**

---

# Workflows = Tasks

Both are **executable, ordered step sequences** the AI follows.

```
# .windsurf/workflows/deploy.md             # tasks.md (spec-kit)

---                                         ## [T03] Write failing tests
description: Deploy the application         ## [T04] Implement connectivity check
---                                         ## [T05] Write CLI command [P]

1. Run tests                                Status tracking:
2. Build Docker image                       - [ ] T03 — write tests
3. Push to registry                         - [x] T04 — implemented
4. Deploy to production                     - [ ] T05 — in progress
```
