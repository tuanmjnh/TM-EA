"""
MetaTrader 5 Model Context Protocol (MCP) Server.
Enables AI agents and Antigravity IDE to query market data, account status,
positions, history, and execute risk-controlled orders on MetaTrader 5.
"""
import os
import sys
import datetime
from typing import Dict, Any, List, Optional
try:
    # Standalone FastMCP package (recommended, avoids Windows pywin32 DLL loading issues)
    from fastmcp import FastMCP  # type: ignore
except (ImportError, ModuleNotFoundError):
    try:
        # MCP v1.x FastMCP
        from mcp.server.fastmcp import FastMCP  # type: ignore
    except (ImportError, ModuleNotFoundError):
        # MCP v2.x MCPServer alias
        from mcp.server.mcpserver import MCPServer as FastMCP  # type: ignore
import MetaTrader5 as mt5  # type: ignore

# Configuration
DEFAULT_TERMINAL_PATH = os.environ.get(
    "MT5_TERMINAL_PATH",
    r"C:\Program Files\MetaTrader 5 EXNESS\terminal64.exe"
)
MAX_LOT_SAFETY_CAP = float(os.environ.get("MT5_MAX_LOT_CAP", "0.5"))

# Initialize FastMCP Server
mcp = FastMCP("mt5")


def _ensure_connected() -> bool:
    """Ensure connection to MetaTrader 5 terminal."""
    if not mt5.initialize(path=DEFAULT_TERMINAL_PATH):
        # Attempt fallback to default path if custom path failed
        if not mt5.initialize():
            return False
    return True


def _resolve_symbol(symbol: str) -> str:
    """Resolve symbol name handling broker suffixes (e.g., XAUUSD vs XAUUSDm)."""
    if mt5.symbol_info(symbol):
        return symbol
    # Try with 'm' suffix
    if mt5.symbol_info(symbol + "m"):
        return symbol + "m"
    # Try stripping 'm' suffix
    if symbol.endswith("m") and mt5.symbol_info(symbol[:-1]):
        return symbol[:-1]
    return symbol


def _timeframe_to_mt5(tf_str: str) -> int:
    """Map string timeframe to MT5 constant."""
    tf_map = {
        "M1": mt5.TIMEFRAME_M1,
        "M2": mt5.TIMEFRAME_M2,
        "M3": mt5.TIMEFRAME_M3,
        "M4": mt5.TIMEFRAME_M4,
        "M5": mt5.TIMEFRAME_M5,
        "M6": mt5.TIMEFRAME_M6,
        "M10": mt5.TIMEFRAME_M10,
        "M12": mt5.TIMEFRAME_M12,
        "M15": mt5.TIMEFRAME_M15,
        "M20": mt5.TIMEFRAME_M20,
        "M30": mt5.TIMEFRAME_M30,
        "H1": mt5.TIMEFRAME_H1,
        "H2": mt5.TIMEFRAME_H2,
        "H3": mt5.TIMEFRAME_H3,
        "H4": mt5.TIMEFRAME_H4,
        "H6": mt5.TIMEFRAME_H6,
        "H8": mt5.TIMEFRAME_H8,
        "H12": mt5.TIMEFRAME_H12,
        "D1": mt5.TIMEFRAME_D1,
        "W1": mt5.TIMEFRAME_W1,
        "MN1": mt5.TIMEFRAME_MN1,
    }
    return tf_map.get(tf_str.upper(), mt5.TIMEFRAME_M5)


@mcp.tool()
def mt5_status() -> Dict[str, Any]:
    """
    Check MT5 terminal connection status, account summary, and server latency.
    """
    if not _ensure_connected():
        return {
            "connected": False,
            "error": f"Failed to connect to MT5 terminal: {mt5.last_error()}"
        }
    
    term = mt5.terminal_info()
    acc = mt5.account_info()
    version = mt5.version()

    return {
        "connected": bool(term.connected) if term else False,
        "terminal_trade_allowed": bool(term.trade_allowed) if term else False,
        "terminal_path": term.path if term else "",
        "mt5_version": version,
        "login": acc.login if acc else None,
        "server": acc.server if acc else None,
        "balance": acc.balance if acc else 0.0,
        "equity": acc.equity if acc else 0.0,
        "currency": acc.currency if acc else ""
    }


@mcp.tool()
def mt5_account_info() -> Dict[str, Any]:
    """
    Get detailed trading account metrics including balance, equity, margin, free margin, leverage, and profit.
    """
    if not _ensure_connected():
        return {"error": f"MT5 not connected: {mt5.last_error()}"}
    
    acc = mt5.account_info()
    if not acc:
        return {"error": f"Unable to fetch account info: {mt5.last_error()}"}
    
    return {
        "login": acc.login,
        "name": acc.name,
        "server": acc.server,
        "currency": acc.currency,
        "leverage": acc.leverage,
        "balance": acc.balance,
        "equity": acc.equity,
        "margin": acc.margin,
        "margin_free": acc.margin_free,
        "margin_level": acc.margin_level,
        "profit": acc.profit,
        "trade_mode": "DEMO" if acc.trade_mode == mt5.ACCOUNT_TRADE_MODE_DEMO else ("REAL" if acc.trade_mode == mt5.ACCOUNT_TRADE_MODE_REAL else "CONTEST"),
        "trade_allowed": acc.trade_allowed,
        "trade_expert": acc.trade_expert
    }


@mcp.tool()
def mt5_symbol_info(symbol: str = "XAUUSDm") -> Dict[str, Any]:
    """
    Get real-time market quote, spread, contract size, and trading specifications for a symbol.
    
    Args:
        symbol: Market symbol (e.g., 'XAUUSDm', 'XAUUSD', 'EURUSD', 'BTCUSD').
    """
    if not _ensure_connected():
        return {"error": f"MT5 not connected: {mt5.last_error()}"}
    
    sym_name = _resolve_symbol(symbol)
    if not mt5.symbol_select(sym_name, True):
        return {"error": f"Symbol '{symbol}' not found or cannot be selected."}
    
    s = mt5.symbol_info(sym_name)
    if not s:
        return {"error": f"Failed to get info for symbol {sym_name}: {mt5.last_error()}"}
    
    return {
        "symbol": s.name,
        "bid": s.bid,
        "ask": s.ask,
        "spread_points": s.spread,
        "spread_value": round(s.ask - s.bid, s.digits),
        "point": s.point,
        "digits": s.digits,
        "contract_size": s.trade_contract_size,
        "volume_min": s.volume_min,
        "volume_max": s.volume_max,
        "volume_step": s.volume_step,
        "swap_long": s.swap_long,
        "swap_short": s.swap_short,
        "trade_mode": s.trade_mode,
        "time": datetime.datetime.fromtimestamp(s.time).strftime("%Y-%m-%d %H:%M:%S")
    }


@mcp.tool()
def mt5_rates(symbol: str = "XAUUSDm", timeframe: str = "M5", count: int = 100) -> Dict[str, Any]:
    """
    Fetch historical OHLCV candlestick rates for technical analysis.
    
    Args:
        symbol: Market symbol (e.g. 'XAUUSDm').
        timeframe: Candle timeframe ('M1', 'M5', 'M15', 'M30', 'H1', 'H4', 'D1').
        count: Number of candles to return (1 to 1000).
    """
    if not _ensure_connected():
        return {"error": f"MT5 not connected: {mt5.last_error()}"}
    
    sym_name = _resolve_symbol(symbol)
    tf = _timeframe_to_mt5(timeframe)
    count = min(max(count, 1), 1000)
    
    rates = mt5.copy_rates_from_pos(sym_name, tf, 0, count)
    if rates is None or len(rates) == 0:
        return {"error": f"No rates returned for {sym_name} {timeframe}: {mt5.last_error()}"}
    
    formatted = []
    for r in rates:
        formatted.append({
            "time": datetime.datetime.fromtimestamp(r['time']).strftime("%Y-%m-%d %H:%M:%S"),
            "open": float(r['open']),
            "high": float(r['high']),
            "low": float(r['low']),
            "close": float(r['close']),
            "tick_volume": int(r['tick_volume']),
            "spread": int(r['spread'])
        })
    
    return {
        "symbol": sym_name,
        "timeframe": timeframe.upper(),
        "count": len(formatted),
        "rates": formatted
    }


@mcp.tool()
def mt5_ticks(symbol: str = "XAUUSDm", count: int = 20) -> Dict[str, Any]:
    """
    Fetch the latest raw market ticks for orderflow analysis and real-time spread calculation.
    
    Args:
        symbol: Market symbol (e.g. 'XAUUSDm').
        count: Number of ticks (1 to 200).
    """
    if not _ensure_connected():
        return {"error": f"MT5 not connected: {mt5.last_error()}"}
    
    sym_name = _resolve_symbol(symbol)
    count = min(max(count, 1), 200)
    ticks = mt5.copy_ticks_from(sym_name, datetime.datetime.now(), count, mt5.COPY_TICKS_ALL)
    
    if ticks is None or len(ticks) == 0:
        return {"error": f"No ticks returned for {sym_name}: {mt5.last_error()}"}
    
    formatted = []
    for t in ticks:
        formatted.append({
            "time": datetime.datetime.fromtimestamp(t['time']).strftime("%Y-%m-%d %H:%M:%S") + f".{t['time_msc'] % 1000:03d}",
            "bid": float(t['bid']),
            "ask": float(t['ask']),
            "last": float(t['last']),
            "volume": float(t['volume'])
        })
    
    return {
        "symbol": sym_name,
        "count": len(formatted),
        "ticks": formatted
    }


@mcp.tool()
def mt5_positions(symbol: str = "") -> List[Dict[str, Any]]:
    """
    List all open trading positions or positions for a specific symbol.
    
    Args:
        symbol: Optional filter by symbol (e.g. 'XAUUSDm'). Empty string returns all.
    """
    if not _ensure_connected():
        return [{"error": f"MT5 not connected: {mt5.last_error()}"}]
    
    if symbol:
        sym_name = _resolve_symbol(symbol)
        positions = mt5.positions_get(symbol=sym_name)
    else:
        positions = mt5.positions_get()
    
    if positions is None:
        return []
    
    res = []
    for p in positions:
        res.append({
            "ticket": p.ticket,
            "time": datetime.datetime.fromtimestamp(p.time).strftime("%Y-%m-%d %H:%M:%S"),
            "type": "BUY" if p.type == mt5.ORDER_TYPE_BUY else "SELL",
            "magic": p.magic,
            "symbol": p.symbol,
            "volume": p.volume,
            "price_open": p.price_open,
            "sl": p.sl,
            "tp": p.tp,
            "price_current": p.price_current,
            "swap": p.swap,
            "profit": p.profit,
            "comment": p.comment
        })
    return res


@mcp.tool()
def mt5_orders(symbol: str = "") -> List[Dict[str, Any]]:
    """
    List all active pending orders.
    
    Args:
        symbol: Optional filter by symbol. Empty string returns all.
    """
    if not _ensure_connected():
        return [{"error": f"MT5 not connected: {mt5.last_error()}"}]
    
    if symbol:
        sym_name = _resolve_symbol(symbol)
        orders = mt5.orders_get(symbol=sym_name)
    else:
        orders = mt5.orders_get()
    
    if orders is None:
        return []
    
    type_names = {
        mt5.ORDER_TYPE_BUY_LIMIT: "BUY_LIMIT",
        mt5.ORDER_TYPE_SELL_LIMIT: "SELL_LIMIT",
        mt5.ORDER_TYPE_BUY_STOP: "BUY_STOP",
        mt5.ORDER_TYPE_SELL_STOP: "SELL_STOP",
        mt5.ORDER_TYPE_BUY_STOP_LIMIT: "BUY_STOP_LIMIT",
        mt5.ORDER_TYPE_SELL_STOP_LIMIT: "SELL_STOP_LIMIT",
    }
    
    res = []
    for o in orders:
        res.append({
            "ticket": o.ticket,
            "time_setup": datetime.datetime.fromtimestamp(o.time_setup).strftime("%Y-%m-%d %H:%M:%S"),
            "type": type_names.get(o.type, str(o.type)),
            "magic": o.magic,
            "symbol": o.symbol,
            "volume_initial": o.volume_initial,
            "volume_current": o.volume_current,
            "price_open": o.price_open,
            "sl": o.sl,
            "tp": o.tp,
            "comment": o.comment
        })
    return res


@mcp.tool()
def mt5_history_deals(days: int = 7, symbol: str = "") -> List[Dict[str, Any]]:
    """
    Get closed deal execution history for performance analysis.
    
    Args:
        days: Number of past days to query (default 7).
        symbol: Optional symbol filter.
    """
    if not _ensure_connected():
        return [{"error": f"MT5 not connected: {mt5.last_error()}"}]
    
    from_date = datetime.datetime.now() - datetime.timedelta(days=days)
    to_date = datetime.datetime.now()
    
    if symbol:
        sym_name = _resolve_symbol(symbol)
        deals = mt5.history_deals_get(from_date, to_date, group=sym_name)
    else:
        deals = mt5.history_deals_get(from_date, to_date)
    
    if deals is None:
        return []
    
    res = []
    for d in deals:
        res.append({
            "ticket": d.ticket,
            "order": d.order,
            "time": datetime.datetime.fromtimestamp(d.time).strftime("%Y-%m-%d %H:%M:%S"),
            "type": "BUY" if d.type == mt5.DEAL_TYPE_BUY else ("SELL" if d.type == mt5.DEAL_TYPE_SELL else "OTHER"),
            "entry": "IN" if d.entry == mt5.DEAL_ENTRY_IN else ("OUT" if d.entry == mt5.DEAL_ENTRY_OUT else "INOUT"),
            "symbol": d.symbol,
            "volume": d.volume,
            "price": d.price,
            "profit": d.profit,
            "commission": d.commission,
            "swap": d.swap,
            "magic": d.magic,
            "comment": d.comment
        })
    return res


@mcp.tool()
def mt5_order_send(
    symbol: str,
    action: str,
    volume: float,
    price: float = 0.0,
    sl: float = 0.0,
    tp: float = 0.0,
    deviation: int = 20,
    magic: int = 999001,
    comment: str = "AI_Trade_MCP"
) -> Dict[str, Any]:
    """
    Execute a risk-controlled market or pending order on MT5.
    
    Enforces Hard Safety Controls:
    - Maximum lot size capped at MAX_LOT_SAFETY_CAP (0.5 lot default).
    - Rejects invalid actions.
    
    Args:
        symbol: Trading symbol (e.g. 'XAUUSDm').
        action: 'BUY', 'SELL', 'BUY_LIMIT', 'SELL_LIMIT', 'BUY_STOP', 'SELL_STOP'.
        volume: Lot size (must be <= MAX_LOT_SAFETY_CAP).
        price: Price for pending orders (0.0 for market execution).
        sl: Mandatory Stop Loss price for capital protection.
        tp: Take Profit price.
        deviation: Slippage in points.
        magic: EA magic number.
        comment: Order comment tag.
    """
    if not _ensure_connected():
        return {"success": False, "error": f"MT5 not connected: {mt5.last_error()}"}
    
    sym_name = _resolve_symbol(symbol)
    s_info = mt5.symbol_info(sym_name)
    if not s_info:
        return {"success": False, "error": f"Invalid symbol: {sym_name}"}
    
    # 1. Enforce Hard Lot Safety Cap
    if volume > MAX_LOT_SAFETY_CAP:
        return {
            "success": False,
            "error": f"Volume {volume} exceeds safety lot cap of {MAX_LOT_SAFETY_CAP}. Order rejected."
        }
    if volume < s_info.volume_min:
        return {
            "success": False,
            "error": f"Volume {volume} is below broker minimum {s_info.volume_min}."
        }
    
    action_upper = action.upper()
    order_type_map = {
        "BUY": mt5.ORDER_TYPE_BUY,
        "SELL": mt5.ORDER_TYPE_SELL,
        "BUY_LIMIT": mt5.ORDER_TYPE_BUY_LIMIT,
        "SELL_LIMIT": mt5.ORDER_TYPE_SELL_LIMIT,
        "BUY_STOP": mt5.ORDER_TYPE_BUY_STOP,
        "SELL_STOP": mt5.ORDER_TYPE_SELL_STOP,
    }
    
    if action_upper not in order_type_map:
        return {"success": False, "error": f"Unsupported action: {action}. Must be one of {list(order_type_map.keys())}"}
    
    otype = order_type_map[action_upper]
    is_market = action_upper in ["BUY", "SELL"]
    exec_price = (s_info.ask if action_upper == "BUY" else s_info.bid) if is_market else price

    # Structure Order Request
    request = {
        "action": mt5.TRADE_ACTION_DEAL if is_market else mt5.TRADE_ACTION_PENDING,
        "symbol": sym_name,
        "volume": volume,
        "type": otype,
        "price": exec_price,
        "sl": sl,
        "tp": tp,
        "deviation": deviation,
        "magic": magic,
        "comment": comment,
        "type_time": mt5.ORDER_TIME_GTC,
        "type_filling": mt5.ORDER_FILLING_IOC if is_market else mt5.ORDER_FILLING_RETURN,
    }
    
    # Try filling modes if IOC fails (FOK fallback)
    result = mt5.order_send(request)
    if result.retcode != mt5.TRADE_RETCODE_DONE and is_market:
        request["type_filling"] = mt5.ORDER_FILLING_FOK
        result = mt5.order_send(request)
        if result.retcode != mt5.TRADE_RETCODE_DONE:
            request["type_filling"] = mt5.ORDER_FILLING_RETURN
            result = mt5.order_send(request)

    return {
        "success": result.retcode == mt5.TRADE_RETCODE_DONE,
        "retcode": result.retcode,
        "deal": result.deal,
        "order": result.order,
        "volume": result.volume,
        "price": result.price,
        "comment": result.comment,
        "error_details": mt5.last_error() if result.retcode != mt5.TRADE_RETCODE_DONE else None
    }


@mcp.tool()
def mt5_position_close(ticket: int, deviation: int = 20) -> Dict[str, Any]:
    """
    Close an open trading position by ticket number.
    
    Args:
        ticket: Position ticket to close.
        deviation: Maximum allowed slippage points.
    """
    if not _ensure_connected():
        return {"success": False, "error": f"MT5 not connected: {mt5.last_error()}"}
    
    pos = mt5.positions_get(ticket=ticket)
    if not pos or len(pos) == 0:
        return {"success": False, "error": f"Position ticket #{ticket} not found."}
    
    p = pos[0]
    close_type = mt5.ORDER_TYPE_SELL if p.type == mt5.ORDER_TYPE_BUY else mt5.ORDER_TYPE_BUY
    s_info = mt5.symbol_info(p.symbol)
    price = s_info.bid if p.type == mt5.ORDER_TYPE_BUY else s_info.ask
    
    request = {
        "action": mt5.TRADE_ACTION_DEAL,
        "position": p.ticket,
        "symbol": p.symbol,
        "volume": p.volume,
        "type": close_type,
        "price": price,
        "deviation": deviation,
        "magic": p.magic,
        "comment": f"MCP_Close_#{p.ticket}",
        "type_time": mt5.ORDER_TIME_GTC,
        "type_filling": mt5.ORDER_FILLING_IOC,
    }
    
    result = mt5.order_send(request)
    if result.retcode != mt5.TRADE_RETCODE_DONE:
        request["type_filling"] = mt5.ORDER_FILLING_FOK
        result = mt5.order_send(request)

    return {
        "success": result.retcode == mt5.TRADE_RETCODE_DONE,
        "retcode": result.retcode,
        "deal": result.deal,
        "order": result.order,
        "comment": result.comment
    }


@mcp.tool()
def mt5_position_modify(ticket: int, sl: float, tp: float) -> Dict[str, Any]:
    """
    Modify Stop Loss (SL) and Take Profit (TP) of an open position.
    
    Args:
        ticket: Position ticket.
        sl: New Stop Loss price.
        tp: New Take Profit price.
    """
    if not _ensure_connected():
        return {"success": False, "error": f"MT5 not connected: {mt5.last_error()}"}
    
    pos = mt5.positions_get(ticket=ticket)
    if not pos or len(pos) == 0:
        return {"success": False, "error": f"Position ticket #{ticket} not found."}
    
    p = pos[0]
    request = {
        "action": mt5.TRADE_ACTION_SLTP,
        "position": p.ticket,
        "symbol": p.symbol,
        "sl": sl,
        "tp": tp
    }
    
    result = mt5.order_send(request)
    return {
        "success": result.retcode == mt5.TRADE_RETCODE_DONE,
        "retcode": result.retcode,
        "comment": result.comment
    }


if __name__ == "__main__":
    # Run the MCP server over stdio
    mcp.run()
