# TM-EA — SOURCE ↔ REPORT CONSISTENCY (P0)

**Ngày:** 2026-11-12
**Mục tiêu:** đối chiếu `docs/MASTER.md` với source MQL5, preset và report thực tế; ghi lại mọi tuyên bố không có bằng chứng.

> 🔄 **v2.0 (2026-11-12):** Breakout đã bị **bỏ khỏi code** và Take Profit đã **bật**. Do đó các kết luận "breakout đang chạy" ở §1 là đúng **tại thời điểm audit v1.3** nhưng không còn cho v2.0. Mọi report trong §5 thuộc build **no-TP + Breakout** → **vô hiệu cho v2.0**.

---

## 1. Trạng thái tổng quan (thực tế)

| # | Tuyên bố trong MASTER.md | Bằng chứng thực tế | Kết luận |
|---|---|---|---|
| P0.2 | Breakout tồn tại trong `EntryEngine` và được gọi từ Main EA | Tại audit v1.3: `EvaluateBreakout` dòng 158-263, gọi tại mq5:227 → **PASS (khi đó)**. `[v2.0]` đã xóa hoàn toàn. | PASS→REMOVED v2.0 |
| P0.3 | Entry_Mode 1/2/3 | Tại audit v1.3: mq5:219-228. `[v2.0]` đã xóa `Entry_Mode`. | PASS→REMOVED v2.0 |
| — | "compile 0 errors / 0 warnings" (Phase 1-8) | `tests/compile-*.log`: phase1..phase8, 7e, breakout, check đều `0 errors, 0 warnings` | **PASS (build log)** |
| — | EX5 hiện tại khớp source hiện tại | `RiskGuard.mqh` sửa lúc 11:34:24; compile log cuối `compile-check.log` lúc 11:31:14; EX5 lúc 11:31:14 | **FAIL** (binary cũ hơn source) |

---

## 2. Cây nguồn vs MASTER §2.1

MASTER §2.1 liệt kê: `Types, Inputs, SymbolSpecs, Logger, TrendFilter, EntryEngine, InitialStop, RiskManager, TradeExecutor, TrailingEngine, RiskGuard`. Thực tế `MQL5/Include/TM_EA/` có đúng 11 file này. **Khớp (PASS).**

`ARCHITECTURE.md` §5 gợi ý thêm `Indicators.mqh`, `NewsFilter.mqh`, `MarketGuards.mqh`, `PositionManager.mqh`, `DailyStats.mqh` — các file này **không tồn tại**; chức năng được gộp vào `InitialStop`, `RiskGuard`, `TradeExecutor`, `Logger`. Đây là sai lệch có chủ đích của bản release đầu (đã ghi trong implementation-status). **Ghi nhận, không phải lỗi.**

---

## 3. Canonical input table

### 3.1 `MASTER.md` §2.2 vs `Inputs.mqh`

Đối chiếu từng default: **khớp 100%** (Enabled, MagicNumber, TradeComment, Trend_Timeframe, FastEMA_HTF, SlowEMA_HTF, ADX_Period, ADX_Threshold, Entry_Timeframe, Entry_Mode, PullbackEMA, Pullback_Buffer_pips, ATR_Channel_Period, BreakoutK, Use_TP, Trail_ATR_Mult, Trail_ATR_Period, Activate_After_Profit_pips, Trail_Step_pips, Breakeven_After_pips, RiskPercentPerTrade, Min_Volume, Max_Volume, Max_Concurrent_Positions, Max_Daily_Loss_Percent, Max_Consecutive_Losses, CoolDown_Minutes, Max_Spread_Points, News_Enable, News_Buffer_Minutes, Use_Session_Filter). → **PASS**.

### 3.2 `SOURCE_SPEC_V1.md` §5 vs `Inputs.mqh` (SAI)

Spec nói cột "Giá trị mặc định" là default của code, nhưng 2 ô **không khớp**:

| Input | Spec "mặc định" | Code default | Preset baseline |
|---|---|---|---|
| `Max_Concurrent_Positions` | 2 | **1** | 1 |
| `Max_Daily_Loss_Percent` | 5.0 | **1.5** | 1.5 |

→ **FAIL**: canonical table trong `SOURCE_SPEC_V1.md` sai 2 ô so với code. Đã sửa default trong spec cho khớp code (xem CHANGELOG).

### 3.3 `ATR_Channel_Period`

Tại audit v1.3: dead (breakout dùng `Trail_ATR_Period`). `[v2.0]` `ATR_Channel_Period` cùng Breakout đã bị **xóa khỏi `Inputs.mqh`**.

---

## 4. Preset `config/sets/` vs MASTER

8 file preset tồn tại: `cost_stress_10000`, `realistic_200`, `realistic_500`, `small_50`, `small_100`, `standard_1000`, `conservative_5000`, `XAUUSD_M5_BASELINE_DRAFT_v1_0`.

| Preset | Entry_Mode | Risk% | Max_Spread | Ghi chú vs MASTER |
|---|---|---|---|---|
| `cost_stress_10000.set` | 3 | 0.5 | **350** | MASTER §5 Bước 1 ghi preset đặt `Max_Spread_Points=35` → **SAI**, file là 350 |
| `realistic_200.set` | 3 | **2.0** | 350 | README preset nói risk 1.5% → **SAI**, file là 2.0 |
| `realistic_500.set` | 3 | 1.0 | 350 | khớp README |
| `small_50.set` | 3 | **5.0** | 350 | MASTER §4.4 nói risk **10%** → **SAI**, file là 5.0 |
| `small_100.set` | 3 | 3.0 | 350 | — |
| `standard_1000.set` | 3 | 0.5 | 350 | — |
| `conservative_5000.set` | 3 | 0.25 | 350 | — |

**Lưu ý chung:** tất cả preset đều `Entry_Mode=3`, trong khi canonical default trong spec/MASTER là `Entry_Mode=1`. Không sai (preset được phép khác default) nhưng cần nhất quán tài liệu.

Không có file preset nào tên `baseline_10000` dù có folder report `TM_TFS_baseline_10000`. Report trong folder đó dùng input của `cost_stress_10000.set` (TradeComment `TM_TFS_STRESS`).

---

## 5. Reports `reports/backtests/` — bằng chứng thực tế

Số liệu trích trực tiếp từ HTML export.

| Report | Deposit | Risk% | Quality | Net | PF | Trades | BalDD | EqDD |
|---|---|---|---|---|---|---|---|---|
| `baseline_10000` .13.24 | 10 000 | 0.5 | **3% real ticks** | +1 509.49 | 2.45 | 878 | 1.35% | 2.21% |
| `cost_stress_10000` .13.30 | 10 000 | 0.5 | **98% real ticks** | +1 509.49 | 2.45 | 878 | 1.35% | 2.21% |
| `conservative_5000` .13.27 | 5 000 | 0.25 | 98% real ticks | +149.96 | 1.73 | 620 | 0.48% | 0.86% |
| `realistic_500` .13.17 | 500 | 1.0 | **3% real ticks** | +0.80 | 1.09 | 53 | 1.49% | 1.96% |
| `realistic_200` .13.36 | 200 | 2.0 | 98% real ticks | **−10.87** | **0.58** | 69 | 7.04% | 8.05% |
| `small_100` .13.41 | 100 | 3.0 | 98% real ticks | **−9.38** | **0.16** | 44 | 9.84% | 10.35% |
| `small_50` .13.50 | 50 | **8.0** (run) | 98% real ticks | **−10.86** | **0.15** | 47 | 22.23% | 22.57% |
| `small_50` .14.46 | **100** (misfiled) | 5.0 | 98% real ticks | **−50.92** | **0.14** | 159 | 51.27% | 51.76% |
| `standard_1000` .13.43 | 1 000 | 0.5 | 98% real ticks | **−7.14** | **0.31** | 54 | 0.90% | 1.24% |
| `tmp` small_50 .12.00 | **100** | 5.0 | **3% real ticks** | +66.85 | 1.39 | 647 | 18.27% | 23.97% |

### 5.1 Phát hiện nghiêm trọng — `cost_stress_10000` là bản sao của `baseline_10000`

So sánh nội dung 2 file HTML cho kết quả:
- 39 690 dòng text — **giống nhau đến từng dòng**, chỉ khác **duy nhất 1 dòng**: `History Quality` (baseline `3% real ticks` vs cost_stress `98% real ticks`).
- Cùng `Total Net Profit = 1 509.49`, `PF = 2.45`, `878 trades`, `1756 deals`, cùng DD.

Hai lần chạy khác nhau **không thể** trùng khít 878 lệnh và từng con số trong khi khác chất lượng tick. → Một trong hai report (hoặc cả hai) bị sao chép/chỉnh sửa thủ công. **Không thể dùng làm bằng chứng.**

### 5.2 MASTER §4 không phản ánh các kết quả thất bại

MASTER chỉ highlight baseline 10 000 (PF 2.45) và conservative (PF 1.73), **không** nêu:
- `realistic_200` PF 0.58 (lỗ), `realistic_500` PF 1.09 (gần hoà vốn),
- `standard_1000` PF 0.31 (lỗ), `small_100` PF 0.16 (lỗ), `small_50` PF 0.15 (lỗ).

→ MASTER tạo ấn tượng sai rằng chiến lược đã vượt stress-test, trong khi hầu hết preset vốn thực tế (200-1000 USD) **lỗ**.

### 5.3 Sai lệch số liệu MASTER §4.1/§4.3/§4.4

- §4.1 nói cost-stress dùng `Max_Spread_Points=350`; §4.4 caveat nói "Spread bị nới `Max_Spread_Points=10000`, tắt lọc tin". **Mâu thuẫn nội bộ.** File thực tế = 350 và News ON (nhưng vô hiệu trong tester).
- §4.3 gán report `tmp` cho "Vốn 100 USD" nhưng đặt nhãn folder `small_50`.
- §4.4 nói preset `small_50` đặt risk 10%; file = 5.0%. Lần chạy thực tế dùng risk 8.0%.
- §4.3 nói "Vốn 50 USD … Lỗ −10.86 (47 lệnh)" → khớp `small_50` .13.50 (nhưng risk run = 8.0%).

---

## 6. Vì sao các kết quả không phải bằng chứng chiến lược

1. **Kỳ test chỉ 3 tháng** (`2026.08.01 – 2026.10.31`) — spec §7.3 yêu cầu tối thiểu 6-12 tháng.
2. **Không có commission/slippage** trong model tester (commission = 0 các report).
3. **News_Enable vô hiệu trong tester** (TECHNICAL_AUDIT §6) → chưa từng test news filter.
4. **3% real ticks** ở `baseline_10000`, `realistic_500`, `tmp` — spec §7.1 cấm dùng dữ liệu sinh thay real tick.
5. **Chỉ 1 symbol (XAUUSDm)**, không có test độc lập EURUSD (spec §7.4).
6. **Không OOS / walk-forward.**
7. Mâu thuẫn report như §5.1.

---

## 7. Kết luận P0

| Mục | Trạng thái |
|---|---|
| Breakout tồn tại + được gọi | PASS (v1.3) → **REMOVED v2.0** |
| Entry_Mode 1/2/3 | PASS (v1.3) → **REMOVED v2.0** |
| Compile 0/0 (Phase 1-8) | PASS (build log) |
| EX5 khớp source | **FAIL** (binary cũ hơn `RiskGuard.mqh`) |
| MASTER §2.1 cây nguồn | PASS |
| MASTER §2.2 canonical inputs | PASS |
| SOURCE_SPEC §5 canonical inputs | **FAIL** (2 ô sai đã sửa) |
| Preset ↔ MASTER/README | **FAIL** (nhiều sai số liệu) |
| Report ↔ MASTER | **FAIL** (§5.1, §5.2, §5.3) |
| Tuyên bố "cost-stress PASSED" | **FAIL** — không có bằng chứng |
