# Backtest Manifest: TM_TFS_small_50 folder, run 2026.11.12 14:46 (MISFILED)

- **Report file:** `ReportTester-464140826_2026.11.12.14.46.html`
- **EA:** `TM_TrendFollowerScalper.ex5` SHA256[0:16]=`B6EC2DAED291B047` — **stale vs `RiskGuard.mqh` (BUG-006)**
- **Preset used:** unknown exact file; TradeComment=`TM_TFS_50`, RiskPercentPerTrade=5
- **Broker / server:** Exness-MT5Trial17 (Build 6292)
- **Symbol / spec:** XAUUSDm, Digits=3, Point=0.001, TickSize=0.001
- **Account:** USD, **deposit=100.00** — note: stored in the `TM_TFS_small_50` folder (BUG-009: misfiled)
- **Period:** M5, 2026.08.01 – 2026.10.31
- **Model:** Every tick — **History Quality: 98% real ticks**
- **Params (run):** RiskPercentPerTrade=5, Trail_ATR_Mult=1.0, Entry_Mode=3
- **Results:** Net **−50.92**, PF **0.14**, Trades 159, Deals 318, BalDD 51.58 (51.27%), EqDD 52.15 (51.76%)
- **Classification:** **FAIL (negative, severe)** — 51% drawdown.
- **Decision:** REJECT. Recommend relocating/renaming to reflect the 100 USD deposit.
