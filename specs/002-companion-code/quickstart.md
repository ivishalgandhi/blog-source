# Quickstart: Patroni HA Book Companion Code

**Prerequisites**: Docker Engine ≥24.x, Docker Compose v2, Git

## Run Your First Lab (LAB-03-A)

```bash
# Clone the repo
git clone https://github.com/ivishalgandhi/blog-source.git
cd blog-source/docs/devops/postgres-ha-patroni-book/_companion

# Deploy the 3-node Patroni + etcd cluster
cd docker/lab-03-a
make setup

# In another terminal, verify the cluster
make verify

# Simulate leader failure
make break

# Verify automatic failover
make verify

# Recover the cluster
make recover

# Clean up
make teardown
```

## Import Observability Stack

```bash
# Grafana dashboards
cd dashboards
# Import dash-06-core.json and dash-06-lag.json via Grafana UI or API

# Prometheus alert rules
cd dashboards/alerts
# Apply all alert-06-*.yaml files to your Prometheus instance
```

## Install an Agent Scaffold

```bash
cd agents/monitoring
pip install -e .
python -m agent_mon --dry-run --config example-config.yaml
```

## Run a Terraform Lab (requires cloud credentials)

```bash
cd terraform/lab-08-b
cp .env.example .env
# Edit .env with your AWS/GCP credentials
make setup
```

## Run an Ansible Lab (requires target hosts)

```bash
cd ansible/lab-b-a
# Edit inventory.ini with your target hosts
ansible-playbook -i inventory.ini playbook.yml
```

## Directory Quick Reference

| Directory | Contains |
|-----------|----------|
| `docker/lab-03-a/` | Core deployment lab |
| `docker/lab-08-a/` | Backup/DR PITR lab |
| `docker/lab-a-a/` | Python runtime upgrade lab |
| `terraform/lab-08-b/` | Cross-region DR lab |
| `ansible/lab-b-a/` | Watchdog/lease pathology lab |
| `patroni/` | Reference configs |
| `dashboards/` | Grafana dashboards + alerts |
| `agents/` | Python agent scaffolds |
| `chaos/` | Chaos scripts |
