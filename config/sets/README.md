# TM_TrendFollowerScalper Presets (.set)

These `.set` files are MetaTrader 5 Strategy Tester input presets.

> **v2.0 (2026-11-12):** all presets are now **Pullback-only** (`Entry_Mode`/`BreakoutK`/`ATR_Channel_Period` removed), have **`Use_TP=true` + `TP_ATR_Mult=1.5`**, and **`Max_Equity_DD_Percent=10.0`**.
> ⚠️ Every result quoted below was produced by the **pre-v2.0 build (no TP, Breakout enabled)** and is **invalid for v2.0**. Re-run required.

## Preset Directory

### A. Realistic & Cost-Stress Presets (Recommended)
- `TM_TFS_cost_stress_10000.set`: Deposit 10,000 USD, Risk 0.5%, ATR mult 2.0x, Spread filter **350 points**, News filter ON. For the (still missing) valid cost-stress run.
- `TM_TFS_realistic_500.set`: Deposit 500 USD, Risk 1.0% ($5.00 cash risk), ATR mult 2.0x, Spread filter **350 points**, News filter ON. **Tested → PF 1.09 (negative / break-even).**
- `TM_TFS_realistic_200.set`: Deposit 200 USD, Risk **2.0% ($4.00 cash risk)**, ATR mult 1.5x (tighter SL), Spread filter **350 points**, News filter ON. **Tested → PF 0.58 (FAIL).**
- `TM_TFS_standard_1000.set`: Deposit 1,000 USD+, Risk 0.5%, ATR mult 2.0x, all protective filters active.
- `TM_TFS_conservative_5000.set`: Deposit 5,000 USD+, Risk 0.25%, ATR mult 2.5x, all protective filters active.

### B. Micro Account Presets (50 USD & 100 USD)
- `TM_TFS_small_100.set`: Deposit 100 USD, Risk 3.0% ($3.00 cash risk), ATR mult 1.2x (tight SL), Spread guard 350 points, News filter ON. Pullback-only; TP on; breaker 10%.
- `TM_TFS_small_50.set`: Deposit 50 USD, Risk 5.0% ($2.50 cash risk), ATR mult 1.0x, Spread guard 350 points, News filter ON. Pullback-only; TP on; breaker 10%. *Khuyến nghị: với 50 USD real, dùng tài khoản Cent (USC) để risk về mức an toàn 1.0% ($0.50).*

## How to Load in MT5 Strategy Tester

1. Direct in MT5 GUI:
   - Open Strategy Tester (`Ctrl+R`).
   - Select Expert: `TM_TrendFollowerScalper.ex5`.
   - Right-click in the Inputs tab -> **Load** -> select the desired `.set` file.
2. Or copy to terminal tester profile folder:
   `C:\Users\tuanmjnh\AppData\Roaming\MetaQuotes\Terminal\53785E099C927DB68A545C249CDBCE06\MQL5\Profiles\Tester\`


## Kim La EA Presets (.set)

Presets dành riêng cho EA **KIM LA** (`TM_KimLa.mq5` / `TM_KimLa.ex5`) tuân thủ triệt để tài liệu kỹ thuật `docs/EA-KIM-LA.md`:

- `TM_KimLa_XAUUSD_M5_Cent_5000USC.set`: **Preset chuẩn (Benchmark)** cho tài khoản Cent (5.000 USC ~ $50 USD). Risk 1.0%, SL 1.8 ATR, Breakeven đệm +0.7 ATR, Trailing ratchet đa tầng (2.0x / 4.0x / 6.0x ATR), MaxSpread 25 points, đóng lệnh cuối phiên (London/NY).
- `TM_KimLa_XAUUSD_M5_Conservative.set`: Preset phòng thủ cao cấp. Risk 0.5%, Max 1 trade/phiên, ADX >= 25, Spread max 20 points, Breakeven đệm +0.8 ATR.
- `TM_KimLa_XAUUSD_M5_Standard_500USD.set`: Preset cho tài khoản Standard USD ($500 USD), `InpLotMode=LOT_MODE_STANDARD`.
- `TM_KimLa_XAUUSD_M5_CostStress.set`: Preset kiểm tra sức chịu tải chi phí (Cost-Stress test), mở rộng spread lên 40 points, SL/TP phòng hộ.
