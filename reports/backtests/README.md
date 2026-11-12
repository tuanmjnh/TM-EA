# Thư mục Báo cáo Backtest (Strategy Tester Reports)

Cấu trúc lưu trữ báo cáo được phân cấp rõ ràng theo **Tên EA / Robot** và **Tên cấu hình Preset (.set)** để dễ dàng đối chiếu, quản lý theo thời gian.

## Cấu trúc thư mục

```text
reports/backtests/
├── README.md                               # Hướng dẫn quy chuẩn lưu trữ báo cáo
├── _template/                              # Mẫu manifest.md cho mỗi lần test
└── TM_TrendFollowerScalper/                # Thư mục theo tên Bot
    ├── TM_TFS_small_50/                    # Vốn 50 USD (Micro Account)
    ├── TM_TFS_small_100/                   # Vốn 100 USD
    ├── TM_TFS_realistic_200/               # Vốn 200 USD
    ├── TM_TFS_realistic_500/               # Vốn 500 USD (Khuyến nghị chuẩn)
    ├── TM_TFS_standard_1000/              # Vốn 1.000 USD
    ├── TM_TFS_conservative_5000/           # Vốn 5.000 USD
    ├── TM_TFS_cost_stress_10000/           # Vốn 10.000 USD (Kiểm tra chịu tải chi phí thật)
    └── TM_TFS_baseline_10000/              # Báo cáo chuẩn đoán ban đầu
```

## Quy chuẩn đặt tên file xuất báo cáo từ MT5

Khi xuất file HTML từ MT5 Strategy Tester (Chuột phải tab Backtest -> Report -> HTML), hãy lưu file vào đúng thư mục cấu hình preset tương ứng và đặt tên theo cú pháp:

`<Tên_Preset>_<YYYY.MM.DD_HH.MM>.html`

*Ví dụ:*
- `TM_TFS_small_50_2026.11.12_12.00.html` (Lưu vào `TM_TFS_small_50/`)
- `TM_TFS_realistic_500_2026.11.12_11.22.html` (Lưu vào `TM_TFS_realistic_500/`)

## Thành phần bắt buộc khi lưu báo cáo
Mỗi lần chạy backtest hoàn chỉnh cần có:
1. File xuất báo cáo HTML (`.html` hoặc `.htm`) kèm ảnh đồ thị sinh ra từ MT5.
2. File preset `.set` đã dùng trong lần chạy đó.
3. Bảng tóm tắt manifest theo mẫu `_template/manifest.md` ghi nhận: Thời gian test, Broker, Symbol, Spread/Commission, Net Profit, Profit Factor, Max Drawdown.
