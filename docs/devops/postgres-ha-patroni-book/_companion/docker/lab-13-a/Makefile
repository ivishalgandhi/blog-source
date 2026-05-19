# LAB-13-A Makefile
# Usage: make setup | make break | make verify | make recover | make teardown
# Artifact ID: LAB-13-A
# Book Reference: Chapter 13 — Network Partition Testing

.SILENT:

GREEN := \033[0;32m
RED := \033[0;31m
YELLOW := \033[0;33m
NC := \033[0m

TIMESTAMP := $(shell date '+%Y-%m-%d %H:%M:%S')

setup:
	@echo "[$(TIMESTAMP)] SETUP starting..."
	@command -v docker >/dev/null 2>&1 || { echo "[$(TIMESTAMP)] $(RED)ERROR: docker is not installed$(NC)"; exit 1; }
	@docker info >/dev/null 2>&1 || { echo "[$(TIMESTAMP)] $(RED)ERROR: docker daemon is not running$(NC)"; exit 1; }
	@docker compose version >/dev/null 2>&1 || { echo "[$(TIMESTAMP)] $(RED)ERROR: docker compose v2 is not installed$(NC)"; exit 1; }
	@echo "[$(TIMESTAMP)] Bringing up 2-node Patroni + 5-node etcd cluster..."
	@docker compose up -d
	@echo "[$(TIMESTAMP)] Waiting for etcd cluster to be healthy (5/5)..."
	@for i in $$(seq 1 60); do \
		OK=0; \
		for etcd in etcd-1 etcd-2 etcd-3 etcd-4 etcd-5; do \
			if docker compose exec -T $$etcd sh -c 'ETCDCTL_API=3 etcdctl --endpoints=http://127.0.0.1:2379 endpoint health' >/dev/null 2>&1; then \
				OK=$$((OK + 1)); \
			fi; \
		done; \
		if [ "$$OK" -eq 5 ]; then \
			echo "[$(TIMESTAMP)] etcd cluster is healthy (5/5)"; \
			break; \
		fi; \
		if [ $$i -eq 60 ]; then \
			echo "[$(TIMESTAMP)] $(RED)ERROR: etcd cluster failed to become healthy$(NC)"; \
			exit 1; \
		fi; \
		sleep 2; \
	done
	@echo "[$(TIMESTAMP)] Waiting for Patroni cluster to be healthy (2/2)..."
	@for i in $$(seq 1 60); do \
		P1=$$(docker inspect --format='{{.State.Health.Status}}' patroni-1 2>/dev/null || echo "starting"); \
		P2=$$(docker inspect --format='{{.State.Health.Status}}' patroni-2 2>/dev/null || echo "starting"); \
		if [ "$$P1" = "healthy" ] && [ "$$P2" = "healthy" ]; then \
			echo "[$(TIMESTAMP)] Patroni cluster is healthy (2/2)"; \
			break; \
		fi; \
		if [ $$i -eq 60 ]; then \
			echo "[$(TIMESTAMP)] $(RED)ERROR: Patroni cluster failed to become healthy$(NC)"; \
			exit 1; \
		fi; \
		sleep 5; \
	done
	@echo "[$(TIMESTAMP)] Loading test data..."
	@LEADER=$$(docker compose exec -T patroni-2 patronictl -c /etc/patroni/patroni.yml list 2>/dev/null | grep "Leader" | awk '{print $$2}' | xargs || true); \
	if [ -z "$$LEADER" ]; then LEADER=patroni-1; fi; \
	docker compose exec -T "$$LEADER" psql -U postgres -f /tmp/init-partition-test-data.sql >/dev/null 2>&1 || \
	echo "[$(TIMESTAMP)] $(YELLOW)WARNING: Could not load test data (may already exist)$(NC)"
	@echo "[$(TIMESTAMP)] Patroni cluster status:"
	@docker compose exec -T patroni-2 patronictl -c /etc/patroni/patroni.yml list 2>/dev/null || true
	@echo "$(GREEN)[$(TIMESTAMP)] SETUP completed (exit 0)$(NC)"

break:
	@echo "[$(TIMESTAMP)] BREAK starting..."
	@echo "[$(TIMESTAMP)] Choose scenario:"
	@echo "  1) clean-stop     — Stop Patroni service on leader (test auto-failover)"
	@echo "  2) full-partition — Isolate leader <-> replica (both see etcd)"
	@echo "  3) asymmetric     — Leader loses etcd, keeps replica link"
	@echo ""
	@echo "Run one of:"
	@echo "  make break-clean-stop"
	@echo "  make break-full-partition"
	@echo "  make break-asymmetric"

break-clean-stop:
	@./break-clean-stop.sh

break-full-partition:
	@./break-full-partition.sh

break-asymmetric:
	@./break-asymmetric-partition.sh

verify:
	@./verify.sh

recover:
	@echo "[$(TIMESTAMP)] RECOVER starting..."
	@echo "[$(TIMESTAMP)] Restoring iptables rules..."
	@bash /tmp/recover-partition.sh 2>/dev/null || \
	bash ../common/recover-partition.sh 2>/dev/null || \
	echo "[$(TIMESTAMP)] $(YELLOW)WARNING: recover script not found, attempting manual flush$(NC)"
	@for node in patroni-1 patroni-2; do \
		docker exec $$node sh -c 'iptables -F 2>/dev/null; iptables -X 2>/dev/null; echo "  $$node flushed"' || true; \
	done
	@echo "[$(TIMESTAMP)] Restarting any stopped Patroni containers..."
	@docker compose start patroni-1 patroni-2 >/dev/null 2>&1 || true
	@echo "[$(TIMESTAMP)] Waiting for cluster to stabilize..."
	@for i in $$(seq 1 60); do \
		STATE=$$(docker compose exec -T patroni-2 patronictl -c /etc/patroni/patroni.yml list 2>/dev/null || true); \
		RUNNING=$$(echo "$$STATE" | grep -c "running" || echo 0); \
		if [ "$$RUNNING" -eq 2 ]; then \
			echo "[$(TIMESTAMP)] Cluster stable: 2/2 running"; \
			break; \
		fi; \
		if [ $$i -eq 60 ]; then \
			echo "[$(TIMESTAMP)] $(YELLOW)WARNING: Cluster did not fully stabilize within timeout$(NC)"; \
		fi; \
		sleep 3; \
	done
	@docker compose exec -T patroni-2 patronictl -c /etc/patroni/patroni.yml list 2>/dev/null || true
	@echo "$(GREEN)[$(TIMESTAMP)] RECOVER completed (exit 0)$(NC)"

teardown:
	@echo "[$(TIMESTAMP)] TEARDOWN starting..."
	@docker compose down -v --remove-orphans
	@echo "$(GREEN)[$(TIMESTAMP)] TEARDOWN completed (exit 0)$(NC)"

help:
	@echo "Available targets:"
	@echo "  setup                — Deploy 2-node Patroni + 5-node etcd cluster"
	@echo "  break                — Show break scenario options"
	@echo "  break-clean-stop     — Stop leader service, test auto-failover"
	@echo "  break-full-partition — Isolate leader <-> replica"
	@echo "  break-asymmetric     — Leader loses etcd access"
	@echo "  verify               — Capture cluster state, logs, consistency"
	@echo "  recover              — Flush iptables, restart containers, verify cluster"
	@echo "  teardown             — Remove all containers, networks, and volumes"
