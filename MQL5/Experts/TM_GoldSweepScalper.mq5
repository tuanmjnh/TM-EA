//+------------------------------------------------------------------+
//| TM_GoldSweepScalper.mq5                                          |
//| Rare-Fire Stable Scalper for XAUUSD (M5)                         |
//| Built strictly according to docs/2026.11.19/SPEC_GOLD_SCALPER.md |
//| 9-Module Architecture:                                           |
//| 1. CSymbolSpecs     2. CTimeService     3. CRegimeEngine         |
//| 4. CLiquidityMap    5. CStrategyHub     6. CRiskManager          |
//| 7. CTrailingEngine  8. CGuards          9. CLogger               |
//+------------------------------------------------------------------+
#property copyright "TM-EA"
#property version   "1.10"
#property strict

#include "..\Include\TM_EA\SymbolSpecs.mqh"
#include "..\Include\TM_EA\TimeService.mqh"
#include "..\Include\TM_EA\RegimeEngine.mqh"
#include "..\Include\TM_EA\LiquidityMap.mqh"
#include "..\Include\TM_EA\StrategyHub.mqh"
#include "..\Include\TM_EA\RiskManager.mqh"
#include "..\Include\TM_EA\TrailingEngine.mqh"
#include "..\Include\TM_EA\Guards.mqh"
#include "..\Include\TM_EA\Logger.mqh"
#include "..\Include\TM_EA\TradeExecutor.mqh"

//--- Inputs
input group "=== GENERAL CONFIG ==="
input bool              Enabled                 = true;
input int               MagicNumber             = 777001;
input string            TradeComment            = "TM_GSS_V1";
input ENUM_TIMEFRAMES   Entry_TF                = PERIOD_M5; // Scalping execution timeframe
input ENUM_TIMEFRAMES   Regime_TF               = PERIOD_H1; // Higher timeframe regime (ADX H1)

input group "=== TIMING & KILL-ZONES (GMT) ==="
input int               BrokerGMTOffset         = 999;       // Broker GMT offset (999 = auto-detect)
input bool              OnlyTradeInKillZones    = true;      // Only trade in London KZ & NY KZ
input bool              OneTradePerKillZone     = true;      // Max 1 trade per kill-zone (Rare-fire gating)

input group "=== STRATEGY SETUPS ==="
input bool              Enable_SweepReversal    = true;      // Setup A: Liquidity Sweep Reversal
input double            Sweep_RR                = 2.0;       // Sweep R:R Target (1.5 - 2.5)
input bool              Enable_ORB              = true;      // Setup B: Opening-Range Breakout
input double            ORB_RR                  = 4.0;       // ORB R:R Target (3.0 - 5.0)
input double            Min_Range_ATR           = 0.5;       // Range must be >= this * ATR(M5)
input double            Max_Range_ATR           = 8.0;       // Range must be <= this * ATR(M5)

input group "=== RISK & POSITION SIZING ==="
input double            RiskPercentPerTrade     = 0.5;       // Risk % per trade (0.25 - 1.0%)
input double            CommissionPerLot        = 0.0;       // Broker commission in $/lot
input double            Min_Volume              = 0.01;
input double            Max_Volume              = 0.50;

input group "=== RISK GUARDS & CIRCUIT BREAKER ==="
input int               Max_Spread_Points       = 350;       // Max allowable spread (points)
input double            Max_Daily_Loss_Pct      = 2.0;       // Stop trading for day if daily loss reaches this
input double            Circuit_Breaker_DD_Pct  = 8.0;       // Hard stop & close all if total DD exceeds this
input int               Max_Consec_Losses       = 3;         // Consecutive losses to trigger cooldown
input int               Cooldown_Seconds        = 1800;      // Cooldown period in seconds (30 mins)

input group "=== TRAILING & BREAKEVEN ==="
input bool              Enable_Trailing         = true;      // Dynamic ATR trailing stop & breakeven
input double            Trailing_ATR_Mult       = 2.0;       // ATR multiplier for trailing distance
input double            Breakeven_ATR_Mult      = 1.0;       // Gate breakeven by at least 1.0 * ATR (fix BUG-013)
input double            Breakeven_After_Pips    = 30.0;      // Move SL to BE after this profit (pips)
input double            Trail_Step_Pips         = 10.0;      // Trailing modification step (pips)

//--- Module Instances
CSymbolSpecs    g_symbol;
CTimeService    g_time;
CRegimeEngine   g_regime;
CLiquidityMap   g_liqMap;
CStrategyHub    g_strategy;
CTrailingEngine g_trailing;
CGuards         g_guards;
CLogger         g_logger;
CTradeExecutor  g_trade;

datetime g_lastBarTime = 0;
datetime g_lastDay = 0;
bool     g_tradedLondonKZ = false;
bool     g_tradedNYKZ = false;
double   g_initBalance = 0.0;
double   g_peakEquity = 0.0;
double   g_maxDD = 0.0;

//+------------------------------------------------------------------+
//| Dump tester performance report                                   |
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
   FileWrite(fh, "expert", "TM_GoldSweepScalper");
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
   PrintFormat("GSS Stats: net=%.2f PF=%.3f trades=%d DD=%.2f%%", finalBalance - g_initBalance, pf, trades, ddPct);
}

//+------------------------------------------------------------------+
//| Expert initialization                                            |
//+------------------------------------------------------------------+
int OnInit()
{
   if(!Enabled) return INIT_SUCCEEDED;

   if(!g_symbol.Refresh(_Symbol))
   {
      Print("INIT FAILED: CSymbolSpecs for ", _Symbol);
      return INIT_FAILED;
   }

   if(!g_trade.Init(MagicNumber, 10, _Symbol))
   {
      Print("INIT FAILED: CTradeExecutor for ", _Symbol);
      return INIT_FAILED;
   }

   g_time.Init(BrokerGMTOffset);

   if(!g_regime.Init(_Symbol, Entry_TF, Regime_TF, 3))
   {
      Print("INIT FAILED: CRegimeEngine");
      return INIT_FAILED;
   }

   if(!g_liqMap.Init(_Symbol, Entry_TF))
   {
      Print("INIT FAILED: CLiquidityMap");
      return INIT_FAILED;
   }

   if(!g_strategy.Init(_Symbol, Entry_TF))
   {
      Print("INIT FAILED: CStrategyHub");
      return INIT_FAILED;
   }

   if(!g_trailing.Init(_Symbol, MagicNumber, g_symbol.Point))
   {
      Print("INIT FAILED: CTrailingEngine");
      return INIT_FAILED;
   }

   g_guards.Init(_Symbol, MagicNumber, Max_Spread_Points, Max_Daily_Loss_Pct,
                 Circuit_Breaker_DD_Pct, Max_Consec_Losses, Cooldown_Seconds);

   g_logger.Init(_Symbol, MagicNumber);

   g_initBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   g_peakEquity = AccountInfoDouble(ACCOUNT_EQUITY);

   g_logger.Log(StringFormat("TM_GoldSweepScalper v1.1 Initialised | Offset=%d | Filling=%s | Risk=%.2f%% | SpreadMax=%d",
                g_time.GetGMTOffset(),
                EnumToString(g_trade.GetSelectedFilling()),
                RiskPercentPerTrade,
                Max_Spread_Points));

   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization                                          |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   DumpTesterStats();
   g_regime.Release();
   g_logger.Log("TM_GoldSweepScalper deinit reason=" + IntegerToString(reason));
   g_logger.Deinit();
}

//+------------------------------------------------------------------+
//| Expert tick handler                                              |
//+------------------------------------------------------------------+
void OnTick()
{
   if(!Enabled || !g_symbol.IsReady())
      return;

   datetime now = TimeCurrent();

   if((bool)MQLInfoInteger(MQL_TESTER))
   {
      double eq = AccountInfoDouble(ACCOUNT_EQUITY);
      if(eq > g_peakEquity) g_peakEquity = eq;
      double dd = g_peakEquity - eq;
      if(dd > g_maxDD) g_maxDD = dd;
   }

   MqlDateTime dt;
   TimeToStruct(now, dt);
   datetime dayStart = now - (dt.hour * 3600 + dt.min * 60 + dt.sec);
   if(dayStart != g_lastDay)
   {
      g_lastDay = dayStart;
      g_tradedLondonKZ = false;
      g_tradedNYKZ = false;
      g_time.RefreshOffset();
      g_guards.CheckNewDay(dayStart, AccountInfoDouble(ACCOUNT_EQUITY));
      g_liqMap.UpdatePDH_PDL(now);
   }

   // Keep Asian Session levels updated between 00:00 and 07:00 GMT
   int asiaStartSrv = g_time.GMTtoServerHour(0);
   int asiaEndSrv   = g_time.GMTtoServerHour(7);
   datetime asiaFrom = dayStart + (datetime)(asiaStartSrv * 3600);
   datetime asiaTo   = dayStart + (datetime)(asiaEndSrv * 3600);
   if(asiaStartSrv > asiaEndSrv)
   {
      if(dt.hour >= asiaStartSrv) asiaTo += 86400;
      else asiaFrom -= 86400;
   }
   if(now >= asiaTo)
   {
      g_liqMap.UpdateAsianRange(asiaFrom, asiaTo);
   }

   // Trailing Stop & Breakeven update on EVERY tick for open positions
   if(Enable_Trailing && g_trade.CountOpenPositions(_Symbol) > 0)
   {
      double curADX = 0.0, curATR = 0.0;
      string rDesc = "";
      g_regime.Update(SymbolInfoDouble(_Symbol, SYMBOL_BID), curADX, curATR, rDesc);
      if(curATR > 0.0)
      {
         g_trailing.Update(g_trade, curATR, Trailing_ATR_Mult,
                           0.0, Trail_Step_Pips,
                           Breakeven_After_Pips, Breakeven_ATR_Mult,
                           g_symbol.TickSize, g_symbol.StopLevelPoints,
                           g_symbol.FreezeLevelPoints);
      }
   }

   // Only evaluate new signals ONCE per closed bar on Entry_TF
   datetime barTime = iTime(_Symbol, Entry_TF, 0);
   if(barTime == 0 || barTime == g_lastBarTime)
      return;
   g_lastBarTime = barTime;

   // Warmup validation
   if(!g_regime.IsWarmedUp())
   {
      static datetime lastWarmupLog = 0;
      if(now - lastWarmupLog >= 3600)
      {
         g_logger.Log("GSS skip: indicator warm-up in progress");
         lastWarmupLog = now;
      }
      return;
   }

   // Check Kill-Zones
   string zoneName = "";
   ENUM_KILL_ZONE kz = g_time.GetCurrentKillZone(now, zoneName);
   bool inKZ = (kz == KZ_LONDON || kz == KZ_NEWYORK);

   if(OnlyTradeInKillZones && !inKZ)
   {
      g_logger.Log(StringFormat("GSS skip: outside kill-zone | %s gmtHour=%d srvHour=%d",
                   zoneName, g_time.ServerToGMTHour(dt.hour), dt.hour));
      return;
   }

   // Gating: One trade per kill-zone
   if(OneTradePerKillZone)
   {
      if(kz == KZ_LONDON && g_tradedLondonKZ)
      {
         g_logger.Log("GSS skip: already traded in London Kill-Zone today");
         return;
      }
      if(kz == KZ_NEWYORK && g_tradedNYKZ)
      {
         g_logger.Log("GSS skip: already traded in New York Kill-Zone today");
         return;
      }
   }

   // Broker Session Check
   if(!g_time.IsTradeSessionOpen(_Symbol, now))
   {
      g_logger.Log("GSS skip: broker trading session closed");
      return;
   }

   // Check Risk Guards (Spread, Open Positions, Circuit Breaker, Cooldown)
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double spreadPoints = (ask - bid) / g_symbol.Point;
   string guardBlockReason = "";
   if(!g_guards.AllowTrade(g_trade, spreadPoints, now, guardBlockReason))
   {
      g_logger.Log("GSS skip: " + guardBlockReason);
      return;
   }

   // Update Regime & Metrics
   double adx_h1 = 0.0, atr_m5 = 0.0;
   string regimeDesc = "";
   ENUM_MARKET_REGIME regime = g_regime.Update(bid, adx_h1, atr_m5, regimeDesc);

   // Evaluate Strategy Signals
   SStrategySignal signal;
   string skipReason = "";
   bool hasSignal = g_strategy.Evaluate(g_liqMap, g_regime, g_time, atr_m5, adx_h1,
                                        Sweep_RR, ORB_RR, Min_Range_ATR, Max_Range_ATR,
                                        Enable_SweepReversal, Enable_ORB, signal, skipReason);
   if(!hasSignal)
   {
      g_logger.Log(StringFormat("GSS skip: %s | Regime=%s | ADX_H1=%.1f ATR_M5=%.2f",
                   skipReason, regimeDesc, adx_h1, atr_m5));
      return;
   }

   // Sizing with Cash-Risk + Commission
   string volReason = "";
   double volume = CRiskManager::CalculateVolume(_Symbol, signal.direction, RiskPercentPerTrade,
                                                 AccountInfoDouble(ACCOUNT_BALANCE),
                                                 signal.entryPrice, signal.stopLoss,
                                                 Min_Volume, Max_Volume,
                                                 g_symbol.VolumeStep, volReason,
                                                 CommissionPerLot);

   if(volume <= 0.0)
   {
      g_logger.Log(StringFormat("GSS skip: volume sizing rejected (%s) | entry=%.2f sl=%.2f minVol=%.2f",
                   volReason, signal.entryPrice, signal.stopLoss, Min_Volume));
      return;
   }

   // Execute Order
   string comment = TradeComment + "_" + (signal.direction > 0 ? "BUY" : "SELL");
   ulong ticket = 0;
   bool ok = (signal.direction > 0)
             ? g_trade.OpenBuy(_Symbol, volume, signal.stopLoss, signal.takeProfit, comment, ticket)
             : g_trade.OpenSell(_Symbol, volume, signal.stopLoss, signal.takeProfit, comment, ticket);

   if(!ok)
   {
      g_logger.Log(StringFormat("GSS Order FAILED | Setup=%s Retcode=%d | vol=%.2f entry=%.2f sl=%.2f tp=%.2f",
                   signal.setupName, g_trade.LastRetcode(), volume, signal.entryPrice, signal.stopLoss, signal.takeProfit));
      return;
   }

   // Mark kill-zone as traded
   if(kz == KZ_LONDON) g_tradedLondonKZ = true;
   if(kz == KZ_NEWYORK) g_tradedNYKZ = true;

   g_logger.Log(StringFormat("GSS OPENED [%s] dir=%d entry=%.2f SL=%.2f TP=%.2f vol=%.2f ticket=%I64u | %s",
                signal.setupName, signal.direction, signal.entryPrice, signal.stopLoss, signal.takeProfit,
                volume, ticket, signal.reason));
}
