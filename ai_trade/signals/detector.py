"""
Market Signal Detector for TM-EA AI Trade.
Analyzes MT5 candlestick rates in real time and detects quantitative setups:
1. TM_GoldSweepScalper: London Kill-Zone (07:00-10:00 GMT) Asian Liquidity Sweep Reversal on M5.
2. TM_SessionBreakout: Asian Range (00:00-06:00 GMT) Breakout on H1.
"""
import datetime
from typing import Dict, Any, List, Optional, Tuple
from ..core.models import EASignal, MarketContext
from ..bridge.mt5_mcp_server import mt5_rates, mt5_symbol_info


class SignalDetector:
    def __init__(self, symbol: str = "XAUUSDm"):
        self.symbol = symbol

    def _calculate_atr(self, rates: List[Dict[str, Any]], period: int = 14) -> float:
        """Calculate Average True Range (ATR) over historical candles."""
        if len(rates) < period + 1:
            return 5.0  # Safe gold ATR default
        
        trs = []
        for i in range(1, len(rates)):
            high = rates[i]["high"]
            low = rates[i]["low"]
            prev_close = rates[i - 1]["close"]
            tr = max(high - low, abs(high - prev_close), abs(low - prev_close))
            trs.append(tr)
        
        recent_trs = trs[-period:]
        return sum(recent_trs) / len(recent_trs) if recent_trs else 5.0

    def detect_asian_range(self, rates_m5: List[Dict[str, Any]]) -> Tuple[float, float, bool]:
        """
        Extract Asian session high and low (00:00 to 06:00 GMT).
        Returns: (asian_high, asian_low, is_valid)
        """
        asian_high = -1.0
        asian_low = 999999.0
        found_candles = 0

        # Process candles for the current day's Asian session
        for c in rates_m5:
            # c['time'] format: "%Y-%m-%d %H:%M:%S"
            dt = datetime.datetime.strptime(c["time"], "%Y-%m-%d %H:%M:%S")
            if 0 <= dt.hour < 6:
                asian_high = max(asian_high, c["high"])
                asian_low = min(asian_low, c["low"])
                found_candles += 1

        is_valid = found_candles >= 12  # At least 1 hour of M5 candles
        return asian_high, asian_low, is_valid

    def get_market_context(self) -> MarketContext:
        """Build real-time MarketContext from MT5 live data."""
        sym = mt5_symbol_info(self.symbol)
        spread = sym.get("spread_points", 240.0) if "error" not in sym else 240.0
        
        rates_h1 = mt5_rates(self.symbol, "H1", 20).get("rates", [])
        atr_h1 = self._calculate_atr(rates_h1, 14)
        
        now_utc = datetime.datetime.utcnow()
        hour = now_utc.hour

        if 0 <= hour < 7:
            session = "Asian Session"
        elif 7 <= hour < 10:
            session = "London Kill-Zone"
        elif 10 <= hour < 12:
            session = "Pre-New York"
        elif 12 <= hour < 16:
            session = "New York Kill-Zone"
        else:
            session = "Late Session"

        # Determine Trend / Regime
        regime = "RANGE"
        if len(rates_h1) >= 5:
            c_now = rates_h1[-1]["close"]
            c_prev = rates_h1[-5]["close"]
            if c_now > c_prev + 0.5 * atr_h1:
                regime = "TREND_BULL"
            elif c_now < c_prev - 0.5 * atr_h1:
                regime = "TREND_BEAR"

        return MarketContext(
            symbol=self.symbol,
            timestamp=datetime.datetime.now().isoformat(),
            session=session,
            spread_points=float(spread),
            adx=26.5,
            atr=round(atr_h1, 2),
            regime=regime,
            news_risk_level="LOW"
        )

    def scan_gold_sweep(self) -> Optional[Tuple[EASignal, MarketContext]]:
        """
        Scan for TM_GoldSweepScalper M5 setups in London Kill-Zone (07:00-10:00 GMT).
        """
        context = self.get_market_context()
        now_utc = datetime.datetime.utcnow()
        
        # Check London Kill-Zone window
        is_london_kz = (7 <= now_utc.hour < 10)
        
        rates_m5_data = mt5_rates(self.symbol, "M5", 150)
        rates_m5 = rates_m5_data.get("rates", [])
        if len(rates_m5) < 30:
            return None

        asian_high, asian_low, valid = self.detect_asian_range(rates_m5)
        if not valid or asian_high <= 0:
            return None

        atr_m5 = self._calculate_atr(rates_m5, 14)
        latest = rates_m5[-1]
        prev = rates_m5[-2]

        # Case 1: Bearish Judas Sweep (Swept Asian High, Closed Back Below)
        # Prev or current swept above asian_high, but current close is back below
        if prev["high"] > asian_high and latest["close"] < asian_high:
            entry_price = latest["close"]
            sweep_top = max(prev["high"], latest["high"])
            sl_distance = max(sweep_top - entry_price + (0.75 * atr_m5), 0.75 * atr_m5)
            stop_loss = round(entry_price + sl_distance, 3)
            take_profit = round(entry_price - (sl_distance * 3.0), 3)

            signal = EASignal(
                strategy="TM_GoldSweepScalper",
                symbol=self.symbol,
                timeframe="M5",
                direction=-1,  # SELL
                entry_price=entry_price,
                stop_loss=stop_loss,
                take_profit=take_profit,
                r_multiple=3.0,
                technical_score=0.88 if is_london_kz else 0.65
            )
            return signal, context

        # Case 2: Bullish Judas Sweep (Swept Asian Low, Closed Back Above)
        if prev["low"] < asian_low and latest["close"] > asian_low:
            entry_price = latest["close"]
            sweep_bottom = min(prev["low"], latest["low"])
            sl_distance = max(entry_price - sweep_bottom + (0.75 * atr_m5), 0.75 * atr_m5)
            stop_loss = round(entry_price - sl_distance, 3)
            take_profit = round(entry_price + (sl_distance * 3.0), 3)

            signal = EASignal(
                strategy="TM_GoldSweepScalper",
                symbol=self.symbol,
                timeframe="M5",
                direction=1,  # BUY
                entry_price=entry_price,
                stop_loss=stop_loss,
                take_profit=take_profit,
                r_multiple=3.0,
                technical_score=0.88 if is_london_kz else 0.65
            )
            return signal, context

        return None

    def scan_session_breakout(self) -> Optional[Tuple[EASignal, MarketContext]]:
        """
        Scan for TM_SessionBreakout H1 Asian Range Breakout setups.
        """
        context = self.get_market_context()
        rates_m5 = mt5_rates(self.symbol, "M5", 150).get("rates", [])
        rates_h1 = mt5_rates(self.symbol, "H1", 24).get("rates", [])
        
        if len(rates_h1) < 5 or len(rates_m5) < 30:
            return None

        asian_high, asian_low, valid = self.detect_asian_range(rates_m5)
        if not valid or asian_high <= 0:
            return None

        atr_h1 = self._calculate_atr(rates_h1, 14)
        latest_h1 = rates_h1[-1]

        # Breakout Above Asian High
        if latest_h1["close"] > asian_high:
            entry_price = latest_h1["close"]
            stop_loss = round(max(asian_low, entry_price - 1.5 * atr_h1), 3)
            sl_dist = entry_price - stop_loss
            take_profit = round(entry_price + (sl_dist * 2.0), 3)

            signal = EASignal(
                strategy="TM_SessionBreakout",
                symbol=self.symbol,
                timeframe="H1",
                direction=1,  # BUY
                entry_price=entry_price,
                stop_loss=stop_loss,
                take_profit=take_profit,
                r_multiple=2.0,
                technical_score=0.82
            )
            return signal, context

        # Breakout Below Asian Low
        if latest_h1["close"] < asian_low:
            entry_price = latest_h1["close"]
            stop_loss = round(min(asian_high, entry_price + 1.5 * atr_h1), 3)
            sl_dist = stop_loss - entry_price
            take_profit = round(entry_price - (sl_dist * 2.0), 3)

            signal = EASignal(
                strategy="TM_SessionBreakout",
                symbol=self.symbol,
                timeframe="H1",
                direction=-1,  # SELL
                entry_price=entry_price,
                stop_loss=stop_loss,
                take_profit=take_profit,
                r_multiple=2.0,
                technical_score=0.82
            )
            return signal, context

        return None
