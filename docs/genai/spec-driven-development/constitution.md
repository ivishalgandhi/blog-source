---
sidebar_position: 2
title: The Constitution
---

# The Constitution

## What It Is

The constitution (`memory/constitution.md` in spec-kit, or `.windsurfrules` in Windsurf) is the most important file in your project.

It is a set of **immutable principles** that the AI must follow in every interaction, for every feature, forever.

> "The constitution acts as the architectural DNA of the system, ensuring that every generated implementation maintains consistency, simplicity, and quality." — spec-kit docs

Unlike a spec (which is feature-scoped) or a plan (which is task-scoped), the constitution is **project-scoped and permanent**.

:::tip Windsurf users
The constitution maps directly to your `.windsurfrules` file. See [SDD meets Windsurf](./windsurf-mapping.md) for a full side-by-side comparison.
:::

## The Nine Articles (spec-kit defaults)

Spec-kit defines nine articles. Here are the most impactful:

### Article I: Library-First Principle
Every feature must begin as a standalone library. This forces modular design from day one and prevents monolithic application code.

### Article II: CLI Interface Mandate
Every library must expose its functionality through a command-line interface with text in/text out. This enforces observability and testability — nothing is hidden inside opaque objects.

### Article III: Test-First Imperative
**The most transformative article.** No implementation code before:
1. Tests are written that describe the expected behavior
2. Those tests are validated and confirmed to **fail** (red phase)
3. Implementation makes them pass (green phase)

This completely changes how AI generates code — instead of producing code and hoping it works, the AI first generates tests that define behavior.

### Article VII: Simplicity Gate
- Maximum 3 projects/modules for initial implementation
- No future-proofing
- No features beyond what the spec requires

### Article VIII: Anti-Abstraction
- Use framework features directly rather than wrapping them
- Single model representation
- No abstractions for single-use code

### Article IX: Integration-First Testing
- Prefer real databases over mocked connections
- Use actual service instances over stubs
- Contract tests mandatory before implementation

## Writing Your Own Constitution

Start with 4–6 articles that encode your team's genuine non-negotiables. Keep it short — the AI reads this on every interaction.

**Template structure:**

```markdown
# Constitution: [Project Name]

## Article I: [Principle Name]
[One clear statement of the rule]

[Rationale — why this matters for your specific project]

## Article II: ...

## Amendment Log
| Date | Article | Change | Rationale |
|------|---------|--------|-----------|
```

## Example: Health Check Scanner Constitution

```markdown
# Constitution: Health Check Scanner

## Article I: Spec-First Imperative
No implementation written without a spec.md.
Workflow: spec → plan → tasks → code. Never the reverse.

## Article II: Test-First Development
Tests exist and fail (red) before any implementation code.
Tests document intent. Code documents implementation.

## Article III: Simplicity Over Cleverness
Maximum 3 top-level modules. No ORM — raw SQL only.
If a junior engineer cannot understand it in 5 minutes, simplify it.

## Article IV: Observable by Default
All CLI commands produce structured stdout output.
All API responses follow the HealthResult schema.
Errors are explicit and actionable — never silent.

## Article V: Integration-First Testing
Test against real Docker Postgres — no mocked connections.
```

## The Power of Immutability

The constitution's power comes from its constancy:

1. **Consistency across time** — code generated today follows the same principles as code generated next year
2. **Consistency across AI models** — different LLMs produce architecturally compatible outputs
3. **Architectural integrity** — every feature reinforces rather than undermines the system design
4. **Team alignment** — the constitution is a team agreement, not just an AI instruction

## Amendment Process

Principles are immutable, but they can be amended:

```markdown
## Amendment Log
| Date | Article | Change | Rationale |
|------|---------|--------|-----------|
| 2026-04-20 | III | Added "no ORM" constraint | psycopg2 direct queries are simpler for health checks |
```

Changes require explicit rationale and peer review. The amendment log makes the evolution of your team's standards visible and auditable.
