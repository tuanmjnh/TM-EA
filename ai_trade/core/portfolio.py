"""
Portfolio Capital Allocator & Multi-Strategy Risk Manager.
Manages aggregate portfolio exposure across TM_GoldSweepScalper and TM_SessionBreakout,
applies conservative Live Probing risk multipliers (0.25x), and enforces the 2.0% aggregate risk cap.
"""
from typing import Dict, Any, List, Optional, Tuple
from pydantic import BaseModel, Field

# Invariant Rules
MAX_AGGREGATE_PORTFOLIO_RISK_PCT = 2.0  # Max total risk open simultaneously across all strategies
DEFAULT_LIVE_PROBING_MULT = 0.25         # 0.25x risk during initial Live probing phase


class StrategyAllocation(BaseModel):
    name: str
    weight: float = 0.50          # Capital allocation weight (e.g. 0.60 for GSS, 0.40 for SB)
    max_active_positions: int = 1
    current_active_positions: int = 0
    current_risk_pct: float = 0.0


class PortfolioManager:
    def __init__(self,
                 total_equity: float = 5000.0,
                 is_live_probing: bool = False,
                 max_aggregate_risk_pct: float = MAX_AGGREGATE_PORTFOLIO_RISK_PCT):
        self.total_equity = total_equity
        self.is_live_probing = is_live_probing
        self.max_aggregate_risk_pct = max_aggregate_risk_pct

        self.allocations: Dict[str, StrategyAllocation] = {
            "TM_GoldSweepScalper": StrategyAllocation(name="TM_GoldSweepScalper", weight=0.60, max_active_positions=1),
            "TM_SessionBreakout": StrategyAllocation(name="TM_SessionBreakout", weight=0.40, max_active_positions=1)
        }

    def get_total_open_risk(self, open_positions: List[Dict[str, Any]]) -> float:
        """Calculate current aggregate risk % across all open positions."""
        total_risk_usd = 0.0
        for p in open_positions:
            entry = p.get("price_open", 0.0)
            sl = p.get("sl", 0.0)
            vol = p.get("volume", 0.01)
            if entry > 0 and sl > 0:
                dist = abs(entry - sl)
                # For gold 1 lot = 100 oz -> 1.0 point = 100 USD
                risk_usd = dist * vol * 100.0
                total_risk_usd += risk_usd
        
        return (total_risk_usd / self.total_equity) * 100.0 if self.total_equity > 0 else 0.0

    def can_open_trade(self,
                       strategy_name: str,
                       proposed_risk_pct: float,
                       open_positions: List[Dict[str, Any]]) -> Tuple[bool, float, str]:
        """
        Verify if portfolio has capacity for a new trade:
        1. Check strategy max active positions.
        2. Apply live probing multiplier if active.
        3. Enforce 2.0% aggregate portfolio risk cap.
        Returns: (approved, effective_risk_pct, reason)
        """
        strat = self.allocations.get(strategy_name)
        if not strat:
            strat = StrategyAllocation(name=strategy_name, weight=0.50, max_active_positions=1)
            self.allocations[strategy_name] = strat

        # Check existing positions for this strategy
        strat_positions = [p for p in open_positions if strategy_name.lower() in p.get("comment", "").lower()]
        if len(strat_positions) >= strat.max_active_positions:
            return False, 0.0, f"Strategy {strategy_name} reached max active position limit ({strat.max_active_positions})"

        # Apply Live Probing Multiplier (0.25x) if in live probing mode
        effective_risk = proposed_risk_pct
        if self.is_live_probing:
            effective_risk *= DEFAULT_LIVE_PROBING_MULT

        # Enforce Aggregate Risk Cap
        current_agg_risk = self.get_total_open_risk(open_positions)
        if current_agg_risk + effective_risk > self.max_aggregate_risk_pct:
            return False, 0.0, f"Aggregate risk would reach {current_agg_risk + effective_risk:.2f}% (Limit: {self.max_aggregate_risk_pct}%)"

        return True, round(effective_risk, 3), "Approved by Portfolio Manager"

    def calculate_lot_size(self,
                           entry_price: float,
                           stop_loss: float,
                           risk_pct: float,
                           min_volume: float = 0.01,
                           max_volume: float = 0.50) -> float:
        """
        Calculate precise lot size based on account equity and Stop Loss distance.
        Formula: Lot = (Equity * Risk%) / (SL_Distance * Contract_Size)
        """
        sl_distance = abs(entry_price - stop_loss)
        if sl_distance <= 0:
            return min_volume

        risk_usd = self.total_equity * (risk_pct / 100.0)
        # Gold standard contract size: 100 oz
        contract_size = 100.0
        calculated_lot = risk_usd / (sl_distance * contract_size)

        # Cap between min and max bounds and round to 2 decimals
        lot = round(min(max(calculated_lot, min_volume), max_volume), 2)
        return lot
