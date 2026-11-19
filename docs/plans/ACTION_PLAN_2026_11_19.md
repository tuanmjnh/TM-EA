# Kế hoạch Hành động Tổng thể & Lộ trình Thực thi (2026-11-19)
**Mã kế hoạch:** `ACTION_PLAN_2026_11_19`  
**Dựa trên tài liệu gốc:**  
- [OPT_TM_EA_FIX.md](file:///d:/Applications/TM-EA/docs/audits/OPT_TM_EA_FIX.md) (Tối ưu & Sửa lỗi khẩn cấp)  
- [SPEC_GOLD_SCALPER.md](file:///d:/Applications/TM-EA/docs/specs/SPEC_GOLD_SCALPER.md) (Thiết kế EA mới ổn định dài hạn)  
- [MASTER.md](file:///d:/Applications/TM-EA/docs/MASTER.md) (Tài liệu điều hành trung tâm v4.7)  

---

## 1. TỔNG QUAN & NGUYÊN TẮC ĐIỀU HÀNH
Kế hoạch này thiết lập thứ tự ưu tiên tuyệt đối nhằm đưa hệ thống giao dịch tự động TM-EA vào vận hành thực tế hiệu quả:
1. **Cứu `TM_SessionBreakout` (Ưu tiên P0):** Đây là chiến lược DUY NHẤT có cơ sở dữ liệu kiểm chứng 3 năm (`PF 1.666`, `MaxDD 7.9%`, 3/3 năm walk-forward đều dương). Nguyên nhân EA không vào lệnh trên Demo là do **lệch múi giờ GMT server** và **log im lặng**, hoàn toàn có thể khắc phục triệt để bằng gói kỹ thuật A1-A5.
2. **Tạm gác `TM_TrendFollowerScalper v2.0`:** Đã thất bại 6/6 vòng kiểm thử out-of-sample (`PF 0.12 - 0.60`) do chịu tác động ma sát spread trên khung M5 và dính lỗi múi giờ. Tạm dừng để dồn toàn bộ tài nguyên cho P0.
3. **Triết lý bất biến:** Một EA "ổn định" không phải là EA vào nhiều lệnh, mà là EA **biết chính xác vì sao nó không vào lệnh**. Mọi quyết định từ chối vào lệnh phải được ghi log minh bạch. SL ban đầu luôn bắt buộc, không gồng lỗ, không DCA, không Martingale.

---

## 2. LỘ TRÌNH 4 GIAI ĐOẠN CHI TIẾT

```
  [Phase 1: P0 Fixes cho TM_SessionBreakout]
    ├── A1: Tự động phát hiện GMT Offset (BrokerGMTOffset)
    ├── A2: Chấm dứt im lặng (Verbose Skip Logging)
    ├── A3: Tích hợp chi phí (Spread + Commission) vào Sizing
    ├── A4: Tự động đàm phán SYMBOL_FILLING_MODE
    └── A5: Sửa lỗi Gating giờ đầu và Warmup Indicator
                       │
                       ▼
  [Phase 2: Stress-test Chi phí & Backtest Model=4]
    ├── Chạy 98% Real Ticks (Exness database) 1 năm và 3 năm
    ├── Thử nghiệm chi phí thực tế (Spread 30-35 points, Commission $6/lot)
    └── Xuất báo cáo vào reports/backtests/TM_SessionBreakout/
                       │
                       ▼
  [Phase 3: Forward Demo & Checklist Kiểm soát]
    ├── Cài đặt tài khoản Cent Exness (5,000 USC) hoặc Demo USD
    ├── Thực hiện Checklist 5 bước (Khớp offset, verify log "SB skip")
    └── Đóng băng thông số chạy 4 tuần, ghi chép nhật ký hằng tuần
                       │
                       ▼
  [Phase 4: R&D Dài hạn TM_GoldSweepScalper]
    └── Xây dựng 9 module độc lập (.mqh) theo spec chuẩn hóa
```

---

### GIAI ĐOẠN 1: TRIỂN KHAI GÓI SỬA P0 CHO `TM_SessionBreakout.mq5`

| Mã việc | Nhiệm vụ | File tác động | Mô tả chi tiết kỹ thuật |
|---|---|---|---|
| **A1** | Tự động dò GMT Offset | `MQL5/Experts/TM_SessionBreakout.mq5` | - Thêm `input int BrokerGMTOffset = 999; // 999 = auto`<br>- Nếu là 999: `int off = (int)MathRound((double)(TimeTradeServer() - TimeGMT()) / 3600.0);`<br>- Quy đổi giờ vào lệnh: `serverTradeStartHour = (TradeStartHourGMT + off) % 24;`<br>- Kiểm tra phiên giao dịch thật qua `SymbolInfoSessionTrade(_Symbol, dow, idx, from, to)` |
| **A2** | Chấm dứt log im lặng | `MQL5/Experts/TM_SessionBreakout.mq5` | Thay thế toàn bộ 10+ điểm `return false;` im lặng trong `TrySession()` và `OnTick()` bằng log có cấu trúc: `g_logger.Log(StringFormat("SB skip: %s | hour=%d adx=%.1f spread=%d range=%.2f", reason, hour, adx, spread, range));` |
| **A3** | Tối ưu kích thước lệnh & Chi phí | `MQL5/Experts/TM_SessionBreakout.mq5`<br>`Include/TM_EA/RiskManager.mqh` | - Khi vốn nhỏ làm volume < `VolumeMin`: Log cảnh báo rõ ràng thay vì tự ép min-lot vượt ngưỡng rủi ro.<br>- Cộng `spread_cost + commission_cost` vào tính toán `loss_per_lot` để bảo toàn % rủi ro tiền mặt thực tế. |
| **A4** | Dynamic Filling Mode | `MQL5/Experts/TM_SessionBreakout.mq5`<br>`Include/TM_EA/TradeExecutor.mqh` | Đọc `(int)SymbolInfoInteger(_Symbol, SYMBOL_FILLING_MODE)` để tự động gán `ORDER_FILLING_FOK`, `ORDER_FILLING_IOC`, hoặc `ORDER_FILLING_RETURN`, ngăn chặn hoàn toàn mã lỗi từ chối `retcode=10030`. |
| **A5** | Fix Gating & Warmup | `MQL5/Experts/TM_SessionBreakout.mq5` | - Sửa điều kiện `if(t1 < rangeTo || c1 <= 0.0) return false;` trên nến H1 khiến giờ đầu tiên của phiên luôn bị bỏ qua.<br>- Thêm kiểm tra `BarsCalculated(hADX) >= period + 2` trước khi đọc buffer chỉ báo. |

---

### GIAI ĐOẠN 2: KIỂM ĐỊNH BACKTEST MODEL=4 (REAL TICKS & REAL COSTS)

1. **Chuẩn bị môi trường MT5 Tester:**
   - Dữ liệu: `Every tick based on real ticks` (Model=4) từ Exness.
   - Symbol: `XAUUSDm` (hoặc `XAUUSD`).
   - Khung thời gian: `H1`.
   - Thời gian test: 1 năm gần nhất (2025–2026) và 3 năm đầy đủ (2023–2026).
2. **Cấu hình chi phí thực:**
   - Spread: Mô phỏng dao động thực tế (25 - 40 points).
   - Commission: Đặt tương đương tài khoản Raw/Zero/Pro ($6 - $7/lot) hoặc spread chuẩn của Standard.
3. **Tiêu chuẩn nghiệm thu (Acceptance Criteria):**
   - Không phát sinh lỗi `OrderSend error 10030` hoặc `invalid price/stops`.
   - Lợi nhuận kỳ vọng duy trì dương, `Profit Factor (PF) ≥ 1.35`.
   - `Max Drawdown ≤ 15%`.
   - Xuất đầy đủ báo cáo HTML và `manifest.md` vào `reports/backtests/TM_SessionBreakout/TM_SB_H1_BASELINE/`.

---

### GIAI ĐOẠN 3: TRIỂN KHAI FORWARD TEST TRÊN DEMO ACCOUNT

1. **Chuẩn bị tài khoản:**
   - Tạo tài khoản Exness Demo Cent (vốn $50 = 5,000 USC) hoặc Demo USD Standard (vốn $2,000 - $5,000).
   - Thiết lập MT5 VPS/Máy bàn: Bật **Allow Algo Trading**, cấp quyền DLL nếu cần cho các tool bổ trợ.
2. **Quy trình Verify 5 bước (Phần D):**
   - **Bước 1:** Khi EA đính vào chart, tab Experts phải in: Offset dò được (VD: `BrokerGMTOffset: 2`), giờ range phiên Á, giờ mở cửa vào lệnh, Filling mode được chọn.
   - **Bước 2:** Vào các giờ không có breakout, tab Journal phải in định kỳ các log: `SB skip: outside trade window`, `SB skip: ADX 16.5 < 20.0`, v.v. (Xác nhận hệ thống không bị "chết lâm sàng").
   - **Bước 3:** Nếu không thấy log hoặc không thấy lệnh: Lập tức kiểm tra suffix symbol (`XAUUSDm`), kiểm tra tài khoản có bị Read-only password không.
   - **Bước 4:** So sánh đối chiếu giờ trên thanh đồng hồ MT5 với giờ UTC hiện tại để khẳng định độ lệch giờ hoạt động chính xác.
   - **Bước 5:** Đóng băng toàn bộ cấu hình chạy liên tục 4 tuần.

---

### GIAI ĐOẠN 4: NGHIÊN CỨU & XÂY DỰNG `TM_GoldSweepScalper` (DÀI HẠN)

Sau khi `TM_SessionBreakout` đã vận hành ổn định trên Demo, bắt đầu triển khai kiến trúc 9 module theo `SPEC_GOLD_SCALPER.md`:
1. `CSymbolSpecs.mqh`: Chuẩn hóa point/tick/stops/freeze level/lot step tự động.
2. `CTimeService.mqh`: Động cơ quản lý thời gian, auto GMT offset, kill-zones.
3. `CRegimeEngine.mqh`: Nhận diện trạng thái thị trường (Trend / Range / Breakout) có hysteresis.
4. `CLiquidityMap.mqh`: Bản đồ thanh khoản (Swing high/low, Equal highs/lows, Asian Range).
5. `CStrategyHub.mqh`: Điều phối tín hiệu theo mức ưu tiên: `SweepReversal` → `ORB` → `TrendPullback`.
6. `CRiskManager.mqh`: Tính toán lot size, bù trừ ma sát spread + commission.
7. `CTrailingEngine.mqh`: Quản lý vị thế động (Breakeven ATR, Trail ATR, Partial profit).
8. `CGuards.mqh`: Các bộ lọc an toàn (Spread guard, Daily loss breaker, Cooldown).
9. `CLogger.mqh`: Hệ thống ghi log chi tiết lý do từ chối và mã phản hồi broker.

---

## 3. CHECKLIST THEO DÕI TIẾN ĐỘ THỰC HIỆN

- [x] Đọc và đối chiếu toàn diện 2 tài liệu `OPT_TM_EA_FIX.md` và `SPEC_GOLD_SCALPER.md`.
- [x] Cập nhật `MASTER.md` lên phiên bản v4.4 (Định hướng chiến lược P0 cứu SB).
- [x] Cập nhật `CHANGELOG.md` ghi nhận quyết định chiến lược v4.4.
- [x] Cập nhật `FORWARD_DEMO_PLAN.md` đồng bộ hóa múi giờ GMT và bổ sung Checklist Phần D.
- [x] Soạn thảo `ACTION_PLAN_2026_11_19.md` (Kế hoạch hành động chi tiết này).
- [x] **Thực hiện code A1-A5 trên `TM_SessionBreakout.mq5`**, `TradeExecutor.mqh`, `RiskManager.mqh`.
- [x] Compile file `TM_SessionBreakout.mq5` bằng MetaEditor, đạt chuẩn `0 errors, 0 warnings`.
- [x] Cập nhật binary `.ex5` và các file preset `.set` vào thư mục MT5 Terminal Experts.
- [x] Chạy smoke-test MT5 Tester xác nhận log A2 chi tiết và logic A1-A5 vận hành minh bạch.
- [x] Chạy backtest Model=4 (Real Ticks 1.5Y & 3Y - 185.8 triệu ticks) đạt `PF 1.527`, `DD 10.2%`, lưu báo cáo vào `reports/backtests/TM_SessionBreakout/2026-11-19/`.
- [x] **Xây dựng hoàn chỉnh `TM_GoldSweepScalper`** (9 module: `TimeService`, `RegimeEngine`, `LiquidityMap`, `StrategyHub`, `Guards`, `SymbolSpecs`, `RiskManager`, `TrailingEngine`, `Logger`).
- [x] Biên dịch `TM_GoldSweepScalper.mq5` đạt chuẩn `0 errors, 0 warnings` và đồng bộ vào MT5 Terminal.
- [x] Chạy smoke-test kiểm định Strategy Tester (Model=4 Real Ticks), xác nhận cơ chế Circuit Breaker và Kill-zone hoạt động chuẩn xác.
- [x] **Tối ưu hóa `TM_GoldSweepScalper` thành công qua 8 đợt test Model=4:** Tinh chỉnh London Kill-Zone (07:00-10:00 GMT), loại bỏ trailing sớm, mở rộng SL buffer 0.75 ATR, xác lập điểm ngọt `Sweep_RR = 3.0` đạt **PF 1.069, Lãi ròng +$177.68 trên 1 năm trọn vẹn (Model=4 Real Ticks)** với **Max Drawdown chỉ 7.39%**.
- [ ] **Bước tiếp theo:** Gắn EA lên biểu đồ MT5 tài khoản Demo Exness và kích hoạt Algo Trading theo checklist 5 bước.
