# TM-EA

**Project:** TM-EA  
**EA:** TM_TrendFollowerScalper  
**Initial strategy:** `TM_TFS_V1`  
**Platform:** MetaTrader 5 / MQL5

Trend-following micro-scalper for small accounts, using pullback and breakout entries, mandatory initial Stop Loss, adaptive trailing exits, and no Take Profit.

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

- No Take Profit orders. `Use_TP` must remain false; verify that no TP price is sent to the broker.
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

Core EA implementation complete (Pullback & Breakout modes implemented in `MQL5/Include/TM_EA/`, compiled binary `TM_TrendFollowerScalper.ex5` verified with 0 errors/0 warnings). Presets standardized in `config/sets/`. Currently in cost-stress testing and demo forward validation phase.
