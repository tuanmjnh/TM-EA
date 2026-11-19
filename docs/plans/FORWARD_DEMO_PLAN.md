# Kế hoạch Forward Demo + Lãi kép — TM_SessionBreakout (v4.4 Update)

**Ngày cập nhật:** 2026-11-19 (v4.4) · **EA:** `TM_SessionBreakout` (`MQL5/Experts/TM_SessionBreakout.mq5`)  
**Trạng thái:** SB là **ứng viên duy nhất có bằng chứng thống kê 3 năm** (3Y PF 1.666, DD 7.9%, walk-forward 3/3 năm dương theo `docs/MASTER.md`).  
**Mục tiêu:** Sửa dứt điểm lỗi không vào lệnh (GMT lệch + log im lặng) và xác nhận trên tài khoản Demo Exness rằng lệnh xuất hiện đúng kỷ luật trước khi tính đến tiền thật. Đây KHÔNG phải cam kết lợi nhuận.

---

## 1. Cấu hình đóng băng (frozen config)
| Thông số | Giá trị chuẩn | Ý nghĩa & Cải tiến v4.4 |
|---|---|---|
| EA | `TM_SessionBreakout.ex5` | Bản đã áp dụng gói sửa A1-A5 |
| Symbol / TF | XAUUSDm / H1 | Vàng tài khoản Exness (Standard / Cent) |
| Preset | `TM_SB_XAUUSD_H1_BASELINE_v1_0.set` | Hoặc `TM_SB_XAUUSD_H1_CENT_v1_0.set` |
| `BrokerGMTOffset` | **999 (Tự động)** | Tự động tính độ lệch GMT giữa server Exness và UTC |
| Range phiên Á | **00:00–07:00 GMT** | Quy đổi chính xác sang giờ server (không hard-code) |
| Cửa sổ vào lệnh | **07:00–20:00 GMT** | Bắt đầu từ mở phiên London đến trước đóng phiên NY |
| Lọc xu hướng | `Use_ADX_Filter=true`, `ADX_Min=20` | Tránh breakout trong thị trường sideway chết |
| SL / TP | SL = biên đối diện range (`SL_Range_Fraction=1.0`); TP = RR5 | R:R cao bù đắp hoàn toàn trượt giá & phí |
| Tần suất | **1 lệnh/ngày** (`OneTradePerDay=true`, `Use_Session2=false`) | Rare-fire chất lượng cao |
| Risk | 0.5–1.0% / lệnh | Định cỡ volume có tính cả spread + commission |
| Filling Mode | **Auto negotiation** | Tự động chọn FOK / IOC / RETURN theo broker |

> ⚠️ **Quy tắc bất biến:** Không đổi tham số trong suốt 4 tuần forward test. Mọi thay đổi đều phải dừng EA, cập nhật changelog và chạy lại kỳ đánh giá từ đầu.

---

## 2. Loại tài khoản triển khai
- **Khuyến nghị số 1 (Vốn nhỏ < $500):** Tài khoản **Cent (USC)** (ví dụ Exness Standard Cent), nạp **50 USD (= 5,000 USC)**. Min-lot 0.01 Cent cho phép định cỡ risk 0.5–1.0% chính xác tuyệt đối mà không bị lỗi đòn bẩy hay cấn min-lot.
- **Hoặc (Vốn ≥ $2,000 - $5,000):** Tài khoản Demo/Real USD chuẩn.
- **Thiết lập tài khoản:** Tài khoản **Hedging**, đòn bẩy ≥ 1:100 (khuyến nghị 1:200 hoặc cao hơn trên Exness).

---

## 3. Quản lý vốn & Lãi kép (Compounding)
- EA tính volume động: `Volume = Risk_Cash / (Loss_Per_Lot_With_Costs)` mỗi khi mở lệnh.
- Khi balance tăng → lot tăng tương ứng tự nhiên theo tỷ lệ phần trăm cố định (lãi kép toán học an toàn).
- **Tuyệt đối giữ risk 0.5% – 1.0%:** Không tăng risk sau chuỗi thắng hay chuỗi thua (không martingale, không revenge trade).
- **Kỳ vọng thực tế:**
  - Tần suất: ~3–5 lệnh/tháng (breakout phiên chất lượng cao).
  - Tỷ lệ thắng kỳ vọng: 35–45%, nhưng R:R là 1:3 đến 1:5 → Kỳ vọng lợi nhuận ròng tăng trưởng bền vững.

---

## 4. Giám sát hằng tuần & Báo cáo
Mỗi cuối tuần ghi nhận dữ liệu vào `reports/forward/TM_SessionBreakout/<YYYY-MM-DD>/`:
- Số lệnh đã khớp, Win/Loss, Lợi nhuận ròng, Max DD trong tuần.
- **Spread thực tế và Slippage:** Đối chiếu xem spread lúc mở lệnh lúc 07:00 GMT (mở phiên London) có bị giãn quá 35 points không.
- **Kiểm tra Log Journal:** Đảm bảo tất cả các ngày không có lệnh đều có dòng log `SB skip: ...` giải thích lý do cụ thể (ADX yếu, Range quá hẹp/quá rộng, hay Spread vượt ngưỡng).

---

## 5. Tiêu chí DỪNG (Fail) và ĐẠT (Pass)
### DỪNG NGAY LẬP TỨC nếu:
1. Max Drawdown chạm ngưỡng **15%**.
2. Thua liên tiếp **8 lệnh** bất thường.
3. Profit Factor (PF) sau ≥ 20 lệnh rơi xuống dưới **1.0**.
4. Xuất hiện lỗi kỹ thuật broker: Rejected `retcode=10030`, freeze level violation, hoặc EA đứng im không in log.

### ĐẠT ĐIỀU KIỆN (Xét cấp vốn thật nhỏ) nếu sau 4-8 tuần:
1. Số lệnh đạt tối thiểu **15–25 lệnh**.
2. Profit Factor ≥ **1.35**, Drawdown ≤ **12%**.
3. Khớp ≥ 80% hành vi so với backtest Model=4 (Real Ticks).
4. Hệ thống log chạy ổn định 100%, không phát sinh lỗi ngoại lệ.

---

## 6. Quy trình Verify Kỹ thuật Demo (Checklist 5 bước Phần D)
Triển khai đúng thứ tự sau khi gắn EA vào đồ thị:

- [ ] **Bước 1: Verify `OnInit` in Terminal Experts tab:**
  - Xác nhận log hiển thị đúng `BrokerGMTOffset` được dò tự động (VD: Exness mùa đông GMT+2, mùa hè GMT+3).
  - Xác nhận giờ range chuyển đổi sang giờ server đúng (VD: 00:00-07:00 GMT → 02:00-09:00 server).
  - Xác nhận `SYMBOL_FILLING_MODE` hợp lệ (không báo lỗi filling).
- [ ] **Bước 2: Verify Log Journal ("Chấm dứt im lặng"):**
  - Vào các giờ không có lệnh (ngoài phiên hoặc khi nến không thỏa breakout), kiểm tra Journal MT5:
  - Phải thấy rõ các log dạng: `SB skip: outside window`, `SB skip: ADX 16.4 < 20.0`, hoặc `SB skip: already traded today`.
- [ ] **Bước 3: Xử lý nếu không có cả log lẫn lệnh:**
  - Nếu không thấy bất kỳ log nào: Kiểm tra suffix cặp tiền (`XAUUSDm` thay vì `XAUUSD`), kiểm tra nút **Algo Trading** (xanh), kiểm tra xem `OnInit` có trả về `INIT_FAILED` không.
- [ ] **Bước 4: Đối chiếu giờ server thực tế:**
  - Nhìn giờ trên thanh trạng thái MT5 so với giờ GMT hiện tại (`TimeGMT()`), đảm bảo công thức cộng offset khớp 100%.
- [ ] **Bước 5: Đóng băng hệ thống chạy 1 tuần:**
  - Để EA chạy trọn vẹn 5 ngày giao dịch (Thứ Hai đến Thứ Sáu), không can thiệp bằng tay, thu thập toàn bộ log cuối tuần.
