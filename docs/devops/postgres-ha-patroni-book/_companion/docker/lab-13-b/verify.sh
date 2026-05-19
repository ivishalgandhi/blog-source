#!/usr/bin/env bash
# verify.sh — LAB-13-B: Capture cluster state after a break scenario

set -euo pipefail

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'

OUTPUT_DIR="./logs"
mkdir -p "$OUTPUT_DIR"
RUN_ID="run-$(date +%s)"
LOGFILE="$OUTPUT_DIR/verify-$RUN_ID.log"

exec > >(tee -a "$LOGFILE") 2>&1

echo "[$TIMESTAMP] VERIFY: Capturing cluster state..."
echo "[$TIMESTAMP] Log file: $LOGFILE"

# 1. Patroni cluster state
echo ""
echo "=== Patroni Cluster State ==="
NODE_WITH_CTL="patroni-2"
docker compose exec -T "$NODE_WITH_CTL" patronictl -c /etc/patroni/patroni.yml list 2>/dev/null || \
docker compose exec -T patroni-1 patronictl -c /etc/patroni/patroni.yml list 2>/dev/null || \
echo "[$TIMESTAMP] ${RED}ERROR: Cannot reach any Patroni node for patronictl${NC}"

# 2. etcd cluster health
echo ""
echo "=== etcd Cluster Health ==="
for etcd in etcd-1 etcd-2 etcd-3 etcd-4 etcd-5; do
    HEALTH=$(docker compose exec -T "$etcd" sh -c 'ETCDCTL_API=3 etcdctl --endpoints=http://127.0.0.1:2379 endpoint health' 2>/dev/null || echo "unreachable")
    echo "  $etcd: $HEALTH"
done

# 3. Identify leader and check replication
echo ""
echo "=== Replication Status ==="
LEADER_NODE=$(docker compose exec -T "$NODE_WITH_CTL" patronictl -c /etc/patroni/patroni.yml list 2>/dev/null | grep "Leader" | awk '{print $2}' | xargs || true)
if [ -n "$LEADER_NODE" ]; then
    echo "  Current leader: $LEADER_NODE"
    docker compose exec -T "$LEADER_NODE" psql -U postgres -tc "SELECT client_addr, state, pg_wal_lsn_diff(sent_lsn, replay_lsn) AS lag_bytes FROM pg_stat_replication;" 2>/dev/null || echo "  (no replication connections)"
else
    echo "  ${YELLOW}WARNING: No leader detected${NC}"
fi

# 4. Data consistency
echo ""
echo "=== Data Consistency Check ==="
for node in patroni-1 patroni-2 patroni-3; do
    RESULT=$(docker compose exec -T "$node" psql -U postgres -tc "SELECT count(*) FROM partition_test.transactions;" 2>/dev/null | xargs || echo "N/A")
    echo "  $node row count: $RESULT"
done

if [ -n "$LEADER_NODE" ]; then
    CHK=$(docker compose exec -T "$LEADER_NODE" psql -U postgres -tc "SELECT md5(string_agg(id::text || ':' || node_name || ':' || payload, ',' ORDER BY id)) FROM partition_test.transactions;" 2>/dev/null | xargs || echo "N/A")
    echo "  Leader checksum: $CHK"
fi

# 5. iptables status on patroni nodes
echo ""
echo "=== iptables Rules (Patroni nodes) ==="
for node in patroni-1 patroni-2 patroni-3; do
    RULES=$(docker exec "$node" iptables -L -n 2>/dev/null | grep -c "DROP" || echo 0)
    echo "  $node DROP rules: $RULES"
done

# 6. Quorum summary
echo ""
echo "=== Quorum Summary ==="
RUNNING=$(docker compose exec -T "$NODE_WITH_CTL" patronictl -c /etc/patroni/patroni.yml list 2>/dev/null | grep -c "running" || echo 0)
if [ "$RUNNING" -ge 2 ]; then
    echo "  ${GREEN}Quorum maintained: $RUNNING of 3 nodes running${NC}"
else
    echo "  ${RED}Quorum lost: only $RUNNING of 3 nodes running${NC}"
fi

echo ""
echo "[$TIMESTAMP] VERIFY completed. Full log: $LOGFILE"
