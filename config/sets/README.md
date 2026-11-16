# config/sets — Presets (.set) theo EA

Cấu trúc: **`config/sets/<Tên EA>/<preset>.set`**.

```text
config/sets/
├── README.md
├── TM_TrendFollowerScalper/     # EA trend-following (Pullback + TP + ATR trail)
├── TM_SessionBreakout/          # EA range-breakout theo phiên (H1/M30/M15)
└── TM_KimLa/                    # EA khác (preset sẵn có trên máy)
```

## TM_SessionBreakout (mới)

Chiến lược: phá range phiên Á (00:00–07:00 server) tại phiên London/NY, 1 lệnh/ngày,
SL = biên đối diện range, TP = RR × risk, có lọc ADX(H1).

| Preset | TF | Kết quả 3Y (real-tick) | Ghi chú |
|---|---|---|---|
| `TM_SB_XAUUSD_H1_BASELINE_v1_0.set` | H1 | **PF 1.666, DD 7.9%** | **Khuyến nghị** — walk-forward 3/3 năm dương |
| `TM_SB_XAUUSD_H1_CENT_v1_0.set` | H1 | (cùng logic baseline) | **Cho tài khoản Cent (USC)** — vốn nhỏ ($50 = 5,000 USC) |
| `TM_SB_XAUUSD_M30_v1_0.set` | M30 | PF ~1.456, DD ~11.4% | Tín hiệu mịn hơn; kém hơn H1 |
| `TM_SB_XAUUSD_M15_v1_0.set` | M15 | PF ~1.217, DD ~14.6% | Nhiễu hơn |

> Quy trình dùng: xem `docs/FORWARD_DEMO_PLAN.md` (cấu hình đóng băng, lãi kép, tiêu chí dừng/đạt).

> ⚠️ **Ứng viên nghiên cứu, CHƯA xác nhận cho tiền thật.** Vốn cần **≥ ~$5000 real** hoặc tài khoản **Cent** (SL theo range × min-lot vàng). Commission chưa model thật trong tester; mẫu nhỏ.

## TM_TrendFollowerScalper

8 preset (baseline, cost_stress, realistic_200/500, small_50/100, standard_1000, conservative_5000).
**Lưu ý:** chiến lược này đã thua 6/6 vòng tối ưu (OOS PF < 1) — xem `reports/backtests/TM_TrendFollowerScalper/RESEARCH_LOG.md`. Không khuyến nghị dùng.

## Cách nạp trong MT5
1. GUI: Strategy Tester (`Ctrl+R`) → chọn Expert `.ex5` → tab Inputs → chuột phải **Load** → chọn `.set`.
2. Hoặc copy `.set` vào `<Terminal>\MQL5\Profiles\Tester\` rồi load trong tester.

## Quy ước tên preset
`<STRATEGY>_<SYMBOL>_<TF>_<PURPOSE>_v<major>_<minor>.set` (theo `docs/ARCHITECTURE.md` §7).
