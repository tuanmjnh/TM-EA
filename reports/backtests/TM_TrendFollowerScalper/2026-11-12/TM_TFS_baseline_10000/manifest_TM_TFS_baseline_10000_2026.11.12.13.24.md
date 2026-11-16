# Backtest Manifest: TM_TFS_baseline_10000 (run 2026.11.12 13:24)

- **Report file:** `ReportTester-464140826_2026.11.12.13.24.html`
- **EA:** `TM_TrendFollowerScalper.ex5` SHA256[0:16]=`B6EC2DAED291B047` — **stale vs `RiskGuard.mqh` (BUG-006)**
- **Preset used:** inputs match `config/sets/TM_TFS_cost_stress_10000.set` (TradeComment=`TM_TFS_STRESS`); no dedicated `baseline_10000.set` exists. Preset SHA256[0:16]=`441E51DB117B2EDC`
- **Broker / server:** Exness-MT5Trial17 (Build 6292)
- **Symbol / spec:** XAUUSDm, Digits=3, Point=0.001, TickSize=0.001
- **Account:** USD, deposit=10 000.00, leverage 1:100, hedging
- **Period:** M5, 2026.08.01 – 2026.10.31 (broker server time)
- **Model:** Every tick — **History Quality: 3% real ticks** (97% generated → invalid per SOURCE_SPEC §7.1)
- **Costs:** commission 0, swap default, spread modelled by ticks; `Max_Spread_Points=350`
- **Params (run):** RiskPercentPerTrade=0.5, Trail_ATR_Mult=2.0, Entry_Mode=3, News_Enable=true (no-op in tester)
- **Results:** Net **+1 509.49**, PF **2.45**, Trades 878, Deals 1756, BalDD 146.56 (1.35%), EqDD 240.52 (2.21%)
- **Classification:** **DIAGNOSTIC ONLY** — 3-month window, 3% real ticks, no commission, news filter inactive, no OOS.
- **Decision:** NOT usable as strategy proof. Superseded for evidence by the low-quality modelling flag.
