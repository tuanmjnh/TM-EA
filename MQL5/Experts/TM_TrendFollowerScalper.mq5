//+------------------------------------------------------------------+
//| TM_TrendFollowerScalper.mq5                                      |
//| TM_TFS_V1 v2.0 - Pullback-only, Take Profit, equity breaker.      |
//| No profitability claim.                                           |
//+------------------------------------------------------------------+
#property copyright "TM-EA"
#property version   "2.00"
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
double           g_testerInitBalance = 0.0;
double           g_testerPeakEquity  = 0.0;
double           g_testerMaxDD       = 0.0;
ulong            g_partialDone[];

bool PartialAlreadyDone(const ulong ticket)
{
   for(int i = 0; i < ArraySize(g_partialDone); i++)
      if(g_partialDone[i] == ticket)
         return true;
   return false;
}

void MarkPartialDone(const ulong ticket)
{
   int n = ArraySize(g_partialDone);
   ArrayResize(g_partialDone, n + 1);
   g_partialDone[n] = ticket;
}

// Scale-out: close part of a position once it reaches the ATR target (v2.5).
void ManagePartialExits(const double atrValue)
{
   if(!Use_Partial_Exit || atrValue <= 0.0)
      return;

   double targetDistance = atrValue * Partial_Exit_ATR_Mult;
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0)
         continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol)
         continue;
      if((int)PositionGetInteger(POSITION_MAGIC) != MagicNumber)
         continue;
      if(PartialAlreadyDone(ticket))
         continue;

      double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
      double volume = PositionGetDouble(POSITION_VOLUME);
      ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      double profitDistance = (type == POSITION_TYPE_BUY) ? (bid - openPrice) : (openPrice - ask);

      if(profitDistance < targetDistance)
         continue;

      double step = g_symbol.VolumeStep;
      double partVolume = volume * Partial_Exit_Percent / 100.0;
      if(step > 0.0)
         partVolume = MathFloor(partVolume / step) * step;
      partVolume = NormalizeDouble(partVolume, 2);
      double remaining = NormalizeDouble(volume - partVolume, 2);

      if(partVolume < g_symbol.VolumeMin || remaining < g_symbol.VolumeMin)
      {
         MarkPartialDone(ticket);
         continue;
      }

      if(g_trade.ClosePartial(ticket, partVolume))
         g_logger.Log("Partial exit: ticket=" + IntegerToString((int)ticket) +
                      " closed=" + DoubleToString(partVolume, 2) +
                      " remaining=" + DoubleToString(remaining, 2));
      MarkPartialDone(ticket);
   }
}

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
   text += "Use_TP: " + (Use_TP ? "true" : "false") + " (TP mult=" + DoubleToString(TP_ATR_Mult, 2) + ")\n";
   text += "Equity DD: " + DoubleToString(g_riskGuard.EquityDrawdownPercent(), 2) + "% (breaker at " + DoubleToString(Max_Equity_DD_Percent, 2) + "%)\n";

   Comment(text);
}

//+------------------------------------------------------------------+
//| Strategy Tester only: dump a machine-readable stats CSV.          |
//+------------------------------------------------------------------+
void DumpTesterStats()
{
   if(!(bool)MQLInfoInteger(MQL_TESTER))
      return;

   double finalBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   double grossProfit = 0.0, grossLoss = 0.0, commission = 0.0, swap = 0.0;
   double largestWin = 0.0, largestLoss = 0.0;
   int trades = 0, wins = 0, losses = 0, consecLoss = 0, maxConsecLoss = 0;

   HistorySelect(0, TimeCurrent());
   int total = HistoryDealsTotal();
   for(int i = 0; i < total; i++)
   {
      ulong dt = HistoryDealGetTicket(i);
      if(dt == 0)
         continue;
      if(HistoryDealGetString(dt, DEAL_SYMBOL) != _Symbol)
         continue;
      if((int)HistoryDealGetInteger(dt, DEAL_MAGIC) != MagicNumber)
         continue;
      if((int)HistoryDealGetInteger(dt, DEAL_ENTRY) != DEAL_ENTRY_OUT)
         continue;

      double p = HistoryDealGetDouble(dt, DEAL_PROFIT);
      double c = HistoryDealGetDouble(dt, DEAL_COMMISSION);
      double s = HistoryDealGetDouble(dt, DEAL_SWAP);
      commission += c;
      swap += s;
      double net = p + c + s;
      trades++;
      if(net > 0.0)
      {
         wins++;
         grossProfit += net;
         if(net > largestWin) largestWin = net;
         consecLoss = 0;
      }
      else if(net < 0.0)
      {
         losses++;
         grossLoss += net;
         if(net < largestLoss) largestLoss = net;
         consecLoss++;
         if(consecLoss > maxConsecLoss) maxConsecLoss = consecLoss;
      }
   }

   double pf = (grossLoss < 0.0) ? grossProfit / MathAbs(grossLoss) : 0.0;
   double ddPct = (g_testerPeakEquity > 0.0) ? g_testerMaxDD / g_testerPeakEquity * 100.0 : 0.0;

   int fh = FileOpen("TM_EA_tester_report_" + _Symbol + ".csv", FILE_WRITE | FILE_CSV | FILE_ANSI | FILE_COMMON, ';');
   if(fh == INVALID_HANDLE)
   {
      Print("Tester report file could not be opened, err=", GetLastError());
      return;
   }
   FileWrite(fh, "key", "value");
   FileWrite(fh, "symbol", _Symbol);
   FileWrite(fh, "expert", "TM_TrendFollowerScalper");
   FileWrite(fh, "end_time", TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS));
   FileWrite(fh, "deposit", DoubleToString(g_testerInitBalance, 2));
   FileWrite(fh, "final_balance", DoubleToString(finalBalance, 2));
   FileWrite(fh, "net_profit", DoubleToString(finalBalance - g_testerInitBalance, 2));
   FileWrite(fh, "gross_profit", DoubleToString(grossProfit, 2));
   FileWrite(fh, "gross_loss", DoubleToString(grossLoss, 2));
   FileWrite(fh, "profit_factor", DoubleToString(pf, 3));
   FileWrite(fh, "trades", IntegerToString(trades));
   FileWrite(fh, "wins", IntegerToString(wins));
   FileWrite(fh, "losses", IntegerToString(losses));
   FileWrite(fh, "commission", DoubleToString(commission, 2));
   FileWrite(fh, "swap", DoubleToString(swap, 2));
   FileWrite(fh, "largest_win", DoubleToString(largestWin, 2));
   FileWrite(fh, "largest_loss", DoubleToString(largestLoss, 2));
   FileWrite(fh, "max_consec_losses", IntegerToString(maxConsecLoss));
   FileWrite(fh, "max_equity_dd_abs", DoubleToString(g_testerMaxDD, 2));
   FileWrite(fh, "max_equity_dd_pct", DoubleToString(ddPct, 3));
   FileClose(fh);
   PrintFormat("Tester stats: net=%.2f PF=%.3f trades=%d DD=%.2f%%",
               finalBalance - g_testerInitBalance, pf, trades, ddPct);
}

//+------------------------------------------------------------------+
int OnInit()
{
   if(!Enabled)
   {
      Print("TM_TrendFollowerScalper is disabled by input.");
      return INIT_SUCCEEDED;
   }

   if(Use_TP && TP_ATR_Mult <= 0.0)
   {
      Print("INIT FAILED: Use_TP is true but TP_ATR_Mult <= 0.");
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

   if(!g_trend.Init(_Symbol, Trend_Timeframe, FastEMA_HTF, SlowEMA_HTF, ADX_Period, ADX_Threshold, Use_EMA_Slope_Filter))
   {
      Print("INIT FAILED: ", g_trend.Reason());
      return INIT_FAILED;
   }

   if(!g_entry.Init(_Symbol, Entry_Timeframe, PullbackEMA, Pullback_Buffer_pips, g_symbol.Point, Require_Close_Beyond_EMA))
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
   g_logger.Log("EA initialized. Symbol specs, trend filter, pullback entry, take profit, initial SL, risk-volume, trade executor, trailing, risk guards and dashboard loaded.");

   if(g_trend.Refresh())
   {
      g_lastTrendState = g_trend.State();
      g_logger.Log("Initial trend state=" + IntegerToString(g_lastTrendState) +
                   " reason=" + g_trend.Reason() +
                   " fastEMA=" + DoubleToString(g_trend.FastEma(), 5) +
                   " slowEMA=" + DoubleToString(g_trend.SlowEma(), 5) +
                   " ADX=" + DoubleToString(g_trend.Adx(), 2));
   }

   g_testerInitBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   g_testerPeakEquity  = AccountInfoDouble(ACCOUNT_EQUITY);
   g_testerMaxDD       = 0.0;

   g_lastEntryBarTime = iTime(_Symbol, Entry_Timeframe, 0);
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   DumpTesterStats();
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

   if((bool)MQLInfoInteger(MQL_TESTER))
   {
      double eq = AccountInfoDouble(ACCOUNT_EQUITY);
      if(eq > g_testerPeakEquity)
         g_testerPeakEquity = eq;
      double dd = g_testerPeakEquity - eq;
      if(dd > g_testerMaxDD)
         g_testerMaxDD = dd;
   }

   if(!g_trend.Refresh())
      return;

   g_riskGuard.Refresh(Max_Consecutive_Losses, CoolDown_Minutes);

   // Equity circuit breaker: force-close everything and halt for the day.
   if(!g_riskGuard.EquityBreakerTripped() &&
      g_riskGuard.EquityDrawdownPercent() >= Max_Equity_DD_Percent)
   {
      g_riskGuard.TripEquityBreaker();
      int closedByBreaker = g_trade.CloseAllPositions(_Symbol);
      g_logger.Log("EQUITY BREAKER tripped: DD=" + DoubleToString(g_riskGuard.EquityDrawdownPercent(), 2) +
                   "% >= " + DoubleToString(Max_Equity_DD_Percent, 2) + "%. Closed " +
                   IntegerToString(closedByBreaker) + " position(s). New entries halted for the day.");
   }

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
                                         Breakeven_ATR_Mult,
                                         g_symbol.TickSize,
                                         g_symbol.StopLevelPoints,
                                         g_symbol.FreezeLevelPoints);

   if(modifiedCount > 0)
      g_logger.Log("Trailing updated " + IntegerToString(modifiedCount) + " position(s).");

   ManagePartialExits(atrValue);

   UpdateDashboard(currentState, atrValue, modifiedCount);

   datetime currentEntryBarTime = iTime(_Symbol, Entry_Timeframe, 0);
   if(currentEntryBarTime == 0 || currentEntryBarTime == g_lastEntryBarTime)
      return;

   g_lastEntryBarTime = currentEntryBarTime;

   if(currentState != TREND_STATE_NONE)
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

      SSignal signal;
      signal.valid = false;

      // Pullback first, then optional Breakout (v2.1 restored).
      signal = g_entry.EvaluatePullback(currentState);
      if(!signal.valid && Use_Breakout)
         signal = g_entry.EvaluateBreakout(currentState, atrValue, BreakoutK);

      if(!signal.valid)
         return;

      if((signal.direction > 0 && Trade_Direction == 2) ||
         (signal.direction < 0 && Trade_Direction == 1))
      {
         g_logger.Log("Signal skipped: direction bias (Trade_Direction=" + IntegerToString(Trade_Direction) + ").");
         return;
      }

      double stopLoss = 0.0;
      if(signal.direction > 0)
      {
         stopLoss = CInitialStop::CalculateBuySL(signal.entryReference,
                                                 signal.invalidationLevel,
                                                 atrValue,
                                                 SL_ATR_Mult,
                                                 g_symbol.Point,
                                                 g_symbol.TickSize,
                                                 g_symbol.StopLevelPoints);
      }
      else
      {
         stopLoss = CInitialStop::CalculateSellSL(signal.entryReference,
                                                  signal.invalidationLevel,
                                                  atrValue,
                                                  SL_ATR_Mult,
                                                  g_symbol.Point,
                                                  g_symbol.TickSize,
                                                  g_symbol.StopLevelPoints);
      }

      string setupStr = (signal.setup == SETUP_BREAKOUT) ? "BREAKOUT" : "PULLBACK";

      if(stopLoss <= 0.0)
      {
         g_logger.Log(setupStr + " signal skipped: invalid initial SL. " + signal.reason +
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
         g_logger.Log(setupStr + " signal skipped: " + volumeReason +
                      " (signalBarTime=" + TimeToString(signal.signalBarTime, TIME_DATE | TIME_MINUTES) + ")");
         return;
      }

      if(g_trade.CountOpenPositions(_Symbol) >= Max_Concurrent_Positions)
      {
         g_logger.Log(setupStr + " signal skipped: max concurrent positions reached.");
         return;
      }

      double takeProfit = 0.0;
      if(Use_TP)
         takeProfit = signal.entryReference + (double)signal.direction * TP_ATR_Mult * atrValue;

      ulong ticket = 0;
      bool opened = false;
      string comment = TradeComment + "_" + setupStr;

      if(signal.direction > 0)
         opened = g_trade.OpenBuy(_Symbol, volume, stopLoss, takeProfit, comment, ticket);
      else
         opened = g_trade.OpenSell(_Symbol, volume, stopLoss, takeProfit, comment, ticket);

      if(!opened)
      {
         g_logger.Log("Order execution failed (" + setupStr + "). Retcode=" + IntegerToString(g_trade.LastRetcode()) +
                      " requestedVolume=" + DoubleToString(volume, 2) +
                      " stopLoss=" + DoubleToString(stopLoss, 5));
         return;
      }

      g_logger.Log("Order opened (" + setupStr + "): ticket=" + IntegerToString((int)ticket) +
                   " price=" + DoubleToString(g_trade.LastPrice(), 5) +
                   " volume=" + DoubleToString(volume, 2) +
                   " SL=" + DoubleToString(stopLoss, 5) +
                   " TP=" + DoubleToString(takeProfit, 5));
   }
}

//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction &trans,
                        const MqlTradeRequest &request,
                        const MqlTradeResult &result)
{
   // Position tracking hooks will be added in Phase 5.
}
