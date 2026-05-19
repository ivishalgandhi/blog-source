#!/usr/bin/env bash
# break.sh
# LAB-B-A: Watchdog and Lease Pathology
#
# PURPOSE:
#   Partition the current Patroni leader from etcd (ports 2379, 2380).
#   This simulates a network partition where the leader can still reach
#   PostgreSQL replicas but NOT the DCS.
#
#   Expected outcome:
#     - Leader fails to renew DCS lease
#     - Watchdog safety_margin expires
#     - Kernel panic / reboot on the old leader (fencing)
#     - Replica acquires lock and promotes to new leader
#
# WARNING:
#   This is a LAB-ONLY operation. It will cause an unplanned failover
#   and reboot the leader node. Do NOT run in production.
# ------------------------------------------------------------------------------

set -euo pipefail

INVENTORY="inventory.ini"
LEADER_CHECK_CMD="patronictl list -f json"

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

function banner() {
  echo -e "${RED}"
  echo "============================================================================"
  echo "  LAB-B-A: INTENTIONAL NETWORK PARTITION — LEADER → ETCD"
  echo "============================================================================"
  echo -e "${NC}"
}

function fatal() {
  echo -e "${RED}FATAL: $*${NC}" >&2
  exit 1
}

function warn() {
  echo -e "${YELLOW}WARNING: $*${NC}"
}

banner

# Determine current leader
echo "[*] Detecting current Patroni leader from inventory..."
LEADER_HOST=$(ansible patroni -i "$INVENTORY" -m shell -a "$LEADER_CHECK_CMD" --one-line 2>/dev/null \
  | grep -o '"Member":"[^"]*"' | head -1 | cut -d'"' -f4)

if [[ -z "$LEADER_HOST" ]]; then
  # Fallback: try patroni-1 and inspect locally
  LEADER_HOST=$(ansible patroni-1 -i "$INVENTORY" -m shell -a "patronictl list -f json | jq -r '.[] | select(.Role==\"Leader\") | .Member'" --one-line 2>/dev/null | tr -d '\r')
fi

if [[ -z "$LEADER_HOST" ]]; then
  fatal "Could not determine current Patroni leader. Is the cluster healthy?"
fi

echo "[*] Current leader: $LEADER_HOST"

# Verify we can SSH to the leader
if ! ansible "$LEADER_HOST" -i "$INVENTORY" -m ping >/dev/null 2>&1; then
  fatal "Cannot reach $LEADER_HOST via Ansible. Check inventory and SSH keys."
fi

# Final warning with countdown
echo ""
warn "This script will DROP all traffic between the LEADER and ETCD."
warn "The leader node ($LEADER_HOST) WILL REBOOT when the watchdog fires."
echo ""
read -rp "Type YES to proceed: " CONFIRM
if [[ "$CONFIRM" != "YES" ]]; then
  echo "Aborted."
  exit 1
fi

echo ""
for i in 30 25 20 15 10 5; do
  echo -e "${YELLOW}  Partition begins in ${i}s...${NC}"
  sleep 5
done

echo ""
echo "[*] $(date '+%Y-%m-%d %H:%M:%S.%N') — Applying iptables rules on $LEADER_HOST ..."
echo "    DROP OUTPUT to etcd port 2379"
echo "    DROP INPUT from etcd port 2379"

ansible "$LEADER_HOST" -i "$INVENTORY" -m shell -a "iptables -A OUTPUT -p tcp --dport 2379 -j DROP"
ansible "$LEADER_HOST" -i "$INVENTORY" -m shell -a "iptables -A INPUT -p tcp --sport 2379 -j DROP"
ansible "$LEADER_HOST" -i "$INVENTORY" -m shell -a "iptables -A OUTPUT -p tcp --dport 2380 -j DROP"
ansible "$LEADER_HOST" -i "$INVENTORY" -m shell -a "iptables -A INPUT -p tcp --sport 2380 -j DROP"

echo ""
echo "[*] Partition active. Timeline (expected, default ttl=30, loop_wait=10):"
echo "    T+0s    — iptables applied (this moment)"
echo "    T+10-20s— Patroni logs 'failed to update leader lock'"
echo "    T+30s   — etcd TTL expires; leader key deleted"
echo "    T+30-32s— Watchdog fires; $LEADER_HOST reboots"
echo "    T+30-40s— Replica promotes to new leader"
echo "    T+60-90s— Old leader boots, rejoins as replica"
echo ""
echo "[*] Use 'make verify-failover' from another terminal to observe promotion."
echo "[*] After reboot, use 'make recover' to remove iptables and restore cluster."
