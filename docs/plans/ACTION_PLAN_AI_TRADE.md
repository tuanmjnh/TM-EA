# Kế hoạch Nâng cấp AI Trade Orchestrator cho TM-EA
**Mã tài liệu:** `ACTION_PLAN_AI_TRADE`  
**Dựa trên tài liệu đặc tả:** [SPEC_AI_TRADE_MODULE.md](file:///d:/Applications/TM-EA/docs/specs/SPEC_AI_TRADE_MODULE.md)  
**Phiên bản:** 1.0 | **Ngày lập:** 2026-11-19  
**Mục tiêu cốt lõi:** Nâng cấp hệ thống TM-EA từ Expert Advisor thuần kỹ thuật sang hệ thống giao dịch tự động thông minh được điều phối bởi hội đồng AI đa tác tử (Multi-Agent Committee), có cơ chế tự tiến hóa và bảo vệ vốn tuyệt đối.

---

## 1. TỔNG QUAN & TRIẾT LÝ NÂNG CẤP

1. **AI không thay thế kỷ luật — AI nâng tầm kỷ luật:**
   - AI không tự ý đặt lệnh ngẫu hứng. AI hoạt động như một **Hội đồng Thẩm định (Adjudicator)**: Khi EA kỹ thuật (`TM_GoldSweepScalper` hoặc `TM_SessionBreakout`) phát hiện tín hiệu, AI sẽ phân tích đa chiều (Tin tức vĩ mô, Lịch kinh tế, Bối cảnh thị trường) để quyết định **chấp thuận, điều chỉnh khối lượng hay hủy bỏ tín hiệu**.
2. **Nguyên tắc "Tường lửa" An toàn (Hard RiskGate):**
   - Dù AI có tự tin đến 99%, mọi lệnh đều phải đi qua chốt chặn an toàn cứng: Bắt buộc có Stop Loss, rủi ro không vượt quá 1% vốn, không giao dịch khi spread cao và tuân thủ chặt chẽ cơ chế Circuit Breaker.
3. **Lộ trình 4 giai đoạn thận trọng:**
   - **Giai đoạn 1:** Paper Trading (Chỉ ghi log phân tích, không vào lệnh).
   - **Giai đoạn 2:** Forward Demo Cent (Thực thi tài khoản nhỏ $50 = 5,000 USC).
   - **Giai đoạn 3:** Self-Evolution Loop (Tự tối ưu tham số và Walk-Forward).
   - **Giai đoạn 4:** Đánh giá lên vốn thật (Scale-up có kiểm soát).

---

## 2. LỘ TRÌNH 4 GIAI ĐOẠN CHI TIẾT

```
  [Giai đoạn 1: Nền tảng AI Orchestrator & Paper Mode] (Tuần 1 - 2)
    ├── Khởi tạo thư mục mã nguồn Python ai_trade/
    ├── Cấu hình Multi-Provider (Gemini, DeepSeek, OpenAI, Ollama)
    ├── Xây dựng Hội đồng 5 tác tử (Technical, News, Risk, Bull/Bear, Chair)
    ├── Tạo cơ sở dữ liệu SQLite data/results.db
    └── Chạy kiểm nghiệm Paper Mode trên 100 tín hiệu (So sánh AI vs EA thuần)
                       │
                       ▼
  [Giai đoạn 2: Tích hợp MT5 Bridge & Forward Demo Cent] (Tuần 3 - 4)
    ├── Kết nối MT5 MCP Server (Boschi404 / MT5 Native MCP)
    ├── Đóng gói chốt chặn an toàn Hard RiskGate
    ├── Kích hoạt thực thi lệnh thật trên Exness Demo Cent (5,000 USC)
    └── Bật cơ chế Kill-Switch vật lý (config/KILL)
                       │
                       ▼
  [Giai đoạn 3: Vòng lặp Tự tiến hóa & Kiểm định OOS] (Tuần 5 - 8)
    ├── Thiết lập "AI Mutation Zone" trong source code MQL5
    ├── Tự động hóa Strategy Tester qua MCP (Genetic Optimization)
    ├── Kiểm định Walk-Forward (4x2) và Monte Carlo (100 runs)
    └── Xây dựng Lineage Tree và cơ chế Auto-Rollback khi suy giảm > 10%
                       │
                       ▼
  [Giai đoạn 4: Đánh giá Toàn diện & Scale Vốn Thật] (Tuần 9+)
    ├── Nghiệm thu 8 tuần chạy Demo Cent (Đạt PF >= 1.3, DD <= 12%)
    └── Cấp vốn thật thăm dò với risk multiplier 0.25x
```

---

### GIAI ĐOẠN 1: THIẾT LẬP NỀN TẢNG AI ORCHESTRATOR & PAPER MODE (TUẦN 1 - 2)

| Mã việc | Nhiệm vụ kỹ thuật | File/Module tác động | Chi tiết triển khai |
|---|---|---|---|
| **P1.1** | Khởi tạo khung dự án Python | `ai_trade/` | Thiết lập môi trường Python 3.11+, file `requirements.txt` (`openai`, `google-genai`, `fastapi`, `pydantic`, `mcp`, `sqlite3`). |
| **P1.2** | Cấu hình Provider Registry | `config/providers.json`<br>`ai_trade/core/provider_router.py` | Quản lý kết nối API cho Gemini, DeepSeek, OpenAI và Local Ollama. Có fallback tự động nếu provider chính bị rate-limit. |
| **P1.3** | Cấu hình gán vai trò Agent | `config/agents.json`<br>`ai_trade/committee/` | Thiết lập prompt và vai trò cho 5 tác tử: `TechnicalAnalyst`, `NewsSentiment`, `RiskAnalyst`, `Debaters (Bull/Bear)`, `CommitteeChair`. |
| **P1.4** | Thiết lập SQLite Results DB | `data/results.db`<br>`ai_trade/storage/db.py` | Tạo bảng `trade_decisions` và `trade_outcomes` để ghi nhận toàn bộ dữ liệu ra quyết định của AI. |
| **P1.5** | Chạy kiểm nghiệm Paper Mode | `tests/test_paper_committee.py` | Đưa 100 tín hiệu lịch sử của `TM_SessionBreakout` và `TM_GoldSweepScalper` vào hội đồng AI phân xử, đo lường độ chính xác và chi phí token. |

**Tiêu chuẩn nghiệm thu Giai đoạn 1:**
- Thời gian hội đồng AI ra quyết định: < 3.0 giây / tín hiệu.
- 100% quyết định có cấu trúc JSON hợp lệ, không có ngoại lệ API.
- Tỷ lệ lọc bỏ tín hiệu nhiễu (False signals) của AI đạt hiệu quả ban đầu > 20%.

---

### GIAI ĐOẠN 2: CHỐT CHẶN HARD RISKGATE & FORWARD DEMO CENT (TUẦN 3 - 4)

| Mã việc | Nhiệm vụ kỹ thuật | File/Module tác động | Chi tiết triển khai |
|---|---|---|---|
| **P2.1** | Xây dựng Hard RiskGate | `ai_trade/core/risk_gate.py` | Kiểm tra 5 lớp rào chắn bắt buộc trước khi lệnh được phép gửi tới MT5: Stop Loss hợp lệ, Risk <= 1%, Spread <= MaxSpread, Trong Kill-Zone, Không dính Cooldown. |
| **P2.2** | Tích hợp MT5 MCP Client | `ai_trade/bridge/mt5_client.py` | Giao tiếp với MT5 qua `Boschi404/mt5-mcp-server` hoặc MT5 Native MCP để đọc giá bid/ask và đặt lệnh thị trường. |
| **P2.3** | Triển khai Kill-Switch vật lý | `ai_trade/core/safety.py` | Tự động giám sát sự tồn tại của file `config/KILL`. Nếu file xuất hiện, lập tức ngắt toàn bộ AI orchestrator và đóng các lệnh đang mở. |
| **P2.4** | Vận hành Demo Cent Exness | MT5 Demo Cent (5,000 USC) | Đính EA lên chart, kết nối với AI Orchestrator chạy nền liên tục trong giờ giao dịch thực tế. |

**Tiêu chuẩn nghiệm thu Giai đoạn 2:**
- Zero lỗi từ chối sàn (`OrderSend error 10030`, `invalid stops`).
- RiskGate chặn thành công 100% các quyết định thử nghiệm vi phạm quy tắc an toàn.
- Dữ liệu khớp lệnh thực tế và PnL được tự động đồng bộ vào `data/results.db`.

---

### GIAI ĐOẠN 3: VÒNG LẶP TỰ TIẾN HÓA & KIỂM ĐỊNH OOS (TUẦN 5 - 8)

| Mã việc | Nhiệm vụ kỹ thuật | File/Module tác động | Chi tiết triển khai |
|---|---|---|---|
| **P3.1** | Thiết lập AI Mutation Zone | `MQL5/Experts/TM_GoldSweepScalper.mq5`<br>`MQL5/Experts/TM_SessionBreakout.mq5` | Đánh dấu vùng tham số được phép tinh chỉnh (`AI_MUTATION_ZONE`), đóng băng vĩnh viễn các khối code an toàn. |
| **P3.2** | Tự động hóa Strategy Tester | `ai_trade/evolution/tester_runner.py` | Điều khiển MT5 Strategy Tester chạy Genetic Optimization ngầm (Model=4 Real Ticks). |
| **P3.3** | Bộ kiểm định Walk-Forward & Monte Carlo | `ai_trade/evolution/validator.py` | Tự động chia dữ liệu In-sample / Out-of-sample (4 cửa sổ x 2) và xáo trộn 100 kịch bản Monte Carlo để kiểm tra độ bền vững của bộ tham số mới. |
| **P3.4** | Quản lý Phả hệ & Auto-Rollback | `ai_trade/evolution/lineage.py` | Ghi nhận cây phả hệ tham số (`config/lineage_tree.json`). Nếu bộ tham số mới gây sụt giảm hiệu suất (Regression) > 10% so với baseline -> **Tự động hủy và Rollback**. |

**Tiêu chuẩn nghiệm thu Giai đoạn 3:**
- Hệ thống tự hoàn thành tối thiểu 3 chu kỳ tiến hóa không cần can thiệp thủ công.
- Tự động phát hiện và loại bỏ các biến thể over-fitting nhờ cơ chế Walk-Forward OOS.

---

### GIAI ĐOẠN 4: ĐÁNH GIÁ TỔNG THỂ & CÂN NHẮC VỐN THẬT (TUẦN 9+)

1. **Điều kiện tiên quyết để chuyển sang Live (Go-Live Gates):**
   - [ ] Đã chạy Demo Cent liên tục tối thiểu 8 tuần.
   - [ ] Tổng số giao dịch tối thiểu: ≥ 50 lệnh thực tế.
   - [ ] `Profit Factor (PF) ≥ 1.30`.
   - [ ] `Max Equity Drawdown ≤ 12.0%`.
   - [ ] Không có bất kỳ ngoại lệ kỹ thuật nào (0 crash, 0 unhandled exceptions).
2. **Quy tắc cấp vốn thật ban đầu:**
   - Cấp vốn khởi điểm nhỏ ($500 - $1,000 USD).
   - Áp dụng hệ số rủi ro thận trọng: `risk_multiplier = 0.25x` (chỉ 0.25% rủi ro / lệnh).
   - Duy trì người giám sát (Human-in-the-loop) theo dõi nhật ký hàng tuần.

---

## 3. CHECKLIST THEO DÕI TIẾN ĐỘ THỰC HIỆN

- [x] Chuẩn hóa toàn diện tài liệu đặc tả kỹ thuật `SPEC_AI_TRADE_MODULE.md`.
- [x] Soạn thảo Kế hoạch hành động tổng thể `ACTION_PLAN_AI_TRADE.md`.
- [x] **Phase 1: Khởi tạo scaffolding mã nguồn Python & Cấu hình:**
  - [x] Tạo thư mục `ai_trade/` và thiết lập môi trường `requirements.txt`.
  - [x] Chuyển và chuẩn hóa các file cấu hình vào `config/ai/` (`config/ai/providers.json`, `config/ai/agents.json`, `config/ai/methods_registry.json`).
  - [x] Xây dựng module `provider_router.py` hỗ trợ Gemini / DeepSeek / OpenAI / TokenHarbor, cơ chế fallback đường dẫn cấu hình và Offline Quant Simulation Engine.
  - [x] Xây dựng các tác tử hội đồng tranh luận (`specialists.py`, `debater.py`, `chair.py`, `orchestrator.py`).
  - [x] Khởi tạo SQLite DB `data/results.db` và module quản lý `ai_trade/storage/db.py`.
  - [x] Xây dựng Mock MT5 Bridge (`ai_trade/bridge/mock_bridge.py`) cho cả H1 Breakout và M5 Sweep.
  - [x] Viết bộ kiểm thử toàn diện `tests/test_ai_committee.py` (4/4 tests passed 100%).
  - [x] Chạy thực tế thành công runner Paper Trading `tests/run_paper_committee.py` (lưu vết ID #5, #6 vào database).
- [x] **Phase 2: Chốt chặn an toàn, MT5 MCP & Live Runner:**
  - [x] Triển khai `risk_gate.py` với 6 lớp bảo vệ cứng và kiểm duyệt hướng SL/TP động.
  - [x] Xây dựng MT5 FastMCP Server hoàn chỉnh (`ai_trade/bridge/mt5_mcp_server.py`) gồm 11 tools giao tiếp MT5 (Status, Account, Symbol Info, Rates, Ticks, Positions, Orders, History Deals, Order Send, Close, Modify).
  - [x] Đăng ký MT5 MCP server vào cấu hình toàn cục (`C:\Users\tuanmjnh\.gemini\config\mcp_config.json`, `settings.json`) và trích xuất tool schema vào `C:\Users\tuanmjnh\.gemini\antigravity\mcp\mt5\`.
  - [x] Kiểm thử kết nối trực tiếp thành công với Exness MT5 Terminal (Account: 464140826, Server: Exness-MT5Trial17).
  - [x] Xây dựng module an toàn & Kill-Switch vật lý (`ai_trade/core/safety.py`), kiểm thử ngắt khẩn cấp và dọn dẹp lệnh thành công.
  - [x] Xây dựng bộ quét tín hiệu thị trường thời gian thực (`ai_trade/signals/detector.py`) cho cả M5 London Sweep và H1 Asian Breakout.
  - [x] Xây dựng Trade Runner đa chế độ (`ai_trade/runner.py`) khép kín toàn bộ chu trình MT5 Rates -> Signal -> AI Committee -> Hard RiskGate -> MT5 Order Execution.
  - [x] Mở rộng bộ kiểm thử tự động `tests/test_safety_and_signals.py` (Toàn bộ 6/6 tests passed 100%).
  - [ ] Vận hành Forward Demo thực tế theo phiên (London/NY) ghi nhận tối thiểu 50 lệnh thực tế.
- [x] **Phase 3: Vòng lặp Tự tiến hóa & Kiểm định OOS:**
  - [x] Đánh dấu vùng `AI_MUTATION_ZONE` và đóng băng `FROZEN SAFETY CODE` trong `TM_GoldSweepScalper.mq5` và `TM_SessionBreakout.mq5`.
  - [x] Xây dựng công cụ chạy Strategy Tester tự động qua Python (`ai_trade/evolution/tester_runner.py`), tự sinh file `.ini` và bóc tách báo cáo HTML.
  - [x] Xây dựng module kiểm định Walk-Forward (4 cửa sổ x 2) và Monte Carlo 100 kịch bản (`ai_trade/evolution/validator.py`).
  - [x] Thiết lập Lineage Tree (`config/ai/lineage_tree.json`) và cơ chế Auto-Rollback khi regression > 10% (`ai_trade/evolution/lineage.py`).
  - [x] Xây dựng Self-Evolution Orchestrator (`ai_trade/evolution/optimizer.py`) điều phối chu trình đột biến -> kiểm thử -> sàng lọc -> thăng hạng.
  - [x] Mở rộng bộ kiểm thử tự động `tests/test_evolution.py` (Toàn bộ 11/11 tests passed 100%).
- [x] **Phase 4: Bộ công cụ Nghiệm thu, Cân bằng Danh mục & Giám sát Hệ thống:**
  - [x] Xây dựng Portfolio Capital Allocator (`ai_trade/core/portfolio.py`) quản trị tỷ trọng vốn giữa 2 chiến lược (60% GSS / 40% SB), trần rủi ro đồng thời (Aggregate Risk Cap <= 2.0%) và hệ số rủi ro thăm dò (Live Probing Multiplier 0.25x).
  - [x] Xây dựng System Watchdog & Heartbeat Monitor (`ai_trade/core/watchdog.py`) liên tục phát xung nhịp `config/ai/heartbeat.json`, giám sát độ trễ và trạng thái terminal.
  - [x] Xây dựng Performance Auditor & Go-Live Readiness Dashboard (`ai_trade/reporting/dashboard.py`) thẩm định 5 cổng điều kiện ngặt nghèo (50 real trades, PF >= 1.30, Max DD <= 12%, 0 lỗi an toàn, AI filter efficiency).
  - [x] Tích hợp hoàn chỉnh Watchdog và Portfolio Manager vào Trade Runner (`ai_trade/runner.py`).
  - [x] Bộ kiểm thử tự động toàn diện `tests/test_reporting_and_portfolio.py` (Toàn bộ 14/14 tests passed 100%).
  - [ ] Tích lũy đủ 50 lệnh thực tế trên Exness Demo Cent và nghiệm thu toàn bộ 5 cổng Go-Live trước khi mở vốn thật.
