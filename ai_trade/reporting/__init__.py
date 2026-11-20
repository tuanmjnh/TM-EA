"""
Reporting and Portfolio Performance Analytics for TM-EA AI Trade.
Evaluates Go-Live readiness metrics, trade distribution, and committee accuracy.
"""

def __getattr__(name: str):
    if name in ("PerformanceAuditor", "GoLiveReport", "GoLiveGate"):
        from .dashboard import PerformanceAuditor, GoLiveReport, GoLiveGate
        return locals()[name]
    raise AttributeError(f"module {__name__!r} has no attribute {name!r}")

__all__ = ["PerformanceAuditor", "GoLiveReport", "GoLiveGate"]
