# Backtest Manifest: TM_TFS_realistic_200 (run 2026.11.12 13:36)

- **Report file:** `ReportTester-464140826_2026.11.12.13.36.html`
- **EA:** `TM_TrendFollowerScalper.ex5` SHA256[0:16]=`B6EC2DAED291B047` — **stale vs `RiskGuard.mqh` (BUG-006)**
- **Preset used:** `config/sets/TM_TFS_realistic_200.set` SHA256[0:16]=`C9419BE7E2793EFC`
- **Broker / server:** Exness-MT5Trial17 (Build 6292)
- **Symbol / spec:** XAUUSDm, Digits=3, Point=0.001, TickSize=0.001
- **Account:** USD, deposit=200.00, leverage 1:100, hedging
- **Period:** M5, 2026.08.01 – 2026.10.31
- **Model:** Every tick — **History Quality: 98% real ticks**
- **Costs:** commission 0, swap default; `Max_Spread_Points=350`; News_Enable=true (no-op in tester)
- **Params (run):** RiskPercentPerTrade=2.0 (file), Trail_ATR_Mult=1.5, Entry_Mode=3
- **Results:** Net **−10.87**, PF **0.58**, Trades 69, Deals 138, BalDD 14.10 (7.04%), EqDD 16.13 (8.05%)
- **Classification:** **FAIL (negative)** — losing preset on 98% real ticks.
- **Decision:** REJECT. Not a viable configuration as tested.
