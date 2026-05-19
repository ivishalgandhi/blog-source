# Lab Output Contract

**Applies to**: All LAB-* artifacts

## Makefile Targets

Every lab MUST expose exactly these Make targets:

| Target | Purpose | Expected Duration |
|--------|---------|-------------------|
| `make setup` | Deploy the full lab environment | &lt; 5 minutes (Docker) / &lt; 15 minutes (Terraform) |
| `make break` | Simulate the failure condition described in the book | &lt; 1 minute |
| `make verify` | Assert that the expected outcome occurred | &lt; 1 minute |
| `make recover` | Return the environment to a healthy state | &lt; 2 minutes |
| `make teardown` | Remove all created resources | &lt; 2 minutes |

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | Failure (CI stops, logs uploaded) |
| 2 | Precondition not met (e.g., Docker not running, missing `.env` file) |

## Output Format

All targets MUST print a timestamped line on start and completion:

```
[YYYY-MM-DD HH:MM:SS] <TARGET> starting...
...
[YYYY-MM-DD HH:MM:SS] <TARGET> completed (exit 0)
```

The `verify` target MUST print the assertion being checked, e.g.:

```
[2026-05-18 14:30:00] VERIFY starting...
Assertion: patronictl list shows 1 Leader and 2 Replicas
[2026-05-18 14:30:01] VERIFY completed (exit 0)
```

## Environment Variables

Labs MAY use a `.env` file for configuration. A `.env.example` MUST be committed showing all required variables without real values. The `.env` file itself MUST be gitignored.
