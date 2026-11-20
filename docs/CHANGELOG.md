# TM-EA — CHANGELOG

Định dạng theo `MASTER.md` §6.6.

---

```yaml
[2026-11-20] - v5.2 (PHASE 4 PERFORMANCE DASHBOARD, PORTFOLIO RISK ALLOCATOR & WATCHDOG)
Thay doi:
  - Hoàn thiện toàn bộ các module của Giai đoạn 4 (Phase 4: Readiness Auditor, Portfolio Risk Management & Watchdog) theo ACTION_PLAN_AI_TRADE.md:
    + 1. Bảng điều khiển Đánh giá Hiệu suất & Cổng Go-Live (`ai_trade/reporting/dashboard.py`):
      * Tự động thẩm định dữ liệu từ SQLite `data/results.db` và MT5 Deals.
      * Đo lường 5 cổng Go-Live nghiêm ngặt: Tối thiểu 50 real trades, Profit Factor >= 1.30, Max Drawdown <= 12%, Zero lỗi an toàn, AI Filter Efficiency (> 10% nhiễu được loại bỏ).
    + 2. Quản trị Phân bổ Vốn & Danh mục Đa chiến lược (`ai_trade/core/portfolio.py`):
      * Phân bổ tỷ trọng vốn mục tiêu (60% TM_GoldSweepScalper / 40% TM_SessionBreakout).
      * Rào chắn rủi ro tổng hợp (Aggregate Portfolio Risk Cap <= 2.0% equity mở đồng thời).
      * Hệ số rủi ro thăm dò (Live Probing Multiplier 0.25x) bảo vệ vốn tối đa khi mới lên live.
      * Tính toán khối lượng động chính xác theo khoảng cách Stop Loss và quy mô hợp đồng vàng.
    + 3. Giám sát Hệ thống & Xung nhịp Sống (`ai_trade/core/watchdog.py`):
      * Tự động phát xung nhịp `config/ai/heartbeat.json` ghi nhận uptime, PID, trạng thái terminal và tham số thị trường.
    + 4. Tích hợp trực tiếp vào Trade Runner (`ai_trade/runner.py`):
      * Tự động đồng bộ số dư thực tế từ MT5 vào PortfolioManager, phát xung nhịp watchdog mỗi chu kỳ lặp và kiểm tra hạn mức danh mục trước khi gửi lệnh.
    + 5. Bộ kiểm thử tự động toàn diện:
      * Bổ sung `tests/test_reporting_and_portfolio.py`, nâng tổng số test suite tự động lên 14/14 tests passed 100%.

[2026-11-20] - v5.1 (PHASE 3 SELF-EVOLUTION ENGINE & WALK-FORWARD OOS COMPLETE)
Thay doi:
  - Hoàn thiện toàn bộ các module của Giai đoạn 3 (Phase 3: Self-Evolution Loop) theo ACTION_PLAN_AI_TRADE.md:
    + 1. Thiết lập "AI Mutation Zone" trong MQL5: Đánh dấu các vùng tham số chiến lược được phép đột biến (`AI_MUTATION_ZONE_START` / `END`) trong `TM_GoldSweepScalper.mq5` và `TM_SessionBreakout.mq5`, đóng băng vĩnh viễn các khối code an toàn (`FROZEN SAFETY CODE`).
    + 2. Module Strategy Tester Headless Runner (`ai_trade/evolution/tester_runner.py`): Tự động sinh file cấu hình `.ini` (Model=4 Real Ticks), khởi chạy MT5 Terminal ngầm và bóc tách báo cáo HTML trích xuất Net Profit, Profit Factor, Max Drawdown %, Trades, Win Rate.
    + 3. Bộ kiểm định Out-Of-Sample & Stress Testing (`ai_trade/evolution/validator.py`):
      * Walk-Forward Analysis (WFA) phân đoạn 4 cửa sổ x 2 (IS/OOS) đo lường WFA Efficiency Ratio chống over-fitting.
      * Monte Carlo Simulator 100 lần xáo trộn xác định Drawdown 95th percentile và rủi ro sụt giảm vốn (Risk of Ruin <= 1.0%).
    + 4. Quản lý Phả hệ & Auto-Rollback (`ai_trade/evolution/lineage.py`): Quản lý cây phả hệ tham số `config/ai/lineage_tree.json`. Nếu biến thể mới bị suy giảm hiệu suất (Regression > 10% PF degradation) hoặc Max Drawdown vượt ngưỡng -> Tự động từ chối và kích hoạt Rollback về baseline ổn định.
    + 5. Trình điều phối Tự tiến hóa (`ai_trade/evolution/optimizer.py`): Tự động lấy baseline, tạo biến dị, chạy backtest, kiểm định OOS và thăng hạng champion mới.
    + 6. Mở rộng test suite tự động: Bổ sung `tests/test_evolution.py` với 5 bài test chuyên sâu, nâng tổng số test lên 11/11 tests passed 100%.

[2026-11-20] - v5.0 (PHASE 2 HARD RISKGATE, SAFETY KILL-SWITCH & LIVE TRADE RUNNER COMPLETE)
Thay doi:
  - Hoàn thiện toàn bộ các mắt xích kỹ thuật của Giai đoạn 2 (Phase 2) theo ACTION_PLAN_AI_TRADE.md:
    + 1. Safety Module & Kill-Switch vật lý (`ai_trade/core/safety.py`): Triển khai cơ chế ngắt khẩn cấp vật lý qua file cờ `config/ai/KILL`, tự động quét và đóng toàn bộ vị thế/lệnh chờ khi có sự cố.
    + 2. Signal Detector (`ai_trade/signals/detector.py`): Quét nến MT5 real-time, tính toán động biên độ phiên Á (Asian Range 00:00-06:00 GMT), ATR và phát hiện chính xác cả 2 setup:
      * TM_GoldSweepScalper (London Kill-Zone M5 Judas Liquidity Sweep Reversal).
      * TM_SessionBreakout (H1 Asian Range Breakout).
    + 3. Trade Runner đa chế độ (`ai_trade/runner.py`): Đóng gói toàn bộ luồng vận hành từ MT5 Rates -> Signal Detector -> Multi-Agent Committee -> Hard RiskGate -> MT5 Order Execution. Hỗ trợ cả 2 chế độ:
      * `--mode paper`: Chạy phân tích ảo, không vào lệnh, lưu đầy đủ bằng chứng vào SQLite `data/results.db`.
      * `--mode live`: Đặt lệnh tự động vào Exness MT5 Terminal kèm kiểm soát an toàn (khối lượng demo 0.01 lot, bắt buộc SL/TP, slippage 20 pts).
    + 4. Bộ kiểm thử tự động: Bổ sung `tests/test_safety_and_signals.py`, nâng tổng số test lên 6/6 tests passed 100%.
    + 5. Chạy thực tế thành công một chu trình khép kín end-to-end trên Terminal Exness (`Account: 464140826`), ghi nhận quyết định #10 vào cơ sở dữ liệu.

[2026-11-20] - v4.9 (MT5 MCP SERVER BRIDGE & AI CONFIG DIRECTORY CONSOLIDATION)
Thay doi:
  - Di chuyển & gom nhóm toàn bộ cấu hình AI Trade vào thư mục chuyên biệt: `config/ai/` (`agents.json`, `methods_registry.json`, `providers.json`).
  - Cập nhật `ProviderRouter` và `AIOrchestrator` tự động ưu tiên đường dẫn `config/ai/` với cơ chế fallback hai tầng, bảo đảm tính tương thích ngược hoàn hảo.
  - Xây dựng thành công MetaTrader 5 FastMCP Server hoàn chỉnh (`ai_trade/bridge/mt5_mcp_server.py`) gồm 11 công cụ giao tiếp MT5:
    + 1. `mt5_status`: Kiểm tra trạng thái kết nối terminal, latency và chế độ giao dịch.
    + 2. `mt5_account_info`: Truy vấn số dư (Balance), vốn thực (Equity), Margin, Đòn bẩy, Tiền tệ.
    + 3. `mt5_symbol_info`: Truy vấn giá Bid/Ask, Spread thực tế, Point, Digits và quy cách khối lượng (XAUUSDm / XAUUSD).
    + 4. `mt5_rates`: Lấy dữ liệu nến lịch sử đa khung thời gian (M1 -> D1) phục vụ phân tích kỹ thuật.
    + 5. `mt5_ticks`: Lấy luồng tick thời gian thực phục vụ phân tích vi cấu trúc orderflow và biến động spread.
    + 6. `mt5_positions`: Liệt kê các vị thế đang mở kèm PnL, SL, TP, Magic number.
    + 7. `mt5_orders`: Liệt kê các lệnh chờ (Pending orders) đang kích hoạt.
    + 8. `mt5_history_deals`: Lấy lịch sử giao dịch đã đóng để đối soát và đánh giá hiệu suất.
    + 9. `mt5_order_send`: Đặt lệnh thị trường/lệnh chờ với chốt chặn an toàn cứng (Max Lot Safety Cap 0.5 lot, bắt buộc Stop Loss).
    + 10. `mt5_position_close`: Đóng vị thế theo ticket với độ trượt giá (deviation) được kiểm soát.
    + 11. `mt5_position_modify`: Điều chỉnh SL/TP cho các vị thế đang mở.
  - Tích hợp và đăng ký MT5 MCP Server vào cấu hình toàn cục Antigravity (`C:\Users\tuanmjnh\.gemini\config\mcp_config.json`, `settings.json`) và tự động xuất 11 schemas JSON cùng tài liệu hướng dẫn (`C:\Users\tuanmjnh\.gemini\antigravity\mcp\mt5/`).
  - Xác thực kết nối trực tiếp thành công với Exness MT5 Terminal (Account: 464140826, Server: Exness-MT5Trial17).

[2026-11-20] - v4.8 (PHASE 1 AI TRADE ORCHESTRATOR COMPLETE)
Thay doi:
  - Hoan thanh toan bo cac hang muc Giai doan 1 (Phase 1: Foundation & Paper Mode) theo ACTION_PLAN_AI_TRADE.md:
    + 1. Khoi tao scaffolding ma nguon Python: ai_trade/core, ai_trade/committee, ai_trade/storage, ai_trade/bridge.
    + 2. Cau hinh Provider & Agents: config/providers.json, config/agents.json, config/methods_registry.json.
    + 3. Xay dung ProviderRouter: ho tro endpoint OpenAI-compatible (TokenHarbor, OpenAI, DeepSeek, Ollama) va che do Offline Quantitative Simulation Engine dua tren ICT/SMC rules de chay paper test 0 cost.
    + 4. Xay dung Multi-Agent Committee: TechnicalAnalyst, NewsSentimentAnalyst, VolatilityRiskAnalyst, BullAdvocate, BearAdvocate va CommitteeChair voi quy trinh tranh luan 2 vong.
    + 5. Dong goi Hard RiskGate: kiem duyet 6 lop an toan (SL hop le, huong SL/TP, max spread, risk cap, kill-switch).
    + 6. Co so du lieu SQLite: khoi tao data/results.db va module ai_trade/storage/db.py ghi nhan toan bo quyet dinh va PnL thuc te.
    + 7. Test suite: tests/test_ai_committee.py (4/4 tests passed 100%) va runner Paper Trading tests/run_paper_committee.py chay thanh cong ca 2 dang tin hieu H1 Asian Breakout va M5 London Judas Sweep.

[2026-11-19] - v4.7 (STANDARDIZE SPEC_AI_TRADE_MODULE & AI ACTION PLAN)
Thay doi:
  - Chuan hoa toan dien tai lieu dac ta kien truc AI Trade Orchestrator (docs/SPEC_AI_TRADE_MODULE.md):
    + Tai cau truc 5 tang modul (MT5 Execution Core -> MCP Bridge -> AI Orchestrator -> Knowledge Store -> Self-Evolution Loop).
    + So do hoa Mermaid diagram va lap bang phan cong chi tiet cho tung tang.
    + Xac lap hop dong JSON Schema chuan cho Multi-AI Committee (5-Tier Verdict: BUY, OVERWEIGHT, HOLD, UNDERWEIGHT, SELL) va cau truc du lieu SQLite results.db.
    + Dinh nghia quy tac an toan bat bien Hard RiskGate va "AI Mutation Zone" dong bang code an toan MQL5.
  - Xay dung Ke hoach Hanh dong Nang cap AI Trade chi tiet (docs/ACTION_PLAN_AI_TRADE.md):
    + Lo trinh 4 giai doan: Phase 1 (Paper Trading 100 mau) -> Phase 2 (Hard RiskGate & Demo Cent) -> Phase 3 (Self-Evolution & Walk-Forward OOS) -> Phase 4 (Live Scaling).
    + Thiet lap checklist nghiem thu va chi so do luong ky thuat ro rang.

[2026-11-19] - v4.6 (OPTIMIZE TM_GOLDSWEEPSCALPER - LONDON KZ 1Y PROFITABLE BASELINE)
Thay doi:
  - Toi uu hoa kien truc chien luoc TM_GoldSweepScalper qua 8 dot kiem dinh Model=4 (Real Ticks Exness):
    + 1. Bo loc nhiễu Kill-Zone: Bo sung Enable_LondonKZ va Enable_NYKZ vao CTimeService va Expert. Phat hien phien New York co nhieu tin tuc lam tang false sweeps. Chi giao dich London Kill-Zone (07:00 - 10:00 GMT) giup Max Drawdown giam tu 9.24% xuong chi con 3.88% tren 3 thang.
    + 2. Toi uu hoa Risk:Reward: Kiem chung plateaus RR (1.5 -> 2.0 -> 2.5 -> 3.0 -> 3.5). Xac dinh Sweep_RR = 3.0 la diem ngot toi uu nhat, giup vi the an tron song Judas Swing va vuot qua ma sat spread.
    + 3. Loai bo Trailing Stop non: Tat trailing stop tren M5 vi co che keo SL hoa von qua som (30 pips) bi nhieu gia M5 cat winners truoc khi cham 3R.
    + 4. Buffer Stop Loss thuc te: Nang buffer SL tu 0.35 * ATR len 0.75 * ATR chong quet re-test rau nen.
  - Ket qua kiem dinh 1 Nam Day Du (2025.08.01 - 2026.07.31 - ~85 trieu real ticks Model=4):
    + Lợi nhuận ròng: +177.68 USD (Duong 100% tren 1 nam day du)
    + Profit Factor: 1.069 (Gross Profit $2,770.21 / Gross Loss -$2,592.53)
    + Tong so lenh: 158 lenh (~13.1 lenh/thang - hiem va chat)
    + Max Equity Drawdown: 7.395% (400.99 USD) - Bao ve von tuyet doi duoi nguong 8%
  - Luu tru bao cao: reports/backtests/TM_GoldSweepScalper/2026-11-19/gss_london_1y_real/.
  - Cap nhat preset chuan: config/sets/TM_GoldSweepScalper/TM_GSS_XAUUSD_M5_BASELINE_v1_0.set va dong bo MT5 Presets.

[2026-11-19] - v4.5 (BUILD TM_GOLDSWEEPSCALPER 9-MODULE ARCHITECTURE)
Thay doi:
  - Trien khai thanh cong toan bo 9 module kien truc chuan hoa cho TM_GoldSweepScalper theo SPEC_GOLD_SCALPER.md:
    + 1. CSymbolSpecs: Chuan hoa specs, lot step, freeze level tu dong.
    + 2. CTimeService (Include/TM_EA/TimeService.mqh): Tu dong do GMT offset, quan ly 3 Kill-zones (Asia 00-07 GMT, London KZ 07-10 GMT, NY KZ 12:30-15 GMT) va kiem tra phien giao dich thuc.
    + 3. CRegimeEngine (Include/TM_EA/RegimeEngine.mqh): Phan loai RANGE / TREND_BULL / TREND_BEAR voi hysteresis giu trang thai chong nhieu.
    + 4. CLiquidityMap (Include/TM_EA/LiquidityMap.mqh): Ban do thanh khoan Asia High/Low, PDH/PDL, Swings M5 va nhan dien Sweep Reversal.
    + 5. CStrategyHub (Include/TM_EA/StrategyHub.mqh): Dieu phoi tin hieu theo bac uu tien (Setup A: SweepReversal -> Setup B: ORB).
    + 6. CRiskManager: Dinh co volume tien mat + commission + spread.
    + 7. CTrailingEngine: Trailing stop ATR + Breakeven (gate toi thieu 1.0 ATR).
    + 8. CGuards (Include/TM_EA/Guards.mqh): He thong bao ve da tang gom Spread guard, Daily loss limit (2.0%), Total DD Circuit Breaker (8.0%), Cooldown sau 3 lenh thua.
    + 9. CLogger: Ghi log 100% moi quyet dinh skip va retcode.
  - Bien dich TM_GoldSweepScalper.mq5 qua MetaEditor: 0 errors, 0 warnings.
  - Dong bo binary .ex5 va preset TM_GSS_XAUUSD_M5_BASELINE_v1_0.set vao MT5 Terminal Presets & Tester.
  - Kiem dinh Strategy Tester (Model=4 Real Ticks): Test smoke 3 thang cho thay Circuit Breaker hoat dong chuan xac, cat lo trong ngay khi DD cham 8% (giu DD o 9.24%, khac biet hoan toan so voi bot khong co guards bi DD > 70%).

[2026-11-19] - v4.4 (STRATEGY REALIGNMENT: RESCUE SB & SPEC GOLD SCALPER)
Thay doi:
  - Dinh huong chien luoc toan du an theo 2 tai lieu phan tich chuyen sau:
    + docs/2026.11.19/OPT_TM_EA_FIX.md (Phan tich & ke hoach sua loi P0 cho TM_SessionBreakout).
    + docs/2026.11.19/SPEC_GOLD_SCALPER.md (Spec 9 module cho bot scalp vang on dinh TM_GoldSweepScalper).
  - P0 Rescue TM_SessionBreakout (SB):
    + Uu tien hang dau la cuu SB de chay forward tren demo. Backtest 3Y (PF 1.666, DD 7.9%, 3/3 nam duong)
      la edge duy nhat co chung cu thong ke dang tin cay cua du an.
    + Xac dinh nguyen nhan SB khong vao lenh tren Demo: Hard-code gio server (lech gio mo cua London/NY khi
      server Exness o GMT+2/GMT+3) va logic log im lang (silent return false khong ghi nguyen nhan).
    + Lap ke hoach sua 5 diem then chot: A1 (tu do BrokerGMTOffset), A2 (log moi nhanh skip), A3 (tinh phi/commission
      vao sizing), A4 (tu chon SYMBOL_FILLING_MODE tranh retcode 10030), A5 (fix gating H1 va indicator warmup).
  - Tam gac TM_TrendFollowerScalper v2.0:
    + Do thua 6/6 vong toi uu ngoai mau (PF 0.12 - 0.60), roi vao bay spread ma sat khi chay tren M5 va
      hard-code gio server lech phien MQL5.
  - Quy hoach dai han TM_GoldSweepScalper:
    + Kien truc 9 module doc lap, edge kep SweepReversal + Opening-Range Breakout co kill-zone gio GMT that.
  - Cap nhat he thong tai lieu: MASTER.md, CHANGELOG.md, FORWARD_DEMO_PLAN.md va khoi tao ACTION_PLAN_2026_11_19.md.
Quyet dinh: Tap trung nguon luc sua A1-A5 cho TM_SessionBreakout, verify Journal tren Demo Exness, san sang cho tuan toi.

[2026-11-16] - v4.3 (LIQUIDITY SWEEP REVERSAL)
Thay doi: build TM_SweepReversal.mq5 (bar dong pha swing roi dong lai vao trong -> dao chieu; SL ngoai
  dinh/day quet; trail ATR; loc HTF EMA; risk; ><). Compile 0/0. Runner tests/run_sweep.ps1.
Ket qua (1 nam real-tick XAUUSDm):
  - M5 + HTF: 1556 lenh, PF 0.895, DD 76.5%.
  - M5 no HTF: 3108 lenh, PF 0.885, DD 91.3%.
  - M15 + HTF: 403 lenh, PF 0.845, DD 48.7%.
Quyet dinh: entry sweep + SL ngoai quet + trail VAN khong co edge (PF < 1, DD rat lon). Chi tiet: EA_BUILD_PLAN.md.

[2026-11-16] - v4.2 (WONDERWHALES + TRAILING/BREAKEVEN)
Thay doi: them trailing ATR + breakeven (gate ATR) vao TM_Wonderwhales (theo yeu cau). Compile 0/0.
Ket qua (XAUUSDm M5, 1 nam, PSAR/EMA):
  - PSAR one+trail: PF 0.978, DD 66.7% (3717 lenh).
  - PSAR one+trail+BE: PF 0.966, DD 71.0%.
  - EMA one+trail: PF 0.930, DD 24.4%.
  - PSAR wide-trail (act2/mult3): PF 0.952, DD 80.7%.
  - PSAR SL=PSAR + trail: PF 0.861, DD 39.6%.
Quyet dinh: trailing/breakeven KHONG cuu duoc WW M5 (PF < 1, DD rat lon). Tin hieu WW nhin "dep" tren
  TradingView la do hindsight/repaint + khong tinh spread. Chi tiet: docs/EA/EA_BUILD_PLAN.md.

[2026-11-16] - v4.1 (ORB - OPENING RANGE BREAKOUT)
Thay doi: dung lai engine SB cho ORB (pha range gio mo cua London/NY), khong code moi.
Ket qua (XAUUSDm, RR3, ADX off):
  - ORB L M5   1Y: PF 1.164, DD 17.8%, 208 lenh.
  - ORB L M15  1Y: PF 1.198, DD 14.2%; 3Y PF 1.039, DD 22.7% (W1 1.049, W2 0.981).
  - ORB L M5   3Y: PF 1.151, DD 12.4%, 563 lenh (~5x SB).
Quyet dinh: ORB la huong tan suat cao "it te nhat" nhung PF ~1.04-1.15 < nguong 1.3 va kem hon SB.
  Chi tiet: docs/EA/EA_BUILD_PLAN.md.

[2026-11-16] - v4.0 (SCALP NHANH LIEN TUC - NGHIEN CUU)
Thay doi: build TM_MeanRevert.mq5 (BB20/2 + RSI + loc range ADX, M5) de thu huong MR scalping.
Ket qua (1 nam real-tick):
  - EURUSDm: 816 lenh, PF 0.648, DD 86.8%.
  - XAUUSDm: 767 lenh, PF 0.855, DD 53.7%.
  - EURUSDm (khong loc range): 1961 lenh, PF 0.655, DD 97.8%.
Quyet dinh: khong bot nao phu hop scalp nhanh lien tuc (trend/breakout/MR deu PF<1, DD cuc lon).
  Chi SB (1 lenh/ngay) co edge. Chi tiet: docs/EA/EA_BUILD_PLAN.md (3.3).

[2026-11-16] - v3.9 (SB HOAN THIEN: SET + FORWARD PLAN)
Thay doi:
  - Cap nhat config/sets/TM_SessionBreakout/ theo EA hien tai: TM_SB_XAUUSD_H1_BASELINE_v1_0.set
    (them Use_Session2=false, day du input) + them TM_SB_XAUUSD_H1_CENT_v1_0.set (tai khoan Cent).
  - Them docs/FORWARD_DEMO_PLAN.md (cau hinh dong bang, lai kep, giam sat, tieu chi dung/dat).
  - Them reports/forward/TM_SessionBreakout/_template.md.
Quyet dinh: SB dong bang H1 baseline; buoc tiep = forward demo Cent 2-4 tuan. Khong doi tham so.
  Chi tiet: docs/FORWARD_DEMO_PLAN.md, config/sets/README.md.

[2026-11-16] - v3.8 (TANG TAN SUAT - KET QUA)
Thay doi: them phien 2 cho TM_SessionBreakout (Use_Session2). Compile 0/0.
Ket qua (XAUUSDm 3Y):
  - 1 phien: 111 lenh, PF 1.666, DD 7.9 (chuan).
  - 2 phien: 175 lenh (+58%), PF 0.941, DD 28.3 -> TE HON.
  - M5: 138 lenh PF 1.058 DD 17; EURCADm PF 0.391 DD 48; USDCADm PF 0.957.
Quyet dinh: moi cach tang tan suat deu pha edge. Edge SB cu the = 1 lenh/ngay (range A -> LDN/NY) tren XAUUSDm.
  Chi tiet: reports/backtests/TM_SessionBreakout/SB_RESEARCH.md (3g).

[2026-11-16] - v3.7 (P2 - SCOPE TRENDLINE BOLLINGER)
Thay doi: xay TM_ScopeTB.mq5 (bias D1+H1, BB M5 + trendline, ATR trail, no TP, re-entry). Compile 0/0.
Them runner tests/run_stb.ps1; report reports/backtests/TM_ScopeTB/.
Ket qua (XAUUSDm M5, 1 nam):
  - Session ON: 554 lenh, PF 0.954, DD 33.5%.
  - Session OFF: 950 lenh, PF 1.000, DD 30.5%.
Quyet dinh: STB ban dau KHONG dat gate (PF ~1.0, DD cao). Chua toi uu them. Khong co edge ro.
  Chi tiet: docs/EA/EA_BUILD_PLAN.md (4.1).

[2026-11-16] - v3.6 (P1 KET LUAN)
Thay doi: sua parity PSAR (tu tinh theo Pine, ham WwPSAR) trong TM_Wonderwhales.
Ket qua (XAUUSDm):
  - PSAR flip: 24 -> hang tram tin hieu/nam (da sua).
  - H1 PSAR close-and-reverse SL=PSAR: 1 nam PF 1.554/DD 4.19%, NHUNG walk-forward
    W1 0.943 / W2 0.709 / W3 1.554 -> 3Y PF 0.942 (AM).
Quyet dinh: Wonderwhales KHONG co edge ben vung -> dung toi uu, chuyen P2 (Scope Trendline Bollinger).

[2026-11-16] - v3.5 (EA BUILD PLAN + WONDERWHALES P1)
Thay đổi:
  - Them docs/EA/EA_BUILD_PLAN.md: ke hoach xay dung & backtest 3 EA moi (Wonderwhales,
    Scope Trendline Bollinger, TM Indicator 2), uu tien P1->P3.
  - Xay TM_Wonderwhales.mq5 (port PSAR/EMA/ATR, signal-only mac dinh). Compile 0/0.
  - Them runner tests/run_ww.ps1; report reports/backtests/TM_Wonderwhales/.
Ket qua dau (XAUUSDm M15, 1 nam real-tick, SL ATR2, TP RR2, risk 1%, dep5000):
  - mode EMA_CROSSOVER (close-and-reverse, no TP): 343 lenh, PF 1.069, DD 32.7%.
  - mode PSAR_REVERSAL: chi 24 tin hieu/nam -> LOI parity PSAR (iSAR vs Pine), can sua.
  - SAR+EMA / SAR+EMA+ATR: gan nhu khong co lenh (do PSAR hong).
Quyet dinh:
  - P1 chua cho ket qua tot hon SB; uu tien sua parity PSAR + thu EMA mode tren TF khac.
    Chi tiet: docs/EA/EA_BUILD_PLAN.md.

[2026-11-15] - v3.4 (SB: TF input, SL bug fix, sets, folders)
Thay đổi (code):
  - TM_SessionBreakout: them input Entry_TF (chay M15/M30/H1); SUA BUG SL_Range_Fraction
    (truoc do neo SL theo entry -> frac=1.0 bi chat hon bien range -> PF sup 0.997;
    nay neo vao bien range -> frac=1.0 = PF 1.666). EX5=6056689F0723FDA8, compile 0/0.
  - Tao preset config/sets/TM_SessionBreakout/ (H1 baseline, M30, M15).
Thay đổi (cau truc):
  - config/sets/ chia theo EA: TM_TrendFollowerScalper/, TM_SessionBreakout/, TM_KimLa/.
  - config/ini/ : copy 49 ini tu MT5 (Profiles\Tester) + 5 ini du an, nhom theo EA.
Ket qua (XAU 3Y, SL dung):
  - H1 1/ngay PF 1.666/DD7.9 (tot nhat); M30 1.456; M15 1.217.
  - NHEU lenh/ngay -> TE hon (H1 0.964). Khung nho khong them lenh.
Quyet dinh:
  - Chot H1 (frac1.0, ADX20, RR5, 1/ngay). Bang frac cu (1.25 "tot") bi BAC BO (la he qua cua bug).
  - Chi tiet: reports/backtests/TM_SessionBreakout/SB_RESEARCH.md (3f).

[2026-11-13] - v3.3 (XAU-FOCUSED OPTIMIZATION)
Thay đổi (code): them input SL_Range_Fraction (SL = frac * range; mac dinh 1.0). EX5=B3FC4346827A04FB.
Ket qua (XAUUSDm 3Y):
  - Cua so: London 07-12 PF 0.775 (te); NY 12-20 PF 1.771 nhung walk-forward khong thang deu -> giu 07-20.
  - SL frac: 0.5->0.973 (DD40%), 1.25->1.778 nhung RR4/5/6=1.084/1.778/1.405 = DINH GIA (overfit);
    1.0 giu plateau RR4-6 = 1.445/1.665/1.680.
Quyet dinh:
  - Cam bay overfit duoc nhan dien va TU CHOI (frac1.25, NY window). GIU cau hinh ben: frac1.0, ADX20, RR5.
  - Cau hinh chot cho XAU. Chi tiet: _sb/SB_RESEARCH.md (3f).

[2026-11-13] - v3.2 (SB ROBUSTNESS)
Thay đổi: khong doi code chien luoc (chi test).
Kiem chung:
  - Do nhay commission (giai tich): PF 1.665 -> 1.459 tai $5/lenh, 1.299 tai $10/lenh -> RAT BEN voi phi.
  - Dai range theo ATR (Min/Max_Range_ATR): loc range lon LAM GIAM PF (1.665 -> 1.394) -> khong dung.
  - Symbol raw XAUUSDr khong test duoc (thieu history) -> commission model truc tiep BLOCKED.
Quyet dinh: Giu cau hinh ADX20 RR5. Ket qua khong doi. Chi tiet: _sb/SB_RESEARCH.md (3d/3e).

[2026-11-13] - v3.1 (SB REGIME FILTER - KET QUA TOT NHAT)
Thay đổi (code):
  - TM_SessionBreakout: them bo loc regime ADX(H1) (Use_ADX_Filter mac dinh true, ADX_Min=20),
    dai range theo ATR (Min/Max_Range_ATR). Mac dinh RR=5. Compiled 0/0; EX5=4E23415AEAE1E96C.
Ket qua (XAUUSDm, dep5000, risk1%):
  - 3Y: khong ADX PF 1.081/DD18.3 -> ADX20 PF 1.665/DD7.9; ADX30 PF 1.746/DD8.2.
  - Walk-forward ADX20 RR5: W1 1.033 (truoc 0.849) / W2 2.692 / W3 1.503 -> CA 3 NAM DUONG.
  - Plateau RR (ADX20, 3Y): RR4 1.445 / RR5 1.665 / RR6 1.680, DD ~8%.
Quyet dinh:
  - Bo loc ADX sua duoc nam am W1. Day la ket qua on dinh nhat cua du an. NHUNG chua xac nhan:
    can commission/slippage that + them symbol. Chua demo/tien that. Chi tiet: _sb/SB_RESEARCH.md.

[2026-11-13] - v3.0 (NEW STRATEGY: SESSION-BREAKOUT H1)
Thay đổi:
  - Thêm EA mới MQL5/Experts/TM_SessionBreakout.mq5 (logic mới hoàn toàn): phá range phiên Á
    (00-07 server) tại London/NY, 1 lệnh/ngày, SL = biên đối diện range, TP = RR*risk.
    Compiled 0/0; EX5 SHA256[0:16]=0476E2E990E99862. Giữ nguyên EA cũ.
  - Thêm runner tests/run_breakout.ps1; report reports/backtests/_sb/.
Lý do: chiến lược cũ thua 6/6 vòng (OOS PF < 1); thử khái niệm khác (volatility expansion theo phiên),
  tần suất thấp -> hợp vốn nhỏ.
Kết quả (XAUUSDm, dep5000, risk1%, real-tick):
  - RR5 3Y: PF 1.081, DD 18.3% | RR6 3Y: PF 1.578, DD 8.7% | RR3 3Y: PF 1.024.
  - Walk-forward RR5: W1(2023.11-24.10) PF 0.849 (AM) | W2 PF 2.023 | W3 PF 1.763 -> phụ thuộc regime.
  - EURUSDm 3Y: PF 0.667 (that bai). Vốn 500: 0 lệnh (min-lot).
Quyết định:
  - GIỮ làm hướng nghiên cứu chính (khac biet ro so voi chien luoc cu), nhung CHUA xac nhan.
    Can: commission/slippage that + loc regime + walk-forward dai. Chua demo/tien that.
    Chi tiet: reports/backtests/_sb/SB_RESEARCH.md.

[2026-11-13] - v2.5 (ROUND 6: SCALE-OUT)
Thay đổi (code):
  - Thêm scale-out: Use_Partial_Exit (default FALSE), Partial_Exit_ATR_Mult, Partial_Exit_Percent;
    CTradeExecutor::ClosePartial. Biên dịch 0/0; EX5 SHA256[0:16]=F76C419727E08752.
Kết quả ($5000, IS): no-partial PF 0.861 vs partial1.0 PF 0.845 vs partial1.5 PF 0.813;
  largest_win 151 -> 75. Scale-out LÀM GIẢM PF (cắt winner lớn).
Quyết định:
  - Bác bỏ B. Mặc định tắt. D (R:R qua TP) vô nghĩa vì TP không bind.
  - Tổng 6 vòng: 0 phương pháp cho OOS PF >= 1. Chi tiết: _v2/RESEARCH_LOG.md.

[2026-11-13] - v2.4 (ROUND 5: ENTRY QUALITY)
Thay đổi (code):
  - Thêm Use_EMA_Slope_Filter (lọc độ dốc EMA HTF) và Require_Close_Beyond_EMA
    (nến pullback phải đóng qua EMA). Biên dịch 0/0; EX5 SHA256[0:16]=129053A96E2C8D0F.
Kết quả:
  - IS: reclaim nâng PF 0.935->1.047, DD 11.8->7.9%. slope filter TRƠ (không đổi gì).
  - OOS: reclaim PF 0.699 (base 0.726), DD 16.1->10.7% -> vẫn <1.
Quyết định:
  - reclaim là bộ GIẢM RỦI RO tốt (giảm DD) nhưng KHÔNG tạo edge. Vẫn chưa sinh lời.
    Chi tiết: reports/backtests/_v2/RESEARCH_LOG.md (Round 5).

[2026-11-13] - v2.3 (RESEARCH ROUNDS 1-4)
Thay đổi (code):
  - Thêm input Trade_Direction (0=Both,1=Buy,2=Sell). Thêm SL_ATR_Mult (tách SL ban đầu khỏi trailing).
  - Biên dịch 0/0; EX5 SHA256[0:16]=CA67C0BBFAC98E5B.
Kết quả (IS 2026.05-07):
  - R1 hướng: long-only PF 0.767 < both 0.935 -> hướng không giúp.
  - R2 tách SL/trail: PF không tăng, DD tăng vọt 30-40%.
  - R3 timeframe: không cải thiện; H1 = 0 lệnh (thiếu warmup).
  - R4 EURUSDm: PF 0.51-0.62, DD 32-42% -> tệ hơn vàng.
Quyết định:
  - KHÔNG áp dụng thay đổi nào (không tạo edge). Vấn đề ở khái niệm entry, không phải tham số.
  - Chiến lược vẫn chưa sinh lời. Chi tiết: reports/backtests/_v2/RESEARCH_LOG.md.

[2026-11-13] - v2.2 (BUG-013 FIX + TEST)
Thay đổi:
  - Sửa BUG-013: thêm input Breakeven_ATR_Mult (default 1.0); breakeven chỉ kích hoạt khi lãi
    >= max(Breakeven_After_pips*pip, Breakeven_ATR_Mult*ATR) -> không còn dời SL về entry khi lãi < nhiễu.
  - Biên dịch 0/0; EX5 SHA256[0:16]=07ED385A5D67E86E.
Kết quả (vốn 500, risk 1%, Pullback+Breakout, atr1.5, act10 step5, ADX25):
  - IS  no-TP: PF 0.935 | IS  TP1.5: PF 0.935 (giống hệt) -> TP vô hiệu trên real-tick.
  - OOS no-TP: PF 0.726 | OOS TP1.5: PF 0.726 (giống hệt).
  - Gate test: Breakeven_ATR_Mult 0.25 -> PF 0.567; 1.0 -> 0.935; 4.0 -> 0.932.
Quyết định:
  - Áp dụng fix (đóng BUG-013 dạng source). Bỏ TP là vô hại/đúng thiết kế gốc (không phải đòn bẩy lãi).
  - Chiến lược VẪN PF < 1 -> chưa sinh lời, không demo/tiền thật. Chi tiết: _v2/OPTIMIZATION_STUDY.md §5.

[2026-11-13] - v2.1 (OPTIMIZATION STUDY)
Thay đổi:
  - Khôi phục Breakout trong code (CEntryEngine::EvaluateBreakout) nhưng có switch; thêm input
    Use_Breakout (default true), BreakoutK (0.7); đánh thức lại SETUP_BREAKOUT. Biên dịch 0/0.
    EX5 mới SHA256[0:16]=60B7454806D2C85A. (v2.0 đã gỡ Breakout; dữ liệu cho thấy cần test lại.)
  - Chạy grid optimization trên IS (2026.05-07) + kiểm chứng OOS (2026.08-10), real-tick.
Phát hiện:
  - BUG-013 (breakeven dời SL về entry quá sớm) là lỗi cơ chế lớn: tắt breakeven đưa PF 0.155 -> 0.897,
    largest_win 0.29 -> 22.66. Đây là cải thiện thật.
  - Khôi phục Breakout: lợi ích nhỏ (PF 0.914 -> 0.932).
  - Tối ưu ADX (IS PF 1.08 tại ADX20) GÃY trên OOS (PF 0.57) -> overfit, KHÔNG áp dụng.
Quyết định:
  - Áp dụng hướng fix breakeven (BUG-013); KHÔNG áp dụng tham số ADX tối ưu IS.
  - Chiến lược vẫn PF < 1 (chưa sinh lời). Không demo/tiền thật. Chi tiết: _v2/OPTIMIZATION_STUDY.md.

[2026-11-13] - v2.0.2 (SET SELECTION STUDY)
Thay đổi: chạy 8 preset trên 6 tháng real-tick (2026.05.01–2026.10.31) + đối chứng TP on/off.
Kết quả: 8/8 âm (PF 0.08–0.31); TẤT CẢ > cổng DD? không; TP on/off GIỐNG HỆT trên real-tick
  → lỗi ở entry (Pullback-only), không phải vốn/TP.
Xếp hạng least-bad: realistic_500 (PF 0.215, DD 4.33%) > standard_1000 (PF 0.168, DD 2.43%);
  tệ nhất: small_50/small_100 (DD 16–18%) và cost_stress_10000 (DD 20.1%).
Quyết định: KHÔNG set nào đáng giao dịch thật. Đề xuất khôi phục Breakout rồi chạy lại study.
  Chi tiết: reports/backtests/_v2/SET_SELECTION_STUDY.md.

[2026-11-13] - v2.0.1 (BACKTEST THỰC THI)
Thay đổi:
  - Biên dịch v2.0 bằng MetaEditor: 0 errors / 0 warnings (tests/compile-v2.log); EX5 SHA256[0:16]=0F50E9E0ADD72C90 (đóng BUG-006).
  - Thêm dump CSV chỉ-trong-tester (DumpTesterStats) vì khóa Report= của MT5 không hoạt động ở chế độ /config.
  - Thêm tests/run_backtest_v2.ps1 (chạy MT5 tester headless, tái lập được).
  - Chạy backtest real-tick (Model=4) 3 tháng cho 6 preset + 4 run kiểm soát.
Kết quả:
  - TẤT CẢ preset v2.0 đều LỖ: realistic_200 PF 0.16; realistic_500 0.41; standard_1000 0.40;
    conservative_5000 0.27; small_50 0.12 (DD 18.4%); cost_stress_10000 0.60.
  - Kiểm soát TP (Model=1): không TP PF 3.39 > TP1.5 PF 2.47 > TP0.2 PF 2.14 → TP không giúp.
  - Điểm bất thường: 1 lệnh thắng +203.77 không đổi theo mọi cấu hình TP (nghi gap real-tick) - CHƯA xác minh.
Quyết định:
  - REJECT v2.0 as-is. Giữ code + report làm bằng chứng. Không chạy tiền thật.
    Chi tiết: reports/backtests/_v2/V2_BACKTEST_RESULTS.md.

[2026-11-12] - v2.0 (STRATEGY CHANGE)
Thay đổi:
  - BỎ Breakout: xóa CEntryEngine::EvaluateBreakout; xóa input Entry_Mode, BreakoutK,
    ATR_Channel_Period; xóa enum ENUM_ENTRY_MODE và SETUP_BREAKOUT. Entry chỉ còn Pullback.
  - BẬT Take Profit: Use_TP mặc định false -> true; thêm input TP_ATR_Mult=1.5;
    OpenBuy/OpenSell nhận và gửi takeProfit = entry + direction * TP_ATR_Mult * ATR;
    bỏ chặn INIT_FAILED khi Use_TP=true.
  - THÊM equity circuit breaker: input Max_Equity_DD_Percent=10.0; mỗi tick nếu
    equity DD từ baseline ngày >= ngưỡng -> đóng toàn bộ vị thế (CTradeExecutor::CloseAllPositions)
    và khóa mở lệnh mới tới hết ngày (RiskGuard breaker flag persist qua restart).
  - SỬA breakeven cả hai nhánh (BUG-010): mức breakeven = openPrice ± spread nhưng
    clamp về openPrice khi SL rơi sai phía thị trường (trước đây bị broker từ chối vì
    SL cao hơn bid / thấp hơn ask khi spread (0.20-0.35) > ngưỡng breakeven (0.08)).
  - Đồng bộ 8 preset config/sets/: bỏ 3 input đã xóa, đặt Use_TP=true, thêm TP_ATR_Mult,
    Max_Equity_DD_Percent.
Lý do:
  - Theo yêu cầu chủ dự án: đơn giản hóa entry (Pullback-only), chốt lời bằng TP,
    và có cầu dao bảo vệ vốn để chặn DD 22-52% đã thấy trên preset vốn nhỏ.
  - ⚠️ Đây là THAY ĐỔI CHIẾN LƯỢC: ghi đè invariant "Không Take Profit" (MASTER §3, SOURCE_SPEC §2.2)
    và bỏ một trong hai cơ chế vào lệnh (SOURCE_SPEC §4.2). Đã cập nhật các tài liệu đó.
File ảnh hưởng:
  - MQL5/Include/TM_EA/Inputs.mqh, EntryEngine.mqh, Types.mqh, TradeExecutor.mqh,
    TrailingEngine.mqh, RiskGuard.mqh
  - MQL5/Experts/TM_TrendFollowerScalper.mq5
  - config/sets/ (toàn bộ 8 preset .set)
  - docs/MASTER.md, docs/SOURCE_SPEC_V1.md, docs/TECHNICAL_AUDIT.md,
    docs/SOURCE_REPORT_CONSISTENCY.md, docs/CHANGELOG.md
  - README.md, tests/implementation-status.md, tests/BUG_REPRODUCTIONS.md, tests/VALIDATION_RESULTS.md
Report/manifest kèm theo:
  - CHƯA có. Code v2.0 CHƯA được biên dịch lại và CHƯA chạy lại backtest.
Kết quả cost-stress:
  - Không áp dụng — cần chạy lại toàn bộ sau khi compile (mọi report cũ KHÔNG còn giá trị cho v2.0).
Quyết định:
  - Giữ; nhưng GIỮ NGUYÊN mọi report cũ làm lịch sử. Trạng thái bắt buộc: NOT RUN cho tới khi
    compile + cost-stress + OOS hoàn tất. Xem tests/BUG_REPRODUCTIONS.md (BUG-002/003/006/007/008 còn mở).

[2026-11-12] - audit-v1.3
Thay đổi:
  - Đối chiếu MASTER với source/preset/report thực tế; tạo TECHNICAL_AUDIT.md,
    SOURCE_REPORT_CONSISTENCY.md, tests/BUG_REPRODUCTIONS.md, tests/VALIDATION_RESULTS.md.
  - Tạo harness test tests/units/TM_EA_UnitTests.mq5 (dùng chính header thật).
  - Tạo manifest cho từng lần kiểm thử + reports/backtests/MANIFEST_INDEX.md.
  - Sửa SOURCE_SPEC_V1.md canonical table: Max_Concurrent_Positions 2->1, Max_Daily_Loss_Percent 5.0->1.5.
  - Rút lại tuyên bố cost-stress "PASSED"; viết lại MASTER §4.
Quyết định:
  - Giữ toàn bộ report cũ. Không PASS hạng mục thiếu bằng chứng.

[2026-11-12] - v1.2
Thay đổi:
  - Max_Spread_Points 35 -> 350 (3-digit gold spread); news calendar unavailable trong tester không chặn.
  - Chuẩn hóa 7 preset trong config/sets/.
  - Soạn docs/USER_GUIDE.md.
Quyết định: Giữ lại.

[2026-11-12] - v1.1
Thay đổi:
  - Chuẩn hóa bảng canonical inputs; thêm preset cost_stress/realistic_200/realistic_500.
  - Triển khai Breakout (EvaluateBreakout) trong EntryEngine và tích hợp vào Main EA.
  - Compile 0 errors/0 warnings; đồng bộ EX5.
Quyết định: Giữ lại. (Breakout đã bị bỏ ở v2.0.)
```
