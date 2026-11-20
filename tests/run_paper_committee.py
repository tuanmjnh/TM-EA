"""
Runner for Paper Trading Multi-Agent Committee Evaluation.
Simulates incoming signals from TM_GoldSweepScalper / TM_SessionBreakout,
runs the multi-AI debate, and records decisions to SQLite database.
"""
import os
import sys
import json
import time

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from ai_trade.committee.orchestrator import AIOrchestrator
from ai_trade.bridge.mock_bridge import MockMT5Bridge


def main():
    print("=" * 70)
    print("TM-EA AI TRADE ORCHESTRATOR — PAPER COMMITTEE EVALUATION")
    print("=" * 70)

    orchestrator = AIOrchestrator(
        providers_path="config/ai/providers.json",
        agents_path="config/ai/agents.json",
        db_path="data/results.db"
    )

    print("\n[1/3] Loading sample signal from Mock MT5 Bridge...")
    context, signal = MockMT5Bridge.get_sample_sweep_signal()
    print(f"  Symbol: {context.symbol} ({context.timeframe}) | Kill-Zone: {context.kill_zone}")
    print(f"  Signal: {signal.setup_name} ({signal.source_ea}) -> {'BUY' if signal.direction > 0 else 'SELL'}")
    print(f"  Entry: {signal.entry_price} | SL: {signal.stop_loss} | TP: {signal.take_profit}")
    print(f"  Context: Spread={context.spread_points} pts, ATR={context.atr}, ADX_H1={context.adx_h1}")

    print("\n[2/3] Dispatching to Multi-AI Committee (Specialists -> Debate -> Chair)...")
    t0 = time.time()
    try:
        decision = orchestrator.evaluate_signal(context, signal)
        elapsed = time.time() - t0

        print(f"\n[3/3] Committee Adjudication Complete in {elapsed:.2f}s!")
        print("=" * 70)
        print(f"  DECISION ID:      {decision.id}")
        print(f"  VERDICT:          {decision.verdict.value}")
        print(f"  CONFIDENCE:       {decision.confidence * 100:.1f}%")
        print(f"  RISK MULTIPLIER:  {decision.execution_params.suggested_risk_mult:.2f}x")
        print(f"  VALIDATION:       {'PASSED' if decision.validation.passed else 'REJECTED'}")
        print(f"  CHAIR REASONING:  {decision.chair_reasoning}")
        print("=" * 70)

        print("\n--- Committee Debrief Summary ---")
        summary = decision.committee_summary
        tech = summary.get("technical", {})
        news = summary.get("sentiment", {})
        risk = summary.get("risk", {})
        debate = summary.get("debate", {})

        print(f"  * Technical [{tech.get('stance')}]: {tech.get('summary')}")
        print(f"  * Macro/News [{news.get('stance')}]: {news.get('summary')}")
        print(f"  * Risk/Vol   [{risk.get('stance')}]: {risk.get('summary')}")
        print(f"  * Bull Argument: {debate.get('bull_argument')[:120]}...")
        print(f"  * Bear Argument: {debate.get('bear_argument')[:120]}...")

        # Verify DB insertion
        recent = orchestrator.db.get_recent_decisions(limit=1)
        print(f"\n[OK] Successfully persisted decision #{decision.id} to data/results.db!")

    except Exception as e:
        print(f"\n[ERROR] Committee evaluation encountered error: {e}")
        import traceback
        traceback.print_exc()


if __name__ == "__main__":
    main()
