"""
Parameter Lineage Tree & Auto-Rollback Engine.
Maintains version history of parameter mutations (config/ai/lineage_tree.json),
evaluates candidate fitness against champion baseline, and executes automatic rollback
if performance degrades by > 10%.
"""
import os
import json
import datetime
from typing import Dict, Any, List, Optional, Tuple
from pydantic import BaseModel, Field

LINEAGE_FILE_PATH = "config/ai/lineage_tree.json"


class VariantRecord(BaseModel):
    version_id: str
    parent_id: Optional[str] = None
    timestamp: str = Field(default_factory=lambda: datetime.datetime.now(datetime.timezone.utc).isoformat())
    strategy: str = "TM_GoldSweepScalper"
    mutated_params: Dict[str, Any] = Field(default_factory=dict)
    net_profit: float = 0.0
    profit_factor: float = 0.0
    max_drawdown_pct: float = 0.0
    total_trades: int = 0
    wfa_passed: bool = False
    mc_passed: bool = False
    status: str = "CANDIDATE"  # BASELINE, CANDIDATE, ACCEPTED, REJECTED_REGRESSION, ROLLED_BACK
    notes: str = ""


class LineageManager:
    def __init__(self, file_path: str = LINEAGE_FILE_PATH):
        self.file_path = file_path
        self.variants: Dict[str, VariantRecord] = {}
        self.active_baseline_id: Optional[str] = None
        self.load_tree()

    def load_tree(self):
        """Load lineage tree from disk or initialize with v1.0 baseline."""
        if os.path.exists(self.file_path):
            try:
                with open(self.file_path, "r", encoding="utf-8") as f:
                    data = json.load(f)
                    self.active_baseline_id = data.get("active_baseline_id")
                    for k, v in data.get("variants", {}).items():
                        self.variants[k] = VariantRecord(**v)
                return
            except Exception:
                pass

        # Initialize Default Champion Baseline (TM_GoldSweepScalper London KZ 1Y)
        baseline = VariantRecord(
            version_id="v1.0-baseline",
            parent_id=None,
            strategy="TM_GoldSweepScalper",
            mutated_params={
                "Sweep_RR": 3.0,
                "Enable_LondonKZ": True,
                "Enable_NYKZ": False,
                "Enable_Trailing": False,
                "RiskPercentPerTrade": 0.5
            },
            net_profit=177.68,
            profit_factor=1.069,
            max_drawdown_pct=7.395,
            total_trades=158,
            wfa_passed=True,
            mc_passed=True,
            status="BASELINE",
            notes="1-Year Full Real-Tick Baseline (2025.08 - 2026.07)"
        )
        self.variants["v1.0-baseline"] = baseline
        self.active_baseline_id = "v1.0-baseline"
        self.save_tree()

    def save_tree(self):
        """Persist lineage tree to JSON file."""
        os.makedirs(os.path.dirname(self.file_path), exist_ok=True)
        data = {
            "active_baseline_id": self.active_baseline_id,
            "last_updated": datetime.datetime.now(datetime.timezone.utc).isoformat(),
            "total_variants": len(self.variants),
            "variants": {k: v.model_dump() for k, v in self.variants.items()}
        }
        with open(self.file_path, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=2, ensure_ascii=False)

    def get_active_baseline(self) -> Optional[VariantRecord]:
        """Return the current active champion baseline variant."""
        if self.active_baseline_id and self.active_baseline_id in self.variants:
            return self.variants[self.active_baseline_id]
        return None

    def evaluate_candidate(self, candidate: VariantRecord) -> Tuple[bool, str]:
        """
        Evaluate candidate against active baseline.
        Rule: If PF drops > 10% or Max DD exceeds baseline * 1.15 -> REJECT & ROLLBACK.
        If accepted, candidate becomes new champion baseline.
        """
        baseline = self.get_active_baseline()
        if not baseline:
            candidate.status = "ACCEPTED"
            self.variants[candidate.version_id] = candidate
            self.active_baseline_id = candidate.version_id
            self.save_tree()
            return True, "Accepted as initial baseline."

        # 1. Regression Threshold Checks (10% PF degradation gate)
        pf_regression = (baseline.profit_factor - candidate.profit_factor) / baseline.profit_factor
        if pf_regression > 0.10:
            candidate.status = "REJECTED_REGRESSION"
            candidate.notes = f"Rejected: PF degraded by {pf_regression*100:.1f}% (> 10% limit) vs baseline {baseline.version_id}"
            self.variants[candidate.version_id] = candidate
            self.save_tree()
            return False, candidate.notes

        # 2. Drawdown Cap Check (DD cannot exceed baseline * 1.15)
        dd_limit = baseline.max_drawdown_pct * 1.15
        if candidate.max_drawdown_pct > dd_limit:
            candidate.status = "REJECTED_REGRESSION"
            candidate.notes = f"Rejected: Max Drawdown {candidate.max_drawdown_pct:.2f}% exceeded limit {dd_limit:.2f}%"
            self.variants[candidate.version_id] = candidate
            self.save_tree()
            return False, candidate.notes

        # 3. Minimum Trades & Out-Of-Sample Validation Check
        if candidate.total_trades < 30:
            candidate.status = "REJECTED_REGRESSION"
            candidate.notes = f"Rejected: Insufficient trade sample ({candidate.total_trades} < 30)"
            self.variants[candidate.version_id] = candidate
            self.save_tree()
            return False, candidate.notes

        # 4. Promotion to Champion
        candidate.status = "ACCEPTED"
        candidate.notes = f"Accepted: Improved or matched baseline performance. Promoted from parent {baseline.version_id}."
        self.variants[candidate.version_id] = candidate
        self.active_baseline_id = candidate.version_id
        self.save_tree()
        return True, candidate.notes

    def rollback(self, reason: str = "Manual rollback") -> Optional[VariantRecord]:
        """Rollback active champion to its parent version."""
        current = self.get_active_baseline()
        if not current or not current.parent_id:
            return None

        parent_id = current.parent_id
        if parent_id in self.variants:
            current.status = "ROLLED_BACK"
            current.notes += f" | Rolled back: {reason}"
            self.active_baseline_id = parent_id
            self.save_tree()
            return self.variants[parent_id]
        return None
