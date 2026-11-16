# TM-EA — Optimization Study (v2.1)

**Ngày:** 2026-11-13 · **EA:** v2.1 `60B7454806D2C85A` (Breakout khôi phục, có switch `Use_Breakout`)
**Symbol/TF:** XAUUSDm M5 · **Model:** 4 (real ticks) · **commission = 0**
**IS:** 2026.05.01–2026.07.31 · **OOS:** 2026.08.01–2026.10.31
**Base:** deposit 500, risk 1.0%, no-TP, pullback(+breakout) · tái lập: `tests/run_backtest_v2.ps1`

## 1. Phát hiện lớn nhất — lỗi logic breakeven (BUG-013)

Breakeven hiện dời SL về `openPrice` khi lãi đạt `Breakeven_After_pips` (mặc định 4–10 "pips" = **0.04–0.10 giá**). Trên vàng spread ~0.20–0.35, nên SL bị kéo về entry **quá sớm** → mọi lệnh thắng bị quét ở ~entry; lệnh thua vẫn chạy hết SL.

| Cấu hình (IS, atr2.0, no-TP) | Net | PF | largest_win |
|---|---|---|---|
| base: act4 step2 be8 | −5.11 | 0.155 | **0.29** |
| be40 | −14.95 | 0.221 | 0.30 |
| be80 | −21.58 | 0.120 | 0.35 |
| **be OFF (9999), act10 step5** | −3.39 | **0.897** | **22.66** |

→ Tắt breakeven: **PF 0.155 → 0.897**, largest_win **0.29 → 22.66**. Đây là **fix cơ chế thật**, không phải tuning đường cong.

## 2. Khôi phục Breakout — lợi ích nhỏ (IS, atr1.5, be OFF)

| Entry (IS) | Net | PF | Trades |
|---|---|---|---|
| Pullback only | −13.90 | 0.914 | 77 |
| Pullback + Breakout | −11.79 | **0.932** | 86 |

## 3. Tuning tham số — DƯƠNG trên IS nhưng GÃY trên OOS (overfit)

Bản đồ ADX (IS, atr1.5, be OFF, both):

| ADX | 15 | 18 | **20** | 22 | 25 | 30 | 35 |
|---|---|---|---|---|---|---|---|
| PF (IS) | 1.024 | 1.040 | **1.083** | 1.014 | 0.932 | 0.831 | 0.503 |
| Trades | 197 | 183 | 166 | 123 | 86 | 61 | 40 |

IS cho PF > 1 (đẹp). **Kiểm chứng OOS (Aug–Oct):**

| ADX | Net (OOS) | PF (OOS) | DD |
|---|---|---|---|
| 18 | −74.97 | 0.624 | 16.96% |
| 20 | −77.71 | **0.570** | 17.50% |
| 22 | −45.32 | 0.786 | 16.49% |

→ **Kết quả IS dương KHÔNG sống sót OOS.** ADX=20: PF 1.083 (IS) → 0.570 (OOS). Đây là **overfit / phụ thuộc chế độ thị trường**, KHÔNG được áp dụng.

## 4. Kết luận

1. **Áp dụng (a):** fix lỗi breakeven (BUG-013) — chuyển cơ chế từ tự-hủy sang mức ~hòa vốn (PF ~0.9). Đây là cải thiện thật.
2. **Không áp dụng:** các giá trị ADX/entry tối ưu trên IS (gãy OOS).
3. **Trạng thái chiến lược:** kể cả với fix breakeven, vẫn **PF < 1** → **chưa sinh lời**, chưa đủ điều kiện demo/tiền thật. Không đạt cổng PF ≥ 1.3.
4. **Hướng đúng tiếp theo:** thiết kế lại **edge vào lệnh** (không phải tinh chỉnh tham số), và sửa BUG-002/003 trước.

> Một dòng: fix breakeven là thắng lợi kỹ thuật thật (PF ×6); còn "tối ưu tham số để tăng lãi" đã **thất bại kiểm chứng OOS** — trung thực ghi nhận, không dùng.

## 5. BUG-013 FIX đã áp dụng và test (v2.2)

**Fix:** thêm input `Breakeven_ATR_Mult` (default 1.0). Breakeven chỉ kích hoạt khi lãi ≥ `max(Breakeven_After_pips × pip, Breakeven_ATR_Mult × ATR)` — chặn việc dời SL về entry khi lãi nhỏ hơn nhiễu/spread. EX5 `07ED385A5D67E86E`, compile `0/0`.

Config test: vốn 500, risk 1%, Pullback+Breakout, `Trail_ATR_Mult=1.5`, act10 step5, ADX25.

| Test | Net | PF | Trades | largest_win | DD% |
|---|---|---|---|---|---|
| **IS** fix, **no-TP** | −11.15 | 0.935 | 91 | 25.23 | 11.79 |
| **IS** fix, **TP 1.5** | −11.15 | 0.935 | 91 | 25.23 | 11.79 |
| **OOS** fix, **no-TP** | −49.99 | 0.726 | 102 | 19.10 | 16.08 |
| **OOS** fix, **TP 1.5** | −49.99 | 0.726 | 102 | 19.10 | 16.08 |

**Kiểm chứng gate hoạt động (IS):** `Breakeven_ATR_Mult` 0.25 → PF **0.567**; 1.0 → 0.935; 4.0 (≈tắt) → 0.932. ⇒ gate đúng và **breakeven chỉ làm hại** trong chiến lược này; tốt nhất là tắt (mult ≥ 1.0).

**Kết luận §5:**
1. Fix hoạt động: không còn sụp PF về 0.15; nay IS ~0.94 / OOS ~0.73.
2. **No-TP ≡ TP1.5 trên real-tick** (TP 1.5 gần như không bao giờ được chạm) → bỏ TP **vô hại** và đúng thiết kế gốc; không phải đòn bẩy lãi.
3. **Vẫn PF < 1** ⇒ chiến lược chưa sinh lời; nguyên nhân còn lại là **edge vào lệnh**, không phải TP/breakeven.
