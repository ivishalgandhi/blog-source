---
sidebar_position: 7
title: Tools & Resources
---

# SDD Tools & Resources

## The Big Three SDD Tools

### spec-kit (GitHub)
**[github.com/github/spec-kit](https://github.com/github/spec-kit)**

GitHub's open-source SDD toolkit. The most customisable of the three because all artifacts live directly in your repo as markdown files.

- **Install:** `uvx spec-kit init`
- **Workflow:** Constitution → `/speckit.specify` → `/speckit.plan` → `/speckit.tasks`
- **Works with:** Windsurf, Cursor, Claude, GitHub Copilot
- **Artifact location:** `.specify/[feature-name]/`
- **Approach:** Spec-first (aspires to spec-anchored)
- **Best for:** Teams who want full control and customisability

### Kiro
**[kiro.dev](https://kiro.dev)**

The most lightweight of the three. A VS Code-based IDE with SDD built in.

- **Workflow:** Requirements → Design → Tasks (3 documents)
- **Memory bank:** Called "steering" — flexible, not prescriptive
- **Default steering files:** `product.md`, `structure.md`, `tech.md`
- **Approach:** Spec-first
- **Best for:** Individuals or small teams wanting a guided, opinionated experience
- **Watch out:** Can feel like a sledgehammer for small tasks

### Tessl Framework
**[docs.tessl.io](https://docs.tessl.io)**

The most ambitious — aspires to spec-as-source. Currently in private beta.

- **Key idea:** Specs marked with `@generate` produce code files; `// GENERATED FROM SPEC - DO NOT EDIT` at the top
- **Workflow:** CLI doubles as MCP server
- **Approach:** Spec-anchored, exploring spec-as-source
- **Best for:** Teams willing to experiment with the leading edge of SDD

## Key Reading

| Resource | Why Read It |
|----------|-------------|
| [Martin Fowler: SDD Tools](https://martinfowler.com/articles/exploring-gen-ai/sdd-3-tools.html) | Honest, balanced assessment of all three tools — including the tradeoffs and open questions |
| [spec-driven.md](https://github.com/github/spec-kit/blob/main/spec-driven.md) | The philosophy behind spec-kit — the best single document explaining SDD |
| [GitHub blog: spec-kit](https://github.blog/ai-and-ml/generative-ai/spec-driven-development-with-ai-get-started-with-a-new-open-source-toolkit/) | Practical introduction from GitHub |
| [Awesome SDD](https://github.com/Engineering4AI/awesome-spec-driven-development) | Curated list of all SDD tools, frameworks, MCP servers, and resources |
| [O'Reilly: How to write a good spec for AI agents](https://www.oreilly.com/radar/how-to-write-a-good-spec-for-ai-agents/) | Practical guidance on spec quality |

## Related Tools from the Ecosystem

### Specification Tools
- **[lean-spec](https://github.com/codervisor/lean-spec)** — lightweight specs under 2,000 tokens, designed for humans and AI
- **[OpenSpec](https://github.com/Fission-AI/OpenSpec)** — aligns developers and AI on specifications before code is written
- **[adversarial-spec](https://github.com/zscole/adversarial-spec)** — iteratively refines specs by facilitating debate between multiple LLMs

### Development Frameworks
- **[BMAD-METHOD](https://github.com/bmad-code-org/BMAD-METHOD)** — Breakthrough Method for AI-driven Agile Development
- **[fspec](https://github.com/sengac/fspec)** — Gherkin-based spec system that auto-generates tests linked to business rules
- **[claude-codepro](https://github.com/maxritter/claude-codepro)** — combines SDD, TDD, and automated quality enforcement

### Workflow & IDE
- **[spec-kit-command-cursor](https://github.com/madebyyaris/spec-kit-command-cursor)** — spec-kit for Cursor IDE
- **[mcp-server-spec-driven-development](https://github.com/formulahendry/mcp-server-spec-driven-development)** — MCP server providing structured prompts for SDD phases

## Getting Started Checklist

```markdown
Day 1:
- [ ] Read spec-driven.md (20 min)
- [ ] Run `uvx spec-kit init` on a new project (see `docs/demos/health-check-scanner/` for a ready Postgres setup)
- [ ] Write a 4-article constitution for your team

Day 2–3:
- [ ] Pick your next feature (3–8 point story)
- [ ] Run /speckit.specify and review the output
- [ ] Run /speckit.plan and check constitutional compliance
- [ ] Run /speckit.tasks and execute with Windsurf

Week 1 retrospective:
- [ ] Did the AI follow the spec? Where did it diverge?
- [ ] What would you add to your constitution?
- [ ] Was the workflow right-sized for the feature?
```

## Honest Tradeoffs

From Martin Fowler's analysis — things to keep in mind:

- **Workflow size matters** — the full spec-kit workflow is overkill for a 1-point bug fix. Right-size the process to the problem.
- **AI doesn't always follow all instructions** — even with extensive specs and templates, agents can ignore notes or go overboard on instructions. Spec-first adds structure but doesn't eliminate non-determinism.
- **Review burden** — spec-kit creates many markdown files. Reviewing them well takes time. If you skim, you lose the benefit.
- **Spec-anchored is hard** — keeping specs in sync with code as both evolve is the unsolved challenge of SDD. Start with spec-first.

> "An effective SDD tool would have to cater to an iterative approach — but small work packages almost seem counter to the idea of SDD." — Martin Fowler
