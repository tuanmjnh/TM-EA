//+------------------------------------------------------------------+
//| Inputs.mqh                                                       |
//| Canonical input parameters for TM_TrendFollowerScalper.           |
//+------------------------------------------------------------------+
#ifndef TM_EA_INPUTS_MQH
#define TM_EA_INPUTS_MQH

//--- General
input bool     Enabled = true;                 // Enable/disable EA
input int      MagicNumber = 123456;           // Magic number
input string   TradeComment = "TM_TFS_V1";     // Trade comment

//--- Direction bias
input int      Trade_Direction = 0;            // 0=Both, 1=Buy only, 2=Sell only

//--- Trend
input ENUM_TIMEFRAMES Trend_Timeframe = PERIOD_M15; // Trend timeframe
input int      FastEMA_HTF = 50;               // Fast EMA on trend timeframe
input int      SlowEMA_HTF = 200;              // Slow EMA on trend timeframe
input int      ADX_Period = 14;                // ADX period
input double   ADX_Threshold = 25.0;           // ADX trend threshold
input bool     Use_EMA_Slope_Filter = true;    // Require HTF fast-EMA slope in trade direction

//--- Entry
input ENUM_TIMEFRAMES Entry_Timeframe = PERIOD_M5; // Entry timeframe
input int      PullbackEMA = 20;               // Pullback EMA on entry timeframe
input int      Pullback_Buffer_pips = 2;       // Pullback buffer around EMA
input bool     Use_Breakout = true;            // Enable Breakout entry (else Pullback only)
input double   BreakoutK = 0.7;                // Breakout k*ATR
input bool     Require_Close_Beyond_EMA = true; // Pullback must reclaim EMA on the closed bar

//--- Exit / trailing
input bool     Use_TP = true;                  // Take profit enabled
input double   TP_ATR_Mult = 1.5;              // Take profit distance = mult*ATR
input double   SL_ATR_Mult = 1.0;              // Initial SL distance = mult*ATR (separate from trail)
input double   Trail_ATR_Mult = 2.0;           // Trailing distance = mult*ATR
input int      Trail_ATR_Period = 14;          // ATR period for trailing
input double   Activate_After_Profit_pips = 4.0; // Activate trailing after profit
input double   Trail_Step_pips = 2.0;           // Minimum SL modification step
input double   Breakeven_After_pips = 8.0;     // Move SL to breakeven after profit
input double   Breakeven_ATR_Mult = 1.0;       // ...and never before this * ATR (BUG-013 fix)
input bool     Use_Partial_Exit = false;       // Scale-out: close part (hurts trend-following; off by default)
input double   Partial_Exit_ATR_Mult = 1.0;    // Target profit = this * ATR
input double   Partial_Exit_Percent = 50.0;    // Percent of volume to close at the target

//--- Risk / money management
input double   RiskPercentPerTrade = 0.5;      // Risk percent per trade
input double   Min_Volume = 0.01;              // Minimum volume
input double   Max_Volume = 0.05;              // Maximum volume
input int      Max_Concurrent_Positions = 1;  // Max concurrent positions

//--- Risk guard
input double   Max_Equity_DD_Percent = 10.0;   // Circuit breaker: force-close all + stop day if equity DD >= this %
input double   Max_Daily_Loss_Percent = 1.5;   // Stop new entries after daily loss
input int      Max_Consecutive_Losses = 4;     // Consecutive losses before cooldown
input int      CoolDown_Minutes = 30;          // Cooldown minutes
input int      Max_Spread_Points = 35;         // Max spread in points
input bool     News_Enable = true;             // Enable news filter
input int      News_Buffer_Minutes = 20;       // News buffer minutes
input bool     Use_Session_Filter = true;      // Enable session filter

#endif // TM_EA_INPUTS_MQH
