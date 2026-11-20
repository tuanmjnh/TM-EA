"""
Specialist Agents for TM-EA AI Trade Committee.
Independent, non-interacting agents evaluating distinct market aspects.
"""
import json
from typing import Dict, Any
from ..core.models import MarketContext, EASignal, SpecialistReport, StanceEnum
from ..core.provider_router import ProviderRouter


class TechnicalAnalyst:
    def __init__(self, router: ProviderRouter):
        self.router = router

    def analyze(self, context: MarketContext, signal: EASignal) -> SpecialistReport:
        prompt = f"""Bạn là Chuyên gia Phân tích Kỹ thuật (Technical Analyst) cao cấp cho thị trường Vàng (XAUUSD).
Hãy đánh giá tín hiệu sau đây:
- Setup: {signal.setup_name} ({signal.source_ea})
- Chiều: {"MUA (BUY)" if signal.direction > 0 else "BÁN (SELL)"}
- Giá vào: {signal.entry_price} | SL: {signal.stop_loss} | TP: {signal.take_profit}
- Bối cảnh: Regime={context.regime}, ATR(M5)={context.atr}, ADX(H1)={context.adx_h1}
- Thanh khoản: Asia High={context.asian_high}, Asia Low={context.asian_low}, PDH={context.pdh}, PDL={context.pdl}
- Lý do kích hoạt: {signal.reason}

Yêu cầu trả về định dạng JSON thuần túy (không markdown) với cấu trúc:
{{
  "stance": "BULLISH" | "BEARISH" | "NEUTRAL",
  "confidence": 0.0 - 1.0,
  "summary": "1-2 câu tóm lược nhận định kỹ thuật",
  "key_factors": ["luận điểm 1", "luận điểm 2"],
  "risk_warnings": ["cảnh báo rủi ro kỹ thuật nếu có"]
}}"""
        system = "Bạn là Technical Analyst độc lập. Chỉ trả lời định dạng JSON hợp lệ theo yêu cầu."
        
        try:
            raw_text, _ = self.router.call_role("technical_specialist", prompt, system)
            clean_text = raw_text.strip().replace("```json", "").replace("```", "").strip()
            data = json.loads(clean_text)
            return SpecialistReport(
                specialist_name="TechnicalAnalyst",
                stance=StanceEnum(data.get("stance", "NEUTRAL")),
                confidence=float(data.get("confidence", 0.5)),
                summary=data.get("summary", ""),
                key_factors=data.get("key_factors", []),
                risk_warnings=data.get("risk_warnings", [])
            )
        except Exception as e:
            return SpecialistReport(
                specialist_name="TechnicalAnalyst",
                stance=StanceEnum.NEUTRAL,
                confidence=0.5,
                summary=f"Technical analysis fallback: {e}",
                key_factors=["Fallback triggered due to parse/call error"],
                risk_warnings=[str(e)]
            )


class NewsSentimentAnalyst:
    def __init__(self, router: ProviderRouter):
        self.router = router

    def analyze(self, context: MarketContext, signal: EASignal) -> SpecialistReport:
        prompt = f"""Bạn là Chuyên gia Kinh tế Vĩ mô & Tin tức (News & Macro Sentiment Analyst) cho Vàng (XAUUSD).
Hãy đánh giá bối cảnh phiên giao dịch hiện tại:
- Kill-Zone: {context.kill_zone} (GMT time: {context.gmt_time})
- Hướng tín hiệu: {"BUY" if signal.direction > 0 else "SELL"}
- Bối cảnh: Phiên London (07:00-10:00 GMT) hoặc NY (12:30-15:00 GMT).

Yêu cầu trả về định dạng JSON thuần túy (không markdown) với cấu trúc:
{{
  "stance": "BULLISH" | "BEARISH" | "NEUTRAL",
  "confidence": 0.0 - 1.0,
  "summary": "Tóm tắt bối cảnh vĩ mô và dòng tiền phiên",
  "key_factors": ["yếu tố vĩ mô 1", "yếu tố vĩ mô 2"],
  "risk_warnings": ["rủi ro tin tức kinh tế / sự kiện vĩ mô"]
}}"""
        system = "Bạn là Macro Sentiment Analyst. Chỉ trả lời JSON hợp lệ theo yêu cầu."

        try:
            raw_text, _ = self.router.call_role("news_sentiment_specialist", prompt, system)
            clean_text = raw_text.strip().replace("```json", "").replace("```", "").strip()
            data = json.loads(clean_text)
            return SpecialistReport(
                specialist_name="NewsSentimentAnalyst",
                stance=StanceEnum(data.get("stance", "NEUTRAL")),
                confidence=float(data.get("confidence", 0.5)),
                summary=data.get("summary", ""),
                key_factors=data.get("key_factors", []),
                risk_warnings=data.get("risk_warnings", [])
            )
        except Exception as e:
            return SpecialistReport(
                specialist_name="NewsSentimentAnalyst",
                stance=StanceEnum.NEUTRAL,
                confidence=0.5,
                summary=f"Sentiment analysis fallback: {e}",
                key_factors=["Fallback triggered due to parse/call error"],
                risk_warnings=[str(e)]
            )


class VolatilityRiskAnalyst:
    def __init__(self, router: ProviderRouter):
        self.router = router

    def analyze(self, context: MarketContext, signal: EASignal) -> SpecialistReport:
        sl_pips = abs(signal.entry_price - signal.stop_loss) * 10.0
        tp_pips = abs(signal.entry_price - signal.take_profit) * 10.0
        rr_ratio = tp_pips / sl_pips if sl_pips > 0 else 0.0

        prompt = f"""Bạn là Chuyên gia Quản trị Biến động & Rủi ro (Volatility & Risk Specialist) cho Vàng (XAUUSD).
Hãy đánh giá tính an toàn của thông số vào lệnh:
- Spread: {context.spread_points} points (Max cho phép: 350 points)
- ATR M5: {context.atr:.2f}
- Khoảng cách SL: {sl_pips:.1f} pips | Khoảng cách TP: {tp_pips:.1f} pips | Tỷ lệ R:R: {rr_ratio:.2f}
- Kill-zone: {context.kill_zone}

Yêu cầu trả về định dạng JSON thuần túy (không markdown) với cấu trúc:
{{
  "stance": "BULLISH" | "BEARISH" | "NEUTRAL",
  "confidence": 0.0 - 1.0,
  "summary": "Nhận định về ma sát spread, khoảng thở SL và tỷ lệ R:R",
  "key_factors": ["yếu tố rủi ro 1", "yếu tố rủi ro 2"],
  "risk_warnings": ["cảnh báo ma sát / độ biến động"]
}}"""
        system = "Bạn là Volatility Risk Analyst. Chỉ trả lời JSON hợp lệ theo yêu cầu."

        try:
            raw_text, _ = self.router.call_role("risk_volatility_specialist", prompt, system)
            clean_text = raw_text.strip().replace("```json", "").replace("```", "").strip()
            data = json.loads(clean_text)
            return SpecialistReport(
                specialist_name="VolatilityRiskAnalyst",
                stance=StanceEnum(data.get("stance", "NEUTRAL")),
                confidence=float(data.get("confidence", 0.5)),
                summary=data.get("summary", ""),
                key_factors=data.get("key_factors", []),
                risk_warnings=data.get("risk_warnings", [])
            )
        except Exception as e:
            return SpecialistReport(
                specialist_name="VolatilityRiskAnalyst",
                stance=StanceEnum.NEUTRAL,
                confidence=0.5,
                summary=f"Risk analysis fallback: {e}",
                key_factors=["Fallback triggered due to parse/call error"],
                risk_warnings=[str(e)]
            )
