"""
AI Trade Orchestrator for TM-EA.
Executes the full Multi-Agent Committee Workflow:
Specialists -> Evidence Package -> 2-Round Debate -> Chair Adjudication -> Hard RiskGate -> DB Record.
"""
import time
from typing import Optional, Dict, Any
from ..core.models import (MarketContext, EASignal, EvidencePackage,
                           DebateRound, CommitteeDecision, VerdictEnum)
from ..core.provider_router import ProviderRouter
from ..core.risk_gate import HardRiskGate
from .specialists import TechnicalAnalyst, NewsSentimentAnalyst, VolatilityRiskAnalyst
from .debater import BullAdvocate, BearAdvocate
from .chair import CommitteeChair
from ..storage.db import ResultsDatabase


class AIOrchestrator:
    def __init__(self,
                 providers_path: str = "config/ai/providers.json",
                 agents_path: str = "config/ai/agents.json",
                 db_path: str = "data/results.db"):
        self.router = ProviderRouter(providers_path, agents_path)
        self.risk_gate = HardRiskGate()
        self.db = ResultsDatabase(db_path)

        # Initialize Committee Members
        self.tech_analyst = TechnicalAnalyst(self.router)
        self.news_analyst = NewsSentimentAnalyst(self.router)
        self.risk_analyst = VolatilityRiskAnalyst(self.router)
        self.bull_debater = BullAdvocate(self.router)
        self.bear_debater = BearAdvocate(self.router)
        self.chair = CommitteeChair(self.router)

    def evaluate_signal(self, context: MarketContext, signal: EASignal) -> CommitteeDecision:
        """Run the end-to-end multi-agent evaluation pipeline on an incoming EA signal."""
        t0 = time.time()

        # Step 1: Run 3 Independent Specialists
        tech_report = self.tech_analyst.analyze(context, signal)
        news_report = self.news_analyst.analyze(context, signal)
        risk_report = self.risk_analyst.analyze(context, signal)

        # Step 2: Compile Evidence Package
        evidence = EvidencePackage(
            context=context,
            signal=signal,
            technical=tech_report,
            sentiment=news_report,
            risk=risk_report
        )

        # Step 3: Round 1 Debate (Opening Arguments)
        bull_arg = self.bull_debater.build_argument(evidence)
        bear_arg = self.bear_debater.build_argument(evidence)

        # Step 4: Round 2 Debate (Cross-Rebuttal)
        bull_reb = self.bull_debater.rebuttal(evidence, bear_arg)
        bear_reb = self.bear_debater.rebuttal(evidence, bull_arg)

        debate = DebateRound(
            round_number=2,
            bull_argument=bull_arg,
            bear_argument=bear_arg,
            bull_rebuttal=bull_reb,
            bear_rebuttal=bear_reb
        )

        # Step 5: Chair Adjudication (5-Tier Verdict)
        verdict, confidence, exec_params, chair_reason = self.chair.adjudicate(evidence, debate)

        # Step 6: Hard RiskGate Validation
        validation = self.risk_gate.validate(signal, exec_params, context)

        # If RiskGate rejected, override verdict to HOLD
        if not validation.passed:
            verdict = VerdictEnum.HOLD
            exec_params.suggested_risk_mult = 0.0

        latency_ms = (time.time() - t0) * 1000.0

        committee_summary = {
            "technical": tech_report.model_dump(),
            "sentiment": news_report.model_dump(),
            "risk": risk_report.model_dump(),
            "debate": debate.model_dump()
        }

        decision = CommitteeDecision(
            symbol=context.symbol,
            source_setup=signal.setup_name,
            verdict=verdict,
            confidence=confidence,
            execution_params=exec_params,
            chair_reasoning=chair_reason,
            committee_summary=committee_summary,
            validation=validation,
            model_version="multi-agent-v1.0",
            latency_ms=latency_ms
        )

        # Step 7: Record to SQLite results.db
        decision_id = self.db.record_decision(decision)
        decision.id = decision_id

        return decision
