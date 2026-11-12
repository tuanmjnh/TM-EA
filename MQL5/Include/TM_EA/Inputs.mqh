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

//--- Trend
input ENUM_TIMEFRAMES Trend_Timeframe = PERIOD_M15; // Trend timeframe
input int      FastEMA_HTF = 50;               // Fast EMA on trend timeframe
input int      SlowEMA_HTF = 200;              // Slow EMA on trend timeframe
input int      ADX_Period = 14;                // ADX period
input double   ADX_Threshold = 25.0;           // ADX trend threshold

//--- Entry
input ENUM_TIMEFRAMES Entry_Timeframe = PERIOD_M5; // Entry timeframe
input int      Entry_Mode = 1;                 // 1=Pullback, 2=Breakout, 3=Both
input int      PullbackEMA = 20;               // Pullback EMA on entry timeframe
input int      Pullback_Buffer_pips = 2;       // Pullback buffer around EMA
input int      ATR_Channel_Period = 14;        // ATR channel period
input double   BreakoutK = 0.7;                // Breakout k*ATR

//--- Exit / trailing
input bool     Use_TP = false;                 // Take profit disabled by design
input double   Trail_ATR_Mult = 2.0;           // Trailing distance = mult*ATR
input int      Trail_ATR_Period = 14;          // ATR period for trailing
input double   Activate_After_Profit_pips = 4.0; // Activate trailing after profit
input double   Trail_Step_pips = 2.0;           // Minimum SL modification step
input double   Breakeven_After_pips = 8.0;     // Move SL to breakeven after profit

//--- Risk / money management
input double   RiskPercentPerTrade = 0.5;      // Risk percent per trade
input double   Min_Volume = 0.01;              // Minimum volume
input double   Max_Volume = 0.05;              // Maximum volume
input int      Max_Concurrent_Positions = 1;  // Max concurrent positions

//--- Risk guard
input double   Max_Daily_Loss_Percent = 1.5;   // Stop new entries after daily loss
input int      Max_Consecutive_Losses = 4;     // Consecutive losses before cooldown
input int      CoolDown_Minutes = 30;          // Cooldown minutes
input int      Max_Spread_Points = 35;         // Max spread in points
input bool     News_Enable = true;             // Enable news filter
input int      News_Buffer_Minutes = 20;       // News buffer minutes
input bool     Use_Session_Filter = true;      // Enable session filter

#endif // TM_EA_INPUTS_MQH
