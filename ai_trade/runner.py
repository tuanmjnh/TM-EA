"""
TM-EA AI Trade Live & Paper Orchestrator Runner.
Continuously scans MT5 market rates, detects quantitative setups,
adjudicates via Multi-Agent Committee, validates through Hard RiskGate,
enforces Portfolio Capital Allocation, monitors System Health,
and executes risk-controlled trades.
"""
import sys
import time
import argparse
import logging
import datetime
from typing import Optional

if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8")
        sys.stderr.reconfigure(encoding="utf-8")
    except Exception:
        pass

from .core.models import EASignal, MarketContext, VerdictEnum
from .core.safety import is_kill_active, emergency_halt_and_close
from .core.portfolio import PortfolioManager
from .core.watchdog import SystemWatchdog
from .committee.orchestrator import AIOrchestrator
from .signals.detector import SignalDetector
from .bridge.mt5_mcp_server import (
    mt5_status,
    mt5_order_send,
    mt5_symbol_info,
    mt5_positions,
    mt5_account_info
)

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[logging.StreamHandler(sys.stdout)]
)
logger = logging.getLogger("ai_trade.runner")


class TradeRunner:
    def __init__(self,
                 symbol: str = "XAUUSDm",
                 mode: str = "paper",
                 fixed_lot: float = 0.01,
                 interval: int = 30):
        self.symbol = symbol
        self.mode = mode.lower()  # "paper" or "live"
        self.fixed_lot = fixed_lot
        self.interval = interval

        self.orchestrator = AIOrchestrator(
            providers_path="config/ai/providers.json",
            agents_path="config/ai/agents.json",
            db_path="data/results.db"
        )
        self.detector = SignalDetector(symbol=self.symbol)
        self.watchdog = SystemWatchdog()
        self.portfolio = PortfolioManager(
            total_equity=5000.0,
            is_live_probing=(self.mode == "live")
        )
        self.last_signal_time: Optional[str] = None

    def check_connection(self) -> bool:
        """Verify MT5 terminal is active and accessible."""
        status = mt5_status()
        if not status.get("connected"):
            logger.error(f"MT5 Terminal not connected: {status.get('error')}")
            self.watchdog.pulse(status_label="DISCONNECTED", extra_meta={"error": status.get("error")})
            return False

        balance = status.get("balance", 5000.0)
        self.portfolio.total_equity = balance
        logger.info(f"MT5 Connected | Login: {status.get('login')} | Server: {status.get('server')} | Balance: ${balance:,.2f} USD")
        self.watchdog.pulse(status_label="CONNECTED", extra_meta={"login": status.get("login"), "balance": balance})
        return True

    def run_cycle(self) -> bool:
        """Execute one complete detection -> adjudication -> execution cycle."""
        # 1. Physical Kill-Switch Check
        if is_kill_active():
            logger.critical("🛑 [KILL-SWITCH ACTIVE] Trading cycle aborted. config/ai/KILL detected.")
            self.watchdog.pulse(status_label="HALTED", extra_meta={"reason": "kill_switch_active"})
            return False

        # Pulse Watchdog
        self.watchdog.pulse(status_label="RUNNING", extra_meta={"symbol": self.symbol, "mode": self.mode})

        # 2. Market Pulse
        sym_info = mt5_symbol_info(self.symbol)
        if "error" in sym_info:
            logger.warning(f"Failed to fetch quote for {self.symbol}: {sym_info.get('error')}")
            return False

        bid = sym_info.get("bid", 0.0)
        ask = sym_info.get("ask", 0.0)
        spread = sym_info.get("spread_points", 0)

        # 3. Scan for Setups (Priority: M5 London KZ Sweep > H1 Asian Breakout)
        setup = self.detector.scan_gold_sweep()
        if not setup:
            setup = self.detector.scan_session_breakout()

        if not setup:
            context = self.detector.get_market_context()
            session_name = getattr(context, "session", getattr(context, "kill_zone", "Session"))
            logger.info(f"Market Pulse [{session_name}] {self.symbol} | Bid: {bid:.3f} Ask: {ask:.3f} | Spread: {spread} pts | Regime: {context.regime} | (No active setup)")
            return True

        signal, context = setup

        # Deduplicate signals on identical price/time
        signal_key = f"{signal.source_ea}_{signal.direction}_{signal.entry_price}"
        if self.last_signal_time == signal_key:
            logger.info(f"Setup already processed ({signal_key}). Waiting for next candle.")
            return True

        logger.info("=" * 60)
        logger.info(f"🎯 NEW SETUP DETECTED: {signal.source_ea} ({signal.setup_name})")
        logger.info(f"Direction: {'BUY' if signal.direction > 0 else 'SELL'} | Entry: {signal.entry_price} | SL: {signal.stop_loss} | TP: {signal.take_profit}")
        logger.info("=" * 60)

        # 4. Multi-Agent Committee Adjudication
        logger.info("🤖 Summoning Multi-Agent Committee (Technical, News, Risk, Bull/Bear, Chair)...")
        decision = self.orchestrator.evaluate_signal(context, signal)

        logger.info(f"🏛️ COMMITTEE VERDICT: {decision.verdict.value} (Confidence: {decision.confidence * 100:.1f}%)")
        logger.info(f"Risk Multiplier: {decision.execution_params.suggested_risk_mult:.2f}x | Reasoning: {decision.chair_reasoning}")

        # 5. RiskGate Check
        if not decision.validation.passed:
            logger.warning(f"❌ BLOCKED BY HARD RISKGATE: {decision.validation.reason} ({decision.validation.violations})")
            self.last_signal_time = signal_key
            return True

        # Check Actionable Verdicts
        is_actionable = decision.verdict in [
            VerdictEnum.STRONG_BUY, VerdictEnum.BUY, VerdictEnum.OVERWEIGHT,
            VerdictEnum.UNDERWEIGHT, VerdictEnum.SELL, VerdictEnum.STRONG_SELL
        ]

        if not is_actionable:
            logger.info("⏸️ Committee decided to HOLD/CANCEL. No trade executed.")
            self.last_signal_time = signal_key
            return True

        # 6. Portfolio Capacity & Dynamic Lot Calculation
        open_pos = mt5_positions(self.symbol) if self.mode == "live" else []
        if isinstance(open_pos, list) and open_pos and "error" in open_pos[0]:
            open_pos = []

        proposed_risk = 1.0 * decision.execution_params.suggested_risk_mult
        can_open, effective_risk, reason = self.portfolio.can_open_trade(
            strategy_name=signal.source_ea,
            proposed_risk_pct=proposed_risk,
            open_positions=open_pos
        )
        if not can_open:
            logger.warning(f"❌ BLOCKED BY PORTFOLIO MANAGER: {reason}")
            self.last_signal_time = signal_key
            return True

        # Compute dynamic lot size based on equity, SL distance, and contract size
        dyn_lot = self.portfolio.calculate_lot_size(
            entry_price=signal.entry_price,
            stop_loss=decision.execution_params.stop_loss,
            risk_pct=effective_risk,
            min_volume=0.01,
            max_volume=max(0.01, self.fixed_lot)
        )
        lot_size = round(dyn_lot, 2)
        action_str = "BUY" if signal.direction > 0 else "SELL"
        sl = decision.execution_params.stop_loss
        tp = decision.execution_params.take_profit

        # 7. Trade Execution (Paper vs Live)
        if self.mode == "live":
            logger.info(f"🚀 [LIVE EXECUTION] Sending {action_str} {lot_size} lot (Effective Risk: {effective_risk:.2f}%) on {self.symbol}...")
            res = mt5_order_send(
                symbol=self.symbol,
                action=action_str,
                volume=lot_size,
                sl=sl,
                tp=tp,
                deviation=20,
                magic=999001,
                comment=f"AI_{decision.verdict.value[:4]}"
            )
            if res.get("success"):
                logger.info(f"✅ ORDER FILLED: Ticket #{res.get('deal')} (Order #{res.get('order')}) @ {res.get('price')}")
            else:
                logger.error(f"❌ ORDER FAILED: Retcode {res.get('retcode')} - {res.get('error_details')}")
        else:
            logger.info(f"📝 [PAPER MODE] Virtual trade recorded: {action_str} {lot_size} lot @ {decision.execution_params.entry_price} (SL: {sl}, TP: {tp}, Effective Risk: {effective_risk:.2f}%)")

        self.last_signal_time = signal_key
        return True

    def start_loop(self):
        """Start continuous monitoring loop."""
        if not self.check_connection():
            return

        logger.info(f"Starting AI Trade Runner in [{self.mode.upper()}] mode on {self.symbol} (Interval: {self.interval}s)...")
        logger.info("Press Ctrl+C to stop.")

        try:
            while True:
                self.run_cycle()
                time.sleep(self.interval)
        except KeyboardInterrupt:
            logger.info("Runner stopped by user.")
            self.watchdog.pulse(status_label="STOPPED", extra_meta={"reason": "user_interrupt"})


def main():
    parser = argparse.ArgumentParser(description="TM-EA AI Trade Orchestrator Runner")
    parser.add_argument("--mode", type=str, default="paper", choices=["paper", "live"],
                        help="Execution mode: paper (virtual log only) or live (Exness Demo execution)")
    parser.add_argument("--symbol", type=str, default="XAUUSDm",
                        help="Trading symbol (e.g. XAUUSDm, XAUUSD)")
    parser.add_argument("--lot", type=float, default=0.01,
                        help="Base lot size for trades (default 0.01)")
    parser.add_argument("--interval", type=int, default=30,
                        help="Loop interval in seconds (default 30)")
    parser.add_argument("--once", action="store_true",
                        help="Run a single evaluation cycle and exit")
    parser.add_argument("--kill", action="store_true",
                        help="Emergency halt and liquidation trigger")

    args = parser.parse_args()

    if args.kill:
        logger.critical("Initiating emergency halt...")
        result = emergency_halt_and_close()
        print(result)
        return

    runner = TradeRunner(
        symbol=args.symbol,
        mode=args.mode,
        fixed_lot=args.lot,
        interval=args.interval
    )

    if args.once:
        runner.check_connection()
        runner.run_cycle()
    else:
        runner.start_loop()


if __name__ == "__main__":
    main()
