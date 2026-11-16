# Backtest Manifest: TM_TFS_standard_1000 (run 2026.11.12 13:43)

- **Report file:** `ReportTester-464140826_2026.11.12.13.43.html`
- **EA:** `TM_TrendFollowerScalper.ex5` SHA256[0:16]=`B6EC2DAED291B047` — **stale vs `RiskGuard.mqh` (BUG-006)**
- **Preset used:** `config/sets/TM_TFS_standard_1000.set` SHA256[0:16]=`BA7961960D0A09FC`
- **Broker / server:** Exness-MT5Trial17 (Build 6292)
- **Symbol / spec:** XAUUSDm, Digits=3, Point=0.001, TickSize=0.001
- **Account:** USD, deposit=1 000.00, leverage 1:100, hedging
- **Period:** M5, 2026.08.01 – 2026.10.31
- **Model:** Every tick — **History Quality: 98% real ticks**
- **Costs:** commission 0; `Max_Spread_Points=350`; News_Enable=true (no-op in tester)
- **Params (run):** RiskPercentPerTrade=0.5, Trail_ATR_Mult=2.0, Entry_Mode=3
- **Results:** Net **−7.14**, PF **0.31**, Trades 54, Deals 108, BalDD 8.96 (0.90%), EqDD 12.36 (1.24%)
- **Classification:** **FAIL (negative)**.
- **Decision:** REJECT. Not mentioned in MASTER §4 — must be recorded.
