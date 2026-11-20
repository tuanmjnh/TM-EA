"""
Committee Chair & Portfolio Manager (Arbitrator) for TM-EA AI Trade Committee.
Synthesizes specialist evidence and debate rounds to issue 5-Tier Verdict.
"""
import json
from typing import Dict, Any, Tuple
from ..core.models import EvidencePackage, DebateRound, VerdictEnum, ExecutionParams
from ..core.provider_router import ProviderRouter


class CommitteeChair:
    def __init__(self, router: ProviderRouter):
        self.router = router

    def adjudicate(self,
                   evidence: EvidencePackage,
                   debate: DebateRound) -> Tuple[VerdictEnum, float, ExecutionParams, str]:
        prompt = f"""Bạn là Chủ tịch Hội đồng Giao dịch (Committee Chair / Lead Portfolio Manager).
Nhiệm vụ: Phân xử cuộc tranh luận và ra QUYẾT ĐỊNH CUỐI CÙNG cho tín hiệu Vàng (XAUUSD).

=== THÔNG TIN TÍN HIỆU TỪ ROBOT MQL5 ===
- Tín hiệu gốc: {evidence.signal.setup_name} ({evidence.signal.source_ea})
- Đề xuất: {"BUY" if evidence.signal.direction > 0 else "SELL"}
- Giá vào đề xuất: {evidence.signal.entry_price}
- Stop Loss đề xuất: {evidence.signal.stop_loss}
- Take Profit đề xuất: {evidence.signal.take_profit}

=== Ý KIẾN CHUYÊN GIA ===
1. Kỹ thuật: {evidence.technical.summary if evidence.technical else 'N/A'}
2. Vĩ mô & Tin: {evidence.sentiment.summary if evidence.sentiment else 'N/A'}
3. Biến động & Phí: {evidence.risk.summary if evidence.risk else 'N/A'}

=== TRANH LUẬN 2 VÒNG ===
- Luận điểm Phe Bò: {debate.bull_argument}
- Phản biện của Bò: {debate.bull_rebuttal}
- Luận điểm Phe Gấu: {debate.bear_argument}
- Phản biện của Gấu: {debate.bear_rebuttal}

=== YÊU CẦU PHÂN XỬ ===
Chọn 1 trong các bậc quyết định sau:
- STRONG_BUY / BUY: Tín hiệu đồng thuận cao, tỷ lệ thắng tốt -> vào 100% volume.
- OVERWEIGHT: Tín hiệu thuận nhưng có rủi ro nhỏ -> vào 50% - 70% volume.
- HOLD: Tranh luận cân bằng, rủi ro cao hoặc mâu thuẫn lớn -> HỦY LỆNH, KHÔNG VÀO.
- UNDERWEIGHT: Tín hiệu bán yếu -> giảm volume hoặc hủy.
- STRONG_SELL / SELL: Tín hiệu bán đồng thuận cao -> vào 100% Sell volume.

Định dạng trả về JSON THUẦN TÚY (không markdown):
{{
  "verdict": "STRONG_BUY" | "BUY" | "OVERWEIGHT" | "HOLD" | "UNDERWEIGHT" | "SELL" | "STRONG_SELL",
  "confidence": 0.0 - 1.0,
  "suggested_risk_mult": 0.0 - 1.0,
  "adjusted_stop_loss": {evidence.signal.stop_loss},
  "adjusted_take_profit": {evidence.signal.take_profit},
  "chair_reasoning": "2-3 câu giải thích rõ lý do phân xử, tại sao chấp thuận hoặc từ chối"
}}"""
        system = "Bạn là Chair / Portfolio Manager tối cao. Ra quyết định thận trọng, bảo vệ vốn. Chỉ trả lời JSON hợp lệ."

        try:
            raw_text, _ = self.router.call_role("committee_chair", prompt, system)
            clean_text = raw_text.strip().replace("```json", "").replace("```", "").strip()
            data = json.loads(clean_text)

            verdict_str = data.get("verdict", "HOLD")
            verdict = VerdictEnum(verdict_str)
            confidence = float(data.get("confidence", 0.5))
            risk_mult = float(data.get("suggested_risk_mult", 1.0))
            sl = float(data.get("adjusted_stop_loss", evidence.signal.stop_loss))
            tp = float(data.get("adjusted_take_profit", evidence.signal.take_profit))
            reasoning = data.get("chair_reasoning", "Consensus reached")

            params = ExecutionParams(
                entry_price=evidence.signal.entry_price,
                stop_loss=sl,
                take_profit=tp,
                suggested_risk_mult=risk_mult,
                adjusted=(sl != evidence.signal.stop_loss or tp != evidence.signal.take_profit or risk_mult != 1.0),
                adjustment_reason=reasoning if risk_mult != 1.0 else ""
            )

            return verdict, confidence, params, reasoning

        except Exception as e:
            # Safe Fallback to HOLD if Chair encounters error
            params = ExecutionParams(
                entry_price=evidence.signal.entry_price,
                stop_loss=evidence.signal.stop_loss,
                take_profit=evidence.signal.take_profit,
                suggested_risk_mult=0.0,
                adjusted=True,
                adjustment_reason=f"Chair error fallback: {e}"
            )
            return VerdictEnum.HOLD, 0.0, params, f"Chair adjudication error fallback to HOLD: {e}"
