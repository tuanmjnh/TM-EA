# Kế hoạch xây dựng & backtest 3 EA mới (Pine → MQL5)

**Ngày:** 2026-11-16 · Tài liệu nguồn: `pine/Wonderwhales.txt`, `pine/TM Indicator 2.txt`,
`docs/EA/Wonderwhales MT5 EA.md`, `docs/EA/TM INDICATOR 2.md`, `docs/EA/Scope Trendline Bollinger.md`.

---

## 1. Đánh giá nguồn & độ khả thi

| EA | Nguồn | Loại | Độ phức tạp | Rủi ro | Ưu tiên |
|---|---|---|---|---|---|
| **Wonderwhales** | pine (indicator, ~415 dòng) | PSAR flip / EMA cross / +ATR, xác nhận nến đóng; VSA chỉ để hiển thị | **Thấp** | Thấp — logic tín hiệu rõ ràng | **P1** |
| **Scope Trendline Bollinger (STB)** | spec (không có pine); demo `.ex5` | Bias D1+H1, BB + trendline M5, ATR trail, no TP, re-entry | **Trung bình** | Trendline auto-detect + "đồng thuận 2 tín hiệu vốn mâu thuẫn" | **P2** |
| **TM Indicator 2** | pine (rất lớn) | Regime, structure BOS/CHoCH, FVG/OB/S-R, sweep, MTF, BTC leader, dual score, 3 mode, TP1-3, BE/trail/time-decay | **Rất cao** | Rất cao — nhiều module, nguy cơ port sai | **P3** |

**Nguyên tắc chung (theo 3 spec):** port tín hiệu trước, `SignalOnly`/không gửi lệnh; chỉ dùng nến đã đóng; không tự thêm filter; mọi khác biệt ghi changelog; không tuyên bố lợi nhuận nếu chưa OOS.

---

## 2. Hạ tầng tái sử dụng (đã có sẵn từ TM-EA)

- Module: `SymbolSpecs.mqh`, `RiskManager.mqh` (size theo risk%), `TradeExecutor.mqh`, `Logger.mqh`, `InitialStop.mqh` (có thể tái dùng hàm SL).
- Runner headless: mẫu `tests/run_*.ps1` (sinh `.ini`, chạy `terminal64 /config`, copy CSV).
- EA tự dump CSV trong tester (không dựa vào `Report=` của MT5).
- Kỷ luật: real-tick (Model=4), IS/OOS + walk-forward, ghi report theo `<Bot>/<ngày>/<cấu hình>/`.
- Kết quả tham chiếu đã có: `TM_SessionBreakout` (H1) = ứng viên tốt nhất tới nay (3Y PF 1.666, DD 7.9%).

**Biên dịch & chạy:** `MetaEditor64.exe /compile` + `terminal64.exe /config` (đã xác minh chạy được; MT5 phải đóng).

---

## 3. PHA 1 — Wonderwhales EA (làm trước)

**Vì sao trước:** nhỏ nhất, tín hiệu rõ, kiểm chứng nhanh, cho "hướng" sớm.

**Phạm vi P1 (theo `Wonderwhales MT5 EA.md`):**
- Tín hiệu: `PSAR_REVERSAL`, `EMA_CROSSOVER`, `SAR_EMA`, `SAR_EMA_ATR`; `ConfirmOnBarClose=true`.
- PSAR: `iSAR` (step=max hay dùng; nếu `start != inc` thì tự tính hoặc ghi rõ).
- Chính sách vị thế: `ONE/OppositeIgnore`, `CLOSE_ON_OPPOSITE`, `CLOSE_AND_REVERSE`, `ALLOW_MULTIPLE`.
- SL: `NONE/FIXED_POINTS/ATR_MULTIPLE/PSAR_LEVEL`; TP: `NONE/FIXED_POINTS/RR_MULTIPLE`.
- Lot: `FIXED` hoặc `RISK_PERCENT`; spread/max trades/ngày; magic riêng.
- `SignalOnly=true` mặc định; bật trade sau khi đối chiếu tín hiệu.
- Log + CSV: time,mode,bar_close,sar,fast/slow ema,atr,raw_signal,valid_signal,block_reason,action,volume,sl,tp,retcode.
- VSA: chỉ hiển thị, **không** lọc tín hiệu (mặc định off).

**Backtest matrix (P1):**
| Biến | Giá trị test |
|---|---|
| Symbol | XAUUSDm (chính), EURUSDm (đối chứng) |
| TF | M5, M15, H1 |
| Mode | PSAR_REVERSAL, EMA_CROSSOVER, SAR_EMA, SAR_EMA_ATR |
| SL | ATR×1.5 / ATR×2.0 / ATR×2.5 |
| TP | NONE (PSAR flip đảo chiều) / RR 1.5 / RR 2.0 |
| Position policy | ONE(ignore opposite) / CLOSE_AND_REVERSE |
| Risk | 0.5–1% |

Quy trình: (1) compile; (2) SignalOnly đối chiếu số tín hiệu; (3) real-tick 1–2 năm + walk-forward; (4) chọn theo OOS PF/DD, không cherry-pick.

**Giao:** `MQL5/Experts/TM_Wonderwhales.mq5` (+.ex5), `.set` ở `config/sets/TM_Wonderwhales/`, report ở `reports/backtests/TM_Wonderwhales/`, mục trong CHANGELOG.

### 3.1 Kết quả P1 ban đầu (2026-11-16)
EA đã build (`TM_Wonderwhales.mq5`, compile 0/0). Test XAUUSDm M15, 1 năm real-tick, SL ATR2.0, TP RR2.0, risk 1%, dep 5000:

| Mode | Policy | Trades | Net | PF | DD% |
|---|---|---|---|---|---|
| EMA_CROSSOVER | close-and-reverse, no TP | 343 | +735.67 | **1.069** | **32.7** |
| EMA_CROSSOVER | one-ignore | 211 | −473.39 | 0.920 | 16.5 |
| PSAR_REVERSAL | mọi policy | 4–8 | −200…−340 | ~0.2 | ~6–8 |
| SAR+EMA / +ATR | — | 0–6 | — | — | — |

**Phát hiện:**
- **Bug parity PSAR:** chỉ **24 tín hiệu thô/năm** (phải hàng trăm) → `iSAR` (step/max) không khớp Pine `ta.sar(0.02,0.02,0.2)`. Cần tự tính PSAR hoặc kiểm tra lại buffer. Đây là điểm spec đã cảnh báo.
- **Mode EMA** chạy thật: PF 1.069 nhưng **DD 32.7% ≥ ngưỡng** → chưa đạt. Cần siết SL/trail, thêm phiên, hoặc đổi TF.
- Chưa EA nào của P1 tốt hơn `TM_SessionBreakout` (PF 1.666, DD 7.9%).

**Việc tiếp của P1:** sửa parity PSAR (tự tính PSAR theo Pine, đối chiếu); thử EMA mode trên H1 + có session/SL tighter; chỉ báo cáo khi có OOS.

### 3.2 Kết quả P1 sau khi sửa parity PSAR (2026-11-16)

Đã thay `iSAR` bằng **PSAR tự tính khớp Pine `ta.sar(0.02,0.02,0.2)`** (hàm `WwPSAR`). PSAR flip từ 24 tín hiệu/năm → hàng trăm. Kết quả XAUUSDm, 1 năm (2025.11–2026.10):

| TF | Mode | Policy | Trades | PF | DD% |
|---|---|---|---|---|---|
| M15 | PSAR | close-and-reverse, SL=PSAR | 424 | 1.061 | 21.5 |
| M15 | PSAR | close-and-reverse, SL=ATR2 | 2027 | 1.074 | 29.7 |
| M15 | PSAR | one-ignore, TP RR2 | 626 | 0.874 | 45.2 |
| **H1** | **PSAR** | **close-and-reverse, SL=PSAR** | **50** | **1.554** | **4.19** |
| H1 | SAR+EMA | close-and-reverse, SL=PSAR | 22 | 0.788 | 5.4 |

**Walk-forward (H1 PSAR close-and-reverse):**

| Cửa sổ | PF |
|---|---|
| W1 2023.11–2024.10 | 0.943 |
| W2 2024.11–2025.10 | 0.709 |
| W3 2025.11–2026.10 | 1.554 |
| **3Y** | **0.942** |

→ **Kết luận P1:** con số H1 PF 1.554 chỉ là **may mắn 1 năm (W3)**; cả 3 năm **PF 0.942 (âm)**. Wonderwhales **KHÔNG có edge bền vững** (giống EA trend cũ). DD cao trên M15.
**Quyết định:** dừng tối ưu WW; ghi nhận. Chuyển P2.

---

## 4. PHA 2 — Scope Trendline Bollinger (STB)

- 3 tầng: Bias (D1 EMA50/200 + ADX>20; H1 EMA20/50; phiên London/NY) → Signal (M5 BB20/2.0 + trendline 2 swing ≥5 nến) → Execution (market sau nến đóng, SL = swing/ATR×1.5, **no TP**, trail ATR×1.2 sau lời ≥1.0×ATR, re-entry khi bias còn).
- Inputs như §4 spec; switch bật/tắt phiên + re-entry để A/B.
- **Điểm khó:** trendline auto-detect (2 swing gần nhất) + quy tắc "đồng thuận BB+trendline" (BB vốn mean-reversion, trendline momentum) — implement đúng spec, ghi rõ giả định.
- Test matrix: XAUUSDm M5; bật/tắt session; bật/tắt re-entry; SL swing vs ATR; ≥1 năm + OOS. Ngưỡng spec: PF>1.3, DD<20%, ≥30 lệnh/tháng.
- Giao: `TM_ScopeTB.mq5`, set, report.

### 4.1 Kết quả P2 ban đầu (2026-11-16)
Đã build `TM_ScopeTB.mq5` (compile 0/0), runner `tests/run_stb.ps1`. Test XAUUSDm M5, 1 năm (2025.11–2026.10), risk 1%, SL ATR1.5, trail ATR1.2, no TP:

| Cấu hình | Trades | Net | PF | DD% |
|---|---|---|---|---|
| Session London/NY ON | 554 | −436.79 | 0.954 | 33.5 |
| Session OFF | 950 | +4.66 | 1.000 | 30.5 |

→ **PF ~0.95–1.00, DD 30%+ → không đạt.** Có thể do: (a) trendline auto-detect/quy tắc breakout còn mơ hồ (spec cũng cảnh báo BB vs trendline xung khắc); (b) tần suất cao trên M5 (≈2 lệnh/ngày) + trail ATR gây nhiễu. **Chưa tối ưu thêm** (ROI thấp). Kết luận: STB (bản đầu) **không có edge đạt gate**.

---

## 5. PHA 3 — TM Indicator 2 (lớn, chia nhỏ)

Thứ tự module (mỗi bước compile + test riêng):
1. Indicators + Regime (EMA/ATR/RSI/MACD/ADX/BBW).
2. Market structure (pivot/BOS/CHoCH/retest) + liquidity (PDH/PDL, session).
3. Zones (S/R, FVG, OB) — **sửa bug Pine**: S/R merof side, broken state, FVG-score theo khoảng cách.
4. Scoring LONG/SHORT độc lập + gates (blocker codes).
5. Entry modes A/B/C (+ limit/pullback).
6. Management: SL, TP1/2/3, partial, BE, trailing, time-decay, max-hold.
7. Persistence + netting/hedging + telemetry.
- Bắt buộc: parity bar-by-bar với Pine + ablation A–E; tách LONG/SHORT; tách regime/mode.
- Đây là dự án nhiều tuần; chỉ nên bắt đầu sau khi P1/P2 có kết luận.

---

### 3.3 P4 (phát sinh) — Mean-Revert scalper + đánh giá "scalp nhanh liên tục" (2026-11-16)
Vì yêu cầu "scalping nhanh liên tục", đã build `TM_MeanRevert.mq5` (BB20/2 + RSI cực trị + lọc range ADX, SL/TP ATR, M5). Kết quả 1 năm real-tick:

| Symbol | Trades | PF | DD% |
|---|---|---|---|
| EURUSDm (range filter) | 816 | 0.648 | **86.8** |
| XAUUSDm (range filter) | 767 | 0.855 | 53.7 |
| EURUSDm (no filter) | 1961 | 0.655 | **97.8** |

→ **Mean-reversion scalping = thảm họa** (DD 54–98%, PF < 1). Đúng như lý thuyết: MR đơn giản ngược xu hướng + chi phí dày.

**Kết luận về "scalp nhanh liên tục":** sau khi thử **trend / breakout / MR** trên vàng + EURUSD, **không bot nào phù hợp scalping nhanh** — tần suất cao luôn làm PF < 1 và DD cực lớn. Chỉ SB (1 lệnh/ngày) có edge.

## 6. Tiêu chí "hướng hợp lý" (gate chung)
- OOS **PF ≥ 1.3**, **MDD < 20%**, đủ mẫu (≥ ~100 lệnh OOS), và **dương ở ≥ 2/3 cửa sổ walk-forward**.
- Bền với phí (commission/slippage) và có plateau tham số (không đỉnh đơn).
- Nếu không EA nào đạt → ghi kết luận trung thực, không "làm đẹp số".

## 7. Rủi ro & chống overfit
- Dùng nến đã đóng; cấm nhìn tương lai.
- Không tối ưu trên toàn bộ dữ liệu; luôn walk-forward.
- MT5 chỉ có tick volume (không phải real volume) → VSA chỉ để tham khảo.
- PSAR `start != inc`: `iSAR` không đảm bảo parity với Pine → ghi rõ.
- Tốn thời gian: TM Indicator 2 rất lớn; ưu tiên ROI (Wonderwhales → STB → TM2).

## 8. Thứ tự thực thi đề xuất
**P1 Wonderwhales** (tuần này) → **P2 STB** → **P3 TM Indicator 2** (chia nhỏ).
