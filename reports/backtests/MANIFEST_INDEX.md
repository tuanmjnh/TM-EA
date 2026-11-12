# Backtest Manifest Index (P3 audit)

**Ngày:** 2026-11-12
Tổng hợp phân loại mọi lần kiểm thử hiện có. Không thay thế report gốc — mỗi run có manifest riêng trong folder tương ứng.

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
