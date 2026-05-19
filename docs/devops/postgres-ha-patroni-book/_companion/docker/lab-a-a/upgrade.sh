#!/bin/bash
set -euo pipefail

NODE=$1
ACTION=${2:-upgrade}
COMPOSE_FILE="docker-compose.yml"

upgrade_node() {
    echo "[$NODE] Installing Patroni dependencies into Python 3.12 virtual environment..."
    docker-compose -f "$COMPOSE_FILE" exec -T "$NODE" bash -c '
        if [ ! -f /opt/venv312/bin/python ]; then
            python3.12 -m venv /opt/venv312
            /opt/venv312/bin/pip install --upgrade pip
            /opt/venv312/bin/pip install "patroni[etcd]" psycopg2-binary
        else
            echo "venv312 already exists, skipping creation."
        fi
    '

    echo "[$NODE] Swapping active venv symlink to Python 3.12..."
    docker-compose -f "$COMPOSE_FILE" exec -T "$NODE" bash -c "ln -sfn /opt/venv312 /opt/patroni/venv"

    echo "[$NODE] Restarting Patroni container to activate the new runtime..."
    docker-compose -f "$COMPOSE_FILE" restart "$NODE"

    echo "[$NODE] Upgrade to Python 3.12 complete."
}

rollback_node() {
    echo "[$NODE] Reverting active venv symlink to Python 3.8..."
    docker-compose -f "$COMPOSE_FILE" exec -T "$NODE" bash -c "ln -sfn /opt/venv38 /opt/patroni/venv"

    echo "[$NODE] Restarting Patroni container to restore the old runtime..."
    docker-compose -f "$COMPOSE_FILE" restart "$NODE"

    echo "[$NODE] Rollback to Python 3.8 complete."
}

case "$ACTION" in
    upgrade)
        upgrade_node
        ;;
    rollback)
        rollback_node
        ;;
    *)
        echo "Usage: $0 <node> [upgrade|rollback]"
        exit 1
        ;;
esac
