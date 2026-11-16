# TM-EA — Autonomous Research Log

**Ngày:** 2026-11-13 · **EA:** v2.3 `CA67C0BBFAC98E5B` (compiled 0/0)
**IS:** 2026.05.01–2026.07.31 · **OOS:** 2026.08.01–2026.10.31 · real-tick (Model=4) · commission=0
**Base:** deposit 500, risk 1%, Pullback+Breakout, no-TP, breakeven đã fix (BUG-013)
Mỗi vòng: giả thuyết → test → quyết định/pivot. Không áp dụng gì chỉ vì "đẹp trên IS".

---

## Round 0 — Baseline & sửa BUG-013
- **Kết quả:** preset v2.0 đều âm (PF 0.12–0.60). Tắt/gate breakeven → PF 0.155→0.897 (IS). *(chi tiết: OPTIMIZATION_STUDY.md)*
- **Pivot:** coi breakeven là lỗi cơ chế; chuyển sang trau chuốt trailing + entry.

## Round 1 — Thiên hướng giao dịch (long/short/both)
Giả thuyết: vàng 2026 tăng mạnh → long-only tốt hơn.

| dir | PF (IS) | Trades | DD% |
|---|---|---|---|
| both | 0.935 | 91 | 11.8 |
| **long-only** | **0.767** | 43 | 7.5 |
| short-only | 0.930 | 49 | 10.9 |

- **Kết quả:** long-only TỆ HƠN. Không có edge theo hướng.
- **Phát hiện phụ:** trail ATR ≥ 2.5 trên vốn $500 → **~0 lệnh** (SL rộng ⇒ volume < min-lot ⇒ bị skip). Vốn nhỏ giới hạn độ rộng trail.
- **Pivot:** bỏ hướng bias; thử tách SL khỏi trailing.

## Round 2 — Tách SL ban đầu khỏi trailing (`SL_ATR_Mult`)
Giả thuyết: SL chặt + trail rộng → R:R tốt hơn.

| SL×ATR / Trail×ATR | PF (IS) | Trades | DD% |
|---|---|---|---|
| 0.5 / 2.0 | 0.914 | 302 | **35.8** |
| 1.0 / 3.0 | 0.775 | 205 | 29.9 |
| 0.5 / 3.0 | 0.821 | 279 | **40.2** |

- **Kết quả:** không tăng PF; **DD tăng vọt 30–40%**.
- **Pivot:** giữ SL=1.0×ATR, trail=1.5×ATR (mức DD thấp nhất ~12%).

## Round 3 — Đổi khung thời gian
| Trend / Entry | PF (IS) | Trades | Ghi chú |
|---|---|---|---|
| M30 / M5 | 0.886 | 236 | DD 23% |
| M15 / M15 | 0.288 | 5 | quá ít lệnh |
| H1 / M5, H1 / M15 | — | 0 | **0 lệnh** (thiếu warmup EMA200 H1) |

- **Kết quả:** không cải thiện; H1 không chạy được trong tester (thiếu bar lịch sử).
- **Pivot:** giữ M15 trend / M5 entry.

## Round 4 — Symbol thứ hai (EURUSDm, spec §7.4)
| ADX | PF (IS) | Trades | DD% |
|---|---|---|---|
| 25 | 0.540 | 362 | 39.0 |
| 20 | 0.622 | 444 | 41.9 |
| 30 | 0.513 | 273 | 31.9 |

- **Kết quả:** EURUSDm **tệ hơn vàng** rõ rệt (PF 0.5–0.6, DD 32–42%).
- **Pivot:** không bê tham số vàng sang EURUSD; chiến lược không có edge ở cả 2 symbol.

---

## Round 5 — Định hướng A: lọc chất lượng entry (v2.4)
Giả thuyết: yêu cầu (i) **độ dốc EMA xu hướng** (`Use_EMA_Slope_Filter`) và/hoặc (ii) **nến pullback đóng trở lại qua EMA** (`Require_Close_Beyond_EMA`) để nâng chất lượng tín hiệu. Test với SL=1.5 (mốc tốt cũ).

| Cấu hình (IS) | Net | PF | Trades | DD% |
|---|---|---|---|---|
| base (no filter) | −11.15 | 0.935 | 91 | 11.79 |
| slope only | −11.15 | 0.935 | 91 | 11.79 (trơ) |
| **reclaim only** | **+5.71** | **1.047** | 67 | **7.87** |
| slope + reclaim | +5.71 | 1.047 | 67 | 7.87 |

**Kiểm chứng OOS:**

| OOS | Net | PF | Trades | DD% |
|---|---|---|---|---|
| base | −49.99 | 0.726 | 102 | 16.08 |
| reclaim | −36.62 | **0.699** | 67 | **10.66** |

- **Kết quả:** `reclaim` cải thiện IS (PF 0.935→1.047) và **giảm DD** (IS 11.8→7.9%, OOS 16.1→10.7%), nhưng **OOS vẫn < 1** (0.699). `slope` trơ (không đổi quyết định nào).
- **Đánh giá:** reclaim là **bộ giảm rủi ro tốt** (giảm DD rõ), nhưng **không tạo edge**. Lại là mẫu "dương IS – âm OOS".

## Round 6 — Định hướng B: scale-out (chốt một phần)
Giả thuyết: chốt 50% tại 1×ATR + thả phần còn lại → cải thiện kỳ vọng.

Phát hiện vận hành: trên vốn $500 (volume 0.01 = min lot), 50% = 0.005 → làm tròn 0 → partial **không chạy**. Phải test trên vốn $5000 (volume ~0.05).

| Cấu hình ($5000, IS) | Net | PF | Trades | largest_win | DD% |
|---|---|---|---|---|---|
| no partial | −356.63 | 0.861 | 347 | **151.37** | 11.21 |
| partial 1.0×ATR 50% | −398.88 | 0.845 | 488 | 75.69 | 10.84 |
| partial 1.5×ATR 50% | −472.23 | 0.813 | 432 | 75.69 | 11.94 |

- **Kết quả:** scale-out **làm giảm PF** (0.861→0.845→0.813) vì cắt mất các lệnh thắng lớn (151→75) — đúng cơ chế trend-following (lợi nhuận đến từ số ít winner lớn).
- **Đánh giá:** B **thất bại**. Mặc định `Use_Partial_Exit=false`.
- **Lưu ý:** D (R:R≥2 qua TP) là vô nghĩa vì TP gần như không bind trên real-tick (đã chứng minh ở v2.2).

## Kết luận sau 6 vòng (định hướng phát triển)

**Không thay đổi phương pháp nào trong khuôn khổ hiện tại tạo được edge bền vững.** Mọi biến thể đều PF 0.5–0.95:

1. Hướng (long/short): không giúp.
2. SL/trail: tăng DD, không tăng PF.
3. Timeframe: không giúp.
4. Symbol: EURUSD tệ hơn.
5. Tham số (ADX): dương IS nhưng gãy OOS (overfit) — đã bác bỏ.
6. Entry quality (`reclaim` nến đóng qua EMA): **giảm DD tốt** (11.8→7.9% IS, 16.1→10.7% OOS) nhưng PF vẫn gãy OOS — **không tạo edge**.
7. Scale-out (chốt 50% tại ATR): **làm giảm PF** (cắt winner lớn) — bác bỏ. (D/R:R qua TP vô nghĩa vì TP không bind.)

> **Tổng: 6 vòng, 0 phương pháp cho OOS PF ≥ 1.** Kết luận: kiến trúc hiện tại (HTF EMA/ADX + pullback/breakout + ATR trailing) **không có edge**. Cần đổi khái niệm chiến lược, không phải thêm tính năng.

**Chẩn đoán:** vấn đề nằm ở **khái niệm entry** (chỉ có ~40% win rate, R:R ~1, sau khi trailing/breakeven đã đúng). Vặn tham số không tạo ra edge.

**Định hướng đề xuất (cần thiết kế mới, không phải tuning):**
- A. **Entry chất lượng cao hơn:** yêu cầu xác nhận momentum (nến phá đỉnh/đáy trước), hoặc vùng pullback "đẹp" (hồi về EMA + nến nhấn), hoặc cấu trúc thị trường (higher-high/higher-low) — thay vì chỉ chạm EMA.
- B. **Exit có kế hoạch:** chốt một phần tại 1×ATR + trail phần còn lại (scale-out) để cải thiện kỳ vọng.
- C. **Regime filter:** chỉ giao dịch khi HTF có cấu trúc trend rõ (ví dụ EMA slope + ATR expansion), tránh sideway.
- D. **Quản lý theo R:** đảm bảo R:R mục tiêu ≥ 2 trước khi vào.

**Trạng thái:** chưa có cấu hình sinh lời → **không demo/tiền thật**. Bước tiếp theo nên là thiết kế lại entry (A/C), rồi lặp lại đúng quy trình IS/OOS này.
