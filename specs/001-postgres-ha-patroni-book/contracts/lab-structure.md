# Lab Structure Contract

Every hands-on lab section inside a chapter MUST follow this structure so readers can rely on identical shape across chapters and CI can extract/validate them.

## Required heading anchor

```md
## Lab <ArtifactRef id="LAB-NN-X" /> — <short title>
```

## Required subsections (in order)

1. **Supported substrates**: list ≥1 of `proxmox-lxc`, `docker` (Docker / Docker Compose), `kind` / `k3d`, `terraform-aws`, `terraform-gcp`, `terraform-azure`. Each listed substrate MUST have working setup/verify/teardown commands in this lab.
2. **Prerequisites**: explicit version pins (Postgres, Patroni, DCS, K8s/kind, Terraform, Ansible) and a system-resource floor (CPU/RAM/disk).
3. **Setup**: copy-pasteable commands wrapped in fenced blocks with explicit language tags (`bash`, `yaml`, etc.). Must end with a "Verify clean state" command.
4. **What you'll learn**: 2–4 bullets tied to the chapter's checklist items.
5. **Break it on purpose** ⚠️: prominent admonition (`:::danger`) at the start; the destructive command(s) with a brief explanation of what they simulate (e.g., "DCS partition", "leader OOM", "cert expiry").
6. **Verification**: an observable assertion — exact command + expected output excerpt or metric value. CI uses this section to assert success.
7. **Recovery procedure** (FR-020): commands to return the cluster to a healthy state, paired with the break step. Must work without external help.
8. **Teardown** (FR-003): explicit cleanup that returns the host to the pre-Setup state. Must remove containers/clusters/volumes/credentials created during the lab.
9. **What this tells you about production**: 1–3 transferable takeaways linking back to the chapter's checklist or a case-study pattern.

## Rules

- The destructive command in **Break it on purpose** MUST be preceded by an explicit guardrail callout naming the safe environment (lab cluster, kind, ephemeral Compose stack) and warning against running it in production. (FR-012)
- The lab MUST be runnable end-to-end from a clean machine using only the Prerequisites section and the companion repo. No undocumented setup steps. (SC-007)
- Every command that requires elevated privileges MUST be flagged inline.
- Every artifact referenced (Terraform module, Ansible role, K8s manifest, `patroni.yml`, dashboard) MUST be by stable artifact ID per `artifact-id.md`.
- The Teardown section MUST NOT be optional or marked "if needed".
