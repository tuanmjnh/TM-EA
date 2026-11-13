# TM-EA — Session-Breakout H1 nghiên cứu (v3.0)

**Ngày:** 2026-11-13 · **EA:** `TM_SessionBreakout.ex5` SHA256[0:16]=`4E23415AEAE1E96C` (mq5 `2F6366134025BE3A`), compiled `0/0` (v3.1: +lọc ADX, mặc định ADX20/RR5)
**Ý tưởng:** phá biên range phiên Á (00:00–07:00 server) tại London/NY; **1 lệnh/ngày**; SL = biên đối diện range; **TP = RR × risk**.
**Symbol:** XAUUSDm H1 · Model=4 real-tick · commission=0 · tái lập: `tests/run_breakout.ps1`

> Vì sao đổi: chiến lược cũ (EMA/ADX + pullback/breakout + ATR trailing) đã thua ở **6/6 vòng nghiên cứu** (OOS PF < 1). SB là khái niệm khác: edge kỳ vọng từ **volatility expansion theo phiên**, tần suất thấp (1 lệnh/ngày) → hợp tài khoản nhỏ (ít chi phí).

## 1. Kết quả chính (XAUUSDm, deposit 5000, risk 1%)

| Cấu hình | Khoảng | Net | PF | Trades | Wins | DD% |
|---|---|---|---|---|---|---|
| RR2 | 12M | −179.21 | 0.890 | 53 | 18 | 8.9 |
| RR3 | 12M | +228.15 | 1.140 | 48 | 15 | 8.6 |
| RR4 | 12M | +296.79 | 1.188 | 44 | 11 | 10.1 |
| RR5 | 12M | +1125.07 | **1.763** | 41 | 12 | 6.2 |
| RR5 | **3Y** | +349.94 | **1.081** | 130 | 26 | 18.3 |
| RR6 | **3Y** | +2286.81 | **1.578** | 99 | 23 | 8.7 |
| RR10 | **3Y** | +1775.38 | 1.786 | 58 | 11 | 12.7 |
| RR5, range 0–6 | 3Y | +1010.89 | 1.218 | 137 | 28 | 13.8 |
| RR5, **EURUSDm** | 3Y | −800.59 | 0.667 | 63 | 8 | 24.6 |

**Nhận xét:** RR cao (≥3) có PF > 1 trên 12M và 3Y. RR2 không đủ. EURUSDm **thất bại** → đặc thù vàng.

## 2. Walk-forward (RR5, 3 cửa sổ 1 năm rời nhau) — ĐIỂM QUAN TRỌNG

| Cửa sổ | Net | PF | Trades | Wins | DD% |
|---|---|---|---|---|---|
| W1 2023.11–2024.10 | −223.93 | **0.849** | 53 | 9 | 12.5 |
| W2 2024.11–2025.10 | +1037.41 | **2.023** | 34 | 10 | 6.3 |
| W3 2025.11–2026.10 | +1125.07 | **1.763** | 41 | 12 | 6.2 |

→ **Không ổn định qua năm:** âm ở W1, dương mạnh W2/W3. **Phụ thuộc chế độ thị trường** (các năm vàng trend mạnh thì thắng). RR6 W2: PF 2.744 (24 trades).

## 3. Ràng buộc vốn nhỏ (như đã cảnh báo)

- Vốn $500: **0 lệnh** — SL theo range (rộng) × min-lot vượt risk cap → `minimum lot exceeds risk cap`.
- Vốn $2000: chỉ 2 lệnh. Cần **≥ ~$5000** để range-SL vừa risk 1% trên vàng → hoặc **tài khoản Cent**.

## 3b. Bộ lọc regime (ADX H1) — bước cải thiện quyết định

Thêm điều kiện ADX(H1) ≥ ngưỡng tại lúc breakout (mặc định bật, `ADX_Min=20`).

**3Y (XAUUSDm, RR5):**

| Lọc | Net | PF | Trades | DD% |
|---|---|---|---|---|
| không ADX | +349.94 | 1.081 | 130 | 18.3 |
| **ADX20** | **+2694.84** | **1.665** | 111 | **7.9** |
| ADX25 | +398.65 | 1.109 | 109 | 16.3 |
| ADX30 | +2828.27 | 1.746 | 103 | 8.2 |

**Walk-forward với ADX20 RR5 (điểm mấu chốt):**

| Cửa sổ | PF (không lọc) | PF (ADX20) |
|---|---|---|
| W1 2023.11–2024.10 | 0.849 | **1.033** |
| W2 2024.11–2025.10 | 2.023 | **2.692** |
| W3 2025.11–2026.10 | 1.763 | **1.503** |

→ **Bộ lọc ADX đã sửa được năm âm W1** — **cả 3 năm đều PF > 1** (lần đầu trong cả dự án).

**Plateau RR (ADX20, 3Y):** RR4 **1.445** / RR5 **1.665** / RR6 **1.680**, DD ~8% → **plateau rộng**, không phải spike đơn lẻ. (ADX25 RR4 = 1.138/DD 20% → kém hơn.)

## 3c. Cấu hình đề xuất (SB v3.1)

`XAUUSDm H1` · range phiên Á `00:00–07:00` · cửa sổ vào `07:00–20:00` · **1 lệnh/ngày**
· `Use_ADX_Filter=true`, `ADX_Min=20` · **RR = 4–6 (chọn 5)** · Risk 0.5–1%/lệnh
· Vốn: **≥ ~$5000 real, hoặc tài khoản Cent**.

## 4. Đánh giá trung thực

**Ưu điểm:** **lần đầu có PF > 1 ở CẢ 3 năm walk-forward** (ADX20 RR5: W1 1.03 / W2 2.69 / W3 1.50); plateau RR rộng (4–6 cho 1.44–1.68); DD thấp (~8%); rất ít lệnh (~1/tuần) → hợp vốn nhỏ về chi phí.
**Nhược điểm / rủi ro:**
- **Mẫu nhỏ** (28–49 lệnh/năm, ~10–30 lệnh thắng) → PF cao vẫn dễ chịu ảnh hưởng vài lệnh lớn.
- **Thất bại trên EURUSDm** (PF 0.667) → đặc thù vàng, chưa tổng quát.
- **Commission = 0** trong toàn bộ test → thực tế sẽ bào mòn (win rate ~20%, gánh bởi vài lệnh lớn).
- ADX/RR được chọn trên chính dữ liệu 3Y (mitigate bằng plateau + nhất quán từng năm, nhưng vẫn là rủi ro overfit).
- Range-SL rộng → cần vốn ≥ $5000 (hoặc Cent) mới vừa risk 1%.

**Kết luận:** SB + lọc ADX là **kết quả mạnh và ổn định nhất của cả dự án** — 3/3 năm dương, DD ~8%, plateau RR. **Nhưng CHƯA được xác nhận**: cần **commission/slippage thật** (yếu tố quyết định), thêm symbol, và giám sát forward. **Chưa đủ điều kiện tiền thật; bước tiếp bắt buộc là test có phí.**

## 5. Đề xuất tiếp theo
1. Bật commission/slippage thật trong tester (nếu broker hỗ trợ trong model) — xem PF còn > 1 không.
2. Chọn RR theo **plateau** (RR4–6 dùng chung), không cherry-pick.
3. Thêm bộ lọc regime (chỉ trade khi ADX/ATR H1 đủ mạnh) để tránh năm sideway (W1).
4. Thử Cent account để hạ yêu cầu vốn.
