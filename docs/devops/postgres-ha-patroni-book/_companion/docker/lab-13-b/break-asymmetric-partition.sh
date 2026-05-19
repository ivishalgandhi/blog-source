#!/usr/bin/env bash
# break-asymmetric-partition.sh — LAB-13-B Scenario 3: Asymmetric Partition
# The leader loses access to etcd but can still reach all replicas.
# Tests DCS failsafe mode behavior in a 3-node cluster.

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

# On leader: block OUTPUT to all etcd IPs, but keep replicas reachable
docker exec "$LEADER" iptables -A OUTPUT -d 172.22.0.2 -j DROP 2>/dev/null || true
docker exec "$LEADER" iptables -A OUTPUT -d 172.22.0.3 -j DROP 2>/dev/null || true
docker exec "$LEADER" iptables -A OUTPUT -d 172.22.0.4 -j DROP 2>/dev/null || true
docker exec "$LEADER" iptables -A OUTPUT -d 172.22.0.5 -j DROP 2>/dev/null || true
docker exec "$LEADER" iptables -A OUTPUT -d 172.22.0.6 -j DROP 2>/dev/null || true

echo "[$TIMESTAMP] ${YELLOW}Asymmetric partition established:${NC}"
echo "  - $LEADER CANNOT reach etcd"
echo "  - $LEADER CAN still reach patroni-1, patroni-2, patroni-3"
echo "  - Replicas CAN still reach etcd"
echo "[$TIMESTAMP] BREAK (asymmetric) completed. Run 'make verify' after 60s."
