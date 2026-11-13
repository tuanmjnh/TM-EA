# TM-EA — VALIDATION RESULTS (P2)

**Ngày:** 2026-11-12
**Nguyên tắc:** `PASS` chỉ khi có bằng chứng chạy thực tế. Vì môi trường audit **không có MT5/MetaEditor**, các test cần runtime mang trạng thái `NOT RUN (BLOCKED: no MT5)`; phần logic được đối chiếu bằng **source trace** và ghi rõ `actual` là giá trị code sẽ tính (không phải kết quả chạy).

> 🔄 **v2.0 (2026-11-12):** Breakout đã bỏ → các test Breakout/Both **không còn áp dụng**. Thêm test Take Profit, circuit breaker, breakeven.

---

## P3 — BACKTEST THỰC THI (2026-11-13) — PASS có bằng chứng

Đã **compile** (`0 errors/0 warnings`) và **chạy real Strategy Tester headless**. Đây là bằng chứng runtime đầu tiên.

| Hạng mục | Kết quả | Trạng thái |
|---|---|---|
| Compile v2.0 | `tests/compile-v2.log` 0/0; EX5 `0F50E9E0ADD72C90` | **PASS** |
| Tester chạy được EA v2.0 (real ticks) | 3 tháng, 6 preset, CSV sinh ra | **PASS** |
| Take Profit áp dụng | TP0.2 khác TP1.5 (net −406.62 vs −410.00) | **PASS** (hoạt động) |
| TP có lợi không? | Model=1: no-TP PF 3.39 > TP1.5 2.47 > TP0.2 2.14 | **FAIL** (TP không giúp) |
| Chiến lược có lãi? | 6/6 preset âm (PF 0.12–0.60) | **FAIL** |
| Equity circuit breaker | chưa kích trong các run này (DD < 10%); chưa test riêng | `NOT RUN` |
| Model=4 `Use_TP` on/off | cho kết quả **y hệt** (TP 1.5 hiếm khi bind) | ghi nhận |
| Lệnh +203.77 bất biến theo TP | nghi gap real-tick, **chưa xác minh** | `SUSPECTED` |

Chi tiết: `reports/backtests/_v2/V2_BACKTEST_RESULTS.md`. Tái lập: `tests/run_backtest_v2.ps1`.

**Ghi chú phương pháp:** khóa `Report=` của MT5 không hoạt động ở `/config` → EA dump CSV riêng trong tester (`DumpTesterStats()`).

---

**Harness chạy được:** `tests/units/TM_EA_UnitTests.mq5` (Script MQL5). Cách chạy:
1. Copy file vào `MQL5/Scripts/TM_EA_UnitTests.mq5` (hoặc mở trực tiếp bằng MetaEditor — path include tương đối `../../MQL5/Include/...`).
2. F5 trên chart bất kỳ; đọc tab Experts. Kỳ vọng: `DONE: N passed, 0 failed`.

Hằng số dùng trong test (từ source, không phải giả định): pip = `point*10`; default `point=0.001`, `tick=0.001` (XAUUSDm, từ report).

---

## P4 — OPTIMIZATION STUDY (2026-11-13, v2.1)

| Hạng mục | Kết quả | Trạng thái |
|---|---|---|
| Fix breakeven (BUG-013) | tắt breakeven: PF 0.155 → **0.897**, largest_win 0.29 → 22.66 | **PASS** (cải thiện cơ chế) |
| Khôi phục Breakout | PF 0.914 → 0.932 | PASS (nhỏ) |
| Tối ưu ADX (IS) | PF đỉnh 1.083 @ ADX20 (IS 2026.05–07) | PASS (IS) |
| Tối ưu ADX (OOS) | PF 0.570–0.786 (2026.08–10) | **FAIL** (overfit — không áp dụng) |
| Chiến lược PF ≥ 1 bền vững | không đạt | **FAIL** |

**v2.2 — fix BUG-013 đã áp dụng & test:**

| Test | PF | Trạng thái |
|---|---|---|
| IS fix, no-TP | 0.935 | (fix hoạt động) |
| IS fix, TP1.5 | 0.935 | ≡ no-TP |
| OOS fix, no-TP | 0.726 | vẫn <1 |
| OOS fix, TP1.5 | 0.726 | ≡ no-TP |
| Gate: Breakeven_ATR_Mult 0.25/1.0/4.0 | 0.567 / 0.935 / 0.932 | gate đúng |

**Kết luận:** fix BUG-013 hiệu quả (không còn sụp PF); **bỏ TP là vô hại nhưng không tăng lãi** (TP 1.5 không bind trên real-tick); chiến lược **vẫn chưa sinh lời** — cần sửa edge entry. Chi tiết: `reports/backtests/_v2/OPTIMIZATION_STUDY.md` §5.

---

## P5 — RESEARCH ROUNDS 1–4 (v2.3, 2026-11-13)

| Vòng | Giả thuyết | Kết quả IS | Quyết định |
|---|---|---|---|
| 1 | long/short bias | long-only PF 0.767 < both 0.935 | Bác bỏ |
| 2 | tách SL khỏi trail | PF không tăng, DD 30–40% | Bác bỏ |
| 3 | đổi timeframe | không cải thiện; H1 = 0 lệnh | Bác bỏ |
| 4 | EURUSDm | PF 0.51–0.62, DD 32–42% | Bác bỏ |
| 5 | Entry quality (reclaim EMA) | IS PF **1.047** / OOS **0.699**; DD IS 11.8→7.9%, OOS 16.1→10.7% | Giữ như bộ **giảm DD**; không tạo edge |
| 6 | Scale-out (chốt 50% tại ATR) | PF 0.861→0.845→0.813; largest_win 151→75 | **Bác bỏ** — cắt winner lớn |

**Kết luận:** **6 vòng, 0 phương pháp cho OOS PF ≥ 1.** Kiến trúc hiện tại không có edge; cần đổi khái niệm chiến lược. `Require_Close_Beyond_EMA` giảm DD đáng kể (đáng giữ). Chi tiết: `reports/backtests/_v2/RESEARCH_LOG.md`.

---

## P6 — NEW STRATEGY: SESSION-BREAKOUT H1 (v3.0, 2026-11-13)

| Cấu hình | PF | DD% | Trạng thái |
|---|---|---|---|
| RR3 12M | 1.140 | 8.6 | PASS (12M) |
| RR5 3Y | 1.081 | 18.3 | PASS (3Y, nhưng DD cao) |
| RR6 3Y | 1.578 | 8.7 | PASS (3Y) |
| RR5 walk-forward | W1 0.849 / W2 2.023 / W3 1.763 | — | **PARTIAL** (phụ thuộc regime) |
| EURUSDm 3Y | 0.667 | 24.6 | **FAIL** |
| Vốn $500 | 0 lệnh (min-lot) | — | BLOCKED (cần ≥$5000 hoặc Cent) |
| **ADX20 RR5 3Y** | **1.665** | 7.9 | **PASS (3Y)** |
| **ADX20 walk-forward** | W1 **1.033** / W2 **2.692** / W3 **1.503** | — | **PASS (3/3 năm dương!)** |
| Plateau RR4/5/6 (ADX20, 3Y) | 1.445 / 1.665 / 1.680 | ~8 | PASS (plateau) |

**Đánh giá:** SB + lọc ADX(H1) là **kết quả ổn định nhất của dự án** — **3/3 năm walk-forward dương**, 3Y PF 1.665/DD 7.9%, plateau RR4–6. **Chưa xác nhận**: commission=0 (yếu tố quyết định), mẫu nhỏ, fail EURUSD, cần ≥$5000/Cent. Bước bắt buộc: test có phí. Chi tiết: `reports/backtests/_sb/SB_RESEARCH.md`.

---

## P2.1 Pullback BUY

- **Nguồn:** `EntryEngine::EvaluatePullback` dòng 112-132.
- **Input (trace):** `trendState=UP`; nến [1]: O=2000.00, H=2001.00, L=1999.00, C=2000.50; EMA20[1]=2000.00; `Pullback_Buffer_pips=2` → bufferPrice=0.02.
- **Điều kiện code:** `L <= EMA+buf` (1999.00 ≤ 2000.02 ✓) AND `C > O` (2000.50 > 2000.00 ✓).
- **Kỳ vọng:** valid, `direction=+1`, `setup=SETUP_PULLBACK`, `signalBarTime=bar[1].time`, `entryReference=C`, `invalidationLevel=L`.
- **Actual (source trace):** đúng như kỳ vọng; đồng thời ghi `m_lastSignalBarTime` chống trùng.
- **Trạng thái:** `NOT RUN (BLOCKED: no MT5)` — logic khớp khi đọc source.

## P2.2 Pullback SELL

- **Nguồn:** dòng 133-153.
- **Input:** `trendState=DOWN`; H=2001.00 ≥ EMA−0.02 ✓; `C<O` ✓.
- **Kỳ vọng:** valid, `direction=-1`, `invalidationLevel=H`.
- **Actual:** khớp (đối xứng). **Trạng thái:** `NOT RUN (BLOCKED)`.

## P2.3 Breakout BUY / P2.4 Breakout SELL / P2.5 Both mode — `[v2.0: KHÔNG CÒN ÁP DỤNG]`

- Breakout đã bị **xóa khỏi `EntryEngine.mqh`**; `Entry_Mode` đã bị xóa khỏi `Inputs.mqh`. Vì vậy các test Breakout và Both-mode **không còn tồn tại**. Ghi lại để bảo toàn lịch sử: tại audit v1.3, `EvaluateBreakout` **có** được gọi (mq5:227) và `m_lastSignalBarTime` dùng chung giữa Pullback/Breakout.
- **Trạng thái:** N/A (feature removed).

## P2.12 Take Profit (v2.0)

- **Nguồn:** `TM_TrendFollowerScalper.mq5` (khối tính `takeProfit`); `TradeExecutor::OpenBuy/OpenSell`.
- **Input:** `Use_TP=true`, `TP_ATR_Mult=1.5`, ATR=2.0, entry=2000.000.
  - BUY (direction=+1): TP = 2000 + 1*1.5*2.0 = **2003.000** (trên entry ✓).
  - SELL (direction=−1): TP = 2000 + (−1)*1.5*2.0 = **1997.000** (dưới entry ✓).
- **Kỳ vọng:** TP luôn đúng phía. **Actual (trace):** khớp. **Trạng thái:** `NOT RUN (BLOCKED)`.

## P2.13 Equity circuit breaker (v2.0)

- **Nguồn:** `RiskGuard::EquityDrawdownPercent/EquityBreakerTripped/TripEquityBreaker`; `OnTick` khối breaker; `TradeExecutor::CloseAllPositions`.
- **Input:** baseline=1000, equity=895, `Max_Equity_DD_Percent=10.0` → DD=10.5% ≥ 10% → kỳ vọng: đóng hết vị thế + set breaker flag (persist) + khóa mở mới tới hết ngày.
- **Actual (trace):** khớp logic; flag lưu GlobalVariable `TM_EA_EquityBreakerDay_*`. **Trạng thái:** `NOT RUN (BLOCKED)`.

## P2.14 Breakeven hợp lệ (BUG-010, v2.0)

- **Nguồn:** `TrailingEngine.mqh` nhánh breakeven.
- **Input BUY:** openPrice=2000.30, spread=0.30, bid=2000.38 (lãi 0.08). Code cũ: SL=2000.60 > bid → sai phía. Code mới: 2000.60 ≥ bid → clamp `openPrice`=2000.30 (< bid → hợp lệ).
- **Input SELL:** openPrice=2000.00, spread=0.30, ask=1999.92. Code cũ: SL=1999.70 < ask → sai phía. Code mới: 1999.70 ≤ ask → clamp `openPrice`=2000.00 (> ask → hợp lệ).
- **Kỳ vọng:** SL hợp lệ, không khóa lỗ. **Actual (trace):** khớp. **Trạng thái:** `NOT RUN (BLOCKED)`.

## P2.6 Trend state

- **Nguồn:** `TrendFilter::Refresh` dòng 143-157.
- **Input A:** Fast=2010 > Slow=2000; ADX=30 > 25; close=2011 > Fast → **UP**.
- **Input B:** Fast=1990 < Slow=2000; ADX=30; close=1989 < Fast → **DOWN**.
- **Input C:** ADX=20 (≤25) → **NONE (sideways)**.
- **Kỳ vọng:** A=UP, B=DOWN, C=NONE. **Actual:** khớp. **Trạng thái:** `NOT RUN (BLOCKED)`.

## P2.7 SL calculation

- **Nguồn:** `CInitialStop::CalculateBuySL/CalculateSellSL`.
- **Input:** entry=2000.000, invalidation=1999.000, atr=1.0, mult=2.0, point=0.001, tick=0.001, stopLevel=0.
- **Kỳ vọng BUY:** `max(1.0, 2.0)=2.0` → SL=1998.000. **SELL:** 2002.000.
- **Input stopLevel=500:** SL bị kéo tối thiểu 0.5 → BUY=1999.500.
- **Input invalidation sai phía:** trả 0.0.
- **Actual:** đúng các công thức trên (đã mã hoá thành assert trong `TM_EA_UnitTests.mq5` §TestBuySL/TestSellSL).
- **Trạng thái:** `NOT RUN` — harness sẵn sàng chạy trên MT5.

## P2.8 Trailing monotonicity

- **Nguồn:** `TrailingEngine::Update`.
- **BUY:** `if(newSL <= currentSL) continue;` (dòng 93) → **không bao giờ hạ SL**. SELL: `if(currentSL>0 && newSL>=currentSL) continue;` (dòng 125) → **không bao giờ nâng SL**.
- **Bước tối thiểu:** BUY `if(currentSL>0 && (newSL-currentSL)<step) continue;` (dòng 95) → tránh spam.
- **Breakeven:** chỉ khi `profitDistance >= breakevenDistance`, đặt SL = open ± spread.
- **Kỳ vọng:** SL đơn điệu theo hướng bảo vệ. **Actual:** khớp. **Cần runtime:** kiểm tra với vị thế thật. **Trạng thái:** `PASS (static)` / `NOT RUN (runtime)`.

## P2.9 Volume rounding

- **Nguồn:** `RiskManager::CalculateVolume` dòng 66-84.
- **Kỳ vọng:** `volume = riskMoney / lossPerLot`, `floor(volume/step)*step`; nếu `< volumeMin` → trả 0; nếu `loss(volumeMin) > riskMoney` → trả 0 ("minimum lot exceeds risk cap"); cap ở `Max_Volume`.
- **Input minh hoạ:** riskMoney=1.0, lossPerLot(1.0 lot)=250 → volume=0.004 → floor về 0.0 → `< min` → trả 0.
- **Input minh hoạ 2:** riskMoney=1.0, loss(volumeMin=0.01)=2.5 > 1.0 → trả 0 ("minimum lot exceeds risk cap").
- **Input minh hoạ 3:** riskMoney=5.0, lossPerLot=250 → 0.02 → floor step 0.01 → 0.02.
- **Actual:** công thức đúng. **Trạng thái:** `NOT RUN` — harness `TestVolumeRounding()` cần symbol data.

## P2.10 RiskGuard

- **Nguồn:** `RiskGuard::CanOpenNewEntry`.
- **Kỳ vọng:** chặn khi cooldown active / daily loss / spread / session / news (live) / margin.
- **Actual (trace):** thứ tự đúng; news no-op trong tester (BUG-004); margin dùng Min_Volume (BUG-008).
- **Trạng thái:** `NOT RUN (BLOCKED)` — cần tester + calendar thật.

## P2.11 State recovery

- **Nguồn:** `RiskGuard` GlobalVariables + `m_lastProcessedDeal`.
- **Kỳ vọng:** baseline/cooldown/consecutive-loss persist qua restart; bộ đếm không đếm trùng.
- **Actual:** baseline/cooldown/consecutive **persist** (PASS static); `m_lastProcessedDeal` **không persist** → đếm trùng (BUG-003, FAIL static).
- **Trạng thái:** `FAIL (static)`, runtime `NOT RUN`.

---

## Tổng hợp P2

| Test | Trạng thái |
|---|---|
| Pullback BUY / SELL | NOT RUN (BLOCKED: no MT5) |
| Breakout BUY / SELL | N/A — **removed in v2.0** |
| Both mode | N/A — **removed in v2.0** |
| Trend state | NOT RUN (BLOCKED) |
| SL calculation | NOT RUN — harness sẵn sàng |
| Trailing monotonicity | PASS (static) / NOT RUN (runtime) |
| Volume rounding | NOT RUN — harness sẵn sàng |
| RiskGuard | NOT RUN (BLOCKED) |
| State recovery | **FAIL (static)** — BUG-003 (vẫn mở) |
| Take Profit đúng phía (v2.0) | NOT RUN (BLOCKED) |
| Equity circuit breaker (v2.0) | NOT RUN (BLOCKED) |
| Breakeven hợp lệ (v2.0) | NOT RUN (BLOCKED) |

**Không test nào đạt PASS-runtime trong lần audit này.** Đây là thực trạng trung thực: cần chạy `tests/units/TM_EA_UnitTests.mq5` trên MT5 và bổ sung bước "synthetic-bar" trong Strategy Tester để phủ Pullback/Breakout/Trend.
