.PHONY: setup verify-python upgrade-node-1 upgrade-node-2 upgrade-node-3 verify rollback teardown

setup:
	docker-compose up -d

verify-python:
	@for node in patroni1 patroni2 patroni3; do \
		echo "=== $$node ==="; \
		docker-compose exec $$node /opt/patroni/venv/bin/python --version; \
	done

upgrade-node-1:
	./upgrade.sh patroni1 upgrade

upgrade-node-2:
	./upgrade.sh patroni2 upgrade

upgrade-node-3:
	./upgrade.sh patroni3 upgrade

verify:
	@echo "=== Cluster Status ==="
	@docker-compose exec patroni1 /opt/patroni/venv/bin/patronictl list
	@echo ""
	@echo "=== Python Versions ==="
	@for node in patroni1 patroni2 patroni3; do \
		echo "--- $$node ---"; \
		docker-compose exec $$node /opt/patroni/venv/bin/python --version; \
	done

rollback:
	@for node in patroni1 patroni2 patroni3; do \
		echo "Rolling back $$node..."; \
		./upgrade.sh $$node rollback; \
	done

teardown:
	docker-compose down -v
