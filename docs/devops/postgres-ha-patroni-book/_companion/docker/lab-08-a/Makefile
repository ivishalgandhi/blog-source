# LAB-08-A — pgBackRest PITR (Docker)
# See README.md for full walkthrough.

.PHONY: setup full-backup incremental-backup pitr-restore verify teardown wait-leader seed-data

# Default PITR target (override via env var or command line)
PITR_TARGET ?= --target-time="$(shell date -u +%Y-%m-%d\ %H:%M:%S)"

setup:
	@echo "=== Starting LAB-08-A infrastructure ==="
	docker compose up -d
	@echo "--- Waiting for Patroni cluster to elect a leader (~30s) ---"
	@sleep 30
	@echo "--- Creating pgBackRest stanza ---"
	docker compose exec -T pgbackrest pgbackrest --stanza=lab-08-a stanza-create || true
	@echo "--- Verifying stanza ---"
	docker compose exec -T pgbackrest pgbackrest --stanza=lab-08-a check
	@echo "--- Taking initial full backup ---"
	docker compose exec -T pgbackrest pgbackrest --stanza=lab-08-a --type=full backup
	@echo "--- Backup info ---"
	docker compose exec -T pgbackrest pgbackrest --stanza=lab-08-a info
	@echo "=== Setup complete ==="

wait-leader:
	@echo "--- Waiting for a healthy leader ---"
	@for i in 1 2 3 4 5 6; do \
		LEADER=$$(docker compose exec -T patroni1 patronictl -c /etc/patroni/patroni.yml list 2>/dev/null | grep -c "Leader" || true); \
		if [ "$$LEADER" -ge 1 ]; then echo "Leader detected."; break; fi; \
		sleep 10; \
	done

seed-data:
	@echo "--- Seeding test data ---"
	docker compose exec -T patroni1 psql -U postgres -c "
		CREATE TABLE IF NOT EXISTS orders (
			id serial PRIMARY KEY,
			amount numeric,
			created_at timestamptz DEFAULT now()
		);
	"
	docker compose exec -T patroni1 psql -U postgres -c "
		INSERT INTO orders (amount) SELECT random()*1000 FROM generate_series(1,10000);
	"
	@echo "--- Row count ---"
	docker compose exec -T patroni1 psql -U postgres -c "SELECT count(*) AS row_count FROM orders;"

full-backup:
	@echo "=== Running full backup ==="
	docker compose exec -T pgbackrest pgbackrest --stanza=lab-08-a --type=full backup
	docker compose exec -T pgbackrest pgbackrest --stanza=lab-08-a info

incremental-backup:
	@echo "=== Running incremental backup ==="
	docker compose exec -T pgbackrest pgbackrest --stanza=lab-08-a --type=incr backup
	docker compose exec -T pgbackrest pgbackrest --stanza=lab-08-a info

pitr-restore:
	@echo "=== Point-in-Time Restore ==="
	@echo "Target: $(PITR_TARGET)"
	@echo "Stop all Patroni nodes..."
	docker compose stop patroni1 patroni2 patroni3
	@echo "Running pgBackRest restore via sidecar..."
	docker compose run --rm pgbackrest pgbackrest --stanza=lab-08-a restore $(PITR_TARGET) --target-action=promote
	@echo "Restart patroni1 (will recover and promote to new timeline)..."
	docker compose start patroni1
	@echo "Waiting for recovery (~30s)..."
	@sleep 30
	@echo "Restart replicas..."
	docker compose start patroni2 patroni3
	@echo "Waiting for replicas to rejoin (~30s)..."
	@sleep 30
	@echo "--- Cluster status after PITR ---"
	docker compose exec -T patroni1 patronictl -c /etc/patroni/patroni.yml list || true

verify:
	@echo "=== Verification ==="
	@echo "--- Cluster status ---"
	docker compose exec -T patroni1 patronictl -c /etc/patroni/patroni.yml list || true
	@echo "--- pgBackRest backup info ---"
	docker compose exec -T pgbackrest pgbackrest --stanza=lab-08-a info
	@echo "--- Sample row count from leader ---"
	docker compose exec -T patroni1 psql -U postgres -c "SELECT count(*) AS row_count FROM orders;" || true
	@echo "--- WAL archive freshness check ---"
	docker compose exec -T pgbackrest pgbackrest --stanza=lab-08-a check || true

teardown:
	@echo "=== Tearing down LAB-08-A ==="
	docker compose down -v
	@echo "All containers, networks, and named volumes removed."
