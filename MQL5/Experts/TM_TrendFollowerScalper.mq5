//+------------------------------------------------------------------+
//| TM_TrendFollowerScalper.mq5                                      |
//| TM_TFS_V1 - trend-following micro-scalper skeleton.               |
//| No profitability claim.                                           |
//+------------------------------------------------------------------+
#property copyright "TM-EA"
#property version   "1.00"
#property strict

#include "..\Include\TM_EA\Types.mqh"
#include "..\Include\TM_EA\Inputs.mqh"
#include "..\Include\TM_EA\SymbolSpecs.mqh"
#include "..\Include\TM_EA\Logger.mqh"
#include "..\Include\TM_EA\TrendFilter.mqh"
#include "..\Include\TM_EA\EntryEngine.mqh"
#include "..\Include\TM_EA\InitialStop.mqh"
#include "..\Include\TM_EA\RiskManager.mqh"
#include "..\Include\TM_EA\TradeExecutor.mqh"
#include "..\Include\TM_EA\TrailingEngine.mqh"
#include "..\Include\TM_EA\RiskGuard.mqh"

CSymbolSpecs     g_symbol;
CLogger          g_logger;
CTrendFilter     g_trend;
CEntryEngine     g_entry;
CTradeExecutor   g_trade;
CTrailingEngine  g_trailing;
CRiskGuard       g_riskGuard;
ENUM_TREND_STATE g_lastTrendState = TREND_STATE_NONE;
datetime         g_lastEntryBarTime = 0;

string TrendStateText(ENUM_TREND_STATE state)
{
   if(state == TREND_STATE_UP) return "UPTREND";
   if(state == TREND_STATE_DOWN) return "DOWNTREND";
   return "SIDEWAYS/NONE";
}

void UpdateDashboard(ENUM_TREND_STATE trendState, double atrValue, int trailingModified)
{
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double spreadPoints = (ask - bid) / g_symbol.Point;
   int positions = g_trade.CountOpenPositions(_Symbol);
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);

   string text = "TM_TrendFollowerScalper V1\n";
   text += "Trend: " + TrendStateText(trendState) + "\n";
   text += "ADX: " + DoubleToString(g_trend.Adx(), 2) + "\n";
   text += "Fast EMA: " + DoubleToString(g_trend.FastEma(), 5) + "\n";
   text += "Slow EMA: " + DoubleToString(g_trend.SlowEma(), 5) + "\n";
   text += "ATR: " + DoubleToString(atrValue, 5) + "\n";
   text += "Spread (points): " + DoubleToString(spreadPoints, 1) + "\n";
   text += "Open positions: " + IntegerToString(positions) + "\n";
   text += "Balance: " + DoubleToString(balance, 2) + "\n";
   text += "Equity: " + DoubleToString(equity, 2) + "\n";
   text += "Trailing modified this tick: " + IntegerToString(trailingModified) + "\n";
   text += "Use_TP: false (no TP)\n";

   Comment(text);
}

//+------------------------------------------------------------------+
int OnInit()
{
   if(!Enabled)
   {
      Print("TM_TrendFollowerScalper is disabled by input.");
      return INIT_SUCCEEDED;
   }

   if(Use_TP)
   {
      Print("INIT FAILED: Use_TP must remain false. No Take Profit is allowed.");
      return INIT_FAILED;
   }

   if(!g_symbol.Refresh(_Symbol))
   {
      Print("INIT FAILED: unable to read symbol specifications for ", _Symbol);
      return INIT_FAILED;
   }

   if(!g_symbol.TradeAllowed)
   {
      Print("INIT FAILED: trading is disabled for ", _Symbol);
      return INIT_FAILED;
   }

   // Warm up the ATR indicator handle so BarsCalculated() can become ready.
   CInitialStop::ATRValue(_Symbol, Entry_Timeframe, Trail_ATR_Period);

   if(!g_trend.Init(_Symbol, Trend_Timeframe, FastEMA_HTF, SlowEMA_HTF, ADX_Period, ADX_Threshold))
   {
      Print("INIT FAILED: ", g_trend.Reason());
      return INIT_FAILED;
   }

   if(!g_entry.Init(_Symbol, Entry_Timeframe, PullbackEMA, Pullback_Buffer_pips, g_symbol.Point))
   {
      Print("INIT FAILED: unable to initialize entry engine.");
      return INIT_FAILED;
   }

   if(!g_trade.Init(MagicNumber, 10))
   {
      Print("INIT FAILED: unable to initialize trade executor.");
      return INIT_FAILED;
   }

   if(!g_trailing.Init(_Symbol, MagicNumber, g_symbol.Point))
   {
      Print("INIT FAILED: unable to initialize trailing engine.");
      return INIT_FAILED;
   }

   if(!g_riskGuard.Init(_Symbol, MagicNumber, g_symbol.Point))
   {
      Print("INIT FAILED: unable to initialize risk guard.");
      return INIT_FAILED;
   }

   g_logger.Init(_Symbol, MagicNumber);
   g_logger.Log("EA initialized. Symbol specs, trend filter, pullback entry, initial SL, risk-volume, trade executor, trailing, risk guards and dashboard loaded.");

   if(g_trend.Refresh())
   {
      g_lastTrendState = g_trend.State();
      g_logger.Log("Initial trend state=" + IntegerToString(g_lastTrendState) +
                   " reason=" + g_trend.Reason() +
                   " fastEMA=" + DoubleToString(g_trend.FastEma(), 5) +
                   " slowEMA=" + DoubleToString(g_trend.SlowEma(), 5) +
                   " ADX=" + DoubleToString(g_trend.Adx(), 2));
   }

   g_lastEntryBarTime = iTime(_Symbol, Entry_Timeframe, 0);
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   Comment("");
   g_entry.Deinit();
   g_trend.Deinit();
   CInitialStop::ReleaseATRHandle();
   g_logger.Log("EA deinitialized. Reason=" + IntegerToString(reason));
   g_logger.Deinit();
}

//+------------------------------------------------------------------+
void OnTick()
{
   if(!Enabled)
   {
      Comment("TM_TrendFollowerScalper is disabled by input.");
      return;
   }

   if(!g_trend.Refresh())
      return;

   g_riskGuard.Refresh(Max_Consecutive_Losses, CoolDown_Minutes);

   ENUM_TREND_STATE currentState = g_trend.State();
   if(currentState != g_lastTrendState)
   {
      g_lastTrendState = currentState;
      g_logger.Log("Trend state changed to " + IntegerToString(currentState) +
                   " reason=" + g_trend.Reason() +
                   " fastEMA=" + DoubleToString(g_trend.FastEma(), 5) +
                   " slowEMA=" + DoubleToString(g_trend.SlowEma(), 5) +
                   " ADX=" + DoubleToString(g_trend.Adx(), 2) +
                   " completedBarTime=" + TimeToString(g_trend.LastCompletedBarTime(), TIME_DATE | TIME_MINUTES));
   }

   double atrValue = CInitialStop::ATRValue(_Symbol, Entry_Timeframe, Trail_ATR_Period);
   int modifiedCount = g_trailing.Update(g_trade,
                                         atrValue,
                                         Trail_ATR_Mult,
                                         Activate_After_Profit_pips,
                                         Trail_Step_pips,
                                         Breakeven_After_pips,
                                         g_symbol.TickSize,
                                         g_symbol.StopLevelPoints,
                                         g_symbol.FreezeLevelPoints);

   if(modifiedCount > 0)
      g_logger.Log("Trailing updated " + IntegerToString(modifiedCount) + " position(s).");

   UpdateDashboard(currentState, atrValue, modifiedCount);

   datetime currentEntryBarTime = iTime(_Symbol, Entry_Timeframe, 0);
   if(currentEntryBarTime == 0 || currentEntryBarTime == g_lastEntryBarTime)
      return;

   g_lastEntryBarTime = currentEntryBarTime;

   if((Entry_Mode == 1 || Entry_Mode == 3) && currentState != TREND_STATE_NONE)
   {
      string guardReason = "";
      if(!g_riskGuard.CanOpenNewEntry(Max_Daily_Loss_Percent,
                                     Max_Spread_Points,
                                     Use_Session_Filter,
                                     News_Enable,
                                     News_Buffer_Minutes,
                                     Min_Volume,
                                     guardReason))
      {
         g_logger.Log("Entry blocked by risk guard: " + guardReason);
         return;
      }

      SSignal signal = g_entry.EvaluatePullback(currentState);
      if(!signal.valid)
         return;

      double stopLoss = 0.0;
      if(signal.direction > 0)
      {
         stopLoss = CInitialStop::CalculateBuySL(signal.entryReference,
                                                 signal.invalidationLevel,
                                                 atrValue,
                                                 Trail_ATR_Mult,
                                                 g_symbol.Point,
                                                 g_symbol.TickSize,
                                                 g_symbol.StopLevelPoints);
      }
      else
      {
         stopLoss = CInitialStop::CalculateSellSL(signal.entryReference,
                                                  signal.invalidationLevel,
                                                  atrValue,
                                                  Trail_ATR_Mult,
                                                  g_symbol.Point,
                                                  g_symbol.TickSize,
                                                  g_symbol.StopLevelPoints);
      }

      if(stopLoss <= 0.0)
      {
         g_logger.Log("Pullback signal skipped: invalid initial SL. " + signal.reason +
                      " entry=" + DoubleToString(signal.entryReference, 5) +
                      " invalidation=" + DoubleToString(signal.invalidationLevel, 5) +
                      " atr=" + DoubleToString(atrValue, 5) +
                      " point=" + DoubleToString(g_symbol.Point, 5));
         return;
      }

      string volumeReason = "";
      double volume = CRiskManager::CalculateVolume(_Symbol,
                                                   signal.direction,
                                                   RiskPercentPerTrade,
                                                   AccountInfoDouble(ACCOUNT_BALANCE),
                                                   signal.entryReference,
                                                   stopLoss,
                                                   Min_Volume,
                                                   Max_Volume,
                                                   g_symbol.VolumeStep,
                                                   volumeReason);

      if(volume <= 0.0)
      {
         g_logger.Log("Pullback signal skipped: " + volumeReason +
                      " (signalBarTime=" + TimeToString(signal.signalBarTime, TIME_DATE | TIME_MINUTES) + ")");
         return;
      }

      if(g_trade.CountOpenPositions(_Symbol) >= Max_Concurrent_Positions)
      {
         g_logger.Log("Pullback signal skipped: max concurrent positions reached.");
         return;
      }

      ulong ticket = 0;
      bool opened = false;
      if(signal.direction > 0)
         opened = g_trade.OpenBuy(_Symbol, volume, stopLoss, TradeComment, ticket);
      else
         opened = g_trade.OpenSell(_Symbol, volume, stopLoss, TradeComment, ticket);

      if(!opened)
      {
         g_logger.Log("Order execution failed. Retcode=" + IntegerToString(g_trade.LastRetcode()) +
                      " requestedVolume=" + DoubleToString(volume, 2) +
                      " stopLoss=" + DoubleToString(stopLoss, 5));
         return;
      }

      g_logger.Log("Order opened: ticket=" + IntegerToString((int)ticket) +
                   " price=" + DoubleToString(g_trade.LastPrice(), 5) +
                   " volume=" + DoubleToString(volume, 2) +
                   " SL=" + DoubleToString(stopLoss, 5) +
                   " (no TP)");
   }
}

//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction &trans,
                        const MqlTradeRequest &request,
                        const MqlTradeResult &result)
{
   // Position tracking hooks will be added in Phase 5.
}
