# Backtest Manifest: TM_TFS_small_100 (run 2026.11.12 13:41)

- **Report file:** `ReportTester-464140826_2026.11.12.13.41.html`
- **EA:** `TM_TrendFollowerScalper.ex5` SHA256[0:16]=`B6EC2DAED291B047` — **stale vs `RiskGuard.mqh` (BUG-006)**
- **Preset used:** `config/sets/TM_TFS_small_100.set` SHA256[0:16]=`0307F5AC3AE13C08`
- **Broker / server:** Exness-MT5Trial17 (Build 6292)
- **Symbol / spec:** XAUUSDm, Digits=3, Point=0.001, TickSize=0.001
- **Account:** USD, deposit=100.00, leverage 1:100, hedging
- **Period:** M5, 2026.08.01 – 2026.10.31
- **Model:** Every tick — **History Quality: 98% real ticks**
- **Costs:** commission 0, swap default; `Max_Spread_Points=350`; News_Enable=true (no-op in tester)
- **Params (run):** RiskPercentPerTrade=3.0, Trail_ATR_Mult=1.2, Entry_Mode=3
- **Results:** Net **−9.38**, PF **0.16**, Trades 44, Deals 88, BalDD 9.88 (9.84%), EqDD 10.41 (10.35%)
- **Classification:** **FAIL (negative)** — losing on 98% real ticks.
- **Decision:** REJECT.
