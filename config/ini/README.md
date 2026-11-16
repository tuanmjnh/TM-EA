# config/ini — MT5 Strategy Tester configs (theo EA)

Bản sao (copy-only) các file `.ini` cấu hình Strategy Tester, gom theo **tên EA**.

## Nguồn
- `<Terminal>\MQL5\Profiles\Tester\*.ini` → copy về đây (không xoá bản gốc trong MT5).
- `_project/` = các ini do dự án tự tạo (runner automation).

Terminal data path: `C:\Users\tuanmjnh\AppData\Roaming\MetaQuotes\Terminal\53785E099C927DB68A545C249CDBCE06`

## Cấu trúc
```
config/ini/
├── _project/                    # ini do dự án tạo (test_v2_run, test_sb_run, test_run_200, ...)
├── TM_TrendFollowerScalper/     # ini tester của EA trend (10)
├── TM_KimLa/                    # EA khác đang có trong terminal (4)
├── FvgGold/ ...                 # các EA khác trong terminal
└── ...                          # mỗi EA một folder
```

## Quy ước tên (MT5 tự sinh)
`<Expert>.<Symbol>.<TF>.<FromDate>_<ToDate>.<Model>.ini`
- **Model:** `0`=mỗi tick, `1`=1 phút OHLC, `2`=Open prices, `3`=math calc, `4`=**mỗi tick dựa trên tick thực**.
- **TF:** `M1/M5/M15/M30/H1/H4/...`
- `<Expert>` khớp tên `.ex5` trong `MQL5/Experts`.

## Lưu ý
- Các ini gốc do MT5 GUI ghi khi bấm chạy/optimize; runner của dự án (`tests/*.ps1`) tạo ini tạm ở `config/` khi chạy headless.
- File `.set` (preset input) nằm ở `config/sets/`; `.ini` (cấu hình tester) nằm ở đây.
- Không chứa thông tin tài khoản nhạy cảm ngoài login/server nếu preset in kèm — kiểm tra trước khi chia sẻ công khai.
