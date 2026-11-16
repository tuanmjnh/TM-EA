# Backtest Manifest: tmp/TM_TFS_small_50 2026.11.12 12:00 (MISFILED / DIAGNOSTIC)

- **Report file:** `TM_TFS_small_50_2026.11.12_12.00.html`
- **EA:** `TM_TrendFollowerScalper.ex5` (build unknown; predates 13:xx runs) — **stale vs `RiskGuard.mqh` (BUG-006)**
- **Preset used:** TradeComment=`TM_TFS_50`, RiskPercentPerTrade=5, Trail_ATR_Mult=1.0, Entry_Mode=3
- **Broker / server:** Exness-MT5Trial17
- **Symbol / spec:** XAUUSDm, Digits=3, Point=0.001, TickSize=0.001
- **Account:** USD, **deposit=100.00** — folder/name says "small_50" but deposit is 100 (BUG-009)
- **Period:** M5, 2026.08.01 – 2026.10.31
- **Model:** **History Quality: 3% real ticks** (invalid per SOURCE_SPEC §7.1)
- **Params (run):** RiskPercentPerTrade=5.0, Trail_ATR_Mult=1.0, Entry_Mode=3
- **Results:** Net **+66.85**, PF **1.39**, Trades 647, Deals 1294, BalDD 23.24 (18.27%), EqDD 31.89 (23.97%)
- **Classification:** **DIAGNOSTIC ONLY** — positive but 3% real ticks, no commission, news inactive, no OOS.
- **Decision:** NOT strategy proof. Note MASTER §4.3 labelled this run "Vốn 100 USD" while filing it under a `small_50` name.
