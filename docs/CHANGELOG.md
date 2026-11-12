# TM-EA — CHANGELOG

Định dạng theo `MASTER.md` §6.6. Chỉ ghi thay đổi **tài liệu/audit**; mã chiến lược và tham số không đổi trong lần này.

---

```yaml
[2026-11-12] - audit-v1.3
Thay đổi:
  - Đối chiếu MASTER với source/preset/report thực tế; tạo docs/TECHNICAL_AUDIT.md,
    docs/SOURCE_REPORT_CONSISTENCY.md, tests/BUG_REPRODUCTIONS.md, tests/VALIDATION_RESULTS.md.
  - Tạo harness test tests/units/TM_EA_UnitTests.mq5 (dùng chính header thật).
  - Tạo manifest cho từng lần kiểm thử + reports/backtests/MANIFEST_INDEX.md.
  - Sửa SOURCE_SPEC_V1.md canonical table: Max_Concurrent_Positions default 2 -> 1,
    Max_Daily_Loss_Percent default 5.0 -> 1.5 (khớp Inputs.mqh).
  - Viết lại MASTER §4 với số liệu thực tế và phân loại PASS/FAIL/DIAGNOSTIC/INVALID.
  - Cập nhật README "Current status" và tests/implementation-status.md cho trung thực.
Lý do:
  - MASTER tuyên bố cost-stress "PASSED" và 0/0 compile ở trạng thái hoàn tất, nhưng
    report cost_stress trùng khít report baseline (BUG-005), binary cũ hơn source (BUG-006),
    và hầu hết preset vốn thực tế đều lỗ. Cần đồng bộ tài liệu với bằng chứng.
File ảnh hưởng:
  - docs/MASTER.md, docs/TECHNICAL_AUDIT.md, docs/SOURCE_REPORT_CONSISTENCY.md, docs/CHANGELOG.md
  - docs/SOURCE_SPEC_V1.md
  - README.md, tests/implementation-status.md, tests/BUG_REPRODUCTIONS.md, tests/VALIDATION_RESULTS.md
  - tests/units/TM_EA_UnitTests.mq5
  - reports/backtests/MANIFEST_INDEX.md và các manifest_*.md
Report/manifest kèm theo:
  - reports/backtests/MANIFEST_INDEX.md
Kết quả cost-stress:
  - CHƯA CÓ cost-stress hợp lệ (commission/slippage/spread chưa stress; news vô hiệu trong tester).
Quyết định:
  - Giữ toàn bộ report cũ. Không đánh dấu PASS cho bất kỳ hạng mục nào thiếu bằng chứng.
  - Mã chiến lược và tham số KHÔNG đổi. Các bug trong tests/BUG_REPRODUCTIONS.md chờ test hồi quy.
```

---

## Lịch sử (giữ nguyên từ MASTER §8 trước đây)

```yaml
[2026-11-12] - v1.2
Thay đổi:
  - Max_Spread_Points 35 -> 350 (3-digit gold spread); news calendar unavailable trong tester không chặn.
  - Chuẩn hóa 7 preset trong config/sets/.
  - Soạn docs/USER_GUIDE.md.
Quyết định: Giữ lại.

[2026-11-12] - v1.1
Thay đổi:
  - Chuẩn hóa bảng canonical inputs; thêm preset cost_stress/realistic_200/realistic_500.
  - Triển khai Breakout (EvaluateBreakout) trong EntryEngine và tích hợp vào Main EA.
  - Compile 0 errors/0 warnings; đồng bộ EX5.
Quyết định: Giữ lại.
```

> Ghi chú: changelog v1.1/v1.2 claim "compile 0/0" có build log hỗ trợ (`tests/compile-*.log`), nhưng EX5 hiện tại cũ hơn `RiskGuard.mqh` (BUG-006) — cần biên dịch lại và cập nhật hash.
