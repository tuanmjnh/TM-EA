# TM-EA — Tài Liệu & Cẩm Nang Vận Hành Dự Án

Thư mục `docs/` chứa toàn bộ tài liệu đặc tả, kiến trúc, kiểm định, kế hoạch hành động và cẩm nang vận hành của dự án TM-EA.

---

## 1. TÀI LIỆU VẬN HÀNH TRUNG TÂM (CORE DOCS)

Các tài liệu điều phối trung tâm được đặt trực tiếp tại thư mục gốc `docs/`:

| Tài liệu | Phiên bản | Mục đích & Phạm vi sử dụng |
|---|:---:|---|
| [MASTER.md](file:///d:/Applications/TM-EA/docs/MASTER.md) | **v5.0 (P0)** | **Tài liệu điều hành tối cao** và cẩm nang vận hành AI. Quy định quy chuẩn coding, invariants rủi ro, thông số canonical và trạng thái các EA. |
| [CHANGELOG.md](file:///d:/Applications/TM-EA/docs/CHANGELOG.md) | **v5.0** | Toàn bộ nhật ký cập nhật, mã lỗi, quyết định kiến trúc và kết quả kiểm định theo dòng thời gian. |
| [ARCHITECTURE.md](file:///d:/Applications/TM-EA/docs/ARCHITECTURE.md) | **v4.3** | Kiến trúc kỹ thuật của hệ thống EA, quy chuẩn module MQL5 và các rào chắn bảo vệ vốn (`CGuards`, `CRiskManager`). |
| [USER_GUIDE.md](file:///d:/Applications/TM-EA/docs/USER_GUIDE.md) | **v5.0** | Cẩm nang hướng dẫn sử dụng toàn diện từ A-Z: Backtest MT5, FastMCP Server, AI Trade Orchestrator, Kill-Switch và kết nối Exness. |

---

## 2. PHÂN LOẠI THƯ MỤC TÀI LIỆU CHUYÊN SÂU

```
docs/
├── specs/       # Các bản đặc tả kỹ thuật và yêu cầu chiến lược (Specifications)
├── plans/       # Kế hoạch hành động, lộ trình triển khai & forward demo (Action Plans)
├── audits/      # Báo cáo kiểm định kỹ thuật, đối chiếu dữ liệu & fix lỗi (Audits & Analysis)
├── research/    # Nghiên cứu chuyên sâu các thuật toán & EA thử nghiệm (Research)
└── archive/     # Kho lưu trữ các phiên bản cũ đã ngừng phát triển (Read-only)
```

### 2.1 Đặc tả Kỹ thuật & Chiến lược (`docs/specs/`)
* [SPEC_GOLD_SCALPER.md](file:///d:/Applications/TM-EA/docs/specs/SPEC_GOLD_SCALPER.md): Đặc tả kiến trúc 9 module của `TM_GoldSweepScalper` (Rare-Fire Scalper, M5 London Kill-Zone Judas Sweep).
* [SPEC_AI_TRADE_MODULE.md](file:///d:/Applications/TM-EA/docs/specs/SPEC_AI_TRADE_MODULE.md): Đặc tả kiến trúc 5 tầng của AI Trade Orchestrator (Multi-AI Committee, Hard RiskGate, Vòng lặp tự tiến hóa).
* [SOURCE_SPEC_V1.md](file:///d:/Applications/TM-EA/docs/specs/SOURCE_SPEC_V1.md): Bản đặc tả yêu cầu nghiệp vụ ban đầu (Single source of truth cho các quy tắc toán học).

### 2.2 Kế hoạch Hành động & Lộ trình (`docs/plans/`)
* [ACTION_PLAN_2026_11_19.md](file:///d:/Applications/TM-EA/docs/plans/ACTION_PLAN_2026_11_19.md): Kế hoạch hành động 4 giai đoạn sửa lỗi P0 cứu `TM_SessionBreakout` và tối ưu `TM_GoldSweepScalper`.
* [ACTION_PLAN_AI_TRADE.md](file:///d:/Applications/TM-EA/docs/plans/ACTION_PLAN_AI_TRADE.md): Lộ trình 4 giai đoạn xây dựng AI Trade Orchestrator (Paper Mode -> Demo Cent -> Self-Evolution -> Live).
* [FORWARD_DEMO_PLAN.md](file:///d:/Applications/TM-EA/docs/plans/FORWARD_DEMO_PLAN.md): Quy trình và Checklist 5 bước vận hành Forward Test trên tài khoản Demo Exness.

### 2.3 Kiểm định & Báo cáo Phân tích (`docs/audits/`)
* [OPT_TM_EA_FIX.md](file:///d:/Applications/TM-EA/docs/audits/OPT_TM_EA_FIX.md): Báo cáo phân tích gốc giải thích nguyên nhân thất bại của TFS v2.0 và cơ sở dữ liệu để cứu `TM_SessionBreakout`.
* [TECHNICAL_AUDIT.md](file:///d:/Applications/TM-EA/docs/audits/TECHNICAL_AUDIT.md): Báo cáo kiểm toán kỹ thuật toàn diện (P1 audit: shift, news, filling mode, warmup).
* [SOURCE_REPORT_CONSISTENCY.md](file:///d:/Applications/TM-EA/docs/audits/SOURCE_REPORT_CONSISTENCY.md): Báo cáo đối chiếu tính nhất quán số liệu giữa MASTER, mã nguồn và kết quả backtest (P0 audit).

### 2.4 Nghiên cứu & EA Thử nghiệm (`docs/research/`)
* [EA_BUILD_PLAN.md](file:///d:/Applications/TM-EA/docs/research/EA_BUILD_PLAN.md): Kế hoạch nghiên cứu và ma trận so sánh các dòng bot thử nghiệm.
* [EA-KIM-LA.md](file:///d:/Applications/TM-EA/docs/research/EA-KIM-LA.md): Phân tích chiến lược Kim La (Breakout & Reversal).
* [Scope Trendline Bollinger.md](file:///d:/Applications/TM-EA/docs/research/Scope%20Trendline%20Bollinger.md): Phân tích chiến lược Trendline kết hợp Bollinger Bands.
* [TM INDICATOR 2.md](file:///d:/Applications/TM-EA/docs/research/TM%20INDICATOR%202.md): Tài liệu đặc tả các chỉ báo kỹ thuật custom.
* [Wonderwhales MT5 EA.md](file:///d:/Applications/TM-EA/docs/research/Wonderwhales%20MT5%20EA.md): Phân tích thuật toán Wonderwhales 2-Mode (Scalp / Swing).

### 2.5 Kho Lưu trữ Lịch sử (`docs/archive/`)
* `archive/v1/`: Chứa mã nguồn và tài liệu của thế hệ EA v1.0 đầu tiên (Read-only).

---

## 3. NGUYÊN TẮC QUẢN TRỊ TÀI LIỆU (DOCUMENTATION GOVERNANCE)

1. **Thứ tự ưu tiên khi có xung đột:**
   `MASTER.md` (Mục 2 Safety Rules & Invariants) > `SPEC_*.md` > `ARCHITECTURE.md` > `audits/` > `archive/`.
2. **Quy tắc cập nhật:**
   - Khi có thay đổi về tham số hoặc trạng thái chiến lược, bắt buộc phải cập nhật đồng thời vào:
     1. `docs/MASTER.md`
     2. `docs/CHANGELOG.md`
     3. Báo cáo manifest tương ứng trong `reports/backtests/`.
3. **Mọi đường dẫn file phải dùng chuẩn Markdown có tiền tố `file:///`** và sử dụng dấu gạch chéo xuôi (`/`).
