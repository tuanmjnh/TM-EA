"""
Bull Advocate & Bear Advocate for TM-EA AI Trade Committee.
Executes 2-Round Adversarial Debate based on Evidence Package.
"""
from ..core.models import EvidencePackage, DebateRound
from ..core.provider_router import ProviderRouter


class BullAdvocate:
    def __init__(self, router: ProviderRouter):
        self.router = router

    def build_argument(self, evidence: EvidencePackage) -> str:
        prompt = f"""Bạn là Phe Bò (Bull Advocate). Hãy bảo vệ luận điểm MUA (BUY) hoặc lý do thị trường Vàng sẽ tăng.
Dữ liệu từ Hội đồng Chuyên gia:
- Tín hiệu EA: {evidence.signal.setup_name} | Direction: {evidence.signal.direction} | Entry: {evidence.signal.entry_price}
- Kỹ thuật: {evidence.technical.summary if evidence.technical else 'N/A'}
- Vĩ mô: {evidence.sentiment.summary if evidence.sentiment else 'N/A'}
- Biến động: {evidence.risk.summary if evidence.risk else 'N/A'}

Hãy đưa ra lập luận chặt chẽ nhất (2-3 luận điểm ngắn gọn) ủng hộ phe Mua."""
        system = "Bạn là Bull Advocate chuyên nghiệp. Chỉ tập trung bảo vệ luận điểm Mua một cách khách quan."
        try:
            res, _ = self.router.call_role("bull_advocate", prompt, system)
            return res.strip()
        except Exception as e:
            return f"Bull argument fallback: {e}"

    def rebuttal(self, evidence: EvidencePackage, bear_argument: str) -> str:
        prompt = f"""Phe Gấu (Bear Advocate) vừa đưa ra lập luận sau:
"{bear_argument}"

Hãy phản biện ngắn gọn điểm-đối-điểm để bảo vệ cơ hội MUA cho lệnh Vàng."""
        system = "Bạn là Bull Advocate. Phản biện súc tích, logic."
        try:
            res, _ = self.router.call_role("bull_advocate", prompt, system)
            return res.strip()
        except Exception as e:
            return f"Bull rebuttal fallback: {e}"


class BearAdvocate:
    def __init__(self, router: ProviderRouter):
        self.router = router

    def build_argument(self, evidence: EvidencePackage) -> str:
        prompt = f"""Bạn là Phe Gấu (Bear Advocate). Hãy bảo vệ luận điểm BÁN (SELL) hoặc chỉ ra các rủi ro chết người nếu Mua Vàng lúc này.
Dữ liệu từ Hội đồng Chuyên gia:
- Tín hiệu EA: {evidence.signal.setup_name} | Direction: {evidence.signal.direction} | Entry: {evidence.signal.entry_price}
- Kỹ thuật: {evidence.technical.summary if evidence.technical else 'N/A'}
- Vĩ mô: {evidence.sentiment.summary if evidence.sentiment else 'N/A'}
- Biến động: {evidence.risk.summary if evidence.risk else 'N/A'}

Hãy đưa ra lập luận chặt chẽ nhất (2-3 luận điểm ngắn gọn) ủng hộ phe Bán hoặc cảnh báo bẫy giá."""
        system = "Bạn là Bear Advocate chuyên nghiệp. Chỉ tập trung bảo vệ luận điểm Bán và phòng ngừa rủi ro."
        try:
            res, _ = self.router.call_role("bear_advocate", prompt, system)
            return res.strip()
        except Exception as e:
            return f"Bear argument fallback: {e}"

    def rebuttal(self, evidence: EvidencePackage, bull_argument: str) -> str:
        prompt = f"""Phe Bò (Bull Advocate) vừa đưa ra lập luận sau:
"{bull_argument}"

Hãy phản biện ngắn gọn điểm-đối-điểm để chỉ ra điểm yếu trong luận cứ của Phe Bò."""
        system = "Bạn là Bear Advocate. Phản biện súc tích, sắc sảo."
        try:
            res, _ = self.router.call_role("bear_advocate", prompt, system)
            return res.strip()
        except Exception as e:
            return f"Bear rebuttal fallback: {e}"
