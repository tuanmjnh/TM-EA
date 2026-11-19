//+------------------------------------------------------------------+
//| TM_SessionBreakout.mq5                                          |
//| Research strategy: break the Asian-session range at London open. |
//| One trade per day, SL = opposite range side, TP = RR * risk.     |
//| v4.4 P0 Fixes: Auto GMT offset, verbose skip logging,            |
//| dynamic filling mode, commission sizing, warmup & gating.        |
//| No profitability claim. Research/validation only.                |
//+------------------------------------------------------------------+
#property copyright "TM-EA"
#property version   "4.40"
#property strict

#include "..\Include\TM_EA\SymbolSpecs.mqh"
#include "..\Include\TM_EA\Logger.mqh"
#include "..\Include\TM_EA\RiskManager.mqh"
#include "..\Include\TM_EA\TradeExecutor.mqh"

//--- Inputs
input bool     Enabled               = true;
input int      MagicNumber           = 555001;
input string   TradeComment          = "TM_SB_V4";
input ENUM_TIMEFRAMES Entry_TF       = PERIOD_H1; // signal/indicator timeframe (H1 default)

//--- Session 1 Timing (GMT Hours)
input int      BrokerGMTOffset       = 999;    // Broker GMT offset in hours (999 = auto-detect)
input int      RangeStartHour        = 0;      // Asia range start (GMT hour, 0 = 00:00 GMT)
input int      RangeEndHour          = 7;      // Asia range end   (GMT hour, 7 = 07:00 GMT)
input int      TradeStartHour        = 7;      // Earliest entry hour (GMT hour, 7 = 07:00 GMT)
input int      TradeEndHour          = 20;     // Latest entry hour (GMT hour, 20 = 20:00 GMT)

//--- Session 2 Timing (GMT Hours, Optional)
input bool     Use_Session2          = false;  // Second session (tested worse: PF 1.67 -> 0.94)
input int      Range2StartHour       = 7;      // Session 2 range start (GMT hour)
input int      Range2EndHour         = 12;     // Session 2 range end (GMT hour)
input int      Trade2StartHour       = 12;     // Session 2 entry start (GMT hour)
input int      Trade2EndHour         = 20;     // Session 2 entry end (GMT hour)

//--- Strategy Parameters
input double   RiskPercentPerTrade   = 1.0;    // Risk % of balance per trade
input double   CommissionPerLot      = 0.0;    // Commission per lot in account currency (0 = broker default)
input double   RR                    = 5.0;    // Take profit = RR * risk (plateau 4-6)
input double   SL_Range_Fraction     = 1.0;    // SL distance = this * range size (1.0 = opposite side)
input double   Min_Volume            = 0.01;
input double   Max_Volume            = 0.50;
input int      Max_Spread_Points     = 350;
input bool     OneTradePerDay        = true;
input bool     Use_ADX_Filter        = true;   // Require ADX(H1) >= ADX_Min at breakout
input int      ADX_Period            = 14;
input double   ADX_Min               = 20.0;
input double   Min_Range_ATR         = 0.0;    // Range must be >= this * ATR(H1)
input double   Max_Range_ATR         = 100.0;  // Range must be <= this * ATR(H1)

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
int      g_effectiveOffset = 0;

//+------------------------------------------------------------------+
//| Get effective broker GMT offset                                  |
//+------------------------------------------------------------------+
int DetectGMTOffset()
{
   if(BrokerGMTOffset != 999)
      return BrokerGMTOffset;

   datetime srv = TimeTradeServer();
   datetime gmt = TimeGMT();
   if(srv > 0 && gmt > 0)
   {
      int diffSeconds = (int)(srv - gmt);
      return (int)MathRound((double)diffSeconds / 3600.0);
   }
   return 0;
}

//+------------------------------------------------------------------+
//| Convert GMT hour to Broker Server hour                           |
//+------------------------------------------------------------------+
int GMTtoServerHour(const int gmtHour, const int offset)
{
   int h = (gmtHour + offset) % 24;
   if(h < 0) h += 24;
   return h;
}

//+------------------------------------------------------------------+
//| Convert Broker Server hour to GMT hour                           |
//+------------------------------------------------------------------+
int ServerToGMTHour(const int serverHour, const int offset)
{
   int h = (serverHour - offset) % 24;
   if(h < 0) h += 24;
   return h;
}

//+------------------------------------------------------------------+
//| Verify if trading session is currently open for the symbol       |
//+------------------------------------------------------------------+
bool IsTradeSessionOpen(const string symbol, const datetime time)
{
   MqlDateTime dt;
   TimeToStruct(time, dt);
   ENUM_DAY_OF_WEEK dow = (ENUM_DAY_OF_WEEK)dt.day_of_week;
   datetime from = 0, to = 0;
   uint sessionIndex = 0;
   uint secOfDay = (uint)(dt.hour * 3600 + dt.min * 60 + dt.sec);
   bool sessionFound = false;

   while(SymbolInfoSessionTrade(symbol, dow, sessionIndex, from, to))
   {
      sessionFound = true;
      uint secFrom = (uint)(from % 86400);
      uint secTo   = (uint)(to % 86400);
      if(secOfDay >= secFrom && secOfDay < secTo)
         return true;
      sessionIndex++;
   }
   return !sessionFound; // If broker does not specify schedule, allow trade
}

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
      Print("INIT FAILED: symbol specs for ", _Symbol);
      return INIT_FAILED;
   }

   // A4: Auto-select SYMBOL_FILLING_MODE dynamically
   if(!g_trade.Init(MagicNumber, 10, _Symbol))
   {
      Print("INIT FAILED: trade executor for ", _Symbol);
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

   // A1: Auto-detect GMT offset and log startup configuration
   g_effectiveOffset = DetectGMTOffset();
   int rStartSrv = GMTtoServerHour(RangeStartHour, g_effectiveOffset);
   int rEndSrv   = GMTtoServerHour(RangeEndHour, g_effectiveOffset);
   int tStartSrv = GMTtoServerHour(TradeStartHour, g_effectiveOffset);
   int tEndSrv   = GMTtoServerHour(TradeEndHour, g_effectiveOffset);

   g_logger.Log(StringFormat("TM_SessionBreakout v4.4 Initialised | Offset=%d (Auto=%s) | Range=[%02d:00-%02d:00 GMT -> %02d:00-%02d:00 Srv] | Trade=[%02d:00-%02d:00 GMT -> %02d:00-%02d:00 Srv] | Filling=%s | MinVol=%.2f MaxVol=%.2f",
                g_effectiveOffset, (BrokerGMTOffset == 999 ? "true" : "false"),
                RangeStartHour, RangeEndHour, rStartSrv, rEndSrv,
                TradeStartHour, TradeEndHour, tStartSrv, tEndSrv,
                EnumToString(g_trade.GetSelectedFilling()),
                Min_Volume, Max_Volume));

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
//| Evaluate one session: range [rStart,rEnd) GMT, window [tStart,tEnd) GMT |
//+------------------------------------------------------------------+
bool TrySession(const int currentServerHour, const datetime dayStart, const double atrH1, const double adxH1,
                const int rStartGMT, const int rEndGMT, const int tStartGMT, const int tEndGMT,
                const string sessionName)
{
   int rStart = GMTtoServerHour(rStartGMT, g_effectiveOffset);
   int rEnd   = GMTtoServerHour(rEndGMT, g_effectiveOffset);
   int tStart = GMTtoServerHour(tStartGMT, g_effectiveOffset);
   int tEnd   = GMTtoServerHour(tEndGMT, g_effectiveOffset);

   // A2: Log skip if outside trade window
   bool inWindow = false;
   if(tStart <= tEnd)
      inWindow = (currentServerHour >= tStart && currentServerHour < tEnd);
   else
      inWindow = (currentServerHour >= tStart || currentServerHour < tEnd);

   if(!inWindow)
   {
      g_logger.Log(StringFormat("SB skip: outside window | %s serverHour=%02d (window %02d-%02d) | gmtHour=%02d",
                   sessionName, currentServerHour, tStart, tEnd, ServerToGMTHour(currentServerHour, g_effectiveOffset)));
      return false;
   }

   // Calculate Range Start / End datetimes
   datetime rangeFrom = dayStart + (datetime)(rStart * 3600);
   datetime rangeTo   = dayStart + (datetime)(rEnd * 3600);
   if(rStart > rEnd) // Session crosses midnight
   {
      if(currentServerHour >= rStart)
         rangeTo += 86400;
      else
         rangeFrom -= 86400;
   }

   MqlRates rates[];
   int n = CopyRates(_Symbol, Entry_TF, rangeFrom, rangeTo, rates);
   if(n <= 0)
   {
      g_logger.Log(StringFormat("SB skip: CopyRates failed (n=%d) for range [%s to %s]",
                   n, TimeToString(rangeFrom, TIME_MINUTES), TimeToString(rangeTo, TIME_MINUTES)));
      return false;
   }

   double rangeHigh = rates[0].high;
   double rangeLow  = rates[0].low;
   for(int i = 1; i < n; i++)
   {
      if(rates[i].high > rangeHigh) rangeHigh = rates[i].high;
      if(rates[i].low  < rangeLow)  rangeLow  = rates[i].low;
   }
   double rangeSize = rangeHigh - rangeLow;

   // Range size filter vs ATR
   if(atrH1 > 0.0)
   {
      if(rangeSize < Min_Range_ATR * atrH1)
      {
         g_logger.Log(StringFormat("SB skip: range too narrow | range=%.2f < min=%.2f (ATR=%.2f)",
                      rangeSize, Min_Range_ATR * atrH1, atrH1));
         return false;
      }
      if(rangeSize > Max_Range_ATR * atrH1)
      {
         g_logger.Log(StringFormat("SB skip: range too wide | range=%.2f > max=%.2f (ATR=%.2f)",
                      rangeSize, Max_Range_ATR * atrH1, atrH1));
         return false;
      }
   }

   // ADX filter
   if(Use_ADX_Filter && adxH1 < ADX_Min)
   {
      g_logger.Log(StringFormat("SB skip: ADX filter rejected | adx=%.1f < min=%.1f | hour=%d range=%.2f",
                   adxH1, ADX_Min, currentServerHour, rangeSize));
      return false;
   }

   // Bar gating
   double c1 = iClose(_Symbol, Entry_TF, 1);
   datetime t1 = iTime(_Symbol, Entry_TF, 1);
   if(c1 <= 0.0)
   {
      g_logger.Log("SB skip: invalid close price c1 <= 0.0");
      return false;
   }

   if(t1 < rangeTo)
   {
      g_logger.Log(StringFormat("SB skip: bar 1 open (%s) is before range end (%s)",
                   TimeToString(t1, TIME_MINUTES), TimeToString(rangeTo, TIME_MINUTES)));
      return false;
   }

   // Spread check
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double currentSpreadPoints = (ask - bid) / g_symbol.Point;
   if(currentSpreadPoints > (double)Max_Spread_Points)
   {
      g_logger.Log(StringFormat("SB skip: spread too wide (%.0f > max %d)", currentSpreadPoints, Max_Spread_Points));
      return false;
   }

   // Trade Session check
   if(!IsTradeSessionOpen(_Symbol, TimeCurrent()))
   {
      g_logger.Log(StringFormat("SB skip: broker trading session closed for %s at server hour %d", _Symbol, currentServerHour));
      return false;
   }

   // Breakout Direction
   int direction = 0;
   double entry = 0.0, stopLoss = 0.0;
   if(c1 > rangeHigh)
   {
      direction = 1;
      entry = ask;
      stopLoss = rangeHigh - SL_Range_Fraction * rangeSize;
   }
   else if(c1 < rangeLow)
   {
      direction = -1;
      entry = bid;
      stopLoss = rangeLow + SL_Range_Fraction * rangeSize;
   }
   else
   {
      g_logger.Log(StringFormat("SB skip: no breakout | close=%.2f inside range [%.2f, %.2f] | hour=%d",
                   c1, rangeLow, rangeHigh, currentServerHour));
      return false;
   }

   double risk = MathAbs(entry - stopLoss);
   if(risk <= 0.0)
   {
      g_logger.Log("SB skip: zero risk distance");
      return false;
   }

   // A3: Sizing with Commission + Fallback SL fraction if min-lot exceeded
   string volReason = "";
   double volume = CRiskManager::CalculateVolume(_Symbol, direction, RiskPercentPerTrade,
                                                 AccountInfoDouble(ACCOUNT_BALANCE),
                                                 entry, stopLoss, Min_Volume, Max_Volume,
                                                 g_symbol.VolumeStep, volReason,
                                                 CommissionPerLot);

   // Sizing fallback: if min-lot exceeds risk cap and SL_Range_Fraction > 0.5, try 0.5 fraction
   if(volume <= 0.0 && volReason == "minimum lot exceeds risk cap" && SL_Range_Fraction > 0.5)
   {
      double fallbackSL = (direction > 0) ? (rangeHigh - 0.5 * rangeSize) : (rangeLow + 0.5 * rangeSize);
      double fallbackRisk = MathAbs(entry - fallbackSL);
      if(fallbackRisk > 0.0)
      {
         string fbReason = "";
         double fbVol = CRiskManager::CalculateVolume(_Symbol, direction, RiskPercentPerTrade,
                                                      AccountInfoDouble(ACCOUNT_BALANCE),
                                                      entry, fallbackSL, Min_Volume, Max_Volume,
                                                      g_symbol.VolumeStep, fbReason,
                                                      CommissionPerLot);
         if(fbVol >= Min_Volume)
         {
            g_logger.Log(StringFormat("SB sizing: adjusted SL_Range_Fraction from %.2f to 0.5 to fit min volume (vol=%.2f)",
                         SL_Range_Fraction, fbVol));
            stopLoss = fallbackSL;
            risk = fallbackRisk;
            volume = fbVol;
            volReason = "ok";
         }
      }
   }

   if(volume <= 0.0)
   {
      g_logger.Log(StringFormat("SB skip: sizing rejected (%s) | entry=%.2f sl=%.2f risk=%.2f minVol=%.2f",
                   volReason, entry, stopLoss, risk, Min_Volume));
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
      g_logger.Log(StringFormat("Breakout order failed | Retcode=%d (%s) | vol=%.2f entry=%.2f sl=%.2f tp=%.2f",
                   g_trade.LastRetcode(), g_trade.LastRetcode() == 10030 ? "INVALID_FILL" : "ERROR",
                   volume, entry, stopLoss, takeProfit));
      return false;
   }

   g_logger.Log(StringFormat("Breakout opened %s dir=%d entry=%.2f SL=%.2f TP=%.2f vol=%.2f range=[%.2f, %.2f] ticket=%I64u",
                sessionName, direction, entry, stopLoss, takeProfit, volume, rangeLow, rangeHigh, ticket));
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
      // Recalculate GMT offset daily to gracefully handle Daylight Saving Time changes
      g_effectiveOffset = DetectGMTOffset();
   }

   if(g_trade.CountOpenPositions(_Symbol) > 0)
      return;

   // Act once per new signal bar on Entry_TF
   datetime h1open = iTime(_Symbol, Entry_TF, 0);
   if(h1open == 0 || h1open == g_lastH1)
      return;
   g_lastH1 = h1open;

   // A5: Warmup check
   if(BarsCalculated(g_hADX) < ADX_Period + 2 || BarsCalculated(g_hATR) < 16)
   {
      static datetime lastWarmupLog = 0;
      if(now - lastWarmupLog >= 3600)
      {
         g_logger.Log(StringFormat("SB skip: indicators warming up | ADX=%d ATR=%d",
                      BarsCalculated(g_hADX), BarsCalculated(g_hATR)));
         lastWarmupLog = now;
      }
      return;
   }

   double atrBuf[2], adxBuf[2];
   if(CopyBuffer(g_hATR, 0, 0, 2, atrBuf) != 2 || CopyBuffer(g_hADX, 0, 0, 2, adxBuf) != 2)
   {
      g_logger.Log("SB skip: CopyBuffer failed for ATR or ADX buffers");
      return;
   }
   double atrH1 = atrBuf[1];
   double adxH1 = adxBuf[1];

   if(OneTradePerDay && g_tradedToday)
   {
      g_logger.Log(StringFormat("SB skip: already traded today | serverHour=%02d", dt.hour));
      return;
   }

   // Session 1: Asian range -> London/NY breakout
   if(!g_tradedToday && TrySession(dt.hour, dayStart, atrH1, adxH1,
                                   RangeStartHour, RangeEndHour, TradeStartHour, TradeEndHour, "Session1"))
   {
      g_tradedToday = true;
      return;
   }

   // Session 2 (optional): London range -> NY breakout
   if(Use_Session2 && !g_tradedSession2 && TrySession(dt.hour, dayStart, atrH1, adxH1,
                                   Range2StartHour, Range2EndHour, Trade2StartHour, Trade2EndHour, "Session2"))
   {
      g_tradedSession2 = true;
      g_tradedToday = true;
      return;
   }
}
