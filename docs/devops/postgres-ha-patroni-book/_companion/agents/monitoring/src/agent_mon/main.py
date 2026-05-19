"""
AGENT-11-MON: Monitoring Agent

Monitors signals, generates incident summaries, and proposes severity.
Uses the shared lifecycle module for state management and audit logging.

Manual-equivalent runbook:
  See Ch. 07 "Investigating Replication Lag and Alert Fatigue" for the
  manual triage playbook this agent automates.
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
    """Build a pydantic-ai agent for incident summarization."""
    # In a real deployment, configure litellm via shared/litellm-config.yaml
    # and set the model name via AGENT_LLM_MODEL env var.
    model_name = os.environ.get("AGENT_LLM_MODEL", "gpt-4o")
    api_key = os.environ.get("OPENAI_API_KEY", "dummy-key-for-scaffold")
    model = OpenAIModel(model_name, api_key=api_key)
    return Agent(
        model,
        system_prompt=(
            "You are a Patroni HA monitoring assistant. "
            "Analyze telemetry signals and produce a concise incident summary with severity."
        ),
    )


def main(argv: list[str] | None = None) -> None:
    parser = argparse.ArgumentParser(description="AGENT-11-MON: Monitoring Agent")
    parser.add_argument("--cluster", default="patroni-main", help="Target cluster name")
    parser.add_argument(
        "--signal",
        default="lag-spike",
        help="Observed signal to process (e.g., lag-spike, conn-saturation)",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        default=None,
        help="Run in dry-run mode (default unless AGENT_DRY_RUN=false)",
    )
    args = parser.parse_args(argv)

    # Default to dry-run mode unless explicitly disabled.
    if args.dry_run is not None:
        os.environ["AGENT_DRY_RUN"] = str(args.dry_run).lower()
    require_dry_run_mode()

    lifecycle = AgentLifecycle(
        agent_id="AGENT-11-MON",
        audit_log_path=f"./audit-{args.cluster}.jsonl",
    )

    # 1. OBSERVE
    action_id = lifecycle.observe(
        signal=args.signal,
        context={"cluster": args.cluster, "agent": "AGENT-11-MON"},
    )

    # 2. PROPOSE
    proposal = lifecycle.propose(
        description=f"Generate incident summary for {args.signal} on {args.cluster}",
        action="generate_incident_summary",
        risk=ActionRisk.LOW,
        params={"cluster": args.cluster, "signal": args.signal},
    )

    # 3. DRY-RUN
    def _dry_run() -> dict[str, Any]:
        if os.environ.get("AGENT_DRY_RUN", "true").lower() not in ("false", "0", "no"):
            print("[DRY-RUN] Would call LLM to generate incident summary and severity.")
            return {
                "incident_summary": f"Detected {args.signal} on {args.cluster}",
                "severity": "warning",
                "affected_nodes": ["node-1", "node-2"],
            }
        agent = _build_agent()
        # Real execution would call the agent with telemetry context.
        result = agent.run_sync(f"Signal: {args.signal} on cluster {args.cluster}")
        return {"incident_summary": result.data, "severity": "warning"}

    dry_result = lifecycle.dry_run(proposal, _dry_run)

    # 4. APPROVE (auto-approve for low-risk monitoring actions)
    approved = lifecycle.approve(proposal, auto_approve=True)
    if not approved:
        print(f"Action {action_id} was not approved. Aborting.")
        return

    # 5. EXECUTE
    def _execute() -> dict[str, Any]:
        if os.environ.get("AGENT_DRY_RUN", "true").lower() not in ("false", "0", "no"):
            print("[DRY-RUN] Would publish incident summary to notification channels.")
            return {"status": "dry_run_skipped", "channels": ["slack", "pagerduty"]}
        return {
            "status": "published",
            "channels": ["slack", "pagerduty"],
            "summary": dry_result.get("incident_summary"),
        }

    lifecycle.execute(proposal, _execute)

    # 6. VERIFY
    def _verify() -> dict[str, Any]:
        return {"success": True, "check": "incident_logged"}

    lifecycle.verify(proposal, _verify)

    print(f"Agent completed. Final state: {lifecycle.current_state.name}")


if __name__ == "__main__":
    main()
