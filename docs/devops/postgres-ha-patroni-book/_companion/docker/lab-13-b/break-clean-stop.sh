#!/usr/bin/env bash
# break-clean-stop.sh — LAB-13-B Scenario 1: Clean Service Stop
# Stops the Patroni service on the current leader and observes whether
# one of the two remaining replicas promotes automatically.

set -euo pipefail

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
YELLOW='\033[0;33m'
NC='\033[0m'

echo "[$TIMESTAMP] BREAK (clean-stop): Identifying current leader..."
LEADER=$(docker compose exec -T patroni-2 patronictl -c /etc/patroni/patroni.yml list 2>/dev/null | grep "Leader" | awk '{print $2}' | xargs || true)

if [ -z "$LEADER" ]; then
    LEADER=$(docker compose exec -T patroni-1 patronictl -c /etc/patroni/patroni.yml list 2>/dev/null | grep "Leader" | awk '{print $2}' | xargs || true)
fi
if [ -z "$LEADER" ]; then
    LEADER=patroni-1
fi

echo "[$TIMESTAMP] Current leader is: $LEADER"
echo "[$TIMESTAMP] Stopping Patroni service on $LEADER..."
docker compose exec -T "$LEADER" pkill -f "patroni" || true
sleep 5

echo "[$TIMESTAMP] BREAK (clean-stop) completed. Run 'make verify' to check failover."
