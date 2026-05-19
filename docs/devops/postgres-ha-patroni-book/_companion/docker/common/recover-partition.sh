#!/usr/bin/env bash
# recover-partition.sh
# Removes all iptables DROP rules injected by break-* scripts.
# Idempotent: safe to run even if no rules exist.

set -euo pipefail

echo "[$(date '+%Y-%m-%d %H:%M:%S')] RECOVER: Flushing iptables DROP rules..."

# Find all containers with names matching patroni-*
for container in $(docker compose ps -q 2>/dev/null | xargs -I{} docker inspect --format '{{.Name}}' {} 2>/dev/null | sed 's|^/||' | grep '^patroni-' || true); do
    echo "  -> Cleaning $container"
    docker exec "$container" sh -c '
        # List all DROP rules in INPUT chain and delete them by rule number (in reverse order)
        iptables -L INPUT --line-numbers -n 2>/dev/null | grep DROP | awk "{print \$1}" | sort -rn | while read num; do
            iptables -D INPUT "$num" 2>/dev/null || true
        done
        # Same for OUTPUT chain
        iptables -L OUTPUT --line-numbers -n 2>/dev/null | grep DROP | awk "{print \$1}" | sort -rn | while read num; do
            iptables -D OUTPUT "$num" 2>/dev/null || true
        done
        echo "     iptables flushed"
    ' || echo "     (container may be stopped, skipping)"
done

echo "[$(date '+%Y-%m-%d %H:%M:%S')] RECOVER: iptables rules removed."
