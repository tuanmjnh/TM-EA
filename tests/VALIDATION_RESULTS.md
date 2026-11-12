# TM-EA — VALIDATION RESULTS (P2)

**Ngày:** 2026-11-12
**Nguyên tắc:** `PASS` chỉ khi có bằng chứng chạy thực tế. Vì môi trường audit **không có MT5/MetaEditor**, các test cần runtime mang trạng thái `NOT RUN (BLOCKED: no MT5)`; phần logic được đối chiếu bằng **source trace** và ghi rõ `actual` là giá trị code sẽ tính (không phải kết quả chạy).

**Harness chạy được:** `tests/units/TM_EA_UnitTests.mq5` (Script MQL5). Cách chạy:
1. Copy file vào `MQL5/Scripts/TM_EA_UnitTests.mq5` (hoặc mở trực tiếp bằng MetaEditor — path include tương đối `../../MQL5/Include/...`).
2. F5 trên chart bất kỳ; đọc tab Experts. Kỳ vọng: `DONE: N passed, 0 failed`.

Hằng số dùng trong test (từ source, không phải giả định): pip = `point*10`; default `point=0.001`, `tick=0.001` (XAUUSDm, từ report).

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

## P2.3 Breakout BUY

- **Nguồn:** `EntryEngine::EvaluateBreakout` dòng 217-238.
- **Input:** `trendState=UP`; close[1] > prevHigh[2] + k*ATR ✓; EMA[1] > EMA[2] (slope up) ✓; close>open ✓.
- **Kỳ vọng:** valid, `setup=SETUP_BREAKOUT`, `direction=+1`.
- **Actual:** khớp. **Lưu ý:** `atrValue` truyền vào là ATR(`Trail_ATR_Period`) chứ không phải `ATR_Channel_Period` (BUG-001).
- **Trạng thái:** `NOT RUN (BLOCKED)`.

## P2.4 Breakout SELL

- **Nguồn:** dòng 239-260. Đối xứng: `close < prevLow − k*ATR`, EMA slope down, close<open.
- **Kỳ vọng:** valid, `direction=-1`. **Actual:** khớp. **Trạng thái:** `NOT RUN (BLOCKED)`.

## P2.5 Both mode (Entry_Mode=3)

- **Nguồn:** `TM_TrendFollowerScalper.mq5` dòng 219-228.
- **Input:** `Entry_Mode=3`; pullback không hợp lệ; breakout hợp lệ.
- **Kỳ vọng:** ưu tiên Pullback trước; nếu invalid → thử Breakout → vào lệnh khi Breakout valid.
- **Actual (source trace):** đúng thứ tự (Pullback → Breakout). **Cảnh báo:** cùng dùng chung `m_lastSignalBarTime`; nếu Pullback valid nhưng bị chặn ở bước volume/max-position phía sau, Breakout **không** được thử lại cho cùng nến đó.
- **Trạng thái:** `NOT RUN (BLOCKED)`.

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
| Breakout BUY / SELL | NOT RUN (BLOCKED) |
| Both mode | NOT RUN (BLOCKED) |
| Trend state | NOT RUN (BLOCKED) |
| SL calculation | NOT RUN — harness sẵn sàng |
| Trailing monotonicity | PASS (static) / NOT RUN (runtime) |
| Volume rounding | NOT RUN — harness sẵn sàng |
| RiskGuard | NOT RUN (BLOCKED) |
| State recovery | **FAIL (static)** — BUG-003 |

**Không test nào đạt PASS-runtime trong lần audit này.** Đây là thực trạng trung thực: cần chạy `tests/units/TM_EA_UnitTests.mq5` trên MT5 và bổ sung bước "synthetic-bar" trong Strategy Tester để phủ Pullback/Breakout/Trend.
