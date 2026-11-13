# Backtest Manifest Index (P3 audit)

**Ngày:** 2026-11-12
Tổng hợp phân loại mọi lần kiểm thử hiện có. Không thay thế report gốc — mỗi run có manifest riêng trong folder tương ứng.

> ⚠️ **v2.0 (2026-11-12):** tất cả run dưới đây được tạo bởi build **trước v2.0** (no-TP, có Breakout). Sau khi đổi sang **Pullback-only + Take Profit + circuit breaker**, **mọi report này vô hiệu cho v2.0** và chỉ còn giá trị lịch sử. Cần chạy lại toàn bộ (cost-stress + OOS) sau khi compile.

## v2.0 runs (2026-11-13) — xem `_v2/`

Đã chạy lại real-tick 3 tháng cho v2.0. Tóm tắt:

| Run | Deposit | Net | PF |
|---|---|---|---|
| realistic_200 | 200 | −16.30 | 0.162 |
| realistic_500 | 500 | −4.16 | 0.414 |
| standard_1000 | 1 000 | −4.24 | 0.404 |
| conservative_5000 | 5 000 | −146.21 | 0.266 |
| small_50 | 50 | −7.96 | 0.121 |
| cost_stress_10000 | 10 000 | −410.00 | 0.601 |

EX5 `0F50E9E0ADD72C90`; chi tiết & tái lập: `_v2/V2_BACKTEST_RESULTS.md`, `_v2/*.csv`, `tests/run_backtest_v2.ps1`.

| # | Preset / folder | Report | Deposit | Quality | Risk% | Net | PF | Trades | EqDD | Phân loại |
|---|---|---|---|---|---|---|---|---|---|---|
| 1 | `TM_TFS_baseline_10000` | `.13.24` | 10 000 | **3% real ticks** | 0.5 | +1 509.49 | 2.45 | 878 | 2.21% | DIAGNOSTIC — quality kém |
| 2 | `TM_TFS_cost_stress_10000` | `.13.30` | 10 000 | 98% real ticks | 0.5 | +1 509.49 | 2.45 | 878 | 2.21% | **INVALID — trùng #1 (BUG-005)** |
| 3 | `TM_TFS_conservative_5000` | `.13.27` | 5 000 | 98% real ticks | 0.25 | +149.96 | 1.73 | 620 | 0.86% | DIAGNOSTIC — chưa stress cost |
| 4 | `TM_TFS_realistic_500` | `.13.17` | 500 | **3% real ticks** | 1.0 | +0.80 | 1.09 | 53 | 1.96% | NEGATIVE / INCONCLUSIVE |
| 5 | `TM_TFS_realistic_200` | `.13.36` | 200 | 98% real ticks | 2.0 | −10.87 | 0.58 | 69 | 8.05% | **FAIL** |
| 6 | `TM_TFS_small_100` | `.13.41` | 100 | 98% real ticks | 3.0 | −9.38 | 0.16 | 44 | 10.35% | **FAIL** |
| 7 | `TM_TFS_small_50` | `.13.50` | 50 | 98% real ticks | 8.0 | −10.86 | 0.15 | 47 | 22.57% | **FAIL** |
| 8 | `TM_TFS_small_50` | `.14.46` | **100** | 98% real ticks | 5.0 | −50.92 | 0.14 | 159 | 51.76% | **FAIL (severe) / misfiled** |
| 9 | `TM_TFS_standard_1000` | `.13.43` | 1 000 | 98% real ticks | 0.5 | −7.14 | 0.31 | 54 | 1.24% | **FAIL** |
| 10 | `tmp/` | `.12.00` | **100** | **3% real ticks** | 5.0 | +66.85 | 1.39 | 647 | 23.97% | DIAGNOSTIC — quality kém |

## Phân loại theo yêu cầu P3

- **10 000 USD diagnostic:** #1 (`baseline_10000`). Diagnostic, quality 3%.
- **50 USD diagnostic:** #7 (`small_50`, 98%) và #8 (`small_50`, misfiled 100 USD).
- **Invalid 0-bar / 0-tick report:** **KHÔNG TỒN TẠI** trong `reports/` (đã quét toàn bộ `.html/.htm/.xml`). Tất cả run đều ~17 909 bars. → `N/A — not present`.
- **CostStress chưa chạy:** đúng — #2 là bản trùng #1, **không** phải cost-stress hợp lệ (commission=0, spread cap 350, news vô hiệu). → `NOT RUN (valid)`.
- **Preset Realistic 200/500 chưa kiểm chứng đạt:** đúng — #4 (PF 1.09, 3% ticks) và #5 (PF 0.58) đều **thất bại**. → `FAIL`.

## Ranh giới bằng chứng

Mọi run ở trên: chỉ 3 tháng dữ liệu (`2026.08.01–2026.10.31`), 1 symbol (XAUUSDm), commission = 0, news filter vô hiệu trong tester, không có OOS/walk-forward. **Không run nào được dùng làm bằng chứng chiến lược đã xác nhận.**

## Quy ước tên manifest

Mỗi run: `manifest_<Preset>_<YYYY.MM.DD.HH.MM>.md` cạnh report HTML. `manifest.md` cũ (conservative, cost_stress) **được giữ nguyên** làm lịch sử; bản mới là bản có ngày giờ.
