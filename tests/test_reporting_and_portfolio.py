"""
Unit tests for Performance Auditor, Go-Live Gates, Portfolio Manager, and Watchdog.
"""
import os
import tempfile
import pytest
from ai_trade.reporting.dashboard import PerformanceAuditor, GoLiveReport
from ai_trade.core.portfolio import PortfolioManager
from ai_trade.core.watchdog import SystemWatchdog


def test_performance_auditor_go_live_gates():
    auditor = PerformanceAuditor(db_path="non_existent_db.db")

    # 1. Test unready scenario (Only 10 trades, PF 1.10)
    mock_trades_unready = [{"outcome": "WIN", "profit": 20.0} if i % 2 == 0 else {"outcome": "LOSS", "profit": -18.0} for i in range(10)]
    report_unready = auditor.audit(closed_trades_override=mock_trades_unready)
    assert not report_unready.go_live_approved
    assert report_unready.total_closed_trades == 10

    # 2. Test ready scenario (60 trades, PF 1.50, DD 4.2%)
    mock_trades_ready = [{"outcome": "WIN", "profit": 45.0} if i % 2 == 0 else {"outcome": "LOSS", "profit": -20.0} for i in range(60)]
    report_ready = auditor.audit(closed_trades_override=mock_trades_ready)
    assert report_ready.total_closed_trades == 60
    assert report_ready.profit_factor >= 1.30
    assert report_ready.max_drawdown_pct <= 12.0
    assert report_ready.go_live_approved
    assert "ĐỦ ĐIỀU KIỆN GO-LIVE" in report_ready.recommendation


def test_portfolio_manager_risk_cap_and_live_probing():
    pm = PortfolioManager(total_equity=5000.0, is_live_probing=False)

    # 1. Lot size calculation
    # Equity 5000, Risk 1.0% ($50), Entry 3580.0, SL 3570.0 (Dist 10.0), Contract 100
    # Lot = 50 / (10 * 100) = 50 / 1000 = 0.05 lot
    lot = pm.calculate_lot_size(entry_price=3580.0, stop_loss=3570.0, risk_pct=1.0)
    assert lot == 0.05

    # 2. Live Probing Multiplier check (0.25x)
    pm_live = PortfolioManager(total_equity=5000.0, is_live_probing=True)
    approved, eff_risk, _ = pm_live.can_open_trade("TM_GoldSweepScalper", 1.0, open_positions=[])
    assert approved
    assert eff_risk == 0.25  # Scaled by 0.25x

    # 3. Aggregate Risk Cap (2.0% limit)
    # Existing open position already risking 1.8%
    mock_open_positions = [{
        "price_open": 3580.0,
        "sl": 3571.0,  # Dist 9.0
        "volume": 0.10, # Risk = 9.0 * 0.10 * 100 = $90 = 1.8% of 5000
        "comment": "TM_GoldSweepScalper"
    }]
    # A new trade asking for 0.5% risk should be blocked (1.8 + 0.5 = 2.3% > 2.0%)
    approved, _, reason = pm.can_open_trade("TM_SessionBreakout", 0.5, open_positions=mock_open_positions)
    assert not approved
    assert "Aggregate risk" in reason


def test_system_watchdog_heartbeat():
    with tempfile.TemporaryDirectory() as tmp_dir:
        hb_file = os.path.join(tmp_dir, "heartbeat.json")
        dog = SystemWatchdog(hb_file)
        pulse = dog.pulse("TESTING", {"cpu": "1.2%"})
        
        assert pulse["status"] == "TESTING"
        assert pulse["uptime_seconds"] >= 0.0
        assert os.path.exists(hb_file)


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
