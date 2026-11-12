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
| 3 — Entry logic (Pullback+Breakout) | Done (compiled) | `EntryEngine` + `compile-breakout.log`; signal logic **chưa** test runtime |
| 4 — SL + risk sizing | Done (compiled) | `compile-phase4.log`; unit harness sẵn sàng, chưa chạy |
| 5 — Execution + position tracking | **Partial** | Market order + SL + no-TP có; `OnTradeTransaction` **placeholder**; filling hard-code FOK (BUG-002) |
| 6 — Trailing | Done (compiled) | `compile-phase6.log`; monotonicity PASS static |
| 7 — Risk guards | **Partial** | `compile-phase7e.log`; news vô hiệu trong tester (BUG-004); restart double-count (BUG-003) |
| 8 — Dashboard + stats | Done (compiled) | `compile-phase8.log` |
| 9 — Backtest/report automation | **Partial** | Manifest template + per-run manifest; cost-stress hợp lệ **chưa chạy** |
| 10 — Robustness + demo | **NOT RUN** | `tests/robustness-checklist.md` toàn bộ chưa tick; không có OOS/forward |

## Safety checklist

- [x] `Use_TP=false` và không gửi TP (code: `m_trade.Buy/Sell(...,0.0, sl, 0.0, ...)`; OnInit chặn `Use_TP=true`)
- [ ] Mọi vị thế có SL hợp lệ — **chưa verify runtime**; không có emergency-close khi broker từ chối SL
- [x] Không có martingale/grid/averaging trong source (grep sạch)
- [x] Volume làm tròn xuống + cap `Max_Volume` (RiskManager) — PASS static
- [x] Minimum-lot breach → skip (RiskManager trả 0) — PASS static
- [x] Trailing SL không nới (BUY `newSL<=currentSL` continue; SELL `newSL>=currentSL` continue) — PASS static
- [ ] Risk guards không vô hiệu hoá quản lý vị thế — **chưa verify runtime**
- [ ] Daily loss + restart persistence — baseline/cooldown persist PASS static; consecutive-loss **FAIL** (BUG-003)
- [ ] News/spread/session guards đúng tài liệu — news **FAIL trong tester** (BUG-004)

## Binary ↔ source

- ❌ EX5 (`B6EC2DAED291B047`) **cũ hơn** `RiskGuard.mqh` (BUG-006). Cần biên dịch lại.

## Critical safety test rule

Do not proceed to the next phase if a critical safety test fails. Hiện tại **chưa** có test runtime nào chạy → chưa thể coi bất kỳ phase nào là "verified".
