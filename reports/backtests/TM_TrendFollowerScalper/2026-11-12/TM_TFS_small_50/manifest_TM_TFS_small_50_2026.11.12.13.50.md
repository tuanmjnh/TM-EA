# Backtest Manifest: TM_TFS_small_50 (run 2026.11.12 13:50)

- **Report file:** `ReportTester-464140826_2026.11.12.13.50.html`
- **EA:** `TM_TrendFollowerScalper.ex5` SHA256[0:16]=`B6EC2DAED291B047` — **stale vs `RiskGuard.mqh` (BUG-006)**
- **Preset used:** based on `config/sets/TM_TFS_small_50.set` SHA256[0:16]=`B0803F903068836F`, **BUT run used RiskPercentPerTrade=8.0** (file says 5.0 — mismatch)
- **Broker / server:** Exness-MT5Trial17 (Build 6292)
- **Symbol / spec:** XAUUSDm, Digits=3, Point=0.001, TickSize=0.001
- **Account:** USD, deposit=50.00, leverage 1:100, hedging
- **Period:** M5, 2026.08.01 – 2026.10.31
- **Model:** Every tick — **History Quality: 98% real ticks**
- **Costs:** commission 0; `Max_Spread_Points=350`; News_Enable=true (no-op in tester)
- **Params (run):** RiskPercentPerTrade=8.0, Trail_ATR_Mult=1.0, Entry_Mode=3
- **Results:** Net **−10.86**, PF **0.15**, Trades 47, Deals 94, BalDD 11.19 (22.23%), EqDD 11.41 (22.57%)
- **Classification:** **FAIL (negative)** — loses on 98% real ticks; DD 22% breaks the <20% gate.
- **Decision:** REJECT for live. Account-50 feasibility not demonstrated. (MASTER §4.3 risk figure of "10%" is wrong; run=8.0, file=5.0.)
