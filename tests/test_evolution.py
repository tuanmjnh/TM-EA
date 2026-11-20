"""
Unit tests for Self-Evolution Engine, Tester Runner, WFA, Monte Carlo, and Lineage Tree.
"""
import os
import tempfile
import pytest
from ai_trade.evolution.tester_runner import StrategyTesterRunner, BacktestResult
from ai_trade.evolution.validator import WalkForwardValidator, MonteCarloSimulator
from ai_trade.evolution.lineage import LineageManager, VariantRecord
from ai_trade.evolution.optimizer import SelfEvolutionEngine


def test_tester_runner_ini_and_html_parser():
    runner = StrategyTesterRunner()
    
    # 1. Test INI generation
    ini = runner.generate_ini(
        expert="TM_GoldSweepScalper.ex5",
        symbol="XAUUSDm",
        period="M5",
        from_date="2025.08.01",
        to_date="2026.07.31",
        inputs={"Sweep_RR": 3.0, "Enable_LondonKZ": True}
    )
    assert "Expert=TM_GoldSweepScalper.ex5" in ini
    assert "Symbol=XAUUSDm" in ini
    assert "Sweep_RR=3.0||3.0||0||0||N" in ini
    assert "Enable_LondonKZ=true||false||0||true||N" in ini

    # 2. Test HTML parser with mock MT5 report content
    mock_html = """
    <html><body>
    <table>
      <tr><td>Total Net Profit</td><td>177.68</td></tr>
      <tr><td>Gross Profit</td><td>2770.21</td></tr>
      <tr><td>Gross Loss</td><td>-2592.53</td></tr>
      <tr><td>Profit Factor</td><td>1.07</td></tr>
      <tr><td>Total Trades</td><td>158</td></tr>
      <tr><td>Maximal Drawdown</td><td>400.99 (7.40%)</td></tr>
      <tr><td>Profit Trades (% of total)</td><td>63 (39.87%)</td></tr>
    </table>
    </body></html>
    """
    with tempfile.NamedTemporaryFile("w", suffix=".htm", delete=False, encoding="utf-8") as f:
        f.write(mock_html)
        tmp_path = f.name

    try:
        metrics = runner.parse_report_html(tmp_path)
        assert metrics["net_profit"] == 177.68
        assert metrics["gross_profit"] == 2770.21
        assert metrics["profit_factor"] == 1.07
        assert metrics["total_trades"] == 158
        assert metrics["max_drawdown_pct"] == 7.40
        assert metrics["win_rate_pct"] == 39.87
    finally:
        if os.path.exists(tmp_path):
            os.remove(tmp_path)


def test_walk_forward_validator():
    wfa = WalkForwardValidator(is_months=3, oos_months=1, windows=4)
    windows = wfa.generate_windows("2025-08-01")
    assert len(windows) == 4
    assert windows[0].is_start == "2025.08.01"

    # Test evaluation
    results = [
        {"is_pf": 1.20, "oos_pf": 1.15, "oos_dd": 6.5},
        {"is_pf": 1.15, "oos_pf": 1.10, "oos_dd": 7.0},
        {"is_pf": 1.25, "oos_pf": 1.18, "oos_dd": 8.0},
        {"is_pf": 1.10, "oos_pf": 1.08, "oos_dd": 5.5},
    ]
    eval_res = wfa.evaluate_wfa(results)
    assert eval_res.total_windows == 4
    assert eval_res.passed_windows == 4
    assert eval_res.is_robust
    assert eval_res.wfa_efficiency_ratio >= 0.80


def test_monte_carlo_simulator():
    mc = MonteCarloSimulator(simulations=100, initial_capital=5000.0)
    
    # 50 wins (+50) and 50 losses (-30) -> Positive expectancy
    trades = [50.0 if i % 2 == 0 else -30.0 for i in range(100)]
    res = mc.simulate(trades)
    
    assert res.simulations_count == 100
    assert res.median_profit_usd > 0
    assert res.max_drawdown_95th_pct > 0.0
    assert res.risk_of_ruin_pct <= 1.0
    assert res.is_acceptable


def test_lineage_manager_and_rollback():
    with tempfile.TemporaryDirectory() as tmp_dir:
        tree_file = os.path.join(tmp_dir, "lineage_tree.json")
        manager = LineageManager(tree_file)
        
        # 1. Baseline initialization
        baseline = manager.get_active_baseline()
        assert baseline is not None
        assert baseline.version_id == "v1.0-baseline"
        assert baseline.profit_factor == 1.069

        # 2. Test candidate rejection (>10% PF regression)
        bad_candidate = VariantRecord(
            version_id="v1.1-bad",
            parent_id="v1.0-baseline",
            profit_factor=0.85,  # Regression > 20%
            max_drawdown_pct=8.0,
            total_trades=100
        )
        accepted, reason = manager.evaluate_candidate(bad_candidate)
        assert not accepted
        assert "Rejected" in reason
        assert manager.active_baseline_id == "v1.0-baseline"

        # 3. Test candidate acceptance (Improvement)
        good_candidate = VariantRecord(
            version_id="v1.2-champion",
            parent_id="v1.0-baseline",
            profit_factor=1.18,
            max_drawdown_pct=6.5,
            total_trades=150
        )
        accepted, reason = manager.evaluate_candidate(good_candidate)
        assert accepted
        assert manager.active_baseline_id == "v1.2-champion"

        # 4. Test rollback
        rolled_back = manager.rollback(reason="Test rollback to parent")
        assert rolled_back is not None
        assert rolled_back.version_id == "v1.0-baseline"
        assert manager.active_baseline_id == "v1.0-baseline"


def test_self_evolution_engine_cycle():
    with tempfile.TemporaryDirectory() as tmp_dir:
        tree_file = os.path.join(tmp_dir, "test_tree.json")
        engine = SelfEvolutionEngine(lineage_path=tree_file)
        
        # Run 2 mock evolution cycles
        cycle1 = engine.run_evolution_cycle(mock_execution=True)
        assert "candidate_id" in cycle1
        assert "wfa_metrics" in cycle1
        assert "mc_metrics" in cycle1

        cycle2 = engine.run_evolution_cycle(mock_execution=True)
        assert "candidate_id" in cycle2
        assert len(engine.lineage.variants) >= 3


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
