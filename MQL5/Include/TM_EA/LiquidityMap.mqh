//+------------------------------------------------------------------+
//| LiquidityMap.mqh                                                 |
//| Liquidity Level Mapping & Sweep Detection                        |
//| (Asian Range, PDH/PDL, Swing Highs/Lows)                         |
//| Standardized for TM_GoldSweepScalper (SPEC_GOLD_SCALPER.md)      |
//+------------------------------------------------------------------+
#ifndef TM_EA_LIQUIDITYMAP_MQH
#define TM_EA_LIQUIDITYMAP_MQH

enum ENUM_LIQUIDITY_LEVEL_TYPE
{
   LIQ_NONE = 0,
   LIQ_ASIA_HIGH,
   LIQ_ASIA_LOW,
   LIQ_PREV_DAY_HIGH,
   LIQ_PREV_DAY_LOW,
   LIQ_SWING_HIGH,
   LIQ_SWING_LOW
};

struct SLiquidityLevel
{
   ENUM_LIQUIDITY_LEVEL_TYPE type;
   double                    price;
   datetime                  time;
   bool                      active;
};

class CLiquidityMap
{
private:
   string           m_symbol;
   ENUM_TIMEFRAMES  m_tf;
   double           m_asiaHigh;
   double           m_asiaLow;
   datetime         m_asiaDate;
   double           m_pdh;
   double           m_pdl;
   datetime         m_pdDate;

public:
   CLiquidityMap()
   {
      m_symbol = "";
      m_tf = PERIOD_M5;
      m_asiaHigh = 0.0;
      m_asiaLow = 0.0;
      m_asiaDate = 0;
      m_pdh = 0.0;
      m_pdl = 0.0;
      m_pdDate = 0;
   }

   bool Init(const string symbol, const ENUM_TIMEFRAMES tf = PERIOD_M5)
   {
      m_symbol = symbol;
      m_tf = tf;
      return true;
   }

   // Update Previous Day High / Low
   bool UpdatePDH_PDL(const datetime currentServerTime)
   {
      MqlRates dailyRates[];
      int n = CopyRates(m_symbol, PERIOD_D1, 1, 1, dailyRates);
      if(n > 0)
      {
         m_pdh = dailyRates[0].high;
         m_pdl = dailyRates[0].low;
         m_pdDate = dailyRates[0].time;
         return true;
      }
      return false;
   }

   // Update Asian Session Range
   bool UpdateAsianRange(const datetime rangeFrom, const datetime rangeTo)
   {
      MqlRates rates[];
      int n = CopyRates(m_symbol, PERIOD_M5, rangeFrom, rangeTo, rates);
      if(n <= 0)
         return false;

      m_asiaHigh = rates[0].high;
      m_asiaLow  = rates[0].low;
      for(int i = 1; i < n; i++)
      {
         if(rates[i].high > m_asiaHigh) m_asiaHigh = rates[i].high;
         if(rates[i].low  < m_asiaLow)  m_asiaLow  = rates[i].low;
      }
      m_asiaDate = rangeFrom;
      return true;
   }

   double GetAsiaHigh() const { return m_asiaHigh; }
   double GetAsiaLow()  const { return m_asiaLow;  }
   double GetPDH()      const { return m_pdh;       }
   double GetPDL()      const { return m_pdl;       }

   // Find recent M5 swing high/low over lookback bars (e.g. 20-30 bars)
   bool GetRecentSwings(const int lookback, double &swingHigh, double &swingLow)
   {
      swingHigh = 0.0;
      swingLow = 0.0;
      MqlRates rates[];
      int n = CopyRates(m_symbol, m_tf, 2, lookback, rates);
      if(n < 5)
         return false;

      swingHigh = rates[0].high;
      swingLow  = rates[0].low;
      for(int i = 1; i < n; i++)
      {
         if(rates[i].high > swingHigh) swingHigh = rates[i].high;
         if(rates[i].low  < swingLow)  swingLow  = rates[i].low;
      }
      return true;
   }

   // Detect Setup A: Liquidity Sweep Reversal
   bool CheckSweepReversal(const double atr,
                           int &outDirection,
                           double &outEntry,
                           double &outStopLoss,
                           double &outLevelPrice,
                           string &outReason)
   {
      outDirection = 0;
      outEntry = 0.0;
      outStopLoss = 0.0;
      outLevelPrice = 0.0;
      outReason = "";

      if(atr <= 0.0) return false;

      MqlRates bar1[1], bar2[1];
      if(CopyRates(m_symbol, m_tf, 1, 1, bar1) != 1 ||
         CopyRates(m_symbol, m_tf, 2, 1, bar2) != 1)
      {
         outReason = "CopyRates failed for bar1/bar2";
         return false;
      }

      double c1 = bar1[0].close;
      double h1 = bar1[0].high;
      double l1 = bar1[0].low;
      double h2 = bar2[0].high;
      double l2 = bar2[0].low;

      double ask = SymbolInfoDouble(m_symbol, SYMBOL_ASK);
      double bid = SymbolInfoDouble(m_symbol, SYMBOL_BID);

      double minPenetration = 0.15 * atr; // Must penetrate past level to trigger real liquidity
      double minReclaim     = 0.05 * atr; // Must close firmly back inside

      // Check against Asia Low / PDL / Swing Low for BULLISH SWEEP
      double candidateLowLevels[3];
      string lowLevelNames[3];
      int lowCount = 0;

      if(m_asiaLow > 0.0) { candidateLowLevels[lowCount] = m_asiaLow; lowLevelNames[lowCount] = "Asia Low"; lowCount++; }
      if(m_pdl > 0.0)     { candidateLowLevels[lowCount] = m_pdl;     lowLevelNames[lowCount] = "PDL";      lowCount++; }

      double swingH = 0.0, swingL = 0.0;
      if(GetRecentSwings(25, swingH, swingL) && swingL > 0.0)
      {
         candidateLowLevels[lowCount] = swingL; lowLevelNames[lowCount] = "Swing Low"; lowCount++;
      }

      for(int i = 0; i < lowCount; i++)
      {
         double lvl = candidateLowLevels[i];
         bool dippedBelow = (l1 < lvl || l2 < lvl);
         bool reclaimedAbove = (c1 > lvl + minReclaim);
         double penetration = lvl - MathMin(l1, l2);

         if(dippedBelow && reclaimedAbove && penetration >= minPenetration && penetration <= 2.5 * atr)
         {
            outDirection = 1; // BUY
            outEntry = ask;
            double sweepExtreme = MathMin(l1, l2);
            outStopLoss = sweepExtreme - (0.35 * atr);
            outLevelPrice = lvl;
            outReason = StringFormat("Bullish Sweep of %s (%.2f) | Pen=%.2f Reclaim=%.2f",
                                     lowLevelNames[i], lvl, penetration, c1);
            return true;
         }
      }

      // Check against Asia High / PDH / Swing High for BEARISH SWEEP
      double candidateHighLevels[3];
      string highLevelNames[3];
      int highCount = 0;

      if(m_asiaHigh > 0.0) { candidateHighLevels[highCount] = m_asiaHigh; highLevelNames[highCount] = "Asia High"; highCount++; }
      if(m_pdh > 0.0)      { candidateHighLevels[highCount] = m_pdh;      highLevelNames[highCount] = "PDH";       highCount++; }
      if(swingH > 0.0)     { candidateHighLevels[highCount] = swingH;     highLevelNames[highCount] = "Swing High"; highCount++; }

      for(int i = 0; i < highCount; i++)
      {
         double lvl = candidateHighLevels[i];
         bool pokedAbove = (h1 > lvl || h2 > lvl);
         bool reclaimedBelow = (c1 < lvl - minReclaim);
         double penetration = MathMax(h1, h2) - lvl;

         if(pokedAbove && reclaimedBelow && penetration >= minPenetration && penetration <= 2.5 * atr)
         {
            outDirection = -1; // SELL
            outEntry = bid;
            double sweepExtreme = MathMax(h1, h2);
            outStopLoss = sweepExtreme + (0.35 * atr);
            outLevelPrice = lvl;
            outReason = StringFormat("Bearish Sweep of %s (%.2f) | Pen=%.2f Reclaim=%.2f",
                                     highLevelNames[i], lvl, penetration, c1);
            return true;
         }
      }

      outReason = "No sweep detected";
      return false;
   }
};

#endif // TM_EA_LIQUIDITYMAP_MQH
