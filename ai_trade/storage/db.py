"""
SQLite Results Database Manager for TM-EA AI Trade Orchestrator.
Records all AI decisions, committee debriefs, and real execution outcomes.
"""
import sqlite3
import json
import os
from typing import Optional, Dict, Any, List
from ..core.models import CommitteeDecision


class ResultsDatabase:
    def __init__(self, db_path: str = "data/results.db"):
        self.db_path = db_path
        os.makedirs(os.path.dirname(os.path.abspath(db_path)), exist_ok=True)
        self.init_schema()

    def get_connection(self) -> sqlite3.Connection:
        conn = sqlite3.connect(self.db_path)
        conn.row_factory = sqlite3.Row
        return conn

    def init_schema(self):
        """Initialize tables as defined in SPEC_AI_TRADE_MODULE.md section 4.2."""
        conn = self.get_connection()
        try:
            with conn:
                cursor = conn.cursor()
                cursor.execute("""
                CREATE TABLE IF NOT EXISTS trade_decisions (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    timestamp TEXT NOT NULL,
                    symbol TEXT NOT NULL,
                    source_setup TEXT NOT NULL,
                    direction INTEGER NOT NULL,
                    entry_price REAL NOT NULL,
                    stop_loss REAL NOT NULL,
                    take_profit REAL NOT NULL,
                    risk_multiplier REAL NOT NULL,
                    verdict TEXT NOT NULL,
                    confidence REAL NOT NULL,
                    validation_passed INTEGER NOT NULL,
                    chair_reasoning TEXT NOT NULL,
                    committee_summary_json TEXT NOT NULL,
                    model_version TEXT NOT NULL,
                    latency_ms REAL NOT NULL
                );
                """)

                cursor.execute("""
                CREATE TABLE IF NOT EXISTS trade_outcomes (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    decision_id INTEGER NOT NULL,
                    ticket INTEGER NOT NULL,
                    close_time TEXT NOT NULL,
                    close_price REAL NOT NULL,
                    pnl_usd REAL NOT NULL,
                    r_multiple REAL NOT NULL,
                    outcome TEXT CHECK(outcome IN ('WIN', 'LOSS', 'BREAKEVEN')),
                    spread_paid REAL NOT NULL,
                    commission_paid REAL NOT NULL,
                    FOREIGN KEY(decision_id) REFERENCES trade_decisions(id)
                );
                """)
                conn.commit()
        finally:
            conn.close()

    def record_decision(self, decision: CommitteeDecision) -> int:
        """Insert a committee decision into SQLite database."""
        conn = self.get_connection()
        try:
            with conn:
                cursor = conn.cursor()
                cursor.execute("""
                INSERT INTO trade_decisions (
                    timestamp, symbol, source_setup, direction,
                    entry_price, stop_loss, take_profit, risk_multiplier,
                    verdict, confidence, validation_passed, chair_reasoning,
                    committee_summary_json, model_version, latency_ms
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """, (
                    decision.timestamp,
                    decision.symbol,
                    decision.source_setup,
                    1 if "BUY" in decision.verdict.value else -1,
                    decision.execution_params.entry_price,
                    decision.execution_params.stop_loss,
                    decision.execution_params.take_profit,
                    decision.execution_params.suggested_risk_mult,
                    decision.verdict.value,
                    decision.confidence,
                    1 if decision.validation.passed else 0,
                    decision.chair_reasoning,
                    json.dumps(decision.committee_summary, ensure_ascii=False),
                    decision.model_version,
                    decision.latency_ms
                ))
                conn.commit()
                return cursor.lastrowid
        finally:
            conn.close()

    def record_outcome(self, decision_id: int, ticket: int, close_time: str,
                       close_price: float, pnl_usd: float, r_multiple: float,
                       outcome: str, spread_paid: float = 0.0, commission_paid: float = 0.0):
        """Record real-world outcome of an executed decision."""
        conn = self.get_connection()
        try:
            with conn:
                cursor = conn.cursor()
                cursor.execute("""
                INSERT INTO trade_outcomes (
                    decision_id, ticket, close_time, close_price,
                    pnl_usd, r_multiple, outcome, spread_paid, commission_paid
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                """, (
                    decision_id, ticket, close_time, close_price,
                    pnl_usd, r_multiple, outcome, spread_paid, commission_paid
                ))
                conn.commit()
        finally:
            conn.close()

    def get_recent_decisions(self, limit: int = 20) -> List[Dict[str, Any]]:
        """Retrieve recent decisions for audit and lineage tracking."""
        conn = self.get_connection()
        try:
            cursor = conn.cursor()
            cursor.execute("""
            SELECT * FROM trade_decisions ORDER BY id DESC LIMIT ?
            """, (limit,))
            rows = cursor.fetchall()
            return [dict(row) for row in rows]
        finally:
            conn.close()
