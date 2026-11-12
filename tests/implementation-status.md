# Implementation status — TM-EA

**Project:** `D:\Applications\TM-EA`  
**EA:** `TM_TrendFollowerScalper`  
**Strategy ID:** `TM_TFS_V1`

## Phase status

| Phase | Status | Notes |
|---|---|---|
| 0 — Environment audit | In progress | MT5 build and compile path verified; symbol/account specs still to verify manually |
| 1 — Skeleton | Done | EA, inputs, symbol specs helper and logger created; compile: 0 errors, 0 warnings |
| 2 — Trend filter | Done | Closed-bar EMA/ADX trend filter implemented; compile: 0 errors, 0 warnings |
| 3 — Entry logic | Done (Pullback) | Pullback scanning on new closed entry bars implemented; Breakout not yet implemented |
| 4 — Initial SL + risk sizing | Done | Initial SL from swing/ATR and cash-risk volume with downward rounding implemented; compile: 0 errors, 0 warnings |
| 5 — Execution + position tracking | Done (basic) | Market orders with mandatory SL and no TP implemented; concurrent-position guard added; OnTradeTransaction hook still placeholder |
| 6 — Trailing | Done (ATR + break-even) | ATR trailing, break-even and monotonic SL protection implemented; compile: 0 errors, 0 warnings |
| 7 — Risk guards | Done | Daily loss, cooldown, spread, session, news fail-safe and margin checks implemented; compile: 0 errors, 0 warnings |
| 8 — Dashboard + stats | Done | Chart Comment dashboard implemented; compile: 0 errors, 0 warnings |
| 9 — Backtest/report automation | Template added | Report folder policy and manifest template added; execution remains manual in MT5 Strategy Tester |
| 10 — Robustness + demo | Checklist added | Robustness and forward-demo checklists added; actual tests remain to be run |

## Safety checklist
- [ ] `Use_TP=false`; no TP price sent
- [ ] Every opened position has valid initial SL
- [ ] No martingale/grid/averaging code
- [ ] Volume rounded down
- [ ] Minimum-lot breach skips trade
- [ ] Trailing SL never loosens
- [ ] Risk guards do not disable position management
- [ ] Daily loss and restart persistence verified
- [ ] News/spread/session guards behave as documented

## Critical safety test rule
Do not proceed to the next phase if a critical safety test fails.
