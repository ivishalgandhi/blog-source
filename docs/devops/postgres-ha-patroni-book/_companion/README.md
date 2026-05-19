# Patroni HA Book Companion Code

![Companion CI](https://github.com/ivishalgandhi/blog-source/actions/workflows/companion-ci.yml/badge.svg)

Companion code repository for **Mastering PostgreSQL High Availability with Patroni (2026 Edition)**.

Book source: [blog-source/docs/devops/postgres-ha-patroni-book](https://github.com/ivishalgandhi/blog-source/tree/main/docs/devops/postgres-ha-patroni-book)

## Quick Reference

| Artifact ID | Path | Chapter | What it does |
|-------------|------|---------|--------------|
| LAB-03-A | `docker/lab-03-a/` | Ch. 03 | 3-node Patroni + etcd: deploy, kill leader, failover, recover |
| LAB-08-A | `docker/lab-08-a/` | Ch. 08 | pgBackRest PITR: full + incremental + restore |
| LAB-08-B | `terraform/lab-08-b/` | Ch. 08 | Cross-region disaster recovery (AWS/GCP) |
| LAB-A-A | `docker/lab-a-a/` | Appendix A | Python 3.8 → 3.12 rolling upgrade |
| LAB-B-A | `ansible/lab-b-a/` | Appendix B | Watchdog and DCS lease pathology |
| LAB-13-A | `docker/lab-13-a/` | Ch. 13 | 2-node network partition test (iptables chaos) |
| LAB-13-B | `docker/lab-13-b/` | Ch. 13 | 3-node quorum recovery test (iptables chaos) |
| CONFIG-04-REF | `patroni/config-04-ref.yml` | Ch. 04 | Annotated reference patroni.yml |
| DASH-06-CORE | `dashboards/dash-06-core.json` | Ch. 06 | Core fleet Grafana dashboard |
| DASH-06-LAG | `dashboards/dash-06-lag.json` | Ch. 06 | Replication lag Grafana dashboard |
| ALERT-06-LAG | `dashboards/alerts/alert-06-lag.yaml` | Ch. 06 | Replication lag > 30s |
| ALERT-06-LEADER-FLAP | `dashboards/alerts/alert-06-leader-flap.yaml` | Ch. 06 | Leader flapping |
| ALERT-06-WAL-BLOAT | `dashboards/alerts/alert-06-wal-bloat.yaml` | Ch. 06 | WAL bloat |
| ALERT-06-DCS-PARTITION | `dashboards/alerts/alert-06-dcs-partition.yaml` | Ch. 06 | DCS partition |
| ALERT-06-CERT-EXPIRY | `dashboards/alerts/alert-06-cert-expiry.yaml` | Ch. 06 | Certificate expiry |
| AGENT-11-* | `agents/` | Ch. 11 | 5 Python agent scaffolds (pydantic-ai + litellm) |
| CHAOS-03-A | `chaos/chaos-03-a.sh` | Ch. 03 | Leader kill chaos script |

## Directory Layout

```
docker/           # Docker Compose labs
  lab-03-a/       # 3-node Patroni + etcd cluster (Ch. 03)
  lab-08-a/       # Backup/DR PITR lab (Ch. 08)
  lab-13-a/       # 2-node network partition test (Ch. 13)
  lab-13-b/       # 3-node quorum recovery test (Ch. 13)
  lab-a-a/        # Python runtime rolling upgrade (Appendix A)
terraform/        # Terraform modules
  lab-08-b/       # Cross-region restore lab (Ch. 08)
ansible/          # Ansible roles
  lab-b-a/        # Watchdog and lease pathology lab (Appendix B)
patroni/          # Reference configurations
  config-04-ref.yml  # Annotated reference patroni.yml (Ch. 04)
dashboards/       # Grafana dashboards and alert rules
  dash-06-core.json
  dash-06-lag.json
  alerts/            # 5 Prometheus alert rule YAMLs
agents/           # Agentic AI reference implementations (Ch. 11)
  monitoring/        # AGENT-11-MON
  predictive-failover/ # AGENT-11-PF
  self-tuning/       # AGENT-11-ST
  auto-remediation/  # AGENT-11-AR
  nl-ops/            # AGENT-11-NL
  shared/            # Common lifecycle module + litellm config
chaos/            # Chaos/fault-injection scripts
  chaos-03-a.sh      # Leader kill script (Ch. 03)
docker/common/    # Shared Docker Compose patterns
dashboards/alerts/ # Prometheus alert rules
```

## Running a Lab

Each lab has a `Makefile` with these targets:

```bash
cd docker/lab-03-a
make setup     # Deploy the lab environment
make break     # Simulate the failure condition
make verify    # Assert expected outcome
make recover   # Return to healthy state
make teardown  # Remove all resources
```

## CI Status

The companion code is validated on every PR via GitHub Actions:
- Docker labs run end-to-end (setup → break → verify → recover → teardown)
- Terraform modules are validated with `terraform validate && terraform fmt -check`
- Agent scaffolds install and run in dry-run mode
- Dashboard JSON and alert YAML are syntax-checked

## Contributing

When adding a new artifact:
1. Create the files in the appropriate directory
2. Add the artifact ID to `ARTIFACT-IDS.md`
3. Update `_companion-links.json` in the book prose
4. Add CI validation if applicable
5. Update this README

## License

MIT
