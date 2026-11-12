# Backtest Manifest: TM_TFS_conservative_5000

- **EA source version:** `TM_TrendFollowerScalper.mq5` (v1.2 Pullback & Breakout)
- **Preset file:** `config/sets/TM_TFS_conservative_5000.set`
- **Broker / Server:** Exness-MT5Trial17
- **Symbol / Specifications:** `XAUUSDm`, Digits = 3, Point = 0.001, Tick size = 0.001
- **Account:** USD, Initial Deposit = 5,000.00, Leverage = 1:100, Hedging
- **Timeframe:** M5
- **Test Period:** 2026.08.01 - 2026.10.31 (3 months)
- **Tester Model:** **Every tick based on real ticks (98% real ticks)**
- **Key Parameters:**
  - `RiskPercentPerTrade = 0.25%`
  - `Trail_ATR_Mult = 2.5`
  - `Activate_After_Profit_pips = 5.0`
  - `Breakeven_After_pips = 10.0`
  - `Trail_Step_pips = 2.5`
  - `Max_Spread_Points = 350`
  - `News_Enable = true`

## Kết quả hiệu suất (Performance Results)
- **Total Net Profit:** **+149.96 USD**
- **Profit Factor (PF):** **1.73**
- **Trade count:** **620 trades**
- **Drawdown:**
  - Equity Drawdown Maximal: **0.86% (44.42 USD)**
- **Quality:** **98% real ticks**

## Đánh giá & Quyết định (Decision)
- **Đánh giá:** Chiến lược cực kỳ an toàn. Drawdown chỉ **0.86%** trong suốt 3 tháng biến động mạnh của vàng. Trailing stop 2.5x ATR giúp EA không bao giờ bị nhiễu động thị trường quét nhầm.
- **Quyết định:** **Candidate for Forward Test** (Phù hợp tài khoản vốn lớn hoặc nhà đầu tư ưu tiên bảo toàn vốn tối đa).

