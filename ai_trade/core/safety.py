"""
Safety & Kill-Switch System for TM-EA AI Trade.
Enables instant physical kill-switch triggering, monitoring,
and emergency trade liquidation.
"""
import os
import logging
from typing import Optional, Dict, Any, List

logger = logging.getLogger("ai_trade.safety")

KILL_SWITCH_PATH = "config/ai/KILL"
LEGACY_KILL_SWITCH_PATH = "config/KILL"


def is_kill_active() -> bool:
    """Return True if any physical KILL file is present."""
    return os.path.exists(KILL_SWITCH_PATH) or os.path.exists(LEGACY_KILL_SWITCH_PATH)


def trigger_kill(reason: str = "Manual emergency halt") -> str:
    """Create the physical KILL file to halt all trading operations."""
    os.makedirs(os.path.dirname(KILL_SWITCH_PATH), exist_ok=True)
    with open(KILL_SWITCH_PATH, "w", encoding="utf-8") as f:
        f.write(f"HALTED: {reason}\n")
    logger.critical(f"KILL-SWITCH ACTIVATED: {reason}")
    return KILL_SWITCH_PATH


def clear_kill() -> bool:
    """Remove KILL files to resume normal operations."""
    cleared = False
    for p in [KILL_SWITCH_PATH, LEGACY_KILL_SWITCH_PATH]:
        if os.path.exists(p):
            try:
                os.remove(p)
                cleared = True
            except OSError as e:
                logger.error(f"Failed to remove {p}: {e}")
    if cleared:
        logger.info("KILL-SWITCH CLEARED: Operations resumed.")
    return cleared


def emergency_halt_and_close() -> Dict[str, Any]:
    """
    Emergency procedure:
    1. Activate physical kill-switch file.
    2. Import mt5 bridge and close all open positions.
    3. Cancel all pending orders.
    """
    trigger_kill("Emergency liquidation requested")
    
    try:
        from ..bridge.mt5_mcp_server import mt5_positions, mt5_orders, mt5_position_close, _ensure_connected
        import MetaTrader5 as mt5
    except ImportError:
        return {"error": "MT5 bridge not available for emergency liquidation"}

    if not _ensure_connected():
        return {"error": "Cannot connect to MT5 for emergency close"}

    closed_positions = []
    positions = mt5_positions()
    for p in positions:
        ticket = p.get("ticket")
        if ticket:
            res = mt5_position_close(ticket=ticket)
            closed_positions.append({"ticket": ticket, "result": res})

    cancelled_orders = []
    orders = mt5_orders()
    for o in orders:
        ticket = o.get("ticket")
        if ticket:
            req = {
                "action": mt5.TRADE_ACTION_REMOVE,
                "order": ticket
            }
            res = mt5.order_send(req)
            cancelled_orders.append({"ticket": ticket, "retcode": res.retcode})

    return {
        "status": "HALTED",
        "closed_positions_count": len(closed_positions),
        "cancelled_orders_count": len(cancelled_orders),
        "closed_positions": closed_positions,
        "cancelled_orders": cancelled_orders
    }
