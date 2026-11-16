# TM-EA — Session-Breakout H1 nghiên cứu (v3.0)

**Ngày:** 2026-11-15 · **EA:** `TM_SessionBreakout.ex5` SHA256[0:16]=`6056689F0723FDA8` (mq5 `1B849DBE158E4C89`), compiled `0/0` (v3.4: +Entry_TF, SL neo biên range, mặc định ADX20/RR5/frac1.0/H1)
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

## 3d. Độ nhạy chi phí (commission) — giải tích

Không model trực tiếp được commission trong tester (symbol Exness không cấu hình phí; `XAUUSDr` thiếu history). Thay vào đó tính từ **gross P/L** của run 3Y ADX20 RR5: gross profit **6550.10**, gross loss **−3933.71**, 111 lệnh. Giả sử mỗi lệnh chịu phí C: `PF = grossProfit / (|grossLoss| + 111·C)`.

| C/lệnh | $0 | $0.5 | $1 | $2 | $5 | $10 |
|---|---|---|---|---|---|---|
| PF | 1.665 | 1.642 | 1.619 | 1.576 | 1.459 | 1.299 |

→ **Rất bền với phí**: kể cả $10/lệnh PF vẫn 1.30. (Spread thật đã có trong tick data; commission vàng vốn nhỏ.)

## 3e. Dải range theo ATR — không giúp

Thêm input `Min/Max_Range_ATR` (đã test). 3Y ADX20 RR5:

| Lọc range | PF | Trades |
|---|---|---|
| none (baseline) | **1.665** | 111 |
| Max = 2.0×ATR (loại range lớn) | 1.394 | 78 |
| Min = 0.5×ATR | 1.666 | 111 (không bind) |
| band 0.5–2.0 | 1.394 | 78 |

→ Lọc "range quá lớn" **làm giảm PF** → không dùng. Giữ nguyên baseline.

## 3f. Tối ưu tập trung XAU (v3.3)

**Cửa sổ vào lệnh** (3Y, ADX20 RR5):

| Window | PF | Trades | DD% |
|---|---|---|---|
| 07–12 (London) | 0.775 | 103 | 20.3 |
| 08–14 | 0.844 | 112 | 20.7 |
| **07–20 (baseline)** | **1.665** | 111 | 7.9 |
| 07–16 | 1.590 | 115 | 10.6 |
| 12–20 (NY) | 1.771 | 95 | 6.1 |

NY nhỉnh hơn 3Y nhưng walk-forward **không thắng đều** (W1 1.26/W2 2.97/W3 1.24 so với baseline 1.03/2.69/1.50) → **không nhận**; giữ 07–20.

**SL = phần của range** (`SL_Range_Fraction`) — **đã sửa định nghĩa (xem cảnh báo dưới)**, 3Y ADX20 RR5:

| frac | PF | Trades | DD% |
|---|---|---|---|
| 0.5 | 1.412 | 170 | 16.9 |
| 0.75 | 1.329 | 118 | 18.6 |
| **1.0 (biên đối diện range)** | **1.666** | 111 | 7.9 |

→ **frac = 1.0 (SL = biên đối diện range) là tốt nhất.** Siết SL chỉ làm tăng DD.

> ⚠️ **Bug đã phát hiện & sửa:** lần thêm `SL_Range_Fraction` đầu tiên mình định nghĩa SL **theo entry** (`entry − frac×range`), khiến frac=1.0 bị **chặt hơn** biên range → 224 lệnh, PF sụp còn 0.997, và bảng frac cũ (1.25 "tốt") là **hiệu ứng của lỗi**, không phải tối ưu thật. Đã neo lại SL vào **biên range** (`rangeHigh − frac×rangeSize` cho BUY) và verify frac1.0 = PF 1.666.

**Khung nhỏ hơn / nhiều lệnh hơn** (3Y, ADX20 RR5, SL đúng):

| Cấu hình | PF | Trades | DD% |
|---|---|---|---|
| H1, 1 lệnh/ngày (baseline) | **1.666** | 111 | 7.9 |
| M30, 1 lệnh/ngày | 1.456 | 110 | 11.4 |
| M15, 1 lệnh/ngày | 1.217 | 112 | 14.6 |
| H1, **nhiều lệnh/ngày** | 0.964 | 109 | 20.9 |
| M30, nhiều lệnh/ngày | 1.196 | 116 | 18.2 |

→ **Nhiều lệnh hơn = tệ hơn** (lệnh breakout đầu ngày là lệnh tốt; vào thêm = hại). Khung nhỏ **không thêm lệnh** (do 1/ngày + cùng ngày breakout) mà chỉ đổi chất lượng → **H1 tốt nhất**.

**Kết luận tối ưu XAU:** **frac = 1.0**, H1, 1 lệnh/ngày. **Cấu hình chốt = range 00–07 · vào 07–20 · ADX≥20 · SL=range · RR=5 · risk 0.5–1% · vốn ≥$5000/Cent.** 3Y PF 1.666 / DD 7.9% / walk-forward 3/3 năm dương. Preset: `config/sets/TM_SessionBreakout/`.

## 3g. Tăng tần suất ("scalp nhiều hơn") — TẤT CẢ đều làm tệ đi (2026-11-16)

| Cách tăng tần suất | Trades (3Y) | PF | DD% |
|---|---|---|---|
| **Baseline** (H1, 1 lệnh/ngày) | **111** | **1.666** | **7.9** |
| Nhiều lệnh/ngày (close-and-reverse) | ~109–175 | 0.96 | 21 |
| TF nhỏ M30 (1/ngày) | 110 | 1.456 | 11.4 |
| TF nhỏ M15 (1/ngày) | 112 | 1.217 | 14.6 |
| TF nhỏ M5 (1/ngày) | 138 | 1.058 | 17.0 |
| **Thêm phiên 2** (Asia→LDN + LDN→NY) | 175 | **0.941** | **28.3** |
| Symbol khác: EURCADm | 111 | 0.391 | 47.9 |
| Symbol khác: USDCADm | 90 | 0.957 | 18.5 |

**Kết luận:** Edge của SB là **cụ thể** = breakout range phiên Á trong cửa sổ London/NY, **1 lệnh/ngày trên XAUUSDm**. Mọi cách tăng tần suất (multi/day, TF nhỏ, thêm phiên, đổi symbol) đều **phá PF và tăng DD gấp 2–4 lần**. ⇒ "Scalp nhiều để bào vốn" **phản tác dụng** trên vàng.

**Vì sao:** spread vàng (0.2–0.35) + edge mỏng mỗi lệnh → tăng số lệnh = tăng chi phí + whipsaw; lợi nhuận SB đến từ **số ít lệnh thắng lớn** (RR5), nên tăng tần suất chỉ thêm lệnh thua.

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
