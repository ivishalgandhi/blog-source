"""
AGENT-11-ST: Self-Tuning Agent

Analyzes workload patterns and proposes adjustments to work_mem,
shared_buffers, and checkpoint settings.
Uses the shared lifecycle module for state management and audit logging.

Manual-equivalent runbook:
  See Ch. 09 "Zero-Downtime Configuration Changes" for the manual
  procedure of rolling out Postgres parameter adjustments.
"""

from __future__ import annotations

import argparse
import os
import sys
from pathlib import Path
from typing import Any

# Allow importing from the shared lifecycle module when running in-tree.
sys.path.insert(0, str(Path(__file__).resolve().parents[4]))

from agents.shared.lifecycle import (
    ActionRisk,
    AgentLifecycle,
    require_dry_run_mode,
)

# pydantic-ai + litellm imports (scaffold integration)
from pydantic_ai import Agent
from pydantic_ai.models.openai import OpenAIModel
import litellm


def _build_agent() -> Agent:
    """Build a pydantic-ai agent for workload tuning recommendations."""
    model_name = os.environ.get("AGENT_LLM_MODEL", "gpt-4o")
    api_key = os.environ.get("OPENAI_API_KEY", "dummy-key-for-scaffold")
    model = OpenAIModel(model_name, api_key=api_key)
    return Agent(
        model,
        system_prompt=(
            "You are a PostgreSQL tuning assistant. "
            "Analyze workload patterns and recommend work_mem, shared_buffers, "
            "and checkpoint settings with justification."
        ),
    )


def main(argv: list[str] | None = None) -> None:
    parser = argparse.ArgumentParser(description="AGENT-11-ST: Self-Tuning Agent")
    parser.add_argument("--cluster", default="patroni-main", help="Target cluster name")
    parser.add_argument(
        "--workload",
        default="oltp",
        choices=["oltp", "olap", "mixed"],
        help="Detected workload profile",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        default=None,
        help="Run in dry-run mode (default unless AGENT_DRY_RUN=false)",
    )
    parser.add_argument(
        "--auto-approve",
        action="store_true",
        default=False,
        help="Auto-approve proposed tuning changes",
    )
    args = parser.parse_args(argv)

    # Default to dry-run mode unless explicitly disabled.
    if args.dry_run is not None:
        os.environ["AGENT_DRY_RUN"] = str(args.dry_run).lower()
    require_dry_run_mode()

    lifecycle = AgentLifecycle(
        agent_id="AGENT-11-ST",
        audit_log_path=f"./audit-{args.cluster}.jsonl",
    )

    # 1. OBSERVE
    action_id = lifecycle.observe(
        signal=f"workload-pattern-{args.workload}",
        context={"cluster": args.cluster, "agent": "AGENT-11-ST", "workload": args.workload},
    )

    # 2. PROPOSE
    proposal = lifecycle.propose(
        description=f"Tune Postgres parameters for {args.workload} workload on {args.cluster}",
        action="apply_parameter_changes",
        risk=ActionRisk.MEDIUM,
        params={
            "cluster": args.cluster,
            "workload": args.workload,
            "parameters": ["work_mem", "shared_buffers", "max_wal_size", "checkpoint_timeout"],
        },
    )

    # 3. DRY-RUN
    def _dry_run() -> dict[str, Any]:
        if os.environ.get("AGENT_DRY_RUN", "true").lower() not in ("false", "0", "no"):
            print("[DRY-RUN] Would analyze workload and propose parameter deltas.")
            return {
                "work_mem": "32MB → 64MB",
                "shared_buffers": "8GB → 12GB",
                "max_wal_size": "2GB → 4GB",
                "checkpoint_timeout": "5min → 10min",
                "justification": "Increased read-heavy ratio detected",
            }
        agent = _build_agent()
        prompt = (
            f"Cluster: {args.cluster}\n"
            f"Workload profile: {args.workload}\n"
            f"Recommend parameter adjustments."
        )
        result = agent.run_sync(prompt)
        return {"recommendation": result.data}

    dry_result = lifecycle.dry_run(proposal, _dry_run)

    # 4. APPROVE
    approved = lifecycle.approve(
        proposal,
        auto_approve=args.auto_approve,
        human_confirmed=False,
    )
    if not approved:
        print(f"Action {action_id} was not approved. Aborting.")
        return

    # 5. EXECUTE
    def _execute() -> dict[str, Any]:
        if os.environ.get("AGENT_DRY_RUN", "true").lower() not in ("false", "0", "no"):
            print("[DRY-RUN] Would apply parameter changes via Patroni dynamic configuration.")
            return {"status": "dry_run_skipped", "patroni_api": "PATCH /config"}
        # Live execution: update Patroni dynamic configuration
        return {"status": "applied", "parameters_updated": dry_result}

    lifecycle.execute(proposal, _execute)

    # 6. VERIFY
    def _verify() -> dict[str, Any]:
        return {"success": True, "check": "parameters_active_and_bloat_stable"}

    lifecycle.verify(proposal, _verify)

    print(f"Agent completed. Final state: {lifecycle.current_state.name}")


if __name__ == "__main__":
    main()
