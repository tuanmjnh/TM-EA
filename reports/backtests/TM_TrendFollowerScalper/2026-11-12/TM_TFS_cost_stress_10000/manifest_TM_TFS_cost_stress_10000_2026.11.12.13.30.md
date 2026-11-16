# Backtest Manifest: TM_TFS_cost_stress_10000 (run 2026.11.12 13:30)

- **Report file:** `ReportTester-464140826_2026.11.12.13.30.html`
- **EA:** `TM_TrendFollowerScalper.ex5` SHA256[0:16]=`B6EC2DAED291B047` — **stale vs `RiskGuard.mqh` (BUG-006)**
- **Preset used:** `config/sets/TM_TFS_cost_stress_10000.set` SHA256[0:16]=`441E51DB117B2EDC`
- **Broker / server:** Exness-MT5Trial17 (Build 6292)
- **Symbol / spec:** XAUUSDm, Digits=3, Point=0.001, TickSize=0.001
- **Account:** USD, deposit=10 000.00, leverage 1:100, hedging
- **Period:** M5, 2026.08.01 – 2026.10.31
- **Model:** Every tick — **History Quality: 98% real ticks**
- **Costs:** commission 0, swap default; `Max_Spread_Points=350` (NOT a widened-spread stress), News_Enable=true (no-op in tester)
- **Params (run):** RiskPercentPerTrade=0.5, Trail_ATR_Mult=2.0, Entry_Mode=3
- **Results:** Net **+1 509.49**, PF **2.45**, Trades 878, Deals 1756, BalDD 146.56 (1.35%), EqDD 240.52 (2.21%)
- **❗ Integrity finding (BUG-005):** identical to `baseline_10000` report in 39 690/39 690 text lines; the **only** difference is the `History Quality` string (3% vs 98%). Same 878 trades and identical stats cannot result from two independent runs with different tick quality. Treated as **non-independent / not trustworthy**.
- **Classification:** **INVALID as cost-stress evidence.** No commission, no slippage stress, spread cap loose, news filter inactive, no OOS.
- **Decision:** REJECT as strategy proof. Previous `manifest.md` claim "PASSED — Strong Candidate" is **withdrawn** (see `docs/SOURCE_REPORT_CONSISTENCY.md` §5).
