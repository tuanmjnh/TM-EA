"""
Hard RiskGate (Local Validator) for TM-EA AI Trade Orchestrator.
Enforces non-negotiable safety rules before any trade can touch MT5.
"""
import os
from typing import Tuple, List
from .models import EASignal, ExecutionParams, MarketContext, ValidationResult


class HardRiskGate:
    def __init__(self,
                 max_spread_points: float = 350.0,
                 max_risk_pct: float = 1.0,
                 kill_switch_path: str = "config/ai/KILL"):
        self.max_spread_points = max_spread_points
        self.max_risk_pct = max_risk_pct
        self.kill_switch_path = kill_switch_path
        self.legacy_kill_switch = "config/KILL"

    def is_kill_switch_active(self) -> bool:
        """Check if physical kill switch exists in either primary or legacy path."""
        return os.path.exists(self.kill_switch_path) or os.path.exists(self.legacy_kill_switch)

    def validate(self,
                 signal: EASignal,
                 params: ExecutionParams,
                 context: MarketContext) -> ValidationResult:
        violations: List[str] = []

        # 1. Physical Kill-Switch Check
        if self.is_kill_switch_active():
            return ValidationResult(
                passed=False,
                violations=["KILL_SWITCH_ACTIVE: Emergency KILL file exists in config/"],
                reason="Trading halted by physical kill switch"
            )

        # 2. Mandatory Stop Loss Check
        if params.stop_loss <= 0.0:
            violations.append("STOP_LOSS_ZERO: Stop Loss must be > 0.0")

        # 3. Stop Loss Direction Integrity
        if signal.direction > 0:  # BUY
            if params.stop_loss >= params.entry_price:
                violations.append(f"BUY_SL_INVALID: SL ({params.stop_loss}) >= Entry ({params.entry_price})")
            if params.take_profit <= params.entry_price:
                violations.append(f"BUY_TP_INVALID: TP ({params.take_profit}) <= Entry ({params.entry_price})")
        elif signal.direction < 0:  # SELL
            if params.stop_loss <= params.entry_price:
                violations.append(f"SELL_SL_INVALID: SL ({params.stop_loss}) <= Entry ({params.entry_price})")
            if params.take_profit >= params.entry_price:
                violations.append(f"SELL_TP_INVALID: TP ({params.take_profit}) >= Entry ({params.entry_price})")

        # 4. Spread Filter
        if context.spread_points > self.max_spread_points:
            violations.append(f"SPREAD_EXCEEDED: Spread {context.spread_points} > Max {self.max_spread_points}")

        # 5. Risk Multiplier Bounds (0.0 to 1.0)
        if params.suggested_risk_mult < 0.0 or params.suggested_risk_mult > 1.0:
            violations.append(f"RISK_MULT_BOUNDS: Multiplier {params.suggested_risk_mult} must be in [0.0, 1.0]")

        # 6. Minimum Stop Loss Distance (prevent noise stop-outs)
        sl_distance = abs(params.entry_price - params.stop_loss)
        if context.atr > 0.0 and sl_distance < 0.5 * context.atr:
            violations.append(f"SL_TOO_TIGHT: Distance {sl_distance:.2f} < 0.5 * ATR ({context.atr:.2f})")

        if violations:
            return ValidationResult(
                passed=False,
                violations=violations,
                reason="Rejected by Hard RiskGate: " + "; ".join(violations)
            )

        return ValidationResult(
            passed=True,
            violations=[],
            reason="Verified by Hard RiskGate"
        )
