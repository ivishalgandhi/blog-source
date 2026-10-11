# Claude Certified Architect (CCA-F) — 10-Week Study Plan

## Exam Snapshot

| Attribute | Detail |
|---|---|
| **Format** | 60 scenario-based multiple-choice questions |
| **Duration** | 120 minutes (2 min/question average) |
| **Passing** | 720/1000 (roughly 75%) |
| **Delivery** | Remote proctored, closed-book, no AI assistance |
| **Scenarios** | 4 of 6 randomly selected per exam |
| **Cost** | $99 per attempt |
| **Validity** | 2 years |

## 6 Exam Scenarios (4 appear per test)

1. **Customer Support Resolution Agent** — Agent SDK, high-ambiguity tickets, MCP tools, escalation
2. **Code Generation with Claude Code** — Generation, refactor, debug, docs, slash commands, CLAUDE.md
3. **Multi-Agent Research System** — Coordinator delegates to search/analysis/synthesis agents
4. **Developer Productivity Tools** — Agent SDK, codebase exploration, boilerplate, automation
5. **Claude Code in CI/CD** — Automated review, tests, PR feedback, reducing false positives
6. **Structured Data Extraction** — Unstructured docs → validated JSON, schema enforcement, edge cases

## 5 Domains & Weights

| Domain | Weight | Focus |
|---|---|---|
| D1: Agentic Architecture & Orchestration | 27% | Agentic loops, multi-agent patterns, hooks, task decomposition, session state |
| D2: Tool Design & MCP Integration | 18% | Tool schemas, structured errors, MCP servers, tool distribution |
| D3: Claude Code Configuration & Workflows | 20% | CLAUDE.md, slash commands, plan mode, CI/CD, team workflows |
| D4: Prompt Engineering & Structured Output | 20% | Explicit criteria, few-shot, JSON-schema enforcement, validation-retry |
| D5: Context Management & Reliability | 15% | Escalation, ambiguity resolution, large codebase context, human review |

## Your Advantage

You already use:
- ✅ Claude Code daily (CLAUDE.md, slash commands, plan mode)
- ✅ Hermes Agent with MCP (Devin, Honcho)
- ✅ Multi-agent orchestration (Hermes → Devin delegation)
- ✅ Prompt engineering for structured output

**Gaps to close:**
- ⚠️ Claude Agent SDK (not just Claude Code)
- ⚠️ Lifecycle hooks and enforcement patterns
- ⚠️ Formal evaluation frameworks for agent reliability
- ⚠️ Exam-style scenario reasoning (tradeoff decisions, not just implementation)

---

## 10-Week Study Plan

### Phase 1: Foundations (Weeks 1–3)
**Goal:** Master D1 (Agentic Architecture) and D2 (Tool Design/MCP)

**Week 1 — Agentic Architecture & Orchestration**
- [ ] Read: Anthropic "Building Effective Agents" research paper
- [ ] Read: Claude Agent SDK Overview docs
- [ ] Study: Agentic loop lifecycle — tool_use → execute → observe → respond
- [ ] Study: Coordinator-subagent patterns (when to delegate vs. handle)
- [ ] Build: A simple agentic loop using the Claude API (not Claude Code)
- [ ] Practice: 5 scenario questions on task decomposition

**Week 2 — Multi-Agent Orchestration**
- [ ] Study: Agent Teams vs. Subagents in Claude Code
- [ ] Study: Session state management across agents
- [ ] Study: Hook interception — pre/post tool call enforcement
- [ ] Build: Two-agent system: coordinator + research specialist
- [ ] Practice: 5 scenario questions on multi-agent tradeoffs

**Week 3 — Tool Design & MCP Integration**
- [ ] Study: MCP protocol spec — tools, resources, prompts
- [ ] Study: Tool description best practices (clarity, boundaries, examples)
- [ ] Study: Structured error responses for MCP tools
- [ ] Build: An MCP server with 3 tools (local or cloud)
- [ ] Practice: 5 scenario questions on tool distribution across agents

---

### Phase 2: Applied Knowledge (Weeks 4–6)
**Goal:** Master D3 (Claude Code) and D4 (Prompt Engineering/Structured Output)

**Week 4 — Claude Code Deep Dive**
- [ ] Study: CLAUDE.md hierarchy — project → directory → file-specific rules
- [ ] Study: Custom slash commands and Agent Skills
- [ ] Study: Plan mode vs. direct execution — decision framework
- [ ] Practice: Build a CLAUDE.md for a real project with path-specific rules
- [ ] Practice: 5 scenario questions on when to use plan mode

**Week 5 — Prompt Engineering Mastery**
- [ ] Study: Explicit criteria in system prompts (constraints, output format, examples)
- [ ] Study: Few-shot prompting structure — example selection, ordering, diversity
- [ ] Study: Chain-of-thought elicitation (not just "think step by step")
- [ ] Build: A prompt that reliably produces structured JSON via tool_use
- [ ] Practice: 5 scenario questions on prompt failure diagnosis

**Week 6 — Structured Output & Validation**
- [ ] Study: JSON schema enforcement via tool_use
- [ ] Study: Validation-retry loops — when to retry vs. escalate
- [ ] Study: Multi-pass review patterns (generation → validation → correction)
- [ ] Build: A data extraction pipeline with schema validation and retry
- [ ] Practice: 5 scenario questions on edge case handling in structured output

---

### Phase 3: Reliability & Exam Prep (Weeks 7–10)
**Goal:** Master D5 (Context/Reliability) and simulate exam conditions

**Week 7 — Context Management & Reliability**
- [ ] Study: Long-horizon context strategies — summarization, windowing, caching
- [ ] Study: Escalation patterns — confidence thresholds, human handoff
- [ ] Study: Error propagation in multi-agent setups
- [ ] Study: Information provenance and handling contradictions
- [ ] Practice: 5 scenario questions on reliability design

**Week 8 — Integration & Hands-On Exercises**
- [ ] Build: Multi-tool agent with escalation logic (official Anthropic exercise)
- [ ] Build: Configure Claude Code for team workflow with CLAUDE.md
- [ ] Build: Structured data extraction pipeline with validation
- [ ] Build: Debug a multi-agent research pipeline
- [ ] Review all 12 official sample questions with full reasoning

**Week 9 — Practice Exams**
- [ ] Take Full Practice Exam 1 (untimed, all 6 scenarios)
- [ ] Score and review: Identify weak domains
- [ ] Take Full Practice Exam 2 (timed, 120 minutes)
- [ ] Score and review: Focus on weakest 2 domains
- [ ] Re-study missed concepts with official docs

**Week 10 — Final Prep**
- [ ] Take Full Practice Exam 3 (timed, simulate exam day)
- [ ] Review: Anti-patterns cheatsheet
- [ ] Review: Decision frameworks (root cause > symptom, deterministic > probabilistic)
- [ ] Light review: Only weakest areas, no new material
- [ ] Exam day strategy: Skip hard questions, mark for review, answer everything

---

## Daily Study Structure (60–90 min/day)

| Day | Activity | Time |
|---|---|---|
| Mon | Read official docs / research paper | 45 min |
| Tue | Hands-on build exercise | 60 min |
| Wed | Read + take notes on domain concepts | 45 min |
| Thu | Practice scenario questions | 30 min |
| Fri | Hands-on build + debug | 60 min |
| Sat | Review week's notes, consolidate | 45 min |
| Sun | Rest or light review only | — |

---

## Official Resources (Free)

1. **Anthropic Academy (Skilljar)** — https://anthropic.skilljar.com
   - Building with Claude API (course)
   - Claude Tool Use (course)
   - Claude Code (course)
   - MCP Introduction (course)

2. **Official Exam Guide PDF** — Download from Anthropic Academy
   - Contains all 5 domains, task statements, 12 sample questions

3. **GitHub: 12-Week Training Program**
   - https://github.com/schinchli/cloud-certification-exam-prep
   - Structured weekly plan with exercises

4. **Anthropic Research Papers**
   - "Building Effective Agents" — https://www.anthropic.com/research/building-effective-agents
   - "Context as a Tool" (referenced in exam)

5. **Documentation**
   - Claude Tool Use Docs: https://docs.anthropic.com/en/docs/build-with-claude/tool-use
   - Claude Code Docs: https://docs.anthropic.com/en/docs/claude-code/overview
   - MCP Introduction: https://modelcontextprotocol.io/introduction
   - Claude Agent SDK: https://github.com/anthropics/anthropic-cookbook/tree/main/skills/agents

---

## Third-Party Study Guides

| Resource | URL | Notes |
|---|---|---|
| Claude Certifications (free) | https://claudecertifications.com | 30 lessons, 150+ questions, mock exam |
| dnacenta Study Guide | https://github.com/dnacenta/claude-certified-architect | Domain deep dives, anti-patterns |
| GovindaPaliwal Guide | https://github.com/GovindaPaliwal/Anthropic-Claude-Certified-Architect-Guide | Beginner-friendly, 5-week plan |
| claudecertifiedarchitect.net | https://claudecertifiedarchitect.net | Consolidated exam content |
| explainx.ai Blog | https://explainx.ai/blog/anthropic-claude-certified-architect-exam-2026 | Partner perspective |

---

## Anti-Patterns to Avoid (Exam Killers)

| Anti-Pattern | Why It Fails | Correct Approach |
|---|---|---|
| Giving one agent all tasks | Context rot, no specialization | Delegate to subagents with isolated context |
| Vague tool descriptions | Model picks wrong tool | Explicit boundaries, examples, error shapes |
| No escalation path | Agent loops on ambiguity | Confidence threshold → human handoff |
| Plan mode for trivial tasks | Wastes time | Direct execution for \<3 step changes |
| Probabilistic validation | False confidence | Deterministic schema validation + retry |
| Ignoring MCP for internal tools | Reinvents protocol | MCP standardizes tool interface |
| No session state cleanup | Memory leaks across runs | Lifecycle hooks for cleanup |

---

## Key Decision Frameworks (Memorize These)

**Plan Mode vs. Direct Execution:**
- Plan mode: >3 steps, cross-file changes, architectural decisions, needs review
- Direct execution: \<3 steps, single file, well-understood pattern

**Subagent vs. Same Session:**
- Subagent: Verbose intermediate output, isolated context, parallelizable
- Same session: Context still relevant, continuity matters

**Tool Use vs. Plain Text:**
- Tool use: Guaranteed structured output, deterministic parsing needed
- Plain text: Flexible output, human consumption, no downstream automation

**Escalate vs. Retry vs. Fail:**
- Retry: Transient error, same input might succeed
- Escalate: Ambiguous input, human judgment needed
- Fail: Invalid input, deterministic rejection

---

## Exam Day Strategy

1. **First pass (60 min):** Answer every question you know quickly. Skip hard ones. No question should take >2 min.
2. **Second pass (40 min):** Return to skipped questions. Eliminate obviously wrong distractors. Make educated guesses.
3. **Review (20 min):** Check flagged questions. Trust first instinct unless you find clear evidence to change.
4. **No blank answers:** Unanswered = incorrect. Always select something.

**Scenario questions follow a pattern:**
- Read the scenario once for context (30 seconds)
- Read the question stem
- Eliminate 1–2 distractors immediately
- Select the answer that balances correctness with production practicality

---

## Self-Assessment Checklist

Before booking the exam, verify:
- [ ] Can explain the agentic loop lifecycle cold
- [ ] Can design a coordinator-subagent system with tool distribution
- [ ] Can write a CLAUDE.md with path-specific rules
- [ ] Can implement structured output via tool_use with JSON schema
- [ ] Can design escalation logic with confidence thresholds
- [ ] Can debug a multi-agent pipeline with context isolation
- [ ] Can explain when to use plan mode vs. direct execution
- [ ] Score ≥80% on timed practice exam
- [ ] Can complete all 4 official hands-on exercises

## Estimated Total Study Time

| Phase | Weeks | Hours/Week | Total Hours |
|---|---|---|---|
| Foundations | 3 | 8–10 | 25–30 |
| Applied Knowledge | 3 | 8–10 | 25–30 |
| Reliability & Exam Prep | 4 | 10–12 | 40–48 |
| **Total** | **10** | | **90–108 hours** |

At 60–90 min/day, this is achievable in 10 weeks. At 2 hours/day, compress to 7–8 weeks.
