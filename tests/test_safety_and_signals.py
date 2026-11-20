"""
Unit tests for Safety (Kill-Switch) and Signal Detection modules.
"""
import os
import pytest
from ai_trade.core.safety import is_kill_active, trigger_kill, clear_kill
from ai_trade.signals.detector import SignalDetector
from ai_trade.core.models import MarketContext, EASignal


def test_kill_switch_lifecycle():
    # 1. Clear before test
    clear_kill()
    assert not is_kill_active()

    # 2. Trigger
    p = trigger_kill("Unit test kill")
    assert is_kill_active()
    assert os.path.exists(p)

    # 3. Clear after test
    cleared = clear_kill()
    assert cleared
    assert not is_kill_active()


def test_signal_detector_calculations():
    detector = SignalDetector("XAUUSDm")
    
    # Mock candle data
    mock_candles = [
        {"time": f"2026-11-20 0{i}:00:00", "open": 3580.0, "high": 3585.0, "low": 3575.0, "close": 3582.0, "tick_volume": 100, "spread": 240}
        for i in range(1, 6)
    ]
    # Add 10 more candles to meet min requirement
    for i in range(10):
        mock_candles.append(
            {"time": f"2026-11-20 05:{i*5:02d}:00", "open": 3580.0, "high": 3588.0, "low": 3572.0, "close": 3581.0, "tick_volume": 100, "spread": 240}
        )

    high, low, valid = detector.detect_asian_range(mock_candles)
    assert valid
    assert high == 3588.0
    assert low == 3572.0

    atr = detector._calculate_atr(mock_candles, 14)
    assert atr > 0.0


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
