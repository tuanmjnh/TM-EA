# Thư mục Báo cáo Backtest — Quy chuẩn lưu trữ

Cấu trúc chuẩn: **`<Tên Bot> / <Ngày chạy> / <Cấu hình>`**.

```text
reports/backtests/
├── README.md                     # file này (quy chuẩn)
├── MANIFEST_INDEX.md             # chỉ mục tổng hợp mọi run
├── _template/                    # mẫu manifest.md
├── TM_TrendFollowerScalper/      # Bot 1 (chiến lược trend-following)
│   ├── V2_BACKTEST_RESULTS.md    # báo cáo nghiên cứu (bot-level)
│   ├── RESEARCH_LOG.md
│   ├── OPTIMIZATION_STUDY.md
│   ├── SET_SELECTION_STUDY.md
│   ├── 2026-11-12/               # report MT5 gốc (HTML), theo preset
│   │   ├── TM_TFS_cost_stress_10000/
│   │   │   ├── ReportTester-*.html + ảnh
│   │   │   └── manifest*.md
│   │   └── ... (9 preset) + tmp/
│   └── 2026-11-13/               # run nghiên cứu (CSV do EA xuất)
│       └── <cấu hình>/
│           ├── report.csv
│           └── manifest.md
└── TM_SessionBreakout/           # Bot 2 (range-breakout H1 theo phiên)
    ├── SB_RESEARCH.md            # báo cáo nghiên cứu (bot-level)
    └── 2026-11-13/
        └── <cấu hình>/
            ├── report.csv
            └── manifest.md
```

## Quy ước đặt tên

- **Tên Bot:** tên file EA không đuôi (ví dụ `TM_TrendFollowerScalper`, `TM_SessionBreakout`).
- **Ngày chạy:** `YYYY-MM-DD` theo ngày chạy trên máy (không phải giai đoạn test).
- **Cấu hình:** tên run, mã hoá cờ/tham số (ví dụ `fx_3y_adx20_rr5`, `sb_12m_rr3`, `r6_realistic_500`).

Mỗi thư mục cấu hình chứa:
1. `report.csv` — số liệu do EA xuất (net, PF, trades, DD, commission…).
2. `manifest.md` — tóm tắt bot / ngày / cấu hình / chỉ số chính.

## Ghi chú kỹ thuật

- Report MT5 gốc (2026-11-12) là **HTML chụp từ Strategy Tester GUI** (Model 4 real ticks), kèm `manifest*.md` phân tích.
- Từ 2026-11-13, EA tự xuất **CSV** trong Strategy Tester (khóa `Report=` của MT5 không hoạt động ở chế độ `/config`), runner copy về đây.
- Runner: `tests/run_backtest_v2.ps1` (bot TF) · `tests/run_breakout.ps1` (bot SB).
- **Không ghi đè** report cũ. Mọi run lưu giữ, kể cả run âm (bằng chứng quan trọng).
- `.set`/hash/broker/spec của mỗi run: xem `manifest.md` + `docs/TECHNICAL_AUDIT.md`.
