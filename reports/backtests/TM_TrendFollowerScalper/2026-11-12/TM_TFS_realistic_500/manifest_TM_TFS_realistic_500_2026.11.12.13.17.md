# Backtest Manifest: TM_TFS_realistic_500 (run 2026.11.12 13:17)

- **Report file:** `ReportTester-464140826_2026.11.12.13.17.html`
- **EA:** `TM_TrendFollowerScalper.ex5` SHA256[0:16]=`B6EC2DAED291B047` — **stale vs `RiskGuard.mqh` (BUG-006)**
- **Preset used:** `config/sets/TM_TFS_realistic_500.set` SHA256[0:16]=`C8C06BB2F2E5F34A`
- **Broker / server:** Exness-MT5Trial17 (Build 6292)
- **Symbol / spec:** XAUUSDm, Digits=3, Point=0.001, TickSize=0.001
- **Account:** USD, deposit=500.00, leverage 1:100, hedging
- **Period:** M5, 2026.08.01 – 2026.10.31
- **Model:** Every tick — **History Quality: 3% real ticks** (invalid per SOURCE_SPEC §7.1)
- **Costs:** commission 0, swap default; `Max_Spread_Points=350`; News_Enable=true (no-op in tester)
- **Params (run):** RiskPercentPerTrade=1.0, Trail_ATR_Mult=2.0, Entry_Mode=3
- **Results:** Net **+0.80**, PF **1.09**, Trades 53, Deals 106, BalDD 7.49 (1.49%), EqDD 9.84 (1.96%)
- **Classification:** **NEGATIVE / INCONCLUSIVE** — essentially break-even, only 53 trades, 3% real ticks.
- **Decision:** REJECT. Do not use realistic_500 as validated.
