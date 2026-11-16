# Kế hoạch Forward Demo + Lãi kép — TM_SessionBreakout

**Ngày:** 2026-11-16 · **EA:** `TM_SessionBreakout` (`config/sets/TM_SessionBreakout/`)
**Trạng thái:** SB là **ứng viên nghiên cứu tốt nhất** (3Y PF 1.666, DD 7.9%, walk-forward 3/3 năm dương).
**Mục tiêu:** xác nhận trên demo account rằng kết quả **khớp backtest** trước khi nghĩ tới tiền thật. Đây KHÔNG phải cam kết lợi nhuận.

---

## 1. Cấu hình đóng băng (frozen config)
| Thông số | Giá trị |
|---|---|
| EA | `TM_SessionBreakout.ex5` (chia sẻ binary trong MT5 `MQL5\Experts\`) |
| Symbol / TF | XAUUSDm / H1 |
| Preset | `TM_SB_XAUUSD_H1_BASELINE_v1_0.set` (real) hoặc `TM_SB_XAUUSD_H1_CENT_v1_0.set` (Cent) |
| Range phiên Á | 00:00–07:00 (server) |
| Cửa sổ vào | 07:00–20:00 (server) |
| Lọc | `Use_ADX_Filter=true`, `ADX_Min=20` |
| SL / TP | SL = biên đối diện range (`SL_Range_Fraction=1.0`); TP = RR5 |
| Tần suất | **1 lệnh/ngày** (`OneTradePerDay=true`, `Use_Session2=false`) |
| Risk | 0.5–1.0% / lệnh |

**Không đổi tham số trong suốt forward test.** Mọi thay đổi = dừng, ghi changelog, chạy lại từ đầu.

## 2. Tài khoản
- **Khuyến nghị (vốn nhỏ):** **Cent (USC)** — ví dụ Exness Cent, nạp **50 USD (= 5,000 USC)**. Min-lot vàng vừa risk ~1%.
- **Hoặc (vốn ≥ $5000):** tài khoản real/demo USD chuẩn.
- Loại: **hedging**, đòn bẩy ≥ 1:100, server Exness.

## 3. Lãi kép (compounding)
- EA tính volume = `balance × RiskPercent / 100` mỗi lệnh ⇒ **lãi kép tự động**: balance tăng → lot tăng tương ứng.
- **Giữ risk cố định 0.5–1%.** Không tăng risk sau chuỗi thắng (đó là martingale về mặt hành vi).
- **Quy tắc rút/gia hạn:** *không* rút trong 4 tuần demo; đánh giá lại cuối kỳ.
- Kỳ vọng toán (backtest): ~3–4 lệnh/tháng·… thực tế ~1 lệnh/ngày breakout ⇒ ~35–50 lệnh/năm; PF ~1.5–1.67. **Nếu khớp ≥80% kỳ vọng → cân nhắc tiền thật nhỏ.**

## 4. Giám sát hằng tuần (bắt buộc ghi)
Mỗi tuần ghi vào `reports/forward/TM_SessionBreakout/<YYYY-MM-DD>/`:
- Số lệnh, win/loss, gross profit/loss, PF, DD tuần, balance cuối tuần.
- **Spread thực lúc vào lệnh, slippage** (so với giả định backtest spread ~0.2–0.35).
- Số lần **news filter** chặn (trên demo filter chạy thật, khác tester).
- Lệch so với kỳ vọng backtest (số lệnh/tháng, PF).

Dùng template: `reports/forward/TM_SessionBreakout/_template.md`.

## 5. Tiêu chí DỪNG (stop) và ĐẠT (pass)
**DỪNG ngay nếu:**
- DD vượt **15%** (gần ngưỡng gate 20%), hoặc
- **10 lệnh thua liên tiếp** bất thường, hoặc
- PF forward sau **≥30 lệnh** < **1.0**, hoặc
- Lệch cấu trúc: EA không vào lệnh nhiều ngày liền do lỗi spread/min-lot/broker.

**ĐẠT (để bàn tiền thật nhỏ) nếu sau 4 tuần (≥ ~15–20 lệnh):**
- PF ≥ **1.3**, DD ≤ **20%**, số lệnh & PF khớp backtest trong biên hợp lý, slippage/spread không phá kỳ vọng.

## 6. Kiểm tra kỹ thuật trước khi bật
- [ ] MT5: **Allow Algo Trading** bật; EA không ở trạng thái lỗi.
- [ ] Đúng symbol/tài khoản; `MagicNumber` không trùng EA khác.
- [ ] Đã copy `.ex5` + `.set` vào terminal (Experts / Profiles\Tester).
- [ ] Đã xác nhận EA vào lệnh đúng 1 lần/ngày, SL đặt đúng biên range.
- [ ] Không chạy EA trend cũ trên cùng tài khoản/symbol.

## 7. Nhắc lại rủi ro
- Backtest còn **commission=0 + news filter vô hiệu** ⇒ số thực có thể xấu hơn.
- Mẫu nhỏ (~35–50 lệnh/năm); PF có thể dao động mạnh theo năm (W1 1.03 → W2 2.69).
- Không có EA nào đảm bảo; chỉ dùng tiền chấp nhận mất. **SB chưa được xác nhận cho tiền thật.**
