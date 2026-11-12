# TM_TrendFollowerScalper tester presets

These `.set` files are MetaTrader 5 Strategy Tester input presets.

## How to use

1. Copy the selected `.set` file to the terminal tester profile folder:

   `<Terminal Data>\MQL5\Profiles\Tester\`

2. Set `ExpertParameters` in `TM_TFS_backtest.ini`:

   `ExpertParameters=TM_TFS_small_50.set`

3. Run:

   `terminal64.exe /config:TM_TFS_backtest.ini`

## Files

- `TM_TFS_small_50.set`: ~50 USD accounts, risk 10%, ATR mult 1.0, diagnostic filters relaxed.
- `TM_TFS_small_100.set`: ~100 USD accounts, risk 5%, ATR mult 1.2, diagnostic filters relaxed.
- `TM_TFS_standard_1000.set`: ~1000 USD and above, risk 0.5%, ATR mult 2.0, normal filters.
- `TM_TFS_conservative_5000.set`: ~5000 USD and above, risk 0.25%, ATR mult 2.5, normal filters.

## Notes

- `Max_Spread_Points=10000` and `News_Enable=false` in small presets are for diagnostic backtests only.
- Do not use small-account risk settings on large accounts without reviewing drawdown.
- `Use_TP` remains false by design; every trade must have a valid SL.