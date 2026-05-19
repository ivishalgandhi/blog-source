# Research: Patroni HA Book Companion Code

**Date**: 2026-05-18
**Feature**: specs/002-companion-code/

## Decisions

### Decision: Docker Compose for all local labs (LAB-03-A, LAB-08-A, LAB-A-A)

**Rationale**: Docker Compose is the most portable substrate. Readers on macOS, Windows (WSL2), and Linux can all run it. It requires no cloud credentials, no VM provisioning, and teardown is reliable. The book's lab structure contract requires at least one of {proxmox-lxc, docker, kind, terraform-aws, terraform-gcp}; Docker satisfies this with the lowest barrier to entry.

**Alternatives considered**:
- kind/k3d: More complex, requires Kubernetes knowledge that not all DBAs have.
- Proxmox LXC: Linux-only, requires a Proxmox host.
- Vagrant: Heavier, requires VirtualBox/VMware.

### Decision: Terraform for cloud labs (LAB-08-B)

**Rationale**: Cross-region DR requires actual cloud infrastructure. Terraform is the industry standard for multi-cloud IaC. The spec requires ≥2 cloud providers (AWS + GCP). Terraform modules abstract provider differences.

**Alternatives considered**:
- CloudFormation (AWS-only): violates multi-cloud requirement.
- Pulumi: Overkill for reference labs; Terraform is more familiar to the target audience.

### Decision: Ansible for kernel-level labs (LAB-B-A)

**Rationale**: Watchdog requires kernel module loading (`modprobe softdog`) and iptables manipulation. These operations need root access on real hosts. Ansible is the standard for bare-metal / VM configuration management and supports both local and SSH-based execution.

**Alternatives considered**:
- Docker: Cannot safely load kernel modules or reboot the host.
- Shell scripts only: Harder to maintain and less idempotent than Ansible.

### Decision: pydantic-ai + litellm for agent scaffolds

**Rationale**: pydantic-ai provides typed, validated agent interfaces (critical for the 6-state lifecycle). litellm provides provider portability (OpenAI, Anthropic, Bedrock, local models) with a single API. This matches the book's Chapter 11 specification exactly.

**Alternatives considered**:
- LangChain: More complex, heavier dependency tree.
- Raw OpenAI SDK: Locks to one provider, violates portability requirement.
- CrewAI: Multi-agent orchestration is overkill for single-workflow scaffolds.

### Decision: Grafana JSON + Prometheus YAML for observability

**Rationale**: These are the de-facto standards in the target audience's environments. Grafana dashboards can be imported via API or UI. Prometheus rules are applied via ConfigMap or direct file mount.

**Alternatives considered**:
- Datadog/New Relic dashboards: Vendor-specific, violates portability.
- Custom UI: Far out of scope.

## Resolved Clarifications

No [NEEDS CLARIFICATION] markers were present in the spec. All technology choices are justified by the spec's functional requirements and the book chapter source of truth.

## References

- Book Ch. 03 (03-deploying-patroni-cluster.mdx): LAB-03-A source of truth
- Book Ch. 04 (04-configuration-best-practices.mdx): CONFIG-04-REF source of truth
- Book Ch. 06 (06-observability-monitoring.mdx): Dashboards and alerts source of truth
- Book Ch. 08 (08-backup-dr-pitr.mdx): LAB-08-A and LAB-08-B source of truth
- Book Ch. 11 (11-agentic-ai-autonomous-ops.mdx): Agent scaffolds source of truth
- Book Appendix A (appendix-a-python-runtime.mdx): LAB-A-A source of truth
- Book Appendix B (appendix-b-patroni-internals.mdx): LAB-B-A source of truth
