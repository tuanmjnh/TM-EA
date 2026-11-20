"""
Headless Strategy Tester Runner for MetaTrader 5.
Generates automated .ini tester configurations, runs MT5 in headless mode,
and parses HTML/log reports into structured metrics.
"""
import os
import re
import time
import subprocess
import tempfile
from typing import Dict, Any, Optional, Tuple, List
from pydantic import BaseModel, Field

DEFAULT_TERMINAL_PATH = os.environ.get(
    "MT5_TERMINAL_PATH",
    r"C:\Program Files\MetaTrader 5 EXNESS\terminal64.exe"
)


class BacktestResult(BaseModel):
    expert: str
    symbol: str
    period: str
    from_date: str
    to_date: str
    net_profit: float = 0.0
    gross_profit: float = 0.0
    gross_loss: float = 0.0
    profit_factor: float = 0.0
    total_trades: int = 0
    win_rate_pct: float = 0.0
    max_drawdown_pct: float = 0.0
    max_drawdown_usd: float = 0.0
    consecutive_losses: int = 0
    inputs: Dict[str, Any] = Field(default_factory=dict)
    report_path: Optional[str] = None
    execution_time_sec: float = 0.0
    success: bool = True
    error_message: Optional[str] = None


class StrategyTesterRunner:
    def __init__(self, terminal_path: str = DEFAULT_TERMINAL_PATH):
        self.terminal_path = terminal_path

    def generate_ini(self,
                     expert: str,
                     symbol: str,
                     period: str,
                     from_date: str,
                     to_date: str,
                     deposit: int = 5000,
                     leverage: int = 100,
                     model: int = 4,  # 4 = Every tick based on real ticks
                     report_path: Optional[str] = None,
                     inputs: Optional[Dict[str, Any]] = None) -> str:
        """
        Generate MT5 configuration .ini file content.
        """
        lines = [
            "[Common]",
            "",
            "[Tester]",
            f"Expert={expert}",
            f"Symbol={symbol}",
            f"Period={period}",
            "Optimization=0",
            f"Model={model}",
            f"FromDate={from_date}",
            f"ToDate={to_date}",
            "ForwardMode=0",
            f"Deposit={deposit}",
            "Currency=USD",
            "ProfitInPips=0",
            f"Leverage={leverage}",
            "ExecutionMode=0",
            "Visual=0",
            "ReplaceReport=1",
            "ShutdownTerminal=1",
        ]

        if report_path:
            lines.append(f"Report={report_path}")

        lines.append("")
        lines.append("[TesterInputs]")
        if inputs:
            for k, v in inputs.items():
                if isinstance(v, bool):
                    lines.append(f"{k}={'true' if v else 'false'}||false||0||true||N")
                else:
                    lines.append(f"{k}={v}||{v}||0||0||N")

        return "\n".join(lines)

    def parse_report_html(self, html_path: str) -> Dict[str, float]:
        """
        Extract key quantitative metrics from an MT5 backtest HTML report.
        """
        metrics = {
            "net_profit": 0.0,
            "gross_profit": 0.0,
            "gross_loss": 0.0,
            "profit_factor": 0.0,
            "total_trades": 0,
            "win_rate_pct": 0.0,
            "max_drawdown_pct": 0.0,
            "max_drawdown_usd": 0.0,
        }

        if not os.path.exists(html_path):
            return metrics

        try:
            with open(html_path, "r", encoding="utf-8", errors="ignore") as f:
                content = f.read()

            # 1. Total Net Profit
            m_np = re.search(r"Total Net Profit</td>\s*<td[^>]*>([-\d\.\s,]+)</td>", content, re.IGNORECASE)
            if m_np:
                metrics["net_profit"] = float(m_np.group(1).replace(" ", "").replace(",", ""))

            # 2. Gross Profit & Loss
            m_gp = re.search(r"Gross Profit</td>\s*<td[^>]*>([-\d\.\s,]+)</td>", content, re.IGNORECASE)
            if m_gp:
                metrics["gross_profit"] = float(m_gp.group(1).replace(" ", "").replace(",", ""))

            m_gl = re.search(r"Gross Loss</td>\s*<td[^>]*>([-\d\.\s,]+)</td>", content, re.IGNORECASE)
            if m_gl:
                metrics["gross_loss"] = float(m_gl.group(1).replace(" ", "").replace(",", ""))

            # 3. Profit Factor
            m_pf = re.search(r"Profit Factor</td>\s*<td[^>]*>([-\d\.\s,]+)</td>", content, re.IGNORECASE)
            if m_pf:
                metrics["profit_factor"] = float(m_pf.group(1).replace(" ", "").replace(",", ""))

            # 4. Total Trades
            m_tt = re.search(r"Total Trades</td>\s*<td[^>]*>(\d+)</td>", content, re.IGNORECASE)
            if m_tt:
                metrics["total_trades"] = int(m_tt.group(1))

            # 5. Max Drawdown % & USD
            m_dd = re.search(r"Maximal Drawdown</td>\s*<td[^>]*>([-\d\.\s,]+)\s*\(([\d\.]+)\%\)</td>", content, re.IGNORECASE)
            if m_dd:
                metrics["max_drawdown_usd"] = float(m_dd.group(1).replace(" ", "").replace(",", ""))
                metrics["max_drawdown_pct"] = float(m_dd.group(2))

            # 6. Win Rate (Short/Long win trades %)
            m_wr = re.search(r"Profit Trades\s*\(%\s*of\s*total\)</td>\s*<td[^>]*>\d+\s*\(([\d\.]+)\%\)</td>", content, re.IGNORECASE)
            if m_wr:
                metrics["win_rate_pct"] = float(m_wr.group(1))

        except Exception as e:
            pass

        return metrics

    def run_test(self,
                 expert: str,
                 symbol: str,
                 period: str,
                 from_date: str,
                 to_date: str,
                 deposit: int = 5000,
                 leverage: int = 100,
                 model: int = 4,
                 inputs: Optional[Dict[str, Any]] = None,
                 timeout_sec: int = 600) -> BacktestResult:
        """
        Execute headless MT5 strategy test and return parsed performance.
        """
        t0 = time.time()
        with tempfile.TemporaryDirectory() as tmp_dir:
            ini_file = os.path.join(tmp_dir, "run.ini")
            report_file = os.path.join(tmp_dir, "report.htm")

            ini_content = self.generate_ini(
                expert=expert,
                symbol=symbol,
                period=period,
                from_date=from_date,
                to_date=to_date,
                deposit=deposit,
                leverage=leverage,
                model=model,
                report_path=report_file,
                inputs=inputs
            )

            with open(ini_file, "w", encoding="utf-8") as f:
                f.write(ini_content)

            # Check if terminal executable exists
            if not os.path.exists(self.terminal_path):
                return BacktestResult(
                    expert=expert,
                    symbol=symbol,
                    period=period,
                    from_date=from_date,
                    to_date=to_date,
                    inputs=inputs or {},
                    success=False,
                    error_message=f"MT5 terminal not found at: {self.terminal_path}"
                )

            # Run MT5 with /config
            cmd = [self.terminal_path, f"/config:{ini_file}"]
            try:
                proc = subprocess.run(cmd, timeout=timeout_sec, capture_output=True)
            except subprocess.TimeoutExpired:
                return BacktestResult(
                    expert=expert,
                    symbol=symbol,
                    period=period,
                    from_date=from_date,
                    to_date=to_date,
                    inputs=inputs or {},
                    success=False,
                    error_message=f"Backtest timed out after {timeout_sec} seconds"
                )

            t_elapsed = time.time() - t0
            metrics = self.parse_report_html(report_file)

            return BacktestResult(
                expert=expert,
                symbol=symbol,
                period=period,
                from_date=from_date,
                to_date=to_date,
                net_profit=metrics["net_profit"],
                gross_profit=metrics["gross_profit"],
                gross_loss=metrics["gross_loss"],
                profit_factor=metrics["profit_factor"],
                total_trades=metrics["total_trades"],
                win_rate_pct=metrics["win_rate_pct"],
                max_drawdown_pct=metrics["max_drawdown_pct"],
                max_drawdown_usd=metrics["max_drawdown_usd"],
                inputs=inputs or {},
                report_path=report_file if os.path.exists(report_file) else None,
                execution_time_sec=round(t_elapsed, 2),
                success=True
            )
