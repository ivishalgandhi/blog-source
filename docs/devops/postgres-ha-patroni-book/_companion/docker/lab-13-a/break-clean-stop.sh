#!/usr/bin/env bash
# break-clean-stop.sh — LAB-13-A Scenario 1: Clean Service Stop
# Stops the Patroni service on the current leader and observes whether
# the replica promotes automatically.

set -euo pipefail

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'

echo "[$TIMESTAMP] BREAK (clean-stop): Identifying current leader..."
LEADER=$(docker compose exec -T patroni-2 patronictl -c /etc/patroni/patroni.yml list 2>/dev/null | grep "Leader" | awk '{print $2}' | xargs || true)

if [ -z "$LEADER" ]; then
    echo "[$TIMESTAMP] ${YELLOW}WARNING: Could not determine leader from patroni-2. Trying patroni-1...${NC}"
    LEADER=$(docker compose exec -T patroni-1 patronictl -c /etc/patroni/patroni.yml list 2>/dev/null | grep "Leader" | awk '{print $2}' | xargs || true)
fi

if [ -z "$LEADER" ]; then
    echo "[$TIMESTAMP] ${YELLOW}WARNING: Still cannot determine leader. Defaulting to patroni-1.${NC}"
    LEADER=patroni-1
fi

echo "[$TIMESTAMP] Current leader is: $LEADER"
echo "[$TIMESTAMP] Stopping Patroni service on $LEADER..."
docker compose exec -T "$LEADER" pkill -f "patroni" || true
sleep 5

echo "[$TIMESTAMP] BREAK (clean-stop) completed. Run 'make verify' to check failover."
