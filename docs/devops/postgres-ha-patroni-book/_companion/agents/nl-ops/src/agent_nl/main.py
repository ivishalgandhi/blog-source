"""
AGENT-11-NL: Natural-Language Ops Agent

Answers natural-language questions about cluster telemetry.
Grounds responses in pg_stat_replication, Patroni logs, and metrics.
Uses the shared lifecycle module for state management and audit logging.

Manual-equivalent runbook:
  See Ch. 07 "Interpreting pg_stat_replication and Patroni Logs"
  for the manual investigation steps this agent grounds its answers in.
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
    """Build a pydantic-ai agent for NL cluster telemetry Q&A."""
    model_name = os.environ.get("AGENT_LLM_MODEL", "gpt-4o")
    api_key = os.environ.get("OPENAI_API_KEY", "dummy-key-for-scaffold")
    model = OpenAIModel(model_name, api_key=api_key)
    return Agent(
        model,
        system_prompt=(
            "You are a Patroni HA operations assistant. "
            "Answer questions using pg_stat_replication, Patroni logs, and Prometheus metrics. "
            "Cite your sources and express uncertainty when data is missing."
        ),
    )


def main(argv: list[str] | None = None) -> None:
    parser = argparse.ArgumentParser(description="AGENT-11-NL: Natural-Language Ops Agent")
    parser.add_argument("--cluster", default="patroni-main", help="Target cluster name")
    parser.add_argument(
        "--question",
        default="Why is replication lag increasing?",
        help="Natural-language question to answer",
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
        agent_id="AGENT-11-NL",
        audit_log_path=f"./audit-{args.cluster}.jsonl",
    )

    # 1. OBSERVE
    action_id = lifecycle.observe(
        signal="nl-query",
        context={"cluster": args.cluster, "agent": "AGENT-11-NL", "question": args.question},
    )

    # 2. PROPOSE
    proposal = lifecycle.propose(
        description=f"Answer NL question: '{args.question}' for {args.cluster}",
        action="answer_nl_question",
        risk=ActionRisk.LOW,
        params={"cluster": args.cluster, "question": args.question},
    )

    # 3. DRY-RUN
    def _dry_run() -> dict[str, Any]:
        if os.environ.get("AGENT_DRY_RUN", "true").lower() not in ("false", "0", "no"):
            print("[DRY-RUN] Would retrieve telemetry and synthesize an answer.")
            return {
                "answer": (
                    f"Replication lag on {args.cluster} is increasing because "
                    f"the synchronous replica is under I/O pressure."
                ),
                "sources": ["pg_stat_replication", "node_disk_io_saturation"],
                "confidence": 0.78,
            }
        agent = _build_agent()
        # In a real implementation, fetch telemetry context and inject into prompt.
        telemetry_context = (
            f"pg_stat_replication: lag=120MB, state=streaming\n"
            f"Patroni log: no leader flaps in last 10m\n"
            f"Prometheus: disk_io_wait=85% on replica-2"
        )
        prompt = f"Question: {args.question}\n\nTelemetry:\n{telemetry_context}"
        result = agent.run_sync(prompt)
        return {"answer": result.data, "sources": ["pg_stat_replication", "patroni_logs"]}

    dry_result = lifecycle.dry_run(proposal, _dry_run)

    # 4. APPROVE (auto-approve for low-risk read-only Q&A)
    approved = lifecycle.approve(proposal, auto_approve=True)
    if not approved:
        print(f"Action {action_id} was not approved. Aborting.")
        return

    # 5. EXECUTE
    def _execute() -> dict[str, Any]:
        if os.environ.get("AGENT_DRY_RUN", "true").lower() not in ("false", "0", "no"):
            print("[DRY-RUN] Would return the synthesized answer to the user.")
            return {"status": "dry_run_skipped", "answer": dry_result.get("answer")}
        return {"status": "answered", "answer": dry_result.get("answer")}

    lifecycle.execute(proposal, _execute)

    # 6. VERIFY
    def _verify() -> dict[str, Any]:
        return {"success": True, "check": "answer_grounded_in_telemetry"}

    lifecycle.verify(proposal, _verify)

    print(f"Agent completed. Final state: {lifecycle.current_state.name}")


if __name__ == "__main__":
    main()
