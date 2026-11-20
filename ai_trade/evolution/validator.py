"""
Out-Of-Sample Validation & Monte Carlo Robustness Engine.
Implements Walk-Forward Analysis (WFA) windows and Monte Carlo trade shuffling
to detect and eliminate over-fitting before live deployment.
"""
import random
import datetime
from typing import List, Dict, Any, Tuple
from pydantic import BaseModel, Field


class WalkForwardWindow(BaseModel):
    window_id: int
    is_start: str
    is_end: str
    oos_start: str
    oos_end: str


class WFAResult(BaseModel):
    total_windows: int
    passed_windows: int
    wfa_efficiency_ratio: float  # (OOS Mean PF) / (IS Mean PF)
    is_robust: bool
    details: List[Dict[str, Any]] = Field(default_factory=list)


class MonteCarloResult(BaseModel):
    simulations_count: int = 100
    mean_drawdown_pct: float
    max_drawdown_95th_pct: float
    max_drawdown_worst_pct: float
    risk_of_ruin_pct: float  # Prob of losing >= 30% capital
    median_profit_usd: float
    is_acceptable: bool  # 95th DD <= 12% and Risk of Ruin <= 1.0%


class WalkForwardValidator:
    def __init__(self, is_months: int = 3, oos_months: int = 1, windows: int = 4):
        self.is_months = is_months
        self.oos_months = oos_months
        self.windows = windows

    def generate_windows(self, start_date: str = "2025-08-01") -> List[WalkForwardWindow]:
        """
        Generate consecutive rolling In-Sample (IS) and Out-Of-Sample (OOS) windows.
        """
        dt_start = datetime.datetime.strptime(start_date, "%Y-%m-%d")
        result = []

        for i in range(self.windows):
            # Shift by i * oos_months
            offset_start = dt_start + datetime.timedelta(days=i * 30 * self.oos_months)
            is_end = offset_start + datetime.timedelta(days=self.is_months * 30)
            oos_start = is_end + datetime.timedelta(days=1)
            oos_end = oos_start + datetime.timedelta(days=self.oos_months * 30)

            result.append(WalkForwardWindow(
                window_id=i + 1,
                is_start=offset_start.strftime("%Y.%m.%d"),
                is_end=is_end.strftime("%Y.%m.%d"),
                oos_start=oos_start.strftime("%Y.%m.%d"),
                oos_end=oos_end.strftime("%Y.%m.%d"),
            ))

        return result

    def evaluate_wfa(self, window_results: List[Dict[str, Any]]) -> WFAResult:
        """
        Evaluate WFA results across all tested windows.
        Each item in window_results: {"is_pf": float, "oos_pf": float, "oos_dd": float}
        """
        if not window_results:
            return WFAResult(
                total_windows=0,
                passed_windows=0,
                wfa_efficiency_ratio=0.0,
                is_robust=False
            )

        passed = 0
        is_pfs = []
        oos_pfs = []

        for w in window_results:
            is_pf = w.get("is_pf", 1.0)
            oos_pf = w.get("oos_pf", 0.0)
            oos_dd = w.get("oos_dd", 0.0)

            is_pfs.append(is_pf)
            oos_pfs.append(oos_pf)

            # Criteria: OOS PF >= 1.05 and OOS DD <= 10.0%
            if oos_pf >= 1.05 and oos_dd <= 10.0:
                passed += 1

        mean_is = sum(is_pfs) / len(is_pfs) if is_pfs else 1.0
        mean_oos = sum(oos_pfs) / len(oos_pfs) if oos_pfs else 0.0

        eff_ratio = round(mean_oos / mean_is, 2) if mean_is > 0 else 0.0
        is_robust = (passed >= int(len(window_results) * 0.75)) and (eff_ratio >= 0.50)

        return WFAResult(
            total_windows=len(window_results),
            passed_windows=passed,
            wfa_efficiency_ratio=eff_ratio,
            is_robust=is_robust,
            details=window_results
        )


class MonteCarloSimulator:
    def __init__(self, simulations: int = 100, initial_capital: float = 5000.0):
        self.simulations = simulations
        self.initial_capital = initial_capital

    def simulate(self, trade_pnl_list: List[float]) -> MonteCarloResult:
        """
        Run Monte Carlo random trade permutations to compute tail-risk distributions.
        """
        if not trade_pnl_list or len(trade_pnl_list) < 5:
            return MonteCarloResult(
                simulations_count=0,
                mean_drawdown_pct=0.0,
                max_drawdown_95th_pct=0.0,
                max_drawdown_worst_pct=0.0,
                risk_of_ruin_pct=0.0,
                median_profit_usd=0.0,
                is_acceptable=False
            )

        n_trades = len(trade_pnl_list)
        max_drawdowns = []
        final_profits = []
        ruin_events = 0
        ruin_threshold = self.initial_capital * 0.70  # 30% capital loss

        for _ in range(self.simulations):
            # Reshuffle trades with replacement
            sampled_pnls = [random.choice(trade_pnl_list) for _ in range(n_trades)]
            
            equity = self.initial_capital
            peak = equity
            max_dd_usd = 0.0

            for pnl in sampled_pnls:
                equity += pnl
                if equity > peak:
                    peak = equity
                dd = peak - equity
                if dd > max_dd_usd:
                    max_dd_usd = dd
                if equity <= ruin_threshold:
                    ruin_events += 1
                    break

            dd_pct = (max_dd_usd / self.initial_capital) * 100.0
            max_drawdowns.append(dd_pct)
            final_profits.append(equity - self.initial_capital)

        max_drawdowns.sort()
        final_profits.sort()

        # 95th Percentile DD
        idx_95 = int(self.simulations * 0.95)
        dd_95 = max_drawdowns[min(idx_95, len(max_drawdowns) - 1)]
        dd_worst = max_drawdowns[-1]
        mean_dd = sum(max_drawdowns) / len(max_drawdowns)
        med_profit = final_profits[len(final_profits) // 2]
        ruin_pct = (ruin_events / self.simulations) * 100.0

        # Acceptance Criteria: 95th DD <= 12% and Risk of Ruin <= 1.0%
        is_acceptable = (dd_95 <= 12.0) and (ruin_pct <= 1.0) and (med_profit > 0)

        return MonteCarloResult(
            simulations_count=self.simulations,
            mean_drawdown_pct=round(mean_dd, 2),
            max_drawdown_95th_pct=round(dd_95, 2),
            max_drawdown_worst_pct=round(dd_worst, 2),
            risk_of_ruin_pct=round(ruin_pct, 2),
            median_profit_usd=round(med_profit, 2),
            is_acceptable=is_acceptable
        )
