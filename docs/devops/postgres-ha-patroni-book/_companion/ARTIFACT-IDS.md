# Companion Code Artifact IDs

This file maps artifact IDs used in the book prose (`_companion-links.json`) to physical file paths in the companion code repository.

## Labs

| ID | Path | Book Reference | Status |
|----|------|---------------|--------|
| LAB-03-A | `docker/lab-03-a/` | Ch. 03 "Deploying the First Cluster" | Implemented |
| LAB-08-A | `docker/lab-08-a/` | Ch. 08 "pgBackRest PITR" | Implemented |
| LAB-08-B | `terraform/lab-08-b/` | Ch. 08 "Cross-Region DR" | Implemented |
| LAB-A-A | `docker/lab-a-a/` | Appendix A "Python Rolling Upgrade" | Implemented |
| LAB-B-A | `ansible/lab-b-a/` | Appendix B "Watchdog & DCS Lease Pathology" | Implemented |
| LAB-13-A | `docker/lab-13-a/` | Ch. 13 "2-Node Partition Test" | Implemented |
| LAB-13-B | `docker/lab-13-b/` | Ch. 13 "3-Node Quorum Test" | Implemented |

## Reference Configurations

| ID | Path | Book Reference | Status |
|----|------|---------------|--------|
| CONFIG-04-REF | `patroni/config-04-ref.yml` | Ch. 04 "Configuration Best Practices" | Implemented |
| CHAOS-03-A | `chaos/chaos-03-a.sh` | Ch. 03 "Playbook 1" | Implemented |

## Dashboards & Alerts

| ID | Path | Book Reference | Status |
|----|------|---------------|--------|
| DASH-06-CORE | `dashboards/dash-06-core.json` | Ch. 06 "Core Fleet Dashboard" | Implemented |
| DASH-06-LAG | `dashboards/dash-06-lag.json` | Ch. 06 "Replication Lag Dashboard" | Implemented |
| ALERT-06-LAG | `dashboards/alerts/alert-06-lag.yaml` | Ch. 06 "Signal: pg_stat_replication -> lag > 30s" | Implemented |
| ALERT-06-LEADER-FLAP | `dashboards/alerts/alert-06-leader-flap.yaml` | Ch. 06 "Signal: leader_status flapping" | Implemented |
| ALERT-06-WAL-BLOAT | `dashboards/alerts/alert-06-wal-bloat.yaml` | Ch. 06 "Signal: WAL bloat" | Implemented |
| ALERT-06-DCS-PARTITION | `dashboards/alerts/alert-06-dcs-partition.yaml` | Ch. 06 "Signal: DCS partition" | Implemented |
| ALERT-06-CERT-EXPIRY | `dashboards/alerts/alert-06-cert-expiry.yaml` | Ch. 06 "Signal: Certificate expiry" | Implemented |

## Agent Scaffolds (Ch. 11)

| ID | Path | Book Reference | Status |
|----|------|---------------|--------|
| AGENT-11-MON | `agents/monitoring/` | Ch. 11 "Monitoring Agent" | Implemented (dry-run default) |
| AGENT-11-PF | `agents/predictive-failover/` | Ch. 11 "Predictive Failover" | Implemented (dry-run default) |
| AGENT-11-ST | `agents/self-tuning/` | Ch. 11 "Self-Tuning Agent" | Implemented (dry-run default) |
| AGENT-11-AR | `agents/auto-remediation/` | Ch. 11 "Auto-Remediation" | Implemented (dry-run default) |
| AGENT-11-NL | `agents/nl-ops/` | Ch. 11 "Natural Language Ops" | Implemented (dry-run default) |

## Shared

| ID | Path | Book Reference | Status |
|----|------|---------------|--------|
| SHARED-LIFECYCLE | `agents/shared/lifecycle.py` | Ch. 11 (all agents) | Implemented |

## Legend

- **Implemented**: Code present, CI validation added (where applicable)
- **Future**: Planned but not yet implemented
- **Deprecated**: Removed, do not reference
