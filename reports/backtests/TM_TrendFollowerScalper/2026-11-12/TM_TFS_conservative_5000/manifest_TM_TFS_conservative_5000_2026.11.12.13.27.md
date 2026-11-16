# Backtest Manifest: TM_TFS_conservative_5000 (run 2026.11.12 13:27)

- **Report file:** `ReportTester-464140826_2026.11.12.13.27.html`
- **EA:** `TM_TrendFollowerScalper.ex5` SHA256[0:16]=`B6EC2DAED291B047` — **stale vs `RiskGuard.mqh` (BUG-006)**
- **Preset used:** `config/sets/TM_TFS_conservative_5000.set` SHA256[0:16]=`FAF3B48B598AC66C`
- **Broker / server:** Exness-MT5Trial17 (Build 6292)
- **Symbol / spec:** XAUUSDm, Digits=3, Point=0.001, TickSize=0.001
- **Account:** USD, deposit=5 000.00, leverage 1:100, hedging
- **Period:** M5, 2026.08.01 – 2026.10.31
- **Model:** Every tick — **History Quality: 98% real ticks**
- **Costs:** commission 0, swap default; `Max_Spread_Points=350`; News_Enable=true (no-op in tester)
- **Params (run):** RiskPercentPerTrade=0.25, Trail_ATR_Mult=2.5, Entry_Mode=3
- **Results:** Net **+149.96**, PF **1.73**, Trades 620, Deals 1240, BalDD 24.63 (0.48%), EqDD 44.42 (0.86%)
- **Classification:** DIAGNOSTIC ONLY — 3 months, no commission, news inactive, no OOS, single symbol.
- **Decision:** NOT strategy proof. At most a weak signal to investigate; PF 1.73 with 0 cost is not evidence.
