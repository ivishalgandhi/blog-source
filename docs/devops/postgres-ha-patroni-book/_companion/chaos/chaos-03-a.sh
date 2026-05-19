#!/usr/bin/env bash
# CHAOS-03-A: Leader Kill Script
# Artifact ID: CHAOS-03-A
# Source: Chapter 03 — Deploying Patroni Cluster
#
# Purpose: Simulate an unplanned leader failure by killing the leader container.
#          Used in the LAB-03-A "Break it on purpose" exercise.
#
# SAFETY: This script contains guardrails to prevent accidental execution
#         against production clusters. Read the checks below.

set -euo pipefail

# ============================================================================
# GUARDRAILS — DO NOT REMOVE
# ============================================================================

CONTAINER_NAME="${1:-}"

if [[ -z "$CONTAINER_NAME" ]]; then
    echo "ERROR: Container name required."
    echo "Usage: $0 <leader-container-name>"
    echo "Example: $0 lab-03-a-patroni-1"
    exit 2
fi

# Guardrail 1: Must be running in a Docker environment with Compose labels
if ! docker inspect "$CONTAINER_NAME" >/dev/null 2>&1; then
    echo "ERROR: Container '$CONTAINER_NAME' not found."
    echo "       Make sure you are running the LAB-03-A Docker Compose stack."
    exit 2
fi

# Guardrail 2: Container MUST have a lab-specific label to prevent production kills
COMPOSE_PROJECT=$(docker inspect --format='{{index .Config.Labels "com.docker.compose.project"}}' "$CONTAINER_NAME" 2>/dev/null || echo "")
if [[ "$COMPOSE_PROJECT" != lab-* ]]; then
    echo "ERROR: Safety guardrail triggered."
    echo "       Container '$CONTAINER_NAME' does not have a lab-specific Compose project label."
    echo "       This script is designed ONLY for lab environments (project name starting with 'lab-')."
    echo "       If you are sure this is a lab container, set the Compose project name accordingly."
    exit 2
fi

# Guardrail 3: Container image must match known lab images
IMAGE=$(docker inspect --format='{{.Config.Image}}' "$CONTAINER_NAME")
if [[ ! "$IMAGE" =~ (spilo|patroni|postgres) ]]; then
    echo "WARNING: Container image '$IMAGE' does not look like a Patroni/Postgres lab image."
    read -r -p "Are you sure you want to kill this container? (type YES to proceed): " confirm
    if [[ "$confirm" != "YES" ]]; then
        echo "Aborted."
        exit 2
    fi
fi

# Guardrail 4: Warn if Patroni role is not "Leader" (we might be killing a replica)
ROLE=$(docker exec "$CONTAINER_NAME" patronictl list -f json 2>/dev/null | jq -r '.[] | select(.Member=="'"$CONTAINER_NAME"'") | .Role' 2>/dev/null || echo "unknown")
if [[ "$ROLE" != "Leader" && "$ROLE" != "leader" ]]; then
    echo "WARNING: Container '$CONTAINER_NAME' role is '$ROLE', not 'Leader'."
    echo "         This will NOT simulate a leader failure."
    read -r -p "Continue anyway? (type YES): " confirm
    if [[ "$confirm" != "YES" ]]; then
        echo "Aborted."
        exit 2
    fi
fi

# ============================================================================
# EXECUTE — THE BREAK
# ============================================================================

echo "[$(date '+%Y-%m-%d %H:%M:%S')] BREAK starting..."
echo "Target: $CONTAINER_NAME (Compose project: $COMPOSE_PROJECT, Image: $IMAGE, Role: $ROLE)"
echo ""
echo "Killing container in 3 seconds... (Ctrl+C to abort)"
sleep 3

docker kill --signal=SIGKILL "$CONTAINER_NAME"

echo ""
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Container $CONTAINER_NAME killed."
echo "Expected: Patroni detects leader loss → replica promotes within TTL + loop_wait (~40s)."
echo "Verify with: docker compose -p $COMPOSE_PROJECT ps"
echo "            docker compose -p $COMPOSE_PROJECT logs -f patroni-2"
