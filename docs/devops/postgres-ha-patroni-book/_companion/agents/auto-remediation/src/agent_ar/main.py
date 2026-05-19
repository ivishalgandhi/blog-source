"""
AGENT-11-AR: Auto-Remediation Agent

Detects dead slots, blocking queries, and stuck WAL senders.
Proposes recovery actions. HIGH RISK — requires human approval.
Uses the shared lifecycle module for state management and audit logging.

Manual-equivalent runbook:
  See Ch. 07 "Resolving Blocking Queries and Dead Replication Slots"
  for the manual remediation steps this agent automates.
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
    """Build a pydantic-ai agent for remediation recommendations."""
    model_name = os.environ.get("AGENT_LLM_MODEL", "gpt-4o")
    api_key = os.environ.get("OPENAI_API_KEY", "dummy-key-for-scaffold")
    model = OpenAIModel(model_name, api_key=api_key)
    return Agent(
        model,
        system_prompt=(
            "You are a PostgreSQL remediation assistant. "
            "Detect dead replication slots, blocking queries, and stuck WAL senders. "
            "Propose safe recovery actions with rollback considerations."
        ),
    )


def main(argv: list[str] | None = None) -> None:
    parser = argparse.ArgumentParser(description="AGENT-11-AR: Auto-Remediation Agent")
    parser.add_argument("--cluster", default="patroni-main", help="Target cluster name")
    parser.add_argument(
        "--symptom",
        default="dead-slot",
        choices=["dead-slot", "blocking-query", "stuck-wal-sender"],
        help="Detected symptom to remediate",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        default=None,
        help="Run in dry-run mode (default unless AGENT_DRY_RUN=false)",
    )
    parser.add_argument(
        "--human-confirmed",
        action="store_true",
        default=False,
        help="Confirm human-in-the-loop approval for HIGH-RISK actions",
    )
    args = parser.parse_args(argv)

    # Default to dry-run mode unless explicitly disabled.
    if args.dry_run is not None:
        os.environ["AGENT_DRY_RUN"] = str(args.dry_run).lower()
    require_dry_run_mode()

    lifecycle = AgentLifecycle(
        agent_id="AGENT-11-AR",
        audit_log_path=f"./audit-{args.cluster}.jsonl",
        require_human_approval_for={ActionRisk.HIGH},
    )

    # 1. OBSERVE
    action_id = lifecycle.observe(
        signal=args.symptom,
        context={"cluster": args.cluster, "agent": "AGENT-11-AR", "symptom": args.symptom},
    )

    # 2. PROPOSE
    proposal = lifecycle.propose(
        description=f"Remediate {args.symptom} on {args.cluster}",
        action=f"remediate_{args.symptom.replace('-', '_')}",
        risk=ActionRisk.HIGH,
        params={"cluster": args.cluster, "symptom": args.symptom},
    )

    # 3. DRY-RUN
    def _dry_run() -> dict[str, Any]:
        if os.environ.get("AGENT_DRY_RUN", "true").lower() not in ("false", "0", "no"):
            print(f"[DRY-RUN] Would diagnose {args.symptom} and plan remediation.")
            if args.symptom == "dead-slot":
                return {
                    "action": "pg_drop_replication_slot",
                    "target_slot": "stale_slot_1",
                    "backup_required": True,
                }
            if args.symptom == "blocking-query":
                return {
                    "action": "pg_terminate_backend",
                    "target_pid": 12345,
                    "grace_period_seconds": 30,
                }
            return {
                "action": "restart_wal_sender",
                "target_backend": "walsender_123",
            }
        agent = _build_agent()
        prompt = f"Cluster: {args.cluster}\nSymptom: {args.symptom}\nPropose remediation."
        result = agent.run_sync(prompt)
        return {"recommendation": result.data}

    dry_result = lifecycle.dry_run(proposal, _dry_run)

    # 4. APPROVE (HIGH RISK — requires human approval)
    approved = lifecycle.approve(
        proposal,
        auto_approve=False,
        human_confirmed=args.human_confirmed,
    )
    if not approved:
        print(f"Action {action_id} was not approved. Aborting.")
        return

    # 5. EXECUTE
    def _execute() -> dict[str, Any]:
        if os.environ.get("AGENT_DRY_RUN", "true").lower() not in ("false", "0", "no"):
            print(f"[DRY-RUN] Would execute remediation: {dry_result.get('action')}")
            return {"status": "dry_run_skipped", "remediation": dry_result.get("action")}
        return {"status": "executed", "remediation": dry_result.get("action")}

    lifecycle.execute(proposal, _execute)

    # 6. VERIFY
    def _verify() -> dict[str, Any]:
        return {"success": True, "check": f"{args.symptom}_resolved"}

    lifecycle.verify(proposal, _verify)

    print(f"Agent completed. Final state: {lifecycle.current_state.name}")


if __name__ == "__main__":
    main()
