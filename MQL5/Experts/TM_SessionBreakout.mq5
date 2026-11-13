//+------------------------------------------------------------------+
//| TM_SessionBreakout.mq5                                          |
//| Research strategy: break the Asian-session range at London open. |
//| One trade per day, SL = opposite range side, TP = RR * risk.     |
//| No profitability claim. Research/validation only.                |
//+------------------------------------------------------------------+
#property copyright "TM-EA"
#property version   "1.00"
#property strict

#include "..\Include\TM_EA\SymbolSpecs.mqh"
#include "..\Include\TM_EA\Logger.mqh"
#include "..\Include\TM_EA\RiskManager.mqh"
#include "..\Include\TM_EA\TradeExecutor.mqh"

//--- Inputs
input bool     Enabled               = true;
input int      MagicNumber           = 555001;
input string   TradeComment          = "TM_SB_V1";
input int      RangeStartHour        = 0;      // Asia range start (server hour)
input int      RangeEndHour          = 7;      // Asia range end   (server hour)
input int      TradeStartHour        = 7;      // earliest entry hour
input int      TradeEndHour          = 20;     // latest entry hour
input double   RiskPercentPerTrade   = 1.0;    // risk % of balance per trade
input double   RR                    = 5.0;    // take profit = RR * risk (plateau 4-6)
input double   Min_Volume            = 0.01;
input double   Max_Volume            = 0.50;
input int      Max_Spread_Points     = 350;
input bool     OneTradePerDay        = true;
input bool     Use_ADX_Filter        = true;   // require ADX(H1) >= ADX_Min at breakout
input int      ADX_Period            = 14;
input double   ADX_Min               = 20.0;
input double   Min_Range_ATR         = 0.0;    // range must be >= this * ATR(H1)
input double   Max_Range_ATR         = 100.0;  // range must be <= this * ATR(H1)

CSymbolSpecs   g_symbol;
CLogger        g_logger;
CTradeExecutor g_trade;

int      g_hADX = INVALID_HANDLE;
int      g_hATR = INVALID_HANDLE;
datetime g_lastH1 = 0;
datetime g_lastDay = 0;
bool     g_tradedToday = false;
double   g_initBalance = 0.0;
double   g_peakEquity = 0.0;
double   g_maxDD = 0.0;

//+------------------------------------------------------------------+
void DumpTesterStats()
{
   if(!(bool)MQLInfoInteger(MQL_TESTER))
      return;

   double finalBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   double grossProfit = 0.0, grossLoss = 0.0;
   int trades = 0, wins = 0, losses = 0, consecLoss = 0, maxConsecLoss = 0;
   double largestWin = 0.0, largestLoss = 0.0;

   HistorySelect(0, TimeCurrent());
   int total = HistoryDealsTotal();
   for(int i = 0; i < total; i++)
   {
      ulong dt = HistoryDealGetTicket(i);
      if(dt == 0) continue;
      if(HistoryDealGetString(dt, DEAL_SYMBOL) != _Symbol) continue;
      if((int)HistoryDealGetInteger(dt, DEAL_MAGIC) != MagicNumber) continue;
      if((int)HistoryDealGetInteger(dt, DEAL_ENTRY) != DEAL_ENTRY_OUT) continue;

      double p = HistoryDealGetDouble(dt, DEAL_PROFIT) +
                 HistoryDealGetDouble(dt, DEAL_COMMISSION) +
                 HistoryDealGetDouble(dt, DEAL_SWAP);
      trades++;
      if(p > 0.0) { wins++; grossProfit += p; if(p > largestWin) largestWin = p; consecLoss = 0; }
      else if(p < 0.0) { losses++; grossLoss += p; if(p < largestLoss) largestLoss = p; consecLoss++; if(consecLoss > maxConsecLoss) maxConsecLoss = consecLoss; }
   }

   double pf = (grossLoss < 0.0) ? grossProfit / MathAbs(grossLoss) : 0.0;
   double ddPct = (g_peakEquity > 0.0) ? g_maxDD / g_peakEquity * 100.0 : 0.0;

   int fh = FileOpen("TM_EA_tester_report_" + _Symbol + ".csv", FILE_WRITE | FILE_CSV | FILE_ANSI | FILE_COMMON, ';');
   if(fh == INVALID_HANDLE) return;
   FileWrite(fh, "key", "value");
   FileWrite(fh, "symbol", _Symbol);
   FileWrite(fh, "expert", "TM_SessionBreakout");
   FileWrite(fh, "end_time", TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS));
   FileWrite(fh, "deposit", DoubleToString(g_initBalance, 2));
   FileWrite(fh, "final_balance", DoubleToString(finalBalance, 2));
   FileWrite(fh, "net_profit", DoubleToString(finalBalance - g_initBalance, 2));
   FileWrite(fh, "gross_profit", DoubleToString(grossProfit, 2));
   FileWrite(fh, "gross_loss", DoubleToString(grossLoss, 2));
   FileWrite(fh, "profit_factor", DoubleToString(pf, 3));
   FileWrite(fh, "trades", IntegerToString(trades));
   FileWrite(fh, "wins", IntegerToString(wins));
   FileWrite(fh, "losses", IntegerToString(losses));
   FileWrite(fh, "largest_win", DoubleToString(largestWin, 2));
   FileWrite(fh, "largest_loss", DoubleToString(largestLoss, 2));
   FileWrite(fh, "max_consec_losses", IntegerToString(maxConsecLoss));
   FileWrite(fh, "max_equity_dd_abs", DoubleToString(g_maxDD, 2));
   FileWrite(fh, "max_equity_dd_pct", DoubleToString(ddPct, 3));
   FileClose(fh);
   PrintFormat("SB stats: net=%.2f PF=%.3f trades=%d DD=%.2f%%", finalBalance - g_initBalance, pf, trades, ddPct);
}

//+------------------------------------------------------------------+
int OnInit()
{
   if(!Enabled) return INIT_SUCCEEDED;
   if(!g_symbol.Refresh(_Symbol))
   {
      Print("INIT FAILED: symbol specs");
      return INIT_FAILED;
   }
   if(!g_trade.Init(MagicNumber, 10))
   {
      Print("INIT FAILED: trade executor");
      return INIT_FAILED;
   }
   g_hADX = iADX(_Symbol, PERIOD_H1, ADX_Period);
   g_hATR = iATR(_Symbol, PERIOD_H1, 14);
   if(g_hADX == INVALID_HANDLE || g_hATR == INVALID_HANDLE)
   {
      Print("INIT FAILED: indicator handles");
      return INIT_FAILED;
   }
   g_logger.Init(_Symbol, MagicNumber);
   g_initBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   g_peakEquity = AccountInfoDouble(ACCOUNT_EQUITY);
   g_logger.Log("TM_SessionBreakout initialised.");
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   DumpTesterStats();
   if(g_hADX != INVALID_HANDLE) IndicatorRelease(g_hADX);
   if(g_hATR != INVALID_HANDLE) IndicatorRelease(g_hATR);
   g_logger.Log("deinit reason=" + IntegerToString(reason));
   g_logger.Deinit();
}

//+------------------------------------------------------------------+
void OnTick()
{
   if(!Enabled || !g_symbol.IsReady())
      return;

   if((bool)MQLInfoInteger(MQL_TESTER))
   {
      double eq = AccountInfoDouble(ACCOUNT_EQUITY);
      if(eq > g_peakEquity) g_peakEquity = eq;
      double dd = g_peakEquity - eq;
      if(dd > g_maxDD) g_maxDD = dd;
   }

   datetime now = TimeCurrent();
   MqlDateTime dt;
   TimeToStruct(now, dt);
   datetime dayStart = now - (dt.hour * 3600 + dt.min * 60 + dt.sec);

   if(dayStart != g_lastDay)
   {
      g_lastDay = dayStart;
      g_tradedToday = false;
   }

   if(g_trade.CountOpenPositions(_Symbol) > 0)
      return;
   if(OneTradePerDay && g_tradedToday)
      return;
   if(dt.hour < TradeStartHour || dt.hour >= TradeEndHour)
      return;

   // act once per new H1 bar
   datetime h1open = iTime(_Symbol, PERIOD_H1, 0);
   if(h1open == 0 || h1open == g_lastH1)
      return;
   g_lastH1 = h1open;

   // build today's range
   datetime rangeFrom = dayStart + (datetime)(RangeStartHour * 3600);
   datetime rangeTo   = dayStart + (datetime)(RangeEndHour * 3600);
   MqlRates rates[];
   int n = CopyRates(_Symbol, PERIOD_H1, rangeFrom, rangeTo, rates);
   if(n <= 0)
      return;
   double rangeHigh = rates[0].high;
   double rangeLow  = rates[0].low;
   for(int i = 1; i < n; i++)
   {
      if(rates[i].high > rangeHigh) rangeHigh = rates[i].high;
      if(rates[i].low  < rangeLow)  rangeLow  = rates[i].low;
   }

   // regime filters (on the last completed H1 bar)
   double atrBuf[2], adxBuf[2];
   if(CopyBuffer(g_hATR, 0, 0, 2, atrBuf) != 2 || CopyBuffer(g_hADX, 0, 0, 2, adxBuf) != 2)
      return;
   double atrH1 = atrBuf[1];
   double adxH1 = adxBuf[1];
   double rangeSize = rangeHigh - rangeLow;
   if(atrH1 > 0.0)
   {
      if(rangeSize < Min_Range_ATR * atrH1)
      {
         g_logger.Log("Breakout skipped: range too small vs ATR");
         return;
      }
      if(rangeSize > Max_Range_ATR * atrH1)
      {
         g_logger.Log("Breakout skipped: range too large vs ATR");
         return;
      }
   }
   if(Use_ADX_Filter && adxH1 < ADX_Min)
   {
      g_logger.Log("Breakout skipped: ADX too low (" + DoubleToString(adxH1, 1) + ")");
      return;
   }

   // breakout on last completed H1 bar, only after the range is complete
   double c1 = iClose(_Symbol, PERIOD_H1, 1);
   datetime t1 = iTime(_Symbol, PERIOD_H1, 1);
   if(t1 < rangeTo || c1 <= 0.0)
      return;

   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double spreadPoints = (ask - bid) / g_symbol.Point;
   if(spreadPoints > (double)Max_Spread_Points)
   {
      g_logger.Log("Breakout skipped: spread too high (" + DoubleToString(spreadPoints, 1) + ")");
      return;
   }

   int direction = 0;
   double entry = 0.0, stopLoss = 0.0;
   if(c1 > rangeHigh)
   {
      direction = 1;
      entry = ask;
      stopLoss = rangeLow;
   }
   else if(c1 < rangeLow)
   {
      direction = -1;
      entry = bid;
      stopLoss = rangeHigh;
   }
   else
      return;

   double risk = MathAbs(entry - stopLoss);
   if(risk <= 0.0)
      return;

   string volReason = "";
   double volume = CRiskManager::CalculateVolume(_Symbol, direction, RiskPercentPerTrade,
                                                 AccountInfoDouble(ACCOUNT_BALANCE),
                                                 entry, stopLoss, Min_Volume, Max_Volume,
                                                 g_symbol.VolumeStep, volReason);
   if(volume <= 0.0)
   {
      g_logger.Log("Breakout skipped: " + volReason);
      return;
   }

   double takeProfit = (direction > 0) ? (entry + RR * risk) : (entry - RR * risk);
   string comment = TradeComment + (direction > 0 ? "_BUY" : "_SELL");
   ulong ticket = 0;
   bool ok = (direction > 0)
             ? g_trade.OpenBuy(_Symbol, volume, stopLoss, takeProfit, comment, ticket)
             : g_trade.OpenSell(_Symbol, volume, stopLoss, takeProfit, comment, ticket);

   if(!ok)
   {
      g_logger.Log("Breakout order failed. Retcode=" + IntegerToString(g_trade.LastRetcode()));
      return;
   }

   g_tradedToday = true;
   g_logger.Log("Breakout opened: dir=" + IntegerToString(direction) +
                " entry=" + DoubleToString(entry, 5) +
                " SL=" + DoubleToString(stopLoss, 5) +
                " TP=" + DoubleToString(takeProfit, 5) +
                " vol=" + DoubleToString(volume, 2) +
                " rangeHigh=" + DoubleToString(rangeHigh, 5) +
                " rangeLow=" + DoubleToString(rangeLow, 5));
}
