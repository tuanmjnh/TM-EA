# TM-EA v2.0 — Backtest Results (real Strategy Tester runs)

**Ngày:** 2026-11-13
**Thực thi bởi:** AI agent, chạy tự động MT5 Strategy Tester (headless `/config`) trên máy này.
**EA:** `TM_TrendFollowerScalper.ex5` v2.00, SHA256[0:16]=`0F50E9E0ADD72C90`
**Compiler:** MetaEditor 5.0.0.6292 — `0 errors, 0 warnings` (`tests/compile-v2.log`)
**Symbol/khung:** XAUUSDm / M5 · **Broker:** Exness-MT5Trial17 · **Model:** Every tick based on real ticks (`Model=4`)
**Giai đoạn:** 2026.08.01 – 2026.10.31 (3 tháng)
**Commission = 0, swap = 0** (server tester mặc định). **News filter vô hiệu trong tester** (BUG-004).
**Chiến lược v2.0:** Pullback-only + Take Profit (`Use_TP=true`, `TP_ATR_Mult=1.5`) + equity breaker.

> ⚠️ **Không con số nào là cam kết lợi nhuận.** Đây là kết quả test thực tế, có thể tái lập bằng `tests/run_backtest_v2.ps1`.

## 1. Kết quả 3 tháng real-tick

| Preset | Deposit | Net P/L | PF | Trades | W / L | Max Equity DD | File |
|---|---|---|---|---|---|---|---|
| `realistic_200` (risk 2.0, ATR 1.5) | 200 | **−16.30** | 0.162 | 59 | 20/37 | 8.64% | `realistic_200.csv` |
| `realistic_500` (risk 1.0, ATR 2.0) | 500 | **−4.16** | 0.414 | 47 | 20/24 | 1.94% | `realistic_500.csv` |
| `standard_1000` (risk 0.5, ATR 2.0) | 1 000 | **−4.24** | 0.404 | 48 | 21/24 | 0.99% | `standard_1000.csv` |
| `conservative_5000` (risk 0.25, ATR 2.5) | 5 000 | **−146.21** | 0.266 | 511 | 217/278 | 3.02% | `conservative_5000.csv` |
| `small_50` (risk 5.0, ATR 1.0) | 50 | **−7.96** | 0.121 | 26 | 6/19 | **18.40%** | `small_50.csv` |
| `cost_stress_10000` (risk 0.5, ATR 2.0) | 10 000 | **−410.00** | 0.601 | 741 | 296/437 | 6.33% | `cost_stress_10000.csv` |

**Kết luận:** v2.0 **thua lỗ trên mọi preset** trong 3 tháng này (PF 0.12–0.60). Không preset nào đạt cổng `PF ≥ 1.3`. `small_50` DD 18.4%.

## 2. Kiểm soát tác động Take Profit (cùng dữ liệu, model nhanh)

Model=1 (1-minute OHLC), 2026.10.01–10.15, deposit 10 000, cùng tham số khác:

| Cấu hình | Net | PF | Trades | Largest win |
|---|---|---|---|---|
| **TP OFF** (`Use_TP=false`) | **+213.58** | **3.392** | 130 | 104.57 |
| TP on, `TP_ATR_Mult=1.5` | +131.08 | 2.468 | 131 | 27.30 |
| TP on, `TP_ATR_Mult=0.2` (tight) | +140.94 | 2.143 | 147 | 5.11 |

→ **TP làm giảm kết quả** trên cửa sổ này: tắt TP cho PF/Net cao nhất; TP càng chặt càng cắt nhỏ lệnh thắng (largest win 104 → 27 → 5).
Trên cửa sổ 3-tháng Model=4, `TP_ATR_Mult=1.5` hiếm khi được chạm nên `Use_TP` on/off cho kết quả gần như y hệt (`cs_tp_on.csv` == `cs_tp_off.csv`); chỉ khi TP rất chặt (0.2) mới khác (`cs_tp_m4_tight.csv`).

## 3. Điểm bất thường cần xác minh (không tự diễn giải là "ổn")

- Trong nhóm `cost_stress` (volume tới 0.05), có **một lệnh thắng +203.77 USD tồn tại ở MỌI cấu hình TP (0.2 / 1.5 / 6.0 / off)**. Nghĩa là lệnh đó **không thoát qua TP**. Giả thuyết hợp lý: **gap có lợi trên real-tick** (khớp tốt hơn TP). **Chưa xác minh** — cần mở rộng log per-deal để chắc chắn.
- Vì `TP_ATR_Mult=1.5` gần như không bind trên Model=4, kết luận "TP có hại" **chỉ được chứng minh chắc trên Model=1/1-năm-phút**; trên real-tick 3 tháng, khác biệt TP chủ yếu là trung tính.

## 4. Phương pháp & tái lập

- Compile: `MetaEditor64.exe /compile:"...\TM_TrendFollowerScalper.mq5" /log:...` → `tests/compile-v2.log`.
- Chạy: `tests/run_backtest_v2.ps1 -Name <n> -Deposit <d> -Risk <r> ...` → ghi `config/test_v2_run.ini` rồi `terminal64.exe /config:...`.
- **Lưu ý kỹ thuật:** khóa `Report=` của MT5 **không hoạt động** trong chế độ `/config` trên build này (không sinh file HTML). Vì vậy EA được bổ sung **dump CSV chỉ trong Strategy Tester** (`DumpTesterStats()` → `Common\Files\TM_EA_tester_report_XAUUSDm.csv`), rồi script copy về `reports/backtests/_v2/`.
- Số liệu PF/DD/… lấy từ chính history deals của tester (commission+swap included). `max_equity_dd_pct` đo theo tick trong tester.

## 5. Quyết định

**REJECT v2.0 as-is.** Pullback-only + TP không có lợi thế trên dữ liệu thực tế hiện có. Cần:
1. Xác minh điểm bất thường §3 (log per-deal).
2. Cân nhắc khôi phục Breakout (v2.0 gỡ bỏ) hoặc tìm entry khác — kết quả v1.3 (có Breakout) cao hơn nhiều, dù bản thân report v1.3 không đáng tin.
3. Không chạy tiền thật. Chỉ khi có cost-stress + OOS dương mới bàn tiếp.
