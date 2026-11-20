"""
System Watchdog & Heartbeat Monitor for TM-EA AI Trade.
Monitors process health, MT5 terminal connection latency,
and writes health metrics to config/ai/heartbeat.json.
"""
import os
import json
import time
import datetime
import logging
from typing import Dict, Any, Optional

logger = logging.getLogger("ai_trade.watchdog")

HEARTBEAT_FILE = "config/ai/heartbeat.json"


class SystemWatchdog:
    def __init__(self, heartbeat_path: str = HEARTBEAT_FILE):
        self.heartbeat_path = heartbeat_path
        self.start_time = time.time()
        self.last_pulse = 0.0

    def pulse(self,
              status_label: str = "RUNNING",
              extra_meta: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
        """
        Record a heartbeat pulse and write to disk.
        """
        now = time.time()
        self.last_pulse = now
        uptime_sec = round(now - self.start_time, 1)

        payload = {
            "status": status_label,
            "timestamp": datetime.datetime.now(datetime.timezone.utc).isoformat(),
            "uptime_seconds": uptime_sec,
            "pid": os.getpid(),
            "meta": extra_meta or {}
        }

        os.makedirs(os.path.dirname(self.heartbeat_path), exist_ok=True)
        try:
            with open(self.heartbeat_path, "w", encoding="utf-8") as f:
                json.dump(payload, f, indent=2, ensure_ascii=False)
        except Exception as e:
            logger.warning(f"Failed to write heartbeat: {e}")

        return payload

    def check_terminal_health(self) -> Dict[str, Any]:
        """
        Query MT5 terminal connectivity via fast probe.
        """
        try:
            from ..bridge.mt5_mcp_server import mt5_status
            res = mt5_status()
            is_connected = res.get("connected", False)
            return {
                "terminal_connected": is_connected,
                "login": res.get("login"),
                "server": res.get("server"),
                "balance": res.get("balance"),
                "healthy": is_connected
            }
        except Exception as e:
            return {
                "terminal_connected": False,
                "error": str(e),
                "healthy": False
            }
