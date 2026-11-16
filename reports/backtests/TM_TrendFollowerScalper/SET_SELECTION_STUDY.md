# TM-EA v2.0 — Set Selection Study (nghiên cứu chọn preset)

**Ngày:** 2026-11-13 · **EA:** v2.00 `0F50E9E0ADD72C90` · **Symbol:** XAUUSDm M5 · **Model:** 4 (real ticks)
**Cửa sổ:** 2026.05.01 – 2026.10.31 (6 tháng) · commission 0 · news filter vô hiệu trong tester
**Mục đích:** chọn `.set` hợp lý nhất dựa trên dữ liệu thực, không phỏng đoán.
**Tái lập:** `tests/run_backtest_v2.ps1 -Name r6_<set> -From 2026.05.01 -To 2026.10.31 ...`

## 1. Bảng xếp hạng 6 tháng real-tick (tất cả preset)

| Hạng | Set | Vốn | Net | PF | Trades | Max EqDD |
|---|---|---|---|---|---|---|
| 1 | `cost_stress_10000` | 10 000 | −1 837.85 | 0.305 | 1 640 | **20.10%** |
| 2 | `conservative_5000` | 5 000 | −331.85 | 0.230 | 968 | 6.72% |
| 3 | `realistic_200` | 200 | −15.52 | 0.220 | 88 | 8.30% |
| 4 | **`realistic_500`** | 500 | −14.00 | **0.215** | 70 | **4.33%** |
| 5 | `standard_1000` | 1 000 | −19.02 | 0.168 | 73 | **2.43%** |
| 6 | `baseline_1000` | 1 000 | −19.02 | 0.168 | 73 | 2.43% |
| 7 | `small_50` | 50 | −8.26 | 0.101 | 25 | 18.46% |
| 8 | `small_100` | 100 | −15.76 | 0.078 | 40 | 16.81% |

Đối chứng: `realistic_500` với **Use_TP=false** cho kết quả **y hệt** (−14.00 / PF 0.215 / DD 4.33%) → **trên real-tick, TP 1.5×ATR gần như không bind; bật/tắt TP không đổi kết quả.**

## 2. Kết luận nghiên cứu

1. **Không preset nào hợp lý để giao dịch.** 8/8 âm; PF 0.08–0.31; không đạt cổng PF ≥ 1.3.
2. **Lỗi nằm ở entry, không ở tiền vốn, không ở TP.** Vì TP on/off giống nhau ⇒ vấn đề là chất lượng tín hiệu **Pullback-only** (Breakout đã bị bỏ ở v2.0). Đây là bằng chứng trực tiếp rằng việc gỡ Breakout là nghi phạm chính.
3. **Nhóm vốn nhỏ (50/100 USD) tệ nhất về rủi ro:** DD 16.8–18.5% chỉ trong 6 tháng — đúng như tính toán "bẫy vốn nhỏ".
4. Các set khác nhau chủ yếu do **guard** (daily-loss/consec/cooldown) chặn bớt lệnh, không phải do edge tốt hơn.

## 3. Khuyến nghị chọn set

- **Để giao dịch thật: KHÔNG chọn set nào.** Không nạp vốn.
- **Least-bad / baseline nghiên cứu (nếu buộc phải chọn 1):**
  - Vốn nhỏ ($500, real): **`TM_TFS_realistic_500`** — PF cao nhất trong nhóm vốn nhỏ (0.215) và DD thấp (4.33%).
  - Ưu tiên an toàn / DD thấp nhất: **`TM_TFS_standard_1000`** (DD 2.43%).
  - **Tránh** `cost_stress_10000` (DD 20.1%) và nhóm `small_50/100` (DD 16–18%).
- **Nhưng cả hai vẫn lỗ** → chỉ dùng làm *mốc so sánh*, không dùng để chạy.

## 4. Việc cần làm trước khi có set "hợp lý"
1. **Khôi phục Breakout** (entry Pullback+Breakout như v1.3) rồi chạy lại đúng study này — đây là biến duy nhất có bằng chứng là khác biệt lớn.
2. Nếu sau đó vẫn âm → vấn đề sâu hơn ở entry/exit, cần thiết kế lại.
3. Chỉ khi 1 set đạt PF ≥ 1.3 sau cost-stress + OOS mới bàn vốn thật.

> Kết luận một dòng: **"Set hợp lý nhất" hiện tại không tồn tại.** Gần nhất là `realistic_500` (PF 0.215, DD 4.33%) nhưng vẫn lỗ; phải sửa entry (khôi phục Breakout) trước.
