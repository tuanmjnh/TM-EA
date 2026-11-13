# TM-EA — BUG REPRODUCTIONS

Mỗi bug: mô tả, vị trí source, cách tái hiện, tác động, trạng thái. Trạng thái: `CONFIRMED`, `SUSPECTED`, `FIXED (source)`, `RESOLVED`, `WONTFIX`.

> **v2.0 (2026-11-12):** đã sửa source cho một số mục (xem trạng thái từng bug). `FIXED (source)` = đã sửa trong code nhưng **CHƯA compile lại / CHƯA chạy test hồi quy** → vẫn cần verify. Các mục BUG-002/003/007/008 vẫn **mở**.

---

## BUG-001 — `ATR_Channel_Period` là input chết; breakout dùng sai ATR

- **Trạng thái:** RESOLVED v2.0 (đã xóa `ATR_Channel_Period`, `BreakoutK`, `Entry_Mode` cùng Breakout)
- **Vị trí:** `MQL5/Experts/TM_TrendFollowerScalper.mq5` dòng 178 & 227; `MQL5/Include/TM_EA/Inputs.mqh` dòng 25.
- **Tái hiện:**
  1. `grep -n ATR_Channel_Period MQL5` → chỉ có khai báo input, không có nơi đọc.
  2. Đọc dòng 178: `atrValue = CInitialStop::ATRValue(_Symbol, Entry_Timeframe, Trail_ATR_Period);`
  3. Dòng 227 truyền `atrValue` vào `EvaluateBreakout`.
- **Kỳ vọng:** breakout dùng ATR(`ATR_Channel_Period`) theo `SOURCE_SPEC_V1.md` §4.2.2.
- **Thực tế:** breakout dùng ATR(`Trail_ATR_Period`).
- **Tác động:** đổi `Trail_ATR_Period` làm thay đổi ngưỡng breakout (k*ATR) ngoài ý muốn. Với default (14 = 14) trùng nhau nên ẩn.
- **Sửa đề xuất:** dùng `ATR_Channel_Period` cho breakout; hoặc bỏ input và tài liệu hoá rằng breakout dùng chung ATR trailing.

---

## BUG-002 — Filling mode hard-code FOK, không đọc `SYMBOL_FILLING_MODE`

- **Trạng thái:** CONFIRMED
- **Vị trí:** `MQL5/Include/TM_EA/TradeExecutor.mqh` dòng 31.
- **Tái hiện:** `m_trade.SetTypeFilling(ORDER_FILLING_FOK)` là hằng số.
- **Kỳ vọng:** chọn FOK/IOC/RETURN dựa trên `SYMBOL_FILLING_MODE` của broker.
- **Thực tế:** luôn FOK.
- **Tác động:** trên symbol/account chỉ hỗ trợ IOC, mọi lệnh bị từ chối (`TRADE_RETCODE_INVALID_FILL 10030`) → EA không vào được lệnh. Backtest hiện tại khớp được nên lỗi ẩn.
- **Sửa đề xuất:** đọc `(int)SymbolInfoInteger(sym, SYMBOL_FILLING_MODE)` và chọn mode hợp lệ.

---

## BUG-003 — Consecutive-loss đếm trùng sau restart terminal

- **Trạng thái:** CONFIRMED
- **Vị trí:** `MQL5/Include/TM_EA/RiskGuard.mqh` — `m_lastProcessedDeal` khởi tạo `0` (dòng 99, 110) và `RefreshClosedTradeHistory` (dòng 48-88).
- **Tái hiện:**
  1. Chạy EA, có 2 lệnh thua trong ngày → `ConsecutiveLosses=2` (lưu GlobalVariable).
  2. Restart terminal (EA init lại) → `m_lastProcessedDeal=0`.
  3. Tick đầu tiên: `RefreshClosedTradeHistory` quét lại toàn bộ OUT-deals hôm nay → cộng thêm 2 → `ConsecutiveLosses=4` → kích cooldown sai.
- **Kỳ vọng:** bộ đếm idempotent qua restart (persist `m_lastProcessedDeal`).
- **Thực tế:** đếm trùng; một lệnh partial-close nhiều phần cũng bị đếm nhiều lần.
- **Tác động:** cooldown/dừng giao dịch kích hoạt quá sớm (thận trọng hơn — không gây rủi ro tăng, nhưng sai hành vi tài liệu).

---

## BUG-004 — News filter vô hiệu trong Strategy Tester

- **Trạng thái:** CONFIRMED (đánh đổi có chủ đích)
- **Vị trí:** `MQL5/Include/TM_EA/RiskGuard.mqh` dòng 183-192.
- **Tái hiện:** trong tester, `CalendarValueHistory` trả `< 0`; code chỉ fail-safe khi `!MQL_TESTER`.
- **Kỳ vọng:** spec §4.5.1 — calendar không đọc được + `News_Enable=true` → chặn vào lệnh mới.
- **Thực tế:** trong tester bỏ qua chặn.
- **Tác động:** không backtest nào kiểm tra được news filter; `News_Enable=true` là "no-op" trong tester.
- **Sửa đề xuất:** historical news adapter (import CSV sự kiện) để tester mô phỏng buffer.

---

## BUG-005 — Report `cost_stress_10000` không phải bằng chứng hợp lệ

- **Trạng thái:** CONFIRMED (dữ liệu, không phải code)
- **Vị trí:** `reports/backtests/TM_TrendFollowerScalper/TM_TFS_cost_stress_10000/ReportTester-…13.30.html`
- **Tái hiện:** so nội dung với `…/TM_TFS_baseline_10000/ReportTester-…13.24.html` → 39 690/39 690 dòng giống nhau, khác duy nhất dòng `History Quality` (`3%` vs `98%`).
- **Kỳ vọng:** 2 lần chạy độc lập phải khác trade list khi khác chất lượng tick.
- **Thực tế:** trùng khít 878 lệnh và mọi chỉ số.
- **Tác động:** tuyên bố "Cost-Stress PASSED" trong MASTER/manifest là **không có cơ sở**.

---

## BUG-006 — EX5 cũ hơn source MQL5

- **Trạng thái:** FIXED (2026-11-13) — biên dịch lại v2.0 `0 errors/0 warnings`; EX5 `0F50E9E0ADD72C90`; log `tests/compile-v2.log`. (Lịch sử: trước đó CONFIRMED.)
- **Vị trí:** `MQL5/Experts/TM_TrendFollowerScalper.ex5`, `MQL5/Include/TM_EA/RiskGuard.mqh`.
- **Tái hiện:** `Get-Item` → EX5 mtime `2026-11-12 11:31:14`; `RiskGuard.mqh` mtime `2026-11-12 11:34:24`; không có compile log nào sau 11:31.
- **Tác động:** binary đã commit/đem đi backtest **không** chứa thay đổi RiskGuard cuối cùng → report không tái lập được từ source hiện tại.
- **Sửa đề xuất:** biên dịch lại, ghi compile log mới, cập nhật hash EX5 trong manifest.

---

## BUG-007 — Sizing bỏ qua spread/commission

- **Trạng thái:** SUSPECTED (lệch spec)
- **Vị trí:** `MQL5/Include/TM_EA/RiskManager.mqh` dòng 40-46.
- **Kỳ vọng:** `ARCHITECTURE.md` §4.5 & `SOURCE_SPEC_V1.md` §4.4 bước 3: cộng spread hiện tại + commission ước tính vào loss-per-lot.
- **Thực tế:** chỉ dùng `OrderCalcProfit`.
- **Tác động:** trên broker có commission, risk thực > risk cap. Với backtest hiện tại (commission=0) không lộ.

---

## BUG-008 — Margin check dùng `Min_Volume` thay vì volume thực

- **Trạng thái:** SUSPECTED
- **Vị trí:** `MQL5/Experts/TM_TrendFollowerScalper.mq5` dòng 208 (`Min_Volume` truyền làm `volumeForMarginCheck`).
- **Tác động:** ước lượng margin thấp hơn thực với volume lớn (ví dụ preset 5 000 USD, Max_Volume 0.15).

---

## BUG-009 — Report bị đặt sai thư mục/nhãn

- **Trạng thái:** CONFIRMED (dữ liệu)
- **Vị trí:** `reports/backtests/TM_TrendFollowerScalper/TM_TFS_small_50/ReportTester-…14.46.html` (deposit 100 USD, risk 5) nằm trong folder "small_50"; `tmp/TM_TFS_small_50_…12.00.html` cũng là 100 USD.
- **Tác động:** khó truy vết; tên file không phản ánh cấu hình thực.

---

## BUG-010 — Breakeven đặt SL sai phía thị trường (cả BUY lẫn SELL)

- **Trạng thái:** FIXED (source) v2.0 — chưa compile/test.
- **Vị trí:** `MQL5/Include/TM_EA/TrailingEngine.mqh` (nhánh breakeven).
- **Tái hiện (số cụ thể, vàng Exness):** `spread ≈ 0.30`, `Breakeven_After_pips=8` → `breakevenDistance=0.08`.
  - BUY đang lãi 0.08: `bid ≈ openPrice+0.08`; code cũ đặt `SL = openPrice+0.30 > bid` → stop nằm **trên** giá đối với lệnh buy → broker từ chối.
  - SELL đang lãi 0.08: `ask ≈ openPrice−0.08`; code cũ đặt `SL = openPrice−0.30 < ask` → stop nằm **dưới** giá đối với lệnh sell → broker từ chối.
- **Kỳ vọng:** breakeven áp dụng được, SL luôn hợp lệ.
- **Thực tế (trước sửa):** vì `spread (0.2–0.3) > breakevenDistance (0.08)`, breakeven **gần như không bao giờ** sửa được SL.
- **Ghi chú về fix được yêu cầu:** bản đề xuất "SELL: `openPrice + spread`" là **sai** — nó khóa một khoản **lỗ bằng spread** (exit trên entry đối với lệnh bán). Fix đã áp dụng: giữ `openPrice ± spread` nhưng **clamp về `openPrice`** khi SL rơi sai phía (`>= bid` cho BUY, `<= ask` cho SELL) → hợp lệ và không khóa lỗ.

---

## BUG-011 — Chiến lược v2.0 (Pullback-only + TP) thua lỗ; TP không cải thiện

- **Trạng thái:** CONFIRMED (đo bằng backtest thực, 2026-11-13)
- **Bằng chứng:** 6/6 preset real-tick 3 tháng âm (PF 0.12–0.60); kiểm soát Model=1: no-TP PF 3.39 > TP1.5 2.47 > TP0.2 2.14.
- **Tác động:** v2.0 không đủ điều kiện chạy forward/tiền thật.
- **Ghi chú:** v1.3 (có Breakout) cho PF cao hơn nhiều trên cùng cửa sổ, nhưng report v1.3 không đáng tin (BUG-005). Việc gỡ Breakout có thể là nguyên nhân chính, chưa tách bạch được.
- **Xem:** `reports/backtests/_v2/V2_BACKTEST_RESULTS.md`.

## BUG-013 — Breakeven dời SL về entry quá sớm → tự hủy mọi lệnh thắng (nghiêm trọng)

- **Trạng thái:** FIXED (source, 2026-11-13) — thêm `Breakeven_ATR_Mult` (gate theo ATR). Kiểm chứng: gate 0.25→PF 0.567, 1.0→0.935, 4.0→0.932. (Trước fix: PF ~0.155.)
- **Vị trí:** `TrailingEngine.mqh` nhánh breakeven; điều khiển bởi `Breakeven_After_pips` (preset 4–10).
- **Tái hiện (IS, atr2.0, no-TP):** bật breakeven be=8 → PF 0.155, largest_win **0.29**; tắt breakeven (be=9999) → PF **0.897**, largest_win **22.66**.
- **Nguyên nhân:** `Breakeven_After_pips` tính theo pip = 0.01 giá → 0.04–0.10, nhỏ hơn spread vàng (0.20–0.35) và nhỏ hơn nhiễu M5. Khi kích hoạt, SL = `openPrice` → lệnh thắng bị quét ở ~hòa vốn; lệnh thua chạy hết SL.
- **Tác động:** PF giảm ~6 lần; biến mọi winner thành ~breakeven.
- **Sửa đề xuất:** tính breakeven theo ATR (ví dụ kích hoạt khi lãi ≥ 0.5–1.0×ATR) **hoặc** tắt hẳn; tuyệt đối không dùng mức pip cố định nhỏ hơn spread.
- **Xem:** `reports/backtests/_v2/OPTIMIZATION_STUDY.md` §1.

## BUG-012 — Khóa `Report=` của MT5 không sinh file ở chế độ `/config`

- **Trạng thái:** CONFIRMED (môi trường)
- **Vị trí:** `config/test_v2_smoke.ini`, `config/test_v2_run.ini` (khóa `Report=`).
- **Tái hiện:** chạy `terminal64.exe /config:<ini>` có `Report=<abs path>` → không file HTML nào được tạo (đã thử cả khi có/không đuôi `.html`).
- **Giải pháp:** EA tự ghi `TM_EA_tester_report_<sym>.csv` (FILE_COMMON) chỉ trong tester; script `tests/run_backtest_v2.ps1` copy về repo.
