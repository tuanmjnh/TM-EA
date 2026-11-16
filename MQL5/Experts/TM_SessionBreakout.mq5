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
input ENUM_TIMEFRAMES Entry_TF       = PERIOD_H1; // signal/indicator timeframe (H1 default)
input int      RangeStartHour        = 0;      // Asia range start (server hour)
input int      RangeEndHour          = 7;      // Asia range end   (server hour)
input int      TradeStartHour        = 7;      // earliest entry hour (session 1)
input int      TradeEndHour          = 20;     // latest entry hour (session 1)
input bool     Use_Session2          = false;  // second session (tested worse: PF 1.67 -> 0.94)
input int      Range2StartHour       = 7;      // session 2 range start (London)
input int      Range2EndHour         = 12;     // session 2 range end
input int      Trade2StartHour       = 12;     // session 2 entry start (NY)
input int      Trade2EndHour         = 20;     // session 2 entry end
input double   RiskPercentPerTrade   = 1.0;    // risk % of balance per trade
input double   RR                    = 5.0;    // take profit = RR * risk (plateau 4-6)
input double   SL_Range_Fraction     = 1.0;    // SL distance = this * range size (1.0 = opposite side)
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
bool     g_tradedSession2 = false;
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
   g_hADX = iADX(_Symbol, Entry_TF, ADX_Period);
   g_hATR = iATR(_Symbol, Entry_TF, 14);
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
//| Evaluate one session: range [rStart,rEnd), entry window [tStart,tEnd). |
bool TrySession(const int hour, const datetime dayStart, const double atrH1, const double adxH1,
                const int rStart, const int rEnd, const int tStart, const int tEnd)
{
   if(hour < tStart || hour >= tEnd)
      return false;

   datetime rangeFrom = dayStart + (datetime)(rStart * 3600);
   datetime rangeTo   = dayStart + (datetime)(rEnd * 3600);
   MqlRates rates[];
   int n = CopyRates(_Symbol, Entry_TF, rangeFrom, rangeTo, rates);
   if(n <= 0)
      return false;
   double rangeHigh = rates[0].high;
   double rangeLow  = rates[0].low;
   for(int i = 1; i < n; i++)
   {
      if(rates[i].high > rangeHigh) rangeHigh = rates[i].high;
      if(rates[i].low  < rangeLow)  rangeLow  = rates[i].low;
   }
   double rangeSize = rangeHigh - rangeLow;
   if(atrH1 > 0.0)
   {
      if(rangeSize < Min_Range_ATR * atrH1) return false;
      if(rangeSize > Max_Range_ATR * atrH1) return false;
   }
   if(Use_ADX_Filter && adxH1 < ADX_Min) return false;

   double c1 = iClose(_Symbol, Entry_TF, 1);
   datetime t1 = iTime(_Symbol, Entry_TF, 1);
   if(t1 < rangeTo || c1 <= 0.0) return false;

   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   if((ask - bid) / g_symbol.Point > (double)Max_Spread_Points) return false;

   int direction = 0; double entry = 0.0, stopLoss = 0.0;
   if(c1 > rangeHigh)      { direction = 1;  entry = ask; stopLoss = rangeHigh - SL_Range_Fraction * rangeSize; }
   else if(c1 < rangeLow)  { direction = -1; entry = bid; stopLoss = rangeLow  + SL_Range_Fraction * rangeSize; }
   else                    return false;

   double risk = MathAbs(entry - stopLoss);
   if(risk <= 0.0) return false;

   string volReason = "";
   double volume = CRiskManager::CalculateVolume(_Symbol, direction, RiskPercentPerTrade,
                                                 AccountInfoDouble(ACCOUNT_BALANCE),
                                                 entry, stopLoss, Min_Volume, Max_Volume,
                                                 g_symbol.VolumeStep, volReason);
   if(volume <= 0.0)
   {
      g_logger.Log("Breakout skipped: " + volReason);
      return false;
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
      return false;
   }
   g_logger.Log("Breakout opened dir=" + IntegerToString(direction) +
                " entry=" + DoubleToString(entry, 5) + " SL=" + DoubleToString(stopLoss, 5) +
                " TP=" + DoubleToString(takeProfit, 5) + " vol=" + DoubleToString(volume, 2) +
                " range=" + IntegerToString(rStart) + "-" + IntegerToString(rEnd));
   return true;
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
      g_tradedSession2 = false;
   }

   if(g_trade.CountOpenPositions(_Symbol) > 0)
      return;

   // act once per new signal bar
   datetime h1open = iTime(_Symbol, Entry_TF, 0);
   if(h1open == 0 || h1open == g_lastH1)
      return;
   g_lastH1 = h1open;

   double atrBuf[2], adxBuf[2];
   if(CopyBuffer(g_hATR, 0, 0, 2, atrBuf) != 2 || CopyBuffer(g_hADX, 0, 0, 2, adxBuf) != 2)
      return;
   double atrH1 = atrBuf[1];
   double adxH1 = adxBuf[1];

   if(OneTradePerDay && g_tradedToday)
      return;

   // Session 1: Asian range -> London/NY breakout
   if(!g_tradedToday && TrySession(dt.hour, dayStart, atrH1, adxH1,
                                   RangeStartHour, RangeEndHour, TradeStartHour, TradeEndHour))
   {
      g_tradedToday = true;
      return;
   }

   // Session 2 (optional): London range -> NY breakout
   if(Use_Session2 && !g_tradedSession2 && TrySession(dt.hour, dayStart, atrH1, adxH1,
                                   Range2StartHour, Range2EndHour, Trade2StartHour, Trade2EndHour))
   {
      g_tradedSession2 = true;
      g_tradedToday = true;
      return;
   }
}
