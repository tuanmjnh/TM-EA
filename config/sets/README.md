# TM_TrendFollowerScalper Presets (.set)

These `.set` files are MetaTrader 5 Strategy Tester input presets.

## Preset Directory

### A. Realistic & Cost-Stress Presets (Recommended)
- `TM_TFS_cost_stress_10000.set`: Deposit 10,000 USD, Risk 0.5%, ATR mult 2.0x, Spread filter **350 points**, News filter ON. For the (still missing) valid cost-stress run.
- `TM_TFS_realistic_500.set`: Deposit 500 USD, Risk 1.0% ($5.00 cash risk), ATR mult 2.0x, Spread filter **350 points**, News filter ON. **Tested → PF 1.09 (negative / break-even).**
- `TM_TFS_realistic_200.set`: Deposit 200 USD, Risk **2.0% ($4.00 cash risk)**, ATR mult 1.5x (tighter SL), Spread filter **350 points**, News filter ON. **Tested → PF 0.58 (FAIL).**
- `TM_TFS_standard_1000.set`: Deposit 1,000 USD+, Risk 0.5%, ATR mult 2.0x, all protective filters active.
- `TM_TFS_conservative_5000.set`: Deposit 5,000 USD+, Risk 0.25%, ATR mult 2.5x, all protective filters active.

### B. Micro Account Presets (50 USD & 100 USD)
- `TM_TFS_small_100.set`: Deposit 100 USD, Risk 3.0% ($3.00 cash risk), ATR mult 1.2x (tight SL), Spread guard 350 points, News filter ON, Entry_Mode 3 (Pullback & Breakout).
- `TM_TFS_small_50.set`: Deposit 50 USD, Risk 5.0% ($2.50 cash risk), ATR mult 1.0x (very tight SL), Spread guard 350 points, News filter ON, Entry_Mode 3 (Pullback & Breakout). *Khuyến nghị: Với vốn 50 USD, sử dụng tài khoản Cent (USC) để rủi ro về mức an toàn 1.0% ($0.50).*

## How to Load in MT5 Strategy Tester

1. Direct in MT5 GUI:
   - Open Strategy Tester (`Ctrl+R`).
   - Select Expert: `TM_TrendFollowerScalper.ex5`.
   - Right-click in the Inputs tab -> **Load** -> select the desired `.set` file.
2. Or copy to terminal tester profile folder:
   `C:\Users\tuanmjnh\AppData\Roaming\MetaQuotes\Terminal\53785E099C927DB68A545C249CDBCE06\MQL5\Profiles\Tester\`
