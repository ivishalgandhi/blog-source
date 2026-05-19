"""AGENT-11-MON: Monitoring agent for Patroni HA clusters."""

__version__ = "0.1.0"

from agent_mon.main import main

__all__ = ["main", "__version__"]
