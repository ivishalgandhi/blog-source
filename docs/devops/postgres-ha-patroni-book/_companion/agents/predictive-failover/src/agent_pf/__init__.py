"""AGENT-11-PF: Predictive failover agent for Patroni HA clusters."""

__version__ = "0.1.0"

from agent_pf.main import main

__all__ = ["main", "__version__"]
