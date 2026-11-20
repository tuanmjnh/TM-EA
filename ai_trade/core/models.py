"""
Data contracts and Pydantic models for TM-EA AI Trade Orchestrator.
"""
from enum import Enum
from typing import List, Optional, Dict, Any
from pydantic import BaseModel, Field
from datetime import datetime, timezone


class StanceEnum(str, Enum):
    BULLISH = "BULLISH"
    BEARISH = "BEARISH"
    NEUTRAL = "NEUTRAL"


class VerdictEnum(str, Enum):
    STRONG_BUY = "STRONG_BUY"
    BUY = "BUY"
    OVERWEIGHT = "OVERWEIGHT"
    HOLD = "HOLD"
    UNDERWEIGHT = "UNDERWEIGHT"
    SELL = "SELL"
    STRONG_SELL = "STRONG_SELL"


class MarketContext(BaseModel):
    model_config = {"extra": "allow"}

    symbol: str = "XAUUSDm"
    timeframe: str = "M5"
    session: str = "London Kill-Zone"
    kill_zone: str = "London KZ"
    timestamp: str = ""
    bid: float = 0.0
    ask: float = 0.0
    spread_points: float = 0.0
    atr: float = 0.0
    adx: float = 25.0
    adx_h1: float = 25.0
    regime: str = "RANGE"
    news_risk_level: str = "LOW"
    server_time: str = ""
    gmt_time: str = ""
    asian_high: Optional[float] = None
    asian_low: Optional[float] = None
    pdh: Optional[float] = None
    pdl: Optional[float] = None


class EASignal(BaseModel):
    source_ea: str = "TM_GoldSweepScalper"
    setup_name: str = "SweepReversal"
    direction: int = Field(..., description="+1 for BUY, -1 for SELL")
    entry_price: float
    stop_loss: float
    take_profit: float
    proposed_volume: float = 0.01
    reason: str = ""


class SpecialistReport(BaseModel):
    specialist_name: str
    stance: StanceEnum
    confidence: float = Field(..., ge=0.0, le=1.0)
    summary: str
    key_factors: List[str] = Field(default_factory=list)
    risk_warnings: List[str] = Field(default_factory=list)


class EvidencePackage(BaseModel):
    timestamp: str = Field(default_factory=lambda: datetime.now(timezone.utc).isoformat())
    context: MarketContext
    signal: EASignal
    technical: Optional[SpecialistReport] = None
    sentiment: Optional[SpecialistReport] = None
    risk: Optional[SpecialistReport] = None


class DebateRound(BaseModel):
    round_number: int = 1
    bull_argument: str = ""
    bear_argument: str = ""
    bull_rebuttal: Optional[str] = None
    bear_rebuttal: Optional[str] = None


class ExecutionParams(BaseModel):
    entry_price: float
    stop_loss: float
    take_profit: float
    suggested_risk_mult: float = 1.0  # Multiplier on top of canonical risk (0.0 to 1.0)
    adjusted: bool = False
    adjustment_reason: str = ""


class ValidationResult(BaseModel):
    passed: bool
    violations: List[str] = Field(default_factory=list)
    reason: str = ""


class CommitteeDecision(BaseModel):
    id: Optional[int] = None
    timestamp: str = Field(default_factory=lambda: datetime.now(timezone.utc).isoformat())
    symbol: str
    source_setup: str
    verdict: VerdictEnum
    confidence: float = Field(..., ge=0.0, le=1.0)
    execution_params: ExecutionParams
    chair_reasoning: str
    committee_summary: Dict[str, Any] = Field(default_factory=dict)
    validation: ValidationResult
    model_version: str = "orchestrator-v1.0"
    latency_ms: float = 0.0
    cost_usd: float = 0.0
