# LAB-03-A Makefile
# Usage: make setup | make break | make verify | make recover | make teardown
# Artifact ID: LAB-03-A
# Book Reference: Chapter 03 — Core Deployment

.SILENT:

# Color codes for output
GREEN := \033[0;32m
RED := \033[0;31m
YELLOW := \033[0;33m
NC := \033[0m # No Color

TIMESTAMP := $(shell date '+%Y-%m-%d %H:%M:%S')

setup:
	@echo "[$(TIMESTAMP)] SETUP starting..."
	@command -v docker >/dev/null 2>&1 || { echo "[$(TIMESTAMP)] $(RED)ERROR: docker is not installed$(NC)"; exit 1; }
	@docker info >/dev/null 2>&1 || { echo "[$(TIMESTAMP)] $(RED)ERROR: docker daemon is not running$(NC)"; exit 1; }
	@docker compose version >/dev/null 2>&1 || { echo "[$(TIMESTAMP)] $(RED)ERROR: docker compose v2 is not installed$(NC)"; exit 1; }
	@echo "[$(TIMESTAMP)] Bringing up services..."
	@docker compose up -d
	@echo "[$(TIMESTAMP)] Waiting for etcd cluster to be healthy (3/3)..."
	@for i in $$(seq 1 60); do \
		ETCD1=$$(docker compose exec -T etcd-1 sh -c 'ETCDCTL_API=3 etcdctl --endpoints=http://127.0.0.1:2379 endpoint health' >/dev/null 2>&1 && echo "ok" || echo "fail"); \
		ETCD2=$$(docker compose exec -T etcd-2 sh -c 'ETCDCTL_API=3 etcdctl --endpoints=http://127.0.0.1:2379 endpoint health' >/dev/null 2>&1 && echo "ok" || echo "fail"); \
		ETCD3=$$(docker compose exec -T etcd-3 sh -c 'ETCDCTL_API=3 etcdctl --endpoints=http://127.0.0.1:2379 endpoint health' >/dev/null 2>&1 && echo "ok" || echo "fail"); \
		if [ "$$ETCD1" = "ok" ] && [ "$$ETCD2" = "ok" ] && [ "$$ETCD3" = "ok" ]; then \
			echo "[$(TIMESTAMP)] etcd cluster is healthy (3/3)"; \
			break; \
		fi; \
		if [ $$i -eq 60 ]; then \
			echo "[$(TIMESTAMP)] $(RED)ERROR: etcd cluster failed to become healthy$(NC)"; \
			docker compose logs --tail=20 etcd-1 etcd-2 etcd-3; \
			exit 1; \
		fi; \
		sleep 2; \
	done
	@echo "[$(TIMESTAMP)] Waiting for Patroni cluster to be healthy (3/3)..."
	@for i in $$(seq 1 60); do \
		P1=$$(docker inspect --format='{{.State.Health.Status}}' patroni-1 2>/dev/null || echo "starting"); \
		P2=$$(docker inspect --format='{{.State.Health.Status}}' patroni-2 2>/dev/null || echo "starting"); \
		P3=$$(docker inspect --format='{{.State.Health.Status}}' patroni-3 2>/dev/null || echo "starting"); \
		if [ "$$P1" = "healthy" ] && [ "$$P2" = "healthy" ] && [ "$$P3" = "healthy" ]; then \
			echo "[$(TIMESTAMP)] Patroni cluster is healthy (3/3)"; \
			break; \
		fi; \
		if [ $$i -eq 60 ]; then \
			echo "[$(TIMESTAMP)] $(RED)ERROR: Patroni cluster failed to become healthy$(NC)"; \
			echo "[$(TIMESTAMP)] patroni-1: $$P1, patroni-2: $$P2, patroni-3: $$P3"; \
			docker compose logs --tail=20 patroni-1 patroni-2 patroni-3; \
			exit 1; \
		fi; \
		sleep 5; \
	done
	@echo "[$(TIMESTAMP)] Patroni cluster status:"
	@docker compose exec -T patroni-2 patronictl -c /etc/patroni/patroni.yml list 2>/dev/null || true
	@echo "$(GREEN)[$(TIMESTAMP)] SETUP completed (exit 0)$(NC)"

break:
	@echo "[$(TIMESTAMP)] BREAK starting..."
	@echo "[$(TIMESTAMP)] Identifying current leader..."
	@LEADER=$$(docker compose exec -T patroni-2 patronictl -c /etc/patroni/patroni.yml list 2>/dev/null | grep "Leader" | awk '{print $$2}' | xargs); \
	if [ -z "$$LEADER" ]; then \
		echo "[$(TIMESTAMP)] $(YELLOW)WARNING: Could not determine leader. Assuming patroni-1.$(NC)"; \
		LEADER=patroni-1; \
	fi; \
	echo "[$(TIMESTAMP)] Current leader is: $$LEADER"; \
	if [ "$$LEADER" != "patroni-1" ]; then \
		echo "[$(TIMESTAMP)] $(YELLOW)WARNING: Leader is not patroni-1. Killing $$LEADER instead.$(NC)"; \
		KILL_TARGET=$$LEADER; \
	else \
		KILL_TARGET=patroni-1; \
	fi; \
	docker kill -s SIGKILL $$KILL_TARGET; \
	echo "[$(TIMESTAMP)] $$KILL_TARGET killed with SIGKILL"; \
	echo "[$(TIMESTAMP)] Waiting 45 seconds for failover to complete..."; \
	sleep 45; \
	echo "[$(TIMESTAMP)] BREAK completed"

verify:
	@echo "[$(TIMESTAMP)] VERIFY starting..."
	@echo "[$(TIMESTAMP)] Fetching cluster state..."
	@CLUSTER_STATE=$$(docker compose exec -T patroni-2 patronictl -c /etc/patroni/patroni.yml list 2>/dev/null || true); \
	echo "$$CLUSTER_STATE"; \
	echo "[$(TIMESTAMP)] Verifying patroni-1 is NOT leader..."; \
	if echo "$$CLUSTER_STATE" | grep -E "patroni-1.*Leader" >/dev/null 2>&1; then \
		echo "[$(TIMESTAMP)] $(RED)ERROR: patroni-1 is still the leader — failover failed$(NC)"; \
		exit 1; \
	fi; \
	echo "[$(TIMESTAMP)] OK: patroni-1 is not the leader"; \
	echo "[$(TIMESTAMP)] Verifying a new leader exists..."; \
	if ! echo "$$CLUSTER_STATE" | grep -q "Leader"; then \
		echo "[$(TIMESTAMP)] $(RED)ERROR: No leader found in cluster$(NC)"; \
		exit 1; \
	fi; \
	NEW_LEADER=$$(echo "$$CLUSTER_STATE" | grep "Leader" | awk '{print $$2}' | xargs); \
	echo "[$(TIMESTAMP)] OK: New leader is $$NEW_LEADER"; \
	echo "[$(TIMESTAMP)] Verifying at least 2 members are running..."; \
	RUNNING_COUNT=$$(echo "$$CLUSTER_STATE" | grep -c "running" || true); \
	if [ "$$RUNNING_COUNT" -lt 2 ]; then \
		echo "[$(TIMESTAMP)] $(RED)ERROR: Only $$RUNNING_COUNT member(s) running — expected at least 2$(NC)"; \
		exit 1; \
	fi; \
	echo "[$(TIMESTAMP)] OK: $$RUNNING_COUNT members are running"; \
	echo "$(GREEN)[$(TIMESTAMP)] VERIFY completed (exit 0)$(NC)"

recover:
	@echo "[$(TIMESTAMP)] RECOVER starting..."
	@echo "[$(TIMESTAMP)] Starting patroni-1..."
	@docker compose start patroni-1
	@echo "[$(TIMESTAMP)] Waiting for patroni-1 to rejoin as replica..."
	@for i in $$(seq 1 60); do \
		CLUSTER_STATE=$$(docker compose exec -T patroni-2 patronictl -c /etc/patroni/patroni.yml list 2>/dev/null || true); \
		if echo "$$CLUSTER_STATE" | grep "patroni-1" | grep -q "Replica" >/dev/null 2>&1; then \
			echo "[$(TIMESTAMP)] patroni-1 rejoined as Replica"; \
			break; \
		fi; \
		if [ $$i -eq 60 ]; then \
			echo "[$(TIMESTAMP)] $(RED)ERROR: patroni-1 did not rejoin as replica within timeout$(NC)"; \
			echo "[$(TIMESTAMP)] Current cluster state:"; \
			docker compose exec -T patroni-2 patronictl -c /etc/patroni/patroni.yml list 2>/dev/null || true; \
			exit 1; \
		fi; \
		sleep 3; \
	done
	@echo "[$(TIMESTAMP)] Patroni cluster status:"
	@docker compose exec -T patroni-2 patronictl -c /etc/patroni/patroni.yml list 2>/dev/null || true
	@echo "$(GREEN)[$(TIMESTAMP)] RECOVER completed (exit 0)$(NC)"

teardown:
	@echo "[$(TIMESTAMP)] TEARDOWN starting..."
	@docker compose down -v --remove-orphans
	@echo "$(GREEN)[$(TIMESTAMP)] TEARDOWN completed (exit 0)$(NC)"

help:
	@echo "Available targets:"
	@echo "  setup    - Deploy the 3-node Patroni + etcd cluster"
	@echo "  break    - Kill the leader container with SIGKILL"
	@echo "  verify   - Confirm automatic failover elected a new leader"
	@echo "  recover  - Restart the killed node and verify it rejoins as replica"
	@echo "  teardown - Remove all containers, networks, and volumes"
