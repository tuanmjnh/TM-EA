# Implementation status — TM-EA

**Project:** `D:\Applications\TM-EA`  
**EA:** `TM_TrendFollowerScalper`  
**Strategy ID:** `TM_TFS_V1`  
**Updated:** 2026-11-12 (audit v1.3)

> Trạng thái phản ánh **bằng chứng thực tế**. `Done (compiled)` = có build log, **chưa** có test runtime.
> Chi tiết: `docs/TECHNICAL_AUDIT.md`, `docs/SOURCE_REPORT_CONSISTENCY.md`, `tests/VALIDATION_RESULTS.md`.

## Phase status

| Phase | Status | Bằng chứng / Ghi chú |
|---|---|---|
| 0 — Environment audit | **BLOCKED** | Build/compile path có; account mode & symbol specs **chưa** capture (`tests/environment-audit.md` Phase 0 gate chưa tick) |
| 1 — Skeleton | Done (compiled) | `compile-phase1.log` 0 errors/0 warnings |
| 2 — Trend filter | Done (compiled) | `compile-phase2.log` |
| 3 — Entry logic | Done (compiled, pre-v2.0) | v1.3: Pullback+Breakout. **v2.0: Breakout đã bỏ → Pullback-only.** Chưa compile lại, chưa test runtime |
| 4 — SL + risk sizing | Done (compiled) | `compile-phase4.log`; unit harness sẵn sàng, chưa chạy |
| 5 — Execution + position tracking | **Partial** | Market order + SL + no-TP có; `OnTradeTransaction` **placeholder**; filling hard-code FOK (BUG-002) |
| 6 — Trailing | Done (compiled) | `compile-phase6.log`; monotonicity PASS static |
| 7 — Risk guards | **Partial** | `compile-phase7e.log`; news vô hiệu trong tester (BUG-004); restart double-count (BUG-003) |
| 8 — Dashboard + stats | Done (compiled) | `compile-phase8.log` |
| 9 — Backtest/report automation | **Done (basic)** | Headless runner `tests/run_backtest_v2.ps1` + tester CSV dump; **đã chạy 10 backtest real-tick** (2026-11-13) |
| 10 — Robustness + demo | **NOT RUN** | `tests/robustness-checklist.md` toàn bộ chưa tick; không có OOS/forward |

## Safety checklist

- [ ] **[v2.0 đổi]** Take Profit: `Use_TP=true`, TP gửi khi mở lệnh. Cần verify TP luôn đúng phía (chưa runtime). (Trước v2.0: `Use_TP=false`, không gửi TP.)
- [ ] **[v2.0 mới]** Equity circuit breaker hoạt động: DD ≥ `Max_Equity_DD_Percent` → đóng hết + khóa trong ngày + persist (chưa runtime).
- [ ] Mọi vị thế có SL hợp lệ — **chưa verify runtime**; không có emergency-close khi broker từ chối SL
- [x] Không có martingale/grid/averaging trong source (grep sạch)
- [x] Volume làm tròn xuống + cap `Max_Volume` (RiskManager) — PASS static
- [x] Minimum-lot breach → skip (RiskManager trả 0) — PASS static
- [x] Trailing SL không nới (BUY `newSL<=currentSL` continue; SELL `newSL>=currentSL` continue) — PASS static
- [ ] Risk guards không vô hiệu hoá quản lý vị thế — **chưa verify runtime**
- [ ] Daily loss + restart persistence — baseline/cooldown persist PASS static; consecutive-loss **FAIL** (BUG-003)
- [ ] News/spread/session guards đúng tài liệu — news **FAIL trong tester** (BUG-004)

## Binary ↔ source

- ✅ EX5 v2.5 đã biên dịch `0 errors / 0 warnings`, SHA256[0:16]=`F76C419727E08752`. Log: `tests/compile-v2.log`. (BUG-013 fix; thêm `Trade_Direction`, `SL_ATR_Mult`, `Use_EMA_Slope_Filter`, `Require_Close_Beyond_EMA`, scale-out.)
- ✅ Đã chạy backtest real-tick: preset v2.0 đều âm; study tối ưu v2.1 tìm ra **BUG-013 (breakeven)** — fix nâng PF lên ~0.9 nhưng **chưa sinh lời**; tối ưu ADX gãy OOS. Xem `reports/backtests/_v2/`.

## Critical safety test rule

Do not proceed to the next phase if a critical safety test fails. Hiện tại **chưa** có test runtime nào chạy → chưa thể coi bất kỳ phase nào là "verified".
