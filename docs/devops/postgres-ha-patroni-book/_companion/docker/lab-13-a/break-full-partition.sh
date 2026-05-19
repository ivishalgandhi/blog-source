#!/usr/bin/env bash
# break-full-partition.sh — LAB-13-A Scenario 2: Full Network Partition
# Drops all packets between leader and replica. Both nodes can still
# reach the etcd cluster, but cannot reach each other.

set -euo pipefail

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
YELLOW='\033[0;33m'
NC='\033[0m'

echo "[$TIMESTAMP] BREAK (full-partition): Identifying current leader..."
LEADER=$(docker compose exec -T patroni-2 patronictl -c /etc/patroni/patroni.yml list 2>/dev/null | grep "Leader" | awk '{print $2}' | xargs || true)

if [ -z "$LEADER" ]; then
    LEADER=$(docker compose exec -T patroni-1 patronictl -c /etc/patroni/patroni.yml list 2>/dev/null | grep "Leader" | awk '{print $2}' | xargs || true)
fi
if [ -z "$LEADER" ]; then
    LEADER=patroni-1
fi

REPLICA=$([ "$LEADER" = "patroni-1" ] && echo "patroni-2" || echo "patroni-1")
LEADER_IP=$([ "$LEADER" = "patroni-1" ] && echo "172.21.0.11" || echo "172.21.0.12")
REPLICA_IP=$([ "$REPLICA" = "patroni-1" ] && echo "172.21.0.11" || echo "172.21.0.12")

echo "[$TIMESTAMP] Leader: $LEADER ($LEADER_IP)"
echo "[$TIMESTAMP] Replica: $REPLICA ($REPLICA_IP)"
echo "[$TIMESTAMP] Installing iptables DROP rules on both nodes..."

# On leader: block all traffic from/to replica
docker exec "$LEADER" iptables -A INPUT -s "$REPLICA_IP" -j DROP 2>/dev/null || true
docker exec "$LEADER" iptables -A OUTPUT -d "$REPLICA_IP" -j DROP 2>/dev/null || true

# On replica: block all traffic from/to leader
docker exec "$REPLICA" iptables -A INPUT -s "$LEADER_IP" -j DROP 2>/dev/null || true
docker exec "$REPLICA" iptables -A OUTPUT -d "$LEADER_IP" -j DROP 2>/dev/null || true

echo "[$TIMESTAMP] ${YELLOW}Partition established:${NC}"
echo "  - $LEADER cannot reach $REPLICA"
echo "  - $REPLICA cannot reach $LEADER"
echo "  - Both can still reach etcd (172.21.0.2-6)"
echo "[$TIMESTAMP] BREAK (full-partition) completed. Run 'make verify' after 60s."
