//+------------------------------------------------------------------+
//| StrategyHub.mqh                                                  |
//| Multi-Strategy Signal Hub with Hierarchical Execution           |
//| (Priority 1: SweepReversal -> Priority 2: ORB)                   |
//| Standardized for TM_GoldSweepScalper (SPEC_GOLD_SCALPER.md)      |
//+------------------------------------------------------------------+
#ifndef TM_EA_STRATEGYHUB_MQH
#define TM_EA_STRATEGYHUB_MQH

#include "RegimeEngine.mqh"
#include "LiquidityMap.mqh"
#include "TimeService.mqh"

struct SStrategySignal
{
   bool   valid;
   string setupName;
   int    direction;      // +1 BUY, -1 SELL
   double entryPrice;
   double stopLoss;
   double takeProfit;
   string reason;
};

class CStrategyHub
{
private:
   string m_symbol;
   ENUM_TIMEFRAMES m_tf;

public:
   CStrategyHub()
   {
      m_symbol = "";
      m_tf = PERIOD_M5;
   }

   bool Init(const string symbol, const ENUM_TIMEFRAMES tf = PERIOD_M5)
   {
      m_symbol = symbol;
      m_tf = tf;
      return true;
   }

   bool Evaluate(CLiquidityMap &liqMap,
                 CRegimeEngine &regimeEngine,
                 const CTimeService &timeService,
                 const double atr,
                 const double adx,
                 const double sweepRR,
                 const double orbRR,
                 const double minRangeATR,
                 const double maxRangeATR,
                 const bool enableSweep,
                 const bool enableORB,
                 SStrategySignal &signal,
                 string &skipReason)
   {
      signal.valid = false;
      skipReason = "";

      if(atr <= 0.0)
      {
         skipReason = "Invalid ATR value <= 0.0";
         return false;
      }

      ENUM_MARKET_REGIME currentRegime = regimeEngine.GetCurrentRegime();

      // ===================================================================
      // PRIORITY 1: SETUP A - SWEEP REVERSAL
      // ===================================================================
      if(enableSweep)
      {
         int sweepDir = 0;
         double sweepEntry = 0.0, sweepSL = 0.0, sweepLevel = 0.0;
         string sweepReason = "";

         if(liqMap.CheckSweepReversal(atr, sweepDir, sweepEntry, sweepSL, sweepLevel, sweepReason))
         {
            // Regime Filter Confirmation for Sweep:
            // Sweep is highly profitable in RANGE or when fading a sweep that aligned with broader trend
            bool regimeConfirmed = false;
            if(currentRegime == REGIME_RANGE)
            {
               regimeConfirmed = true; // Optimal regime for sweeps
            }
            else if(sweepDir > 0 && currentRegime == REGIME_TREND_BULL)
            {
               regimeConfirmed = true; // Swept lows during bull trend = pullback trap
            }
            else if(sweepDir < 0 && currentRegime == REGIME_TREND_BEAR)
            {
               regimeConfirmed = true; // Swept highs during bear trend = rally trap
            }

            if(regimeConfirmed)
            {
               double risk = MathAbs(sweepEntry - sweepSL);
               if(risk > 0.0)
               {
                  signal.valid = true;
                  signal.setupName = "SweepReversal";
                  signal.direction = sweepDir;
                  signal.entryPrice = sweepEntry;
                  signal.stopLoss = sweepSL;
                  signal.takeProfit = (sweepDir > 0) ? (sweepEntry + sweepRR * risk)
                                                     : (sweepEntry - sweepRR * risk);
                  signal.reason = sweepReason;
                  return true;
               }
            }
            else
            {
               skipReason = "Sweep skipped: regime conflicting (" + EnumToString(currentRegime) + ")";
            }
         }
      }

      // ===================================================================
      // PRIORITY 2: SETUP B - OPENING-RANGE BREAKOUT (ORB)
      // ===================================================================
      if(enableORB)
      {
         double asiaHigh = liqMap.GetAsiaHigh();
         double asiaLow  = liqMap.GetAsiaLow();

         if(asiaHigh > 0.0 && asiaLow > 0.0 && asiaHigh > asiaLow)
         {
            double rangeSize = asiaHigh - asiaLow;
            bool rangeValid = true;

            if(minRangeATR > 0.0 && rangeSize < minRangeATR * atr)
               rangeValid = false;
            if(maxRangeATR > 0.0 && rangeSize > maxRangeATR * atr)
               rangeValid = false;

            if(rangeValid && adx >= 20.0)
            {
               MqlRates bar1[1];
               if(CopyRates(m_symbol, m_tf, 1, 1, bar1) == 1)
               {
                  double c1 = bar1[0].close;
                  double ask = SymbolInfoDouble(m_symbol, SYMBOL_ASK);
                  double bid = SymbolInfoDouble(m_symbol, SYMBOL_BID);
                  double buffer = 0.1 * atr;

                  // Breakout above Asia High
                  if(c1 > asiaHigh + buffer && currentRegime != REGIME_TREND_BEAR)
                  {
                     double entry = ask;
                     double sl = asiaLow;
                     double risk = MathAbs(entry - sl);
                     if(risk > 0.0)
                     {
                        signal.valid = true;
                        signal.setupName = "OpeningRangeBreakout";
                        signal.direction = 1;
                        signal.entryPrice = entry;
                        signal.stopLoss = sl;
                        signal.takeProfit = entry + orbRR * risk;
                        signal.reason = StringFormat("ORB Buy Breakout | Close=%.2f > High=%.2f+%.2f",
                                                     c1, asiaHigh, buffer);
                        return true;
                     }
                  }
                  // Breakout below Asia Low
                  else if(c1 < asiaLow - buffer && currentRegime != REGIME_TREND_BULL)
                  {
                     double entry = bid;
                     double sl = asiaHigh;
                     double risk = MathAbs(entry - sl);
                     if(risk > 0.0)
                     {
                        signal.valid = true;
                        signal.setupName = "OpeningRangeBreakout";
                        signal.direction = -1;
                        signal.entryPrice = entry;
                        signal.stopLoss = sl;
                        signal.takeProfit = entry - orbRR * risk;
                        signal.reason = StringFormat("ORB Sell Breakout | Close=%.2f < Low=%.2f-%.2f",
                                                     c1, asiaLow, buffer);
                        return true;
                     }
                  }
               }
            }
            else if(!rangeValid)
            {
               skipReason = StringFormat("ORB range invalid size (range=%.2f ATR=%.2f)", rangeSize, atr);
            }
            else if(adx < 20.0)
            {
               skipReason = StringFormat("ORB ADX too low (%.1f < 20.0)", adx);
            }
         }
      }

      if(skipReason == "")
         skipReason = "No setup triggered on bar 1";
      return false;
   }
};

#endif // TM_EA_STRATEGYHUB_MQH
