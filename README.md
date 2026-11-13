# TM-EA

**Project:** TM-EA  
**EA:** TM_TrendFollowerScalper  
**Initial strategy:** `TM_TFS_V1`  
**Platform:** MetaTrader 5 / MQL5

Trend-following micro-scalper for small accounts: pullback entries (**v2.0: Breakout removed**), mandatory initial Stop Loss, adaptive trailing exits with **Take Profit (v2.0)**, and an equity-drawdown circuit breaker.

## Project layout

```text
TM-EA/
├── README.md
├── docs/
│   ├── USER_GUIDE.md            # Comprehensive user manual & beginner's guide
│   ├── MASTER.md                # Operating manual & AI orchestration hub
│   ├── ARCHITECTURE.md          # Implementation brief (safety rules win on conflict)
│   ├── SOURCE_SPEC_V1.md        # Single source of truth for strategy requirements
│   └── archive/v1/              # Superseded documents, read-only history
├── MQL5/
│   ├── Experts/                 # EA main file (.mq5) and compiled binary (.ex5)
│   └── Include/TM_EA/           # Modular EA components (.mqh)
├── config/
│   └── sets/                    # Versioned MT5 input presets (.set)
├── reports/
│   ├── backtests/               # MT5 Strategy Tester reports and HTML exports
│   └── forward/                 # Demo forward-test reports
├── tests/                       # Test plans, logs, checklists and validation notes
└── logs/                        # EA diagnostic logs (do not commit sensitive data)
```

## Document precedence

1. `docs/SOURCE_SPEC_V1.md` — strategy requirements, canonical input table.
2. `docs/ARCHITECTURE.md` — implementation detail. Where it conflicts with the spec, its **safety rules
   (section 2)** take priority; the spec was corrected accordingly on 2026-11-11.
3. `docs/archive/` — history only, never a source of truth.

## Important operating rules

- **v2.0:** Take Profit is now enabled by default (`Use_TP=true`, `TP_ATR_Mult`). When enabled, verify TP is always on the correct side of entry. (Pre-v2.0 builds had no TP.)
- Equity circuit breaker: when equity drawdown from the day baseline reaches `Max_Equity_DD_Percent`, close all positions and halt new entries for the day.
- Every opened position must have a valid initial Stop Loss attached. If the broker rejects the SL or the position is found without one, apply the documented emergency-protection procedure and block new entries.
- No martingale, grid, loss recovery sizing, or averaging down.
- Never force the broker's minimum lot if it exceeds the configured risk budget. Skip the trade instead.
- Trailing Stop may only move in the protective direction.
- A `.set` file is a configuration snapshot, not proof of a profitable strategy.
- Save every meaningful backtest report together with the exact `.set`, EA build/version, symbol, timeframe, broker specification, test dates, and modelling mode.

## Documentation & User Guides

- **Beginner & User Guide**: [docs/USER_GUIDE.md](docs/USER_GUIDE.md) — Step-by-step MT5 tester setup, preset selection, report export, and troubleshooting.
- **Master AI Manual**: [docs/MASTER.md](docs/MASTER.md) — Canonical reference, roadmap, strategy invariants, and developer manual.

## Current status

**v2.0 (2026-11-12) — deliberate strategy change:** entry is now **Pullback-only** (Breakout removed), **Take Profit is enabled** (`Use_TP=true`), and an **equity circuit breaker** (`Max_Equity_DD_Percent`) force-closes and halts on deep drawdown. Source updated; **NOT yet recompiled and NOT re-backtested.**

- ❌ The committed `TM_TrendFollowerScalper.ex5` predates the v2.0 source — must be rebuilt (BUG-006).
- ⚠️ **Every existing report is invalid for v2.0** (they were produced by the no-TP, Breakout-enabled build). Kept only as history.
- Open bugs: hard-coded FOK filling (BUG-002), consecutive-loss double-count on restart (BUG-003), news filter inactive in tester (BUG-004), sizing ignores commission (BUG-007), margin uses min volume (BUG-008) — see `tests/BUG_REPRODUCTIONS.md`.

Required next: compile → valid cost-stress (commission+slippage+news) → OOS, then Cent-account demo. Statuses in `tests/VALIDATION_RESULTS.md`; history in `reports/backtests/MANIFEST_INDEX.md`. **No backtest result here is proof of a profitable strategy.**
