"""
Comprehensive Test Suite for TM-EA AI Trade Orchestrator (Phase 1).
Tests Models, ProviderRouter, HardRiskGate, ResultsDatabase, and Orchestrator.
"""
import os
import sys
import tempfile
import pytest

# Add project root to sys.path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from ai_trade.core.models import (
    MarketContext, EASignal, ExecutionParams, ValidationResult,
    VerdictEnum, StanceEnum, SpecialistReport, EvidencePackage, DebateRound, CommitteeDecision
)
from ai_trade.core.risk_gate import HardRiskGate
from ai_trade.core.provider_router import ProviderRouter
from ai_trade.storage.db import ResultsDatabase
from ai_trade.bridge.mock_bridge import MockMT5Bridge
from ai_trade.committee.orchestrator import AIOrchestrator


def test_models_contracts():
    context, signal = MockMT5Bridge.get_sample_sweep_signal()
    assert context.symbol == "XAUUSDm"
    assert signal.direction == 1
    assert signal.entry_price > signal.stop_loss

    spec_report = SpecialistReport(
        specialist_name="TechnicalAnalyst",
        stance=StanceEnum.BULLISH,
        confidence=0.85,
        summary="Clear bullish sweep of Asia low with strong reclaim",
        key_factors=["Reclaim > 0.05 ATR", "Asia low swept"],
        risk_warnings=[]
    )
    assert spec_report.stance == StanceEnum.BULLISH
    assert spec_report.confidence == 0.85


def test_hard_risk_gate():
    gate = HardRiskGate(max_spread_points=350.0, max_risk_pct=1.0)
    context, signal = MockMT5Bridge.get_sample_sweep_signal()
    
    # 1. Valid params should pass
    valid_params = ExecutionParams(
        entry_price=signal.entry_price,
        stop_loss=signal.stop_loss,
        take_profit=signal.take_profit,
        suggested_risk_mult=1.0
    )
    res = gate.validate(signal, valid_params, context)
    assert res.passed is True
    assert len(res.violations) == 0

    # 2. Invalid Stop Loss (SL above entry on BUY)
    bad_sl_params = ExecutionParams(
        entry_price=signal.entry_price,
        stop_loss=signal.entry_price + 5.0,  # Invalid!
        take_profit=signal.take_profit
    )
    res_bad_sl = gate.validate(signal, bad_sl_params, context)
    assert res_bad_sl.passed is False
    assert any("BUY_SL_INVALID" in v for v in res_bad_sl.violations)

    # 3. Spread violation
    context_high_spread = context.model_copy(update={"spread_points": 400.0})
    res_spread = gate.validate(signal, valid_params, context_high_spread)
    assert res_spread.passed is False
    assert any("SPREAD_EXCEEDED" in v for v in res_spread.violations)

    # 4. Physical Kill-Switch Test
    with tempfile.NamedTemporaryFile() as tmp:
        gate_kill = HardRiskGate(kill_switch_path=tmp.name)
        res_kill = gate_kill.validate(signal, valid_params, context)
        assert res_kill.passed is False
        assert any("KILL_SWITCH_ACTIVE" in v for v in res_kill.violations)


def test_results_database():
    with tempfile.TemporaryDirectory() as tmp_dir:
        db_file = os.path.join(tmp_dir, "test_results.db")
        db = ResultsDatabase(db_path=db_file)
        
        # Test inserting decision
        decision = CommitteeDecision(
            symbol="XAUUSDm",
            source_setup="SweepReversal",
            verdict=VerdictEnum.BUY,
            confidence=0.82,
            execution_params=ExecutionParams(
                entry_price=2650.50,
                stop_loss=2642.00,
                take_profit=2676.00,
                suggested_risk_mult=1.0
            ),
            chair_reasoning="Strong confluence of technical reclaim and low spread",
            committee_summary={"test": "data"},
            validation=ValidationResult(passed=True, violations=[], reason="Passed RiskGate"),
            model_version="test-v1.0",
            latency_ms=120.5
        )
        dec_id = db.record_decision(decision)
        assert dec_id > 0

        # Test querying recent decisions
        recent = db.get_recent_decisions(limit=5)
        assert len(recent) == 1
        assert recent[0]["symbol"] == "XAUUSDm"
        assert recent[0]["verdict"] == "BUY"

        # Test recording outcome
        db.record_outcome(
            decision_id=dec_id,
            ticket=99887766,
            close_time="2026-11-19T16:00:00Z",
            close_price=2676.00,
            pnl_usd=127.50,
            r_multiple=3.0,
            outcome="WIN",
            spread_paid=2.8,
            commission_paid=0.0
        )


def test_provider_router_configuration():
    router = ProviderRouter(
        providers_path="config/ai/providers.json",
        agents_path="config/ai/agents.json"
    )
    assert "tokenharbor" in router.providers
    assert "technical_specialist" in router.agents
    role_cfg = router.get_role_config("technical_specialist")
    assert role_cfg["provider"] == "tokenharbor"
    assert role_cfg["temperature"] == 0.2


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
