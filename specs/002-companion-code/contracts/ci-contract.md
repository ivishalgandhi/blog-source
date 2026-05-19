# CI Contract

**Applies to**: `.github/workflows/companion-ci.yml`

## Trigger

On every PR that touches `docs/devops/postgres-ha-patroni-book/_companion/**` or `.github/workflows/companion-ci.yml`.

## Jobs

### docker-labs

Runs on `ubuntu-latest` with Docker service.

Matrix:
- lab: [lab-03-a, lab-08-a, lab-a-a]

Steps per matrix entry:
1. Checkout repo
2. `cd docs/devops/postgres-ha-patroni-book/_companion/docker/${{ matrix.lab }}`
3. `make setup` — must exit 0
4. `make break` — must exit 0
5. `make verify` — must exit 0 and produce expected output
6. `make recover` — must exit 0
7. `make teardown` — must exit 0
8. Verify no containers, volumes, or networks remain from the lab

Timeout per job: 10 minutes.

### terraform-validate

Runs on `ubuntu-latest`.

Steps:
1. Checkout repo
2. `cd docs/devops/postgres-ha-patroni-book/_companion/terraform/lab-08-b`
3. `terraform init -backend=false`
4. `terraform validate` — must exit 0
5. `terraform fmt -check` — must exit 0 (no formatting issues)

Note: `terraform plan` is NOT run in CI because it requires cloud credentials.

### agent-scaffolds

Runs on `ubuntu-latest` with Python 3.12.

Steps:
1. Checkout repo
2. For each agent in `agents/monitoring/`, `agents/predictive-failover/`, `agents/self-tuning/`, `agents/auto-remediation/`, `agents/nl-ops/`:
   a. `cd <agent>`
   b. `pip install -e .`
   c. Run agent in dry-run mode (specific command per agent README)
   d. Verify exit code 0 and dry-run output present

### dashboards-and-alerts

Runs on `ubuntu-latest`.

Steps:
1. Checkout repo
2. Validate all JSON files in `dashboards/` are parseable: `python -c "import json; json.load(open('dash-06-core.json'))"`
3. Validate all YAML files in `dashboards/alerts/` are parseable: `python -c "import yaml; yaml.safe_load(open('alert-06-lag.yaml'))"`
4. Check PromQL syntax for each alert rule using promtool (if available) or regex validation

## Failure Handling

- Any job failure blocks the PR.
- Logs from `make` commands are uploaded as artifacts for debugging.
