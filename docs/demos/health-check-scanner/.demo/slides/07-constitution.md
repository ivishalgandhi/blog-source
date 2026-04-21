# The Constitution — Project DNA

**The most important file in your project.**

`memory/constitution.md` — immutable principles that apply to every single AI interaction.

```markdown
## Article I: Spec-First Imperative
No implementation shall be written without a corresponding spec.md.

## Article II: Test-First Development
No implementation code before tests are written AND failing.

## Article III: Simplicity Over Cleverness
Maximum 3 top-level modules. No future-proofing.

## Article IV: Observable by Default
All CLI commands produce structured output. Errors are explicit.
```

Think of it as: **the rules file your whole team agrees on, enforced by AI.**

---

## The 9 Articles (spec-kit default)

| Article | Principle |
|---------|-----------|
| I | **Library-First** — every feature starts as a standalone library |
| II | **CLI Interface** — all libraries expose a text-in / text-out CLI |
| III | **Test-First** — tests before implementation, always |
| IV | *Integration tests* — contract tests before implementation |
| V | *Research-driven* — research phase before planning |
| VI | *Versioning* — specs are branched and versioned |
| VII | **Simplicity Gate** — ≤ 3 projects, no future-proofing |
| VIII | **Anti-Abstraction** — use framework directly, don't wrap it |
| IX | **Integration-First** — real databases over mocks |
