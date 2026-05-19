#!/usr/bin/env bash
# break-full-partition.sh — LAB-13-B Scenario 2: Full Network Partition
# Isolates the leader from BOTH replicas. All nodes still reach etcd.
# With 3 nodes, the 2 isolated replicas can form a majority and promote.

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

echo "[$TIMESTAMP] Leader: $LEADER"
echo "[$TIMESTAMP] Blocking leader <-> ALL replica traffic..."

# Determine IPs for all 3 nodes
LEADER_IP="172.22.0.11"
if [ "$LEADER" = "patroni-2" ]; then LEADER_IP="172.22.0.12"; fi
if [ "$LEADER" = "patroni-3" ]; then LEADER_IP="172.22.0.13"; fi

# On leader: block all other patroni nodes
for ip in 172.22.0.11 172.22.0.12 172.22.0.13; do
    if [ "$ip" != "$LEADER_IP" ]; then
        docker exec "$LEADER" iptables -A INPUT -s "$ip" -j DROP 2>/dev/null || true
        docker exec "$LEADER" iptables -A OUTPUT -d "$ip" -j DROP 2>/dev/null || true
    fi
done

# On each replica: block only the leader
docker exec patroni-1 iptables -A INPUT -s "$LEADER_IP" -j DROP 2>/dev/null || true
docker exec patroni-1 iptables -A OUTPUT -d "$LEADER_IP" -j DROP 2>/dev/null || true
docker exec patroni-2 iptables -A INPUT -s "$LEADER_IP" -j DROP 2>/dev/null || true
docker exec patroni-2 iptables -A OUTPUT -d "$LEADER_IP" -j DROP 2>/dev/null || true
docker exec patroni-3 iptables -A INPUT -s "$LEADER_IP" -j DROP 2>/dev/null || true
docker exec patroni-3 iptables -A OUTPUT -d "$LEADER_IP" -j DROP 2>/dev/null || true

echo "[$TIMESTAMP] ${YELLOW}Partition established:${NC}"
echo "  - $LEADER isolated from patroni-1, patroni-2, patroni-3"
echo "  - Replicas can still reach each other and etcd"
echo "  - Expected: one replica promotes via quorum"
echo "[$TIMESTAMP] BREAK (full-partition) completed. Run 'make verify' after 60s."
