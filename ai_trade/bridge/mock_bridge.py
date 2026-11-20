"""
Mock MT5 Bridge for Paper Trading & Unit Testing.
Provides realistic sample signals from TM_SessionBreakout and TM_GoldSweepScalper.
"""
from typing import Tuple
from ..core.models import MarketContext, EASignal


class MockMT5Bridge:
    @staticmethod
    def get_sample_sweep_signal() -> Tuple[MarketContext, EASignal]:
        """Realistic sample signal from TM_GoldSweepScalper (M5 London Judas Sweep)."""
        context = MarketContext(
            symbol="XAUUSDm",
            timeframe="M5",
            bid=2650.50,
            ask=2650.78,
            spread_points=28.0,
            atr=3.25,
            adx_h1=22.4,
            regime="RANGE",
            kill_zone="London KZ",
            server_time="2026.11.19 09:15:00",
            gmt_time="2026.11.19 07:15:00",
            asian_high=2655.00,
            asian_low=2645.00,
            pdh=2662.00,
            pdl=2638.00
        )
        signal = EASignal(
            source_ea="TM_GoldSweepScalper",
            setup_name="SweepReversal",
            direction=1,  # BUY
            entry_price=2650.78,
            stop_loss=2642.50,
            take_profit=2675.62,
            proposed_volume=0.05,
            reason="Bullish Sweep of Asia Low (2645.00) | Pen=2.10 Reclaim=2650.50"
        )
        return context, signal

    @staticmethod
    def get_sample_breakout_signal() -> Tuple[MarketContext, EASignal]:
        """Realistic sample signal from TM_SessionBreakout (H1 Asian Breakout)."""
        context = MarketContext(
            symbol="XAUUSDm",
            timeframe="H1",
            bid=2660.10,
            ask=2660.38,
            spread_points=28.0,
            atr=7.50,
            adx_h1=25.8,
            regime="TREND_BULL",
            kill_zone="London KZ",
            server_time="2026.11.19 10:00:00",
            gmt_time="2026.11.19 08:00:00",
            asian_high=2658.00,
            asian_low=2640.00,
            pdh=2665.00,
            pdl=2635.00
        )
        signal = EASignal(
            source_ea="TM_SessionBreakout",
            setup_name="AsianBreakout",
            direction=1,  # BUY
            entry_price=2660.38,
            stop_loss=2640.00,
            take_profit=2762.28,
            proposed_volume=0.03,
            reason="H1 bar 1 closed above Asian High (2660.10 > 2658.00)"
        )
        return context, signal
