"""
Self-Evolution & Parameter Optimization Engine for TM-EA.
Automates Strategy Tester execution, Out-Of-Sample Walk-Forward analysis,
Monte Carlo simulation, and lineage rollback.
"""
from .tester_runner import StrategyTesterRunner, BacktestResult
from .validator import WalkForwardValidator, MonteCarloSimulator
from .lineage import LineageManager, VariantRecord

__all__ = [
    "StrategyTesterRunner",
    "BacktestResult",
    "WalkForwardValidator",
    "MonteCarloSimulator",
    "LineageManager",
    "VariantRecord",
]
