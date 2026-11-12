# Backtest Manifest: TM_TFS_cost_stress_10000

- **EA source version:** `TM_TrendFollowerScalper.mq5` (v1.2 Pullback & Breakout)
- **Preset file:** `config/sets/TM_TFS_cost_stress_10000.set`
- **Broker / Server:** Exness-MT5Trial17
- **Symbol / Specifications:** `XAUUSDm`, Digits = 3, Point = 0.001, Tick size = 0.001
- **Account:** USD, Initial Deposit = 10,000.00, Leverage = 1:100, Hedging
- **Timeframe:** M5
- **Test Period:** 2026.08.01 - 2026.10.31 (3 months)
- **Tester Model:** **Every tick based on real ticks (98% real ticks - 18,969,666 real ticks)**
- **Cost & Protection Guards:**
  - `Max_Spread_Points = 350` (Active 35 cents spread cap)
  - `News_Enable = true` (Active high-impact news filter)
  - `Trail_ATR_Mult = 2.0`
  - `Activate_After_Profit_pips = 4.0`
  - `Breakeven_After_pips = 8.0`
  - `Trail_Step_pips = 2.0`
  - `RiskPercentPerTrade = 0.5%`

## Kết quả hiệu suất (Performance Results)
- **Total Net Profit:** **+1,509.49 USD** (+15.09% ROI)
- **Profit Factor (PF):** **2.45**
- **Trade count:** **878 trades** (1,756 deals)
- **Drawdown:**
  - Equity Drawdown Maximal: **2.21% (240.52 USD)**
- **Quality:** **98% real ticks** (Dữ liệu tick thực Exness)

## Đánh giá & Quyết định (Decision)
- **Đánh giá:** Chiến lược vượt qua bài toán Stress-Test chi phí xuất sắc! Khi đối mặt với 18.9 triệu tick thực tế, ma sát spread và tin tức, EA vẫn đạt Profit Factor 2.45 và Drawdown tối đa chỉ 2.21%.
- **Quyết định:** **PASSED - Strong Candidate for Forward Test** (Cấu hình chuẩn hóa cao nhất của EA).

