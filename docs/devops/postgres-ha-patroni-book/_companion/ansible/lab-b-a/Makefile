# Makefile
# LAB-B-A: Watchdog and Lease Pathology
# Source of truth: Appendix B — Patroni Internals Deep-Dive

INVENTORY   := inventory.ini
PLAYBOOK    := playbook.yml
BREAK_SCRIPT := ./break.sh

.PHONY: setup verify break verify-failover recover teardown lint help

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2}'

setup: ## Deploy etcd, Patroni, and watchdog via Ansible
	ansible-playbook $(PLAYBOOK) -i $(INVENTORY) --become

verify: ## Show Patroni cluster status on all nodes
	@echo "[*] Patroni cluster status:"
	ansible patroni -i $(INVENTORY) -m shell -a "patronictl list" --become

lint: ## Verify YAML and Ansible syntax
	python -c "import yaml; yaml.safe_load(open('playbook.yml'))"
	python -c "import yaml; yaml.safe_load(open('roles/etcd/tasks/main.yml'))"
	python -c "import yaml; yaml.safe_load(open('roles/patroni/tasks/main.yml'))"
	python -c "import yaml; yaml.safe_load(open('roles/watchdog/tasks/main.yml'))"
	ansible-playbook $(PLAYBOOK) -i $(INVENTORY) --syntax-check

break: ## Run the partition script (leader → etcd DROP)
	@echo "============================================================================"
	@echo "  LAB BREAK: Partitioning leader from etcd"
	@echo "============================================================================"
	$(BREAK_SCRIPT)

verify-failover: ## Check that a new leader was elected and old leader rebooted
	@echo "[*] Current cluster state:"
	ansible patroni -i $(INVENTORY) -m shell -a "patronictl list" --become
	@echo ""
	@echo "[*] Verify timeline increment on new leader:"
	ansible patroni -i $(INVENTORY) -m shell -a "psql -h 127.0.0.1 -U postgres -tc \"SELECT timeline_id FROM pg_control_checkpoint();\"" --become

recover: ## Remove iptables rules from old leader and wait for rejoin
	@echo "[*] Removing partition rules from all patroni nodes..."
	ansible patroni -i $(INVENTORY) -m shell -a \
	  "iptables -D OUTPUT -p tcp --dport 2379 -j DROP 2>/dev/null; \
	   iptables -D INPUT -p tcp --sport 2379 -j DROP 2>/dev/null; \
	   iptables -D OUTPUT -p tcp --dport 2380 -j DROP 2>/dev/null; \
	   iptables -D INPUT -p tcp --sport 2380 -j DROP 2>/dev/null; \
	   echo 'done'" \
	  --become
	@echo ""
	@echo "[*] Waiting for old leader to rejoin (sleep 30s)..."
	@sleep 30
	@echo "[*] Current cluster state:"
	ansible patroni -i $(INVENTORY) -m shell -a "patronictl list" --become
	@echo ""
	@echo "[*] Verify all 3 nodes are healthy (1 Leader + 2 Replicas)."

teardown: ## Manual teardown instructions
	@echo "============================================================================"
	@echo "  TEARDOWN (manual — no automated cleanup playbook provided)"
	@echo "============================================================================"
	@echo ""
	@echo "1. Stop Patroni on all nodes:"
	@echo "   ansible patroni -i $(INVENTORY) -m shell -a 'systemctl stop patroni' --become"
	@echo ""
	@echo "2. Stop etcd on all nodes:"
	@echo "   ansible etcd -i $(INVENTORY) -m shell -a 'systemctl stop etcd' --become"
	@echo ""
	@echo "3. Remove iptables rules (if any remain):"
	@echo "   ansible all -i $(INVENTORY) -m shell -a \""
	@echo "     iptables -F; iptables -X; echo 'cleared'"
	@echo "   \" --become"
	@echo ""
	@echo "4. Disable services:"
	@echo "   ansible all -i $(INVENTORY) -m shell -a 'systemctl disable etcd patroni' --become"
	@echo ""
	@echo "5. Unload softdog (optional):"
	@echo "   ansible patroni -i $(INVENTORY) -m shell -a 'rmmod softdog' --become"
	@echo ""
	@echo "6. Remove data directories (DESTRUCTIVE):"
	@echo "   ansible etcd  -i $(INVENTORY) -m shell -a 'rm -rf /var/lib/etcd' --become"
	@echo "   ansible patroni -i $(INVENTORY) -m shell -a 'rm -rf /var/lib/postgresql/18/main /var/lib/pgsql/18/data' --become"
	@echo ""
	@echo "============================================================================"
