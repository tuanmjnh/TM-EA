//+------------------------------------------------------------------+
//|                                                    TM_KimLa.mq5 |
//|                             KIM LA (Compass EA) - Spec V1.0      |
//|               Multi-Timeframe Gold Day Trading: D1 -> H1 -> M5   |
//|                    Mandate: Preserve Capital (Khong Cut Von)    |
//|                                       Copyright 2026, TM-EA     |
//+------------------------------------------------------------------+
#property copyright   "TM-EA"
#property link        "https://github.com/TM-EA"
#property version     "1.10"
#property description "KIM LA EA - Multi-timeframe trend follower for XAUUSD M5."
#property description "D1: Macro Regime | H1: Session Bias | M5: Pullback Entry"
#property description "Core: Breakeven buffer + Accelerated ratchet trailing."
#property strict

#include <Trade\Trade.mqh>

//+------------------------------------------------------------------+
//| Enums and Constants                                              |
//+------------------------------------------------------------------+
enum ENUM_REGIME_D1
{
   REGIME_NONE = 0,
   REGIME_TREND_LONG,
   REGIME_TREND_SHORT,
   REGIME_RANGE
};

enum ENUM_BIAS_H1
{
   BIAS_NONE = 0,
   BIAS_LONG,
   BIAS_SHORT
};

enum ENUM_SESSION_TYPE
{
   SESSION_ASIA = 0,
   SESSION_LONDON,
   SESSION_NY
};

enum ENUM_LOT_MODE
{
   LOT_MODE_CENT,      // Cent Account (USC)
   LOT_MODE_STANDARD   // Standard Account (USD)
};

enum ENUM_EXEC_TYPE
{
   EXEC_MARKET_CONFIRMED, // Market order on M5 confirmed pullback bar (Recommended)
   EXEC_LIMIT_ORDER       // Pending Limit order at EMA20 with timeout
};

//+------------------------------------------------------------------+
//| Input Parameters                                                 |
//+------------------------------------------------------------------+
input group "=== EA Identity ==="
input bool           InpEnabled              = true;             // EA Enabled
input int            InpMagicNumber          = 20261113;         // Magic Number
input string         InpTradeComment         = "KIM_LA_M5";      // Trade Comment

input group "=== Indicator Settings ==="
input int            InpPoints_ATR           = 14;               // ATR Period (M5, H1, D1)
input int            InpEMA_D1_Period        = 200;              // D1 Regime EMA Period
input int            InpEMA_H1_Period        = 50;               // H1 Bias EMA Period
input int            InpEMA_M5_Period        = 20;               // M5 Pullback EMA Period
input int            InpADX_Period           = 14;               // ADX Period (M5)
input double         InpADX_EntryMin         = 20.0;             // Minimum ADX for M5 Entry (default 20-22)
input double         InpH1_Flat_Threshold    = 0.15;             // H1 Flat Threshold (x ATR H1)

input group "=== Multi-Timeframe Alignment ==="
input bool           InpStrictD1Alignment    = true;             // Require D1 trend direction (Filter out counter-trend trades)

input group "=== Risk & Lot Sizing ==="
input ENUM_LOT_MODE  InpLotMode              = LOT_MODE_CENT;    // Lot Mode
input double         InpRiskPct              = 0.5;              // Risk % per trade (0.5% recommended for safety)
input double         InpMinLot               = 0.01;             // Minimum Lot
input double         InpMaxLot               = 0.10;             // Maximum Lot Cap
input bool           InpAllowMinLotFallback  = true;             // Fallback to MinLot if calculated lot < MinLot

input group "=== Circuit Breakers & Loss Guard ==="
input double         InpMaxDailyLossPct      = 2.0;              // Max daily loss % (circuit breaker: halt trading for day)
input int            InpMaxConsecLosses      = 2;                // Max consecutive losses before cooldown
input int            InpCooldownAfterLossMin = 60;               // Cooldown minutes after consecutive losses

input group "=== Stop Loss & Take Profit ==="
input double         InpATR_EntryStop        = 1.8;              // Initial SL = 1.8 x ATR(M5)
input bool           InpUseTakeProfit        = true;             // Enable Take Profit (lock profit on surges)
input double         InpTP_ATR_Mult          = 2.5;              // Take Profit = 2.5 x ATR(M5) (0 = disabled)
input double         InpATR_BreakevenBuffer  = 0.7;              // Breakeven Buffer = 0.7 x ATR(M5)
input double         InpTrailStart           = 2.0;              // Trailing Start at >= 2.0 x ATR(M5)
input double         InpTrailStep1           = 1.8;              // Trailing Distance Stage 1 (profit >= 2.0x)
input double         InpTrailStep2           = 1.3;              // Trailing Distance Stage 2 (profit >= 4.0x)
input double         InpTrailStep3           = 1.0;              // Trailing Distance Stage 3 (profit >= 6.0x)

input group "=== Session Times (GMT) ==="
input int            InpServerGMTOffset      = 0;                // Broker Server GMT Offset (Hours, 0 for Exness)
input int            InpLondonStart_Hour     = 8;                // London Start Hour (GMT)
input int            InpLondonStart_Min      = 0;                // London Start Minute (GMT)
input int            InpLondonEnd_Hour       = 17;               // London End Hour (GMT)
input int            InpNYStart_Hour         = 13;               // NY Start Hour (GMT)
input int            InpNYStart_Min          = 30;               // NY Start Minute (GMT)
input int            InpNYEnd_Hour           = 21;               // NY End Hour (GMT)
input int            InpMaxTradesPerSession  = 2;                // Max trades per session
input bool           InpCloseOnSessionEnd    = true;             // Market-close open trades when session ends

input group "=== Execution & Protection ==="
input ENUM_EXEC_TYPE InpExecType             = EXEC_MARKET_CONFIRMED; // Entry Execution Mode
input int            InpMaxSpreadPoints      = 350;              // Max spread in points (e.g. 350 for 3-digit Gold = $0.35)
input int            InpMaxSeconds_EntryFill = 60;               // Pending Limit timeout (seconds)
input int            InpPullbackSwingBars    = 4;                // Bars for swing support/resistance check
input int            InpCooldownReconnectSec = 0;                // Cooldown after restart/reconnect (sec, 0 in tester)

//+------------------------------------------------------------------+
//| Global Variables & State                                         |
//+------------------------------------------------------------------+
CTrade            g_trade;
int               g_handleATR_M5     = INVALID_HANDLE;
int               g_handleATR_H1     = INVALID_HANDLE;
int               g_handleATR_D1     = INVALID_HANDLE;
int               g_handleEMA_D1     = INVALID_HANDLE;
int               g_handleEMA_H1     = INVALID_HANDLE;
int               g_handleEMA_M5     = INVALID_HANDLE;
int               g_handleADX_M5     = INVALID_HANDLE;

datetime          g_lastM5BarTime    = 0;
datetime          g_initTime         = 0;
ENUM_SESSION_TYPE g_currentSession   = SESSION_ASIA;
ENUM_SESSION_TYPE g_lastSessionType  = SESSION_ASIA;
ENUM_REGIME_D1    g_d1Regime         = REGIME_NONE;
ENUM_BIAS_H1      g_sessionH1Bias    = BIAS_NONE;
int               g_sessionTrades    = 0;
int               g_lastSessionDay   = -1;
long              g_adjustedMaxSpread= 350;

// Performance metrics for reporting
struct SPerformanceStats
{
   int    totalTrades;
   int    winTrades;
   int    lossTrades;
   int    breakevenExits;
   int    trailingExits;
   int    slInitialExits;
   int    sessionEndExits;
   double grossProfit;
   double grossLoss;
   double maxEquityDD;
   double peakEquity;
   double initialBalance;
};
SPerformanceStats g_stats;

//+------------------------------------------------------------------+
//| Forward Declarations                                             |
//+------------------------------------------------------------------+
bool              IsCircuitBreakerTripped();
void              UpdateSessionsAndBias();
void              EvaluateD1Regime();
void              CalculateH1Bias();
void              CheckM5Entry();
void              ExecuteOrderEntry(ENUM_POSITION_TYPE type, double refPrice, double atrM5, double adx);
void              ManageOpenPositions();
void              CleanExpiredPendingOrders();
void              CloseAllPositionsOnSessionEnd();
double            CalculatePositionLot(const double stopLossDistance);
datetime          GetGMTTime();
string            FormatSessionName(ENUM_SESSION_TYPE session);
string            FormatBiasName(ENUM_BIAS_H1 bias);
string            FormatRegimeName(ENUM_REGIME_D1 regime);
void              UpdateChartDashboard();
void              LogTradeAction(const string text);
int               CountActivePositions();
int               CountActivePendingOrders();

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   g_initTime = TimeCurrent();
   ZeroMemory(g_stats);
   g_stats.initialBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   g_stats.peakEquity     = g_stats.initialBalance;

   // Auto-adjust spread points if broker uses 2-digit vs 3-digit gold
   g_adjustedMaxSpread = InpMaxSpreadPoints;
   if(_Digits == 2 && InpMaxSpreadPoints > 50)
      g_adjustedMaxSpread = InpMaxSpreadPoints / 10;
   else if(_Digits == 3 && InpMaxSpreadPoints <= 50)
      g_adjustedMaxSpread = InpMaxSpreadPoints * 10;

   // Setup CTrade execution parameters
   g_trade.SetExpertMagicNumber(InpMagicNumber);
   g_trade.SetDeviationInPoints(20);

   // Configure robust filling mode
   uint fillingMode = (uint)SymbolInfoInteger(_Symbol, SYMBOL_FILLING_MODE);
   if((fillingMode & SYMBOL_FILLING_FOK) != 0)
      g_trade.SetTypeFilling(ORDER_FILLING_FOK);
   else if((fillingMode & SYMBOL_FILLING_IOC) != 0)
      g_trade.SetTypeFilling(ORDER_FILLING_IOC);
   else
      g_trade.SetTypeFilling(ORDER_FILLING_RETURN);

   g_trade.LogLevel(LOG_LEVEL_ERRORS);

   // Create indicator handles
   g_handleATR_M5 = iATR(_Symbol, PERIOD_M5, InpPoints_ATR);
   g_handleATR_H1 = iATR(_Symbol, PERIOD_H1, InpPoints_ATR);
   g_handleATR_D1 = iATR(_Symbol, PERIOD_D1, InpPoints_ATR);
   g_handleEMA_D1 = iMA(_Symbol, PERIOD_D1, InpEMA_D1_Period, 0, MODE_EMA, PRICE_CLOSE);
   g_handleEMA_H1 = iMA(_Symbol, PERIOD_H1, InpEMA_H1_Period, 0, MODE_EMA, PRICE_CLOSE);
   g_handleEMA_M5 = iMA(_Symbol, PERIOD_M5, InpEMA_M5_Period, 0, MODE_EMA, PRICE_CLOSE);
   g_handleADX_M5 = iADX(_Symbol, PERIOD_M5, InpADX_Period);

   if(g_handleATR_M5 == INVALID_HANDLE || g_handleATR_H1 == INVALID_HANDLE ||
      g_handleATR_D1 == INVALID_HANDLE || g_handleEMA_D1 == INVALID_HANDLE ||
      g_handleEMA_H1 == INVALID_HANDLE || g_handleEMA_M5 == INVALID_HANDLE ||
      g_handleADX_M5 == INVALID_HANDLE)
   {
      Print("[KIM LA] ERROR: Failed to create indicator handles. Check symbol/history.");
      return INIT_FAILED;
   }

   // Initial evaluations
   EvaluateD1Regime();
   UpdateSessionsAndBias();

   LogTradeAction(StringFormat("KIM LA initialized. Symbol=%s, Digits=%d, Point=%f, MaxSpread=%d points",
                  _Symbol, _Digits, _Point, (int)g_adjustedMaxSpread));
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   Comment("");

   if(g_handleATR_M5 != INVALID_HANDLE) IndicatorRelease(g_handleATR_M5);
   if(g_handleATR_H1 != INVALID_HANDLE) IndicatorRelease(g_handleATR_H1);
   if(g_handleATR_D1 != INVALID_HANDLE) IndicatorRelease(g_handleATR_D1);
   if(g_handleEMA_D1 != INVALID_HANDLE) IndicatorRelease(g_handleEMA_D1);
   if(g_handleEMA_H1 != INVALID_HANDLE) IndicatorRelease(g_handleEMA_H1);
   if(g_handleEMA_M5 != INVALID_HANDLE) IndicatorRelease(g_handleEMA_M5);
   if(g_handleADX_M5 != INVALID_HANDLE) IndicatorRelease(g_handleADX_M5);

   LogTradeAction(StringFormat("KIM LA EA stopped. Reason code: %d", reason));
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   if(!InpEnabled)
   {
      Comment("KIM LA EA is DISABLED in inputs.");
      return;
   }

   // Update account equity tracking for DD stats
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   if(equity > g_stats.peakEquity)
      g_stats.peakEquity = equity;
   if(g_stats.peakEquity > 0.0)
   {
      double currentDD = (g_stats.peakEquity - equity) / g_stats.peakEquity * 100.0;
      if(currentDD > g_stats.maxEquityDD)
         g_stats.maxEquityDD = currentDD;
   }

   // Update sessions and session H1 bias
   UpdateSessionsAndBias();

   // Clean up any pending limit orders that exceeded timeout (60 sec)
   CleanExpiredPendingOrders();

   // Manage active positions: Breakeven buffer + Accelerated ratchet trailing
   ManageOpenPositions();

   // Update chart dashboard
   UpdateChartDashboard();

   // Cooldown check after reconnect / startup (skip in tester)
   if(!MQLInfoInteger(MQL_TESTER) && InpCooldownReconnectSec > 0)
   {
      if(TimeCurrent() - g_initTime < InpCooldownReconnectSec)
         return;
   }

   // Check spread guard
   long spreadPoints = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
   if(spreadPoints > g_adjustedMaxSpread)
      return;

   // Only check new entry on completed M5 bar
   datetime currentBarTime = iTime(_Symbol, PERIOD_M5, 1);
   if(currentBarTime == 0 || currentBarTime == g_lastM5BarTime)
      return;

   // Re-evaluate D1 macro regime on bar close
   EvaluateD1Regime();

   // Check M5 setup and trigger entry if all 4 conditions match
   CheckM5Entry();

   g_lastM5BarTime = currentBarTime;
}

//+------------------------------------------------------------------+
//| Convert Server Time to GMT                                       |
//+------------------------------------------------------------------+
datetime GetGMTTime()
{
   return TimeCurrent() - (datetime)(InpServerGMTOffset * 3600);
}

//+------------------------------------------------------------------+
//| Tầng 1: D1 Macro Regime                                          |
//+------------------------------------------------------------------+
void EvaluateD1Regime()
{
   double emaD1[];
   double atrD1[];
   ArraySetAsSeries(emaD1, true);
   ArraySetAsSeries(atrD1, true);

   if(CopyBuffer(g_handleEMA_D1, 0, 1, 1, emaD1) <= 0 ||
      CopyBuffer(g_handleATR_D1, 0, 1, 1, atrD1) <= 0)
   {
      return;
   }

   double closeD1 = iClose(_Symbol, PERIOD_D1, 1);
   if(closeD1 <= 0.0 || emaD1[0] <= 0.0 || atrD1[0] <= 0.0)
      return;

   double diff = MathAbs(closeD1 - emaD1[0]);

   // Range: price fluctuates within +/- 1.0 x ATR(D1) around EMA200
   if(diff <= 1.0 * atrD1[0])
   {
      g_d1Regime = REGIME_RANGE;
   }
   else if(closeD1 > emaD1[0])
   {
      g_d1Regime = REGIME_TREND_LONG;
   }
   else
   {
      g_d1Regime = REGIME_TREND_SHORT;
   }
}

//+------------------------------------------------------------------+
//| Tầng 2: H1 Session Bias (Tactical Compass)                       |
//+------------------------------------------------------------------+
void UpdateSessionsAndBias()
{
   datetime gmt = GetGMTTime();
   MqlDateTime dt;
   TimeToStruct(gmt, dt);

   int currentMinutesOfDay = dt.hour * 60 + dt.min;
   int londonStart = InpLondonStart_Hour * 60 + InpLondonStart_Min;
   int nyStart     = InpNYStart_Hour * 60 + InpNYStart_Min;
   int nyEnd       = InpNYEnd_Hour * 60;

   ENUM_SESSION_TYPE newSession = SESSION_ASIA;

   if(currentMinutesOfDay >= londonStart && currentMinutesOfDay < nyStart)
      newSession = SESSION_LONDON;
   else if(currentMinutesOfDay >= nyStart && currentMinutesOfDay < nyEnd)
      newSession = SESSION_NY;
   else
      newSession = SESSION_ASIA;

   // Check session transition
   if(newSession != g_currentSession || dt.day != g_lastSessionDay || g_sessionH1Bias == BIAS_NONE)
   {
      ENUM_SESSION_TYPE oldSession = g_currentSession;
      g_currentSession = newSession;
      g_lastSessionDay = dt.day;

      // Handle session change
      if(g_currentSession == SESSION_LONDON)
      {
         if(oldSession != SESSION_LONDON) g_sessionTrades = 0;
         CalculateH1Bias();
         LogTradeAction(StringFormat("LONDON session ACTIVE (08:00 GMT). H1 Bias: %s | D1 Regime: %s",
                        FormatBiasName(g_sessionH1Bias), FormatRegimeName(g_d1Regime)));
      }
      else if(g_currentSession == SESSION_NY)
      {
         if(oldSession != SESSION_NY) g_sessionTrades = 0;
         CalculateH1Bias();
         LogTradeAction(StringFormat("NY session ACTIVE (13:30 GMT). H1 Bias: %s | D1 Regime: %s",
                        FormatBiasName(g_sessionH1Bias), FormatRegimeName(g_d1Regime)));
      }
      else // Transition to ASIA (end of daily trading window)
      {
         g_sessionH1Bias = BIAS_NONE;
         if(InpCloseOnSessionEnd && (oldSession == SESSION_LONDON || oldSession == SESSION_NY))
         {
            CloseAllPositionsOnSessionEnd();
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Calculate H1 Bias Once at Session Start                          |
//+------------------------------------------------------------------+
void CalculateH1Bias()
{
   double emaH1[];
   double atrH1[];
   ArraySetAsSeries(emaH1, true);
   ArraySetAsSeries(atrH1, true);

   if(CopyBuffer(g_handleEMA_H1, 0, 1, 1, emaH1) <= 0 ||
      CopyBuffer(g_handleATR_H1, 0, 1, 1, atrH1) <= 0)
   {
      g_sessionH1Bias = BIAS_NONE;
      return;
   }

   double closeH1 = iClose(_Symbol, PERIOD_H1, 1);
   if(closeH1 <= 0.0 || emaH1[0] <= 0.0 || atrH1[0] <= 0.0)
   {
      g_sessionH1Bias = BIAS_NONE;
      return;
   }

   double flatBuffer = InpH1_Flat_Threshold * atrH1[0];

   // H1 Bias determination
   if(MathAbs(closeH1 - emaH1[0]) < flatBuffer)
   {
      g_sessionH1Bias = BIAS_NONE; // Flat around EMA50, stand aside
   }
   else if(closeH1 > emaH1[0])
   {
      g_sessionH1Bias = BIAS_LONG;
   }
   else
   {
      g_sessionH1Bias = BIAS_SHORT;
   }
}

//+------------------------------------------------------------------+
//| Circuit Breaker Check (Daily Loss Limit & Consecutive Losses)    |
//+------------------------------------------------------------------+
bool IsCircuitBreakerTripped()
{
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   dt.hour = 0; dt.min = 0; dt.sec = 0;
   datetime todayStart = StructToTime(dt);

   HistorySelect(todayStart, TimeCurrent());
   double todayNetProfit = 0.0;
   int dealsTotal = HistoryDealsTotal();
   int consecLoss = 0;
   datetime lastLossTime = 0;

   for(int i = 0; i < dealsTotal; i++)
   {
      ulong ticket = HistoryDealGetTicket(i);
      if(ticket == 0) continue;
      if(HistoryDealGetString(ticket, DEAL_SYMBOL) != _Symbol) continue;
      if((int)HistoryDealGetInteger(ticket, DEAL_MAGIC) != InpMagicNumber) continue;

      ENUM_DEAL_ENTRY entry = (ENUM_DEAL_ENTRY)HistoryDealGetInteger(ticket, DEAL_ENTRY);
      if(entry != DEAL_ENTRY_OUT) continue;

      double profit = HistoryDealGetDouble(ticket, DEAL_PROFIT) +
                      HistoryDealGetDouble(ticket, DEAL_SWAP) +
                      HistoryDealGetDouble(ticket, DEAL_COMMISSION);
      todayNetProfit += profit;

      if(profit < -0.01)
      {
         consecLoss++;
         lastLossTime = (datetime)HistoryDealGetInteger(ticket, DEAL_TIME);
      }
      else if(profit > 0.01)
      {
         consecLoss = 0;
      }
   }

   double currentBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   double dayStartBalance = currentBalance - todayNetProfit;
   if(dayStartBalance > 0.0)
   {
      double lossPct = (-todayNetProfit) / dayStartBalance * 100.0;
      if(todayNetProfit < 0.0 && lossPct >= InpMaxDailyLossPct)
      {
         return true; // Max daily loss tripped
      }
   }

   if(InpMaxConsecLosses > 0 && consecLoss >= InpMaxConsecLosses)
   {
      if(TimeCurrent() - lastLossTime < InpCooldownAfterLossMin * 60)
      {
         return true; // Consecutive loss cooldown
      }
   }

   return false;
}

//+------------------------------------------------------------------+
//| Tầng 3: M5 Entry Engine (4 Conditions Simultaneously)            |
//+------------------------------------------------------------------+
void CheckM5Entry()
{
   // Condition 0: Only trade during active London or NY session
   if(g_currentSession == SESSION_ASIA)
      return;

   // Circuit breaker guard: halt on deep daily loss or consecutive loss streak
   if(IsCircuitBreakerTripped())
      return;

   // Session trade limit check (halved if D1 is in Range)
   int maxTrades = InpMaxTradesPerSession;
   if(g_d1Regime == REGIME_RANGE)
      maxTrades = MathMax(1, InpMaxTradesPerSession / 2);

   if(g_sessionTrades >= maxTrades)
      return;

   // Spec Section 8 & 9: Strict single position invariant (no stacking, no grid, no martingale)
   if(CountActivePositions() > 0 || CountActivePendingOrders() > 0)
      return;

   // 1. Condition 1: Same direction as H1 Bias
   if(g_sessionH1Bias == BIAS_NONE)
      return;

   bool allowBuy  = (g_sessionH1Bias == BIAS_LONG);
   bool allowSell = (g_sessionH1Bias == BIAS_SHORT);

   // Strict D1 alignment: Never trade against macro daily trend
   if(InpStrictD1Alignment)
   {
      if(g_d1Regime == REGIME_TREND_SHORT) allowBuy = false;
      if(g_d1Regime == REGIME_TREND_LONG)  allowSell = false;
   }

   if(!allowBuy && !allowSell)
      return;

   // 2. Condition 2: Momentum ADX(14) on M5 >= InpADX_EntryMin
   double adxM5[];
   ArraySetAsSeries(adxM5, true);
   if(CopyBuffer(g_handleADX_M5, 0, 1, 1, adxM5) <= 0 || adxM5[0] < InpADX_EntryMin)
      return;

   // Fetch M5 EMA20 and ATR
   double emaM5[];
   double atrM5[];
   ArraySetAsSeries(emaM5, true);
   ArraySetAsSeries(atrM5, true);

   if(CopyBuffer(g_handleEMA_M5, 0, 1, 3, emaM5) <= 0 ||
      CopyBuffer(g_handleATR_M5, 0, 1, 1, atrM5) <= 0)
   {
      return;
   }

   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   if(CopyRates(_Symbol, PERIOD_M5, 1, InpPullbackSwingBars + 3, rates) < InpPullbackSwingBars + 3)
      return;

   // 3. Condition 3: Pullback to EMA20 / Support-Resistance & Candlestick Confirmation
   bool buySignal = false;
   bool sellSignal = false;
   double entryRefPrice = 0.0;

   // Find recent swing levels
   double swingLow = rates[1].low;
   double swingHigh = rates[1].high;
   for(int i = 2; i <= InpPullbackSwingBars; i++)
   {
      if(rates[i].low < swingLow) swingLow = rates[i].low;
      if(rates[i].high > swingHigh) swingHigh = rates[i].high;
   }

   // BUY Signal Check (bar 0 = bar 1 completed; bar 1 = bar 2 completed)
   if(allowBuy)
   {
      bool touchedEMA = (rates[0].low <= emaM5[0] + 0.2 * atrM5[0]) || (rates[1].low <= emaM5[1] + 0.2 * atrM5[0]);
      bool touchedSupport = (rates[0].low <= swingLow + 0.2 * atrM5[0]);
      bool isBullish = (rates[0].close > rates[0].open);
      bool breakPrevHigh = (rates[0].close > rates[1].high);
      bool isEngulfing = (rates[0].close >= rates[1].open && rates[0].open <= rates[1].close && rates[1].close < rates[1].open);

      if((touchedEMA || touchedSupport) && isBullish && (breakPrevHigh || isEngulfing))
      {
         buySignal = true;
         entryRefPrice = emaM5[0];
      }
   }

   // SELL Signal Check
   if(allowSell && !buySignal)
   {
      bool touchedEMA = (rates[0].high >= emaM5[0] - 0.2 * atrM5[0]) || (rates[1].high >= emaM5[1] - 0.2 * atrM5[0]);
      bool touchedResistance = (rates[0].high >= swingHigh - 0.2 * atrM5[0]);
      bool isBearish = (rates[0].close < rates[0].open);
      bool breakPrevLow = (rates[0].close < rates[1].low);
      bool isEngulfing = (rates[0].close <= rates[1].open && rates[0].open >= rates[1].close && rates[1].close > rates[1].open);

      if((touchedEMA || touchedResistance) && isBearish && (breakPrevLow || isEngulfing))
      {
         sellSignal = true;
         entryRefPrice = emaM5[0];
      }
   }

   // 4. Condition 4: No chasing & Entry Dispatch
   if(buySignal)
   {
      ExecuteOrderEntry(POSITION_TYPE_BUY, entryRefPrice, atrM5[0], adxM5[0]);
   }
   else if(sellSignal)
   {
      ExecuteOrderEntry(POSITION_TYPE_SELL, entryRefPrice, atrM5[0], adxM5[0]);
   }
}

//+------------------------------------------------------------------+
//| Execute Order Entry (Market on Confirmation or Limit at EMA20)   |
//+------------------------------------------------------------------+
void ExecuteOrderEntry(ENUM_POSITION_TYPE type, double refPrice, double atrM5, double adx)
{
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

   double slDistance = InpATR_EntryStop * atrM5;
   double lot = CalculatePositionLot(slDistance);
   if(lot <= 0.0)
   {
      LogTradeAction("Entry skipped: lot calculation returned 0 or breached risk rules.");
      return;
   }

   if(type == POSITION_TYPE_BUY)
   {
      double slPrice = NormalizeDouble(ask - slDistance, _Digits);
      double tpPrice = (InpUseTakeProfit && InpTP_ATR_Mult > 0.0) ? NormalizeDouble(ask + InpTP_ATR_Mult * atrM5, _Digits) : 0.0;

      if(InpExecType == EXEC_LIMIT_ORDER && refPrice < ask - 10 * _Point)
      {
         slPrice = NormalizeDouble(refPrice - slDistance, _Digits);
         tpPrice = (InpUseTakeProfit && InpTP_ATR_Mult > 0.0) ? NormalizeDouble(refPrice + InpTP_ATR_Mult * atrM5, _Digits) : 0.0;
         if(g_trade.OrderOpen(_Symbol, ORDER_TYPE_BUY_LIMIT, lot, 0.0, NormalizeDouble(refPrice, _Digits),
                              slPrice, tpPrice, ORDER_TIME_GTC, 0, InpTradeComment))
         {
            g_sessionTrades++;
            LogTradeAction(StringFormat("BUY LIMIT placed: Vol=%.2f Price=%.2f SL=%.2f TP=%.2f (ADX=%.1f)",
                           lot, refPrice, slPrice, tpPrice, adx));
         }
      }
      else // Market execution on confirmed bar
      {
         if(g_trade.Buy(lot, _Symbol, ask, slPrice, tpPrice, InpTradeComment))
         {
            g_sessionTrades++;
            g_stats.totalTrades++;
            LogTradeAction(StringFormat("BUY Market opened: Vol=%.2f Price=%.2f SL=%.2f TP=%.2f (ADX=%.1f)",
                           lot, ask, slPrice, tpPrice, adx));
         }
      }
   }
   else if(type == POSITION_TYPE_SELL)
   {
      double slPrice = NormalizeDouble(bid + slDistance, _Digits);
      double tpPrice = (InpUseTakeProfit && InpTP_ATR_Mult > 0.0) ? NormalizeDouble(bid - InpTP_ATR_Mult * atrM5, _Digits) : 0.0;

      if(InpExecType == EXEC_LIMIT_ORDER && refPrice > bid + 10 * _Point)
      {
         slPrice = NormalizeDouble(refPrice + slDistance, _Digits);
         tpPrice = (InpUseTakeProfit && InpTP_ATR_Mult > 0.0) ? NormalizeDouble(refPrice - InpTP_ATR_Mult * atrM5, _Digits) : 0.0;
         if(g_trade.OrderOpen(_Symbol, ORDER_TYPE_SELL_LIMIT, lot, 0.0, NormalizeDouble(refPrice, _Digits),
                              slPrice, tpPrice, ORDER_TIME_GTC, 0, InpTradeComment))
         {
            g_sessionTrades++;
            LogTradeAction(StringFormat("SELL LIMIT placed: Vol=%.2f Price=%.2f SL=%.2f TP=%.2f (ADX=%.1f)",
                           lot, refPrice, slPrice, tpPrice, adx));
         }
      }
      else // Market execution on confirmed bar
      {
         if(g_trade.Sell(lot, _Symbol, bid, slPrice, tpPrice, InpTradeComment))
         {
            g_sessionTrades++;
            g_stats.totalTrades++;
            LogTradeAction(StringFormat("SELL Market opened: Vol=%.2f Price=%.2f SL=%.2f TP=%.2f (ADX=%.1f)",
                           lot, bid, slPrice, tpPrice, adx));
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Calculate Position Lot with Risk% and Cent/Standard Handling     |
//+------------------------------------------------------------------+
double CalculatePositionLot(const double stopLossDistance)
{
   if(stopLossDistance <= 0.0)
      return 0.0;

   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   if(balance <= 0.0)
      return 0.0;

   double cashRisk = balance * (InpRiskPct / 100.0);
   double stopLossPoints = stopLossDistance / _Point;
   if(stopLossPoints <= 0.0)
      return 0.0;

   double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   if(tickSize <= 0.0 || tickValue <= 0.0)
      return 0.0;

   double pointsPerTick = tickSize / _Point;
   double valuePerPointPerLot = tickValue / pointsPerTick;
   if(valuePerPointPerLot <= 0.0)
      return 0.0;

   double rawLot = cashRisk / (stopLossPoints * valuePerPointPerLot);

   double volMin  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double volMax  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double volStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

   // Volume fallback handling
   if(rawLot < volMin || rawLot < InpMinLot)
   {
      if(InpAllowMinLotFallback)
      {
         rawLot = MathMax(volMin, InpMinLot);
      }
      else
      {
         PrintFormat("[KIM LA SIZING] Raw lot %.4f < MinLot %.2f. Skipping trade to protect capital.",
                     rawLot, MathMax(volMin, InpMinLot));
         return 0.0;
      }
   }

   // Round down to step
   double lot = MathFloor(rawLot / volStep) * volStep;
   lot = NormalizeDouble(lot, 2);

   // Cap at user MaxLot
   if(lot > InpMaxLot)
      lot = InpMaxLot;
   if(lot > volMax)
      lot = volMax;

   return lot;
}

//+------------------------------------------------------------------+
//| Tầng 4: Trailing Ratchet Engine (Breakeven Buffer + Accelerated) |
//+------------------------------------------------------------------+
void ManageOpenPositions()
{
   double atrM5[];
   ArraySetAsSeries(atrM5, true);
   if(CopyBuffer(g_handleATR_M5, 0, 0, 1, atrM5) <= 0 || atrM5[0] <= 0.0)
      return;

   double currentATR = atrM5[0];
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   long stopLevelPoints = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
   double stopLevelDist = stopLevelPoints * _Point;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      if((int)PositionGetInteger(POSITION_MAGIC) != InpMagicNumber) continue;

      double openPrice  = PositionGetDouble(POSITION_PRICE_OPEN);
      double currentSL  = PositionGetDouble(POSITION_SL);
      double currentTP  = PositionGetDouble(POSITION_TP);
      ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);

      if(type == POSITION_TYPE_BUY)
      {
         double profitPoints = bid - openPrice;
         double profitATR    = profitPoints / currentATR;
         double targetSL     = currentSL;
         string stageReason  = "";

         // Phase 3: Accelerated Trailing (>= 6x ATR and >= 4x ATR)
         if(profitATR >= 6.0)
         {
            double step = InpTrailStep3 * currentATR;
            double candidate = bid - step;
            if(candidate > targetSL) { targetSL = candidate; stageReason = "Trail-Stage3 (6x ATR)"; }
         }
         else if(profitATR >= 4.0)
         {
            double step = InpTrailStep2 * currentATR;
            double candidate = bid - step;
            if(candidate > targetSL) { targetSL = candidate; stageReason = "Trail-Stage2 (4x ATR)"; }
         }
         // Phase 2: Trailing Stage 1 (>= 2x ATR)
         else if(profitATR >= InpTrailStart)
         {
            double step = InpTrailStep1 * currentATR;
            double candidate = bid - step;
            if(candidate > targetSL) { targetSL = candidate; stageReason = "Trail-Stage1 (2x ATR)"; }
         }

         // Phase 1: Breakeven with buffer (>= 0.7x ATR)
         if(profitATR >= InpATR_BreakevenBuffer)
         {
            double beSL = openPrice + InpATR_BreakevenBuffer * currentATR;
            if(beSL > targetSL) { targetSL = beSL; stageReason = "Breakeven Buffer (+0.7x ATR)"; }
         }

         // Ratchet invariant: ONLY move forward, never loosen
         targetSL = NormalizeDouble(targetSL, _Digits);
         if(targetSL > currentSL + _Point && targetSL < bid - stopLevelDist)
         {
            if(g_trade.PositionModify(ticket, targetSL, currentTP))
            {
               LogTradeAction(StringFormat("BUY #%d SL updated -> %.2f [%s]", ticket, targetSL, stageReason));
            }
         }
      }
      else if(type == POSITION_TYPE_SELL)
      {
         double profitPoints = openPrice - ask;
         double profitATR    = profitPoints / currentATR;
         double targetSL     = currentSL;
         string stageReason  = "";

         // Phase 3: Accelerated Trailing (>= 6x ATR and >= 4x ATR)
         if(profitATR >= 6.0)
         {
            double step = InpTrailStep3 * currentATR;
            double candidate = ask + step;
            if(currentSL == 0.0 || candidate < targetSL) { targetSL = candidate; stageReason = "Trail-Stage3 (6x ATR)"; }
         }
         else if(profitATR >= 4.0)
         {
            double step = InpTrailStep2 * currentATR;
            double candidate = ask + step;
            if(currentSL == 0.0 || candidate < targetSL) { targetSL = candidate; stageReason = "Trail-Stage2 (4x ATR)"; }
         }
         // Phase 2: Trailing Stage 1 (>= 2x ATR)
         else if(profitATR >= InpTrailStart)
         {
            double step = InpTrailStep1 * currentATR;
            double candidate = ask + step;
            if(currentSL == 0.0 || candidate < targetSL) { targetSL = candidate; stageReason = "Trail-Stage1 (2x ATR)"; }
         }

         // Phase 1: Breakeven with buffer (>= 0.7x ATR)
         if(profitATR >= InpATR_BreakevenBuffer)
         {
            double beSL = openPrice - InpATR_BreakevenBuffer * currentATR;
            if(currentSL == 0.0 || beSL < targetSL) { targetSL = beSL; stageReason = "Breakeven Buffer (+0.7x ATR)"; }
         }

         // Ratchet invariant: ONLY move forward, never loosen
         targetSL = NormalizeDouble(targetSL, _Digits);
         if((currentSL == 0.0 || targetSL < currentSL - _Point) && targetSL > ask + stopLevelDist)
         {
            if(g_trade.PositionModify(ticket, targetSL, currentTP))
            {
               LogTradeAction(StringFormat("SELL #%d SL updated -> %.2f [%s]", ticket, targetSL, stageReason));
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Clean Expired Pending Limit Orders (Older than 60 seconds)       |
//+------------------------------------------------------------------+
void CleanExpiredPendingOrders()
{
   datetime now = TimeCurrent();
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      ulong ticket = OrderGetTicket(i);
      if(ticket == 0) continue;
      if(OrderGetString(ORDER_SYMBOL) != _Symbol) continue;
      if((int)OrderGetInteger(ORDER_MAGIC) != InpMagicNumber) continue;

      datetime setupTime = (datetime)OrderGetInteger(ORDER_TIME_SETUP);
      if(now - setupTime >= InpMaxSeconds_EntryFill)
      {
         g_trade.OrderDelete(ticket);
         LogTradeAction(StringFormat("Cancelled pending limit #%d (unfilled in %d sec - No FOMO rule).",
                        ticket, InpMaxSeconds_EntryFill));
      }
   }
}

//+------------------------------------------------------------------+
//| Market-close all positions when session ends                     |
//+------------------------------------------------------------------+
void CloseAllPositionsOnSessionEnd()
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      if((int)PositionGetInteger(POSITION_MAGIC) != InpMagicNumber) continue;

      if(g_trade.PositionClose(ticket))
      {
         g_stats.sessionEndExits++;
         LogTradeAction(StringFormat("Position #%d closed by Market on Session End (Anti-gap rule).", ticket));
      }
   }

   // Also delete any remaining pending limit orders
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      ulong ticket = OrderGetTicket(i);
      if(ticket == 0) continue;
      if(OrderGetString(ORDER_SYMBOL) != _Symbol) continue;
      if((int)OrderGetInteger(ORDER_MAGIC) != InpMagicNumber) continue;
      g_trade.OrderDelete(ticket);
   }
}

//+------------------------------------------------------------------+
//| Helper Counts & Invariants                                       |
//+------------------------------------------------------------------+
int CountActivePositions()
{
   int count = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      if((int)PositionGetInteger(POSITION_MAGIC) != InpMagicNumber) continue;
      count++;
   }
   return count;
}

int CountActivePendingOrders()
{
   int count = 0;
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      ulong ticket = OrderGetTicket(i);
      if(ticket == 0) continue;
      if(OrderGetString(ORDER_SYMBOL) != _Symbol) continue;
      if((int)OrderGetInteger(ORDER_MAGIC) != InpMagicNumber) continue;
      count++;
   }
   return count;
}

//+------------------------------------------------------------------+
//| String Format Helpers                                            |
//+------------------------------------------------------------------+
string FormatSessionName(ENUM_SESSION_TYPE session)
{
   switch(session)
   {
      case SESSION_LONDON: return "LONDON (Active)";
      case SESSION_NY:     return "NEW YORK (Active)";
      case SESSION_ASIA:   return "ASIA (Stand Aside)";
      default:             return "UNKNOWN";
   }
}

string FormatBiasName(ENUM_BIAS_H1 bias)
{
   switch(bias)
   {
      case BIAS_LONG:  return "LONG (Bullish)";
      case BIAS_SHORT: return "SHORT (Bearish)";
      case BIAS_NONE:  return "NONE (Flat/Unclear)";
      default:         return "UNKNOWN";
   }
}

string FormatRegimeName(ENUM_REGIME_D1 regime)
{
   switch(regime)
   {
      case REGIME_TREND_LONG:  return "TREND LONG (> EMA200)";
      case REGIME_TREND_SHORT: return "TREND SHORT (< EMA200)";
      case REGIME_RANGE:       return "RANGE (Flat +/- 1 ATR)";
      default:                 return "NONE";
   }
}

//+------------------------------------------------------------------+
//| Logger Function                                                  |
//+------------------------------------------------------------------+
void LogTradeAction(const string text)
{
   PrintFormat("[KIM LA] %s - %s", TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS), text);
}

//+------------------------------------------------------------------+
//| On-Chart Dashboard                                               |
//+------------------------------------------------------------------+
void UpdateChartDashboard()
{
   datetime gmt = GetGMTTime();
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double equity  = AccountInfoDouble(ACCOUNT_EQUITY);
   long spread    = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);

   string text = "=================================================\n" +
                 "              KIM LA EA - XAUUSD M5              \n" +
                 "       Mandate: KHONG CUT VON (Capital First)     \n" +
                 "=================================================\n" +
                 StringFormat("GMT Time:        %s (Server Offset: %d h)\n", TimeToString(gmt, TIME_SECONDS), InpServerGMTOffset) +
                 StringFormat("Current Session: %s\n", FormatSessionName(g_currentSession)) +
                 StringFormat("D1 Regime:       %s\n", FormatRegimeName(g_d1Regime)) +
                 StringFormat("H1 Bias:         %s\n", FormatBiasName(g_sessionH1Bias)) +
                 StringFormat("Session Trades:  %d / %d\n", g_sessionTrades, (g_d1Regime == REGIME_RANGE ? MathMax(1, InpMaxTradesPerSession/2) : InpMaxTradesPerSession)) +
                 "-------------------------------------------------\n" +
                 StringFormat("Spread / Max:    %d / %d points\n", spread, (int)g_adjustedMaxSpread) +
                 StringFormat("Account Balance: %.2f %s\n", balance, (InpLotMode == LOT_MODE_CENT ? "USC (Cent)" : "USD")) +
                 StringFormat("Account Equity:  %.2f\n", equity) +
                 StringFormat("Max Drawdown:    %.2f %%\n", g_stats.maxEquityDD) +
                 StringFormat("Active Positions:%d\n", CountActivePositions()) +
                 "=================================================";

   Comment(text);
}

//+------------------------------------------------------------------+
//| Tester End Statistics Report                                     |
//+------------------------------------------------------------------+
double OnTester()
{
   HistorySelect(0, TimeCurrent());
   int totalDeals = HistoryDealsTotal();

   double finalBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   double profit = finalBalance - g_stats.initialBalance;

   Print("=================================================");
   Print("          KIM LA EA - TESTER SUMMARY             ");
   Print("=================================================");
   PrintFormat("Initial Balance:  %.2f", g_stats.initialBalance);
   PrintFormat("Final Balance:    %.2f (Net: %.2f)", finalBalance, profit);
   PrintFormat("Max Equity DD:    %.2f %%", g_stats.maxEquityDD);
   PrintFormat("Total Deals:      %d", totalDeals);
   PrintFormat("Session End Exits:%d", g_stats.sessionEndExits);
   Print("=================================================");

   return profit;
}
//+------------------------------------------------------------------+
