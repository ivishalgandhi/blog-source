# Real Example: This Repo

`.specify/auth-for-docs/` — already in this codebase.

```
.specify/
└── auth-for-docs/
    ├── spec.md    ← Google OAuth user stories + acceptance criteria
    ├── plan.md    ← AuthContext, DocRoot swizzle, LoginPage architecture
    └── tasks.md   ← T01–T13 with dependencies and status tracking
```

This is spec-driven development **you've already done** — before you knew it had a name.

---

# The Complete SDD Pipeline

```
  Constitution
      |
      | governs all
      v
   Specify  ──reviewed──>  Plan  ──reviewed──>  Tasks  ──executed──>  Implement
                                                                           |
                                                        feedback loop  <──┘
```

- **Constitution** governs all phases
- **Human review** required at every arrow
- **Feedback** from implementation refines the spec

```
Constitution → Specify → Plan → Tasks → Implement
```

Each step is versioned in git. Each decision is traceable.
