#!/usr/bin/env bash
# break-asymmetric-partition.sh — LAB-13-A Scenario 3: Asymmetric Partition
# The leader loses access to etcd but can still reach the replica.
# This tests DCS failsafe mode behavior.

set -euo pipefail

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
YELLOW='\033[0;33m'
NC='\033[0m'

echo "[$TIMESTAMP] BREAK (asymmetric): Identifying current leader..."
LEADER=$(docker compose exec -T patroni-2 patronictl -c /etc/patroni/patroni.yml list 2>/dev/null | grep "Leader" | awk '{print $2}' | xargs || true)

if [ -z "$LEADER" ]; then
    LEADER=$(docker compose exec -T patroni-1 patronictl -c /etc/patroni/patroni.yml list 2>/dev/null | grep "Leader" | awk '{print $2}' | xargs || true)
fi
if [ -z "$LEADER" ]; then
    LEADER=patroni-1
fi

echo "[$TIMESTAMP] Leader: $LEADER"
echo "[$TIMESTAMP] Blocking leader -> etcd traffic (all 5 etcd nodes)..."

# On leader: block OUTPUT to all etcd IPs, but keep replica reachable
docker exec "$LEADER" iptables -A OUTPUT -d 172.21.0.2 -j DROP 2>/dev/null || true
docker exec "$LEADER" iptables -A OUTPUT -d 172.21.0.3 -j DROP 2>/dev/null || true
docker exec "$LEADER" iptables -A OUTPUT -d 172.21.0.4 -j DROP 2>/dev/null || true
docker exec "$LEADER" iptables -A OUTPUT -d 172.21.0.5 -j DROP 2>/dev/null || true
docker exec "$LEADER" iptables -A OUTPUT -d 172.21.0.6 -j DROP 2>/dev/null || true

echo "[$TIMESTAMP] ${YELLOW}Asymmetric partition established:${NC}"
echo "  - $LEADER CANNOT reach etcd"
echo "  - $LEADER CAN still reach replica (172.21.0.11 <-> 172.21.0.12)"
echo "  - Replica CAN still reach etcd"
echo "[$TIMESTAMP] BREAK (asymmetric) completed. Run 'make verify' after 60s."
