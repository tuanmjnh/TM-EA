//+------------------------------------------------------------------+
//| Guards.mqh                                                       |
//| Multi-Layer Risk Guard System                                    |
//| (Spread, Daily Equity Breaker, Circuit Breaker, Cooldown)        |
//| Standardized for TM_GoldSweepScalper (SPEC_GOLD_SCALPER.md)      |
//+------------------------------------------------------------------+
#ifndef TM_EA_GUARDS_MQH
#define TM_EA_GUARDS_MQH

#include "TradeExecutor.mqh"

class CGuards
{
private:
   string   m_symbol;
   int      m_magicNumber;
   int      m_maxSpreadPoints;
   double   m_maxDailyLossPct;
   double   m_circuitBreakerDDPct;
   int      m_maxConsecLosses;
   int      m_cooldownSeconds;

   datetime m_lastDay;
   double   m_dayBaselineEquity;
   double   m_peakEquity;
   int      m_consecLosses;
   datetime m_lastLossTime;
   bool     m_lockedToday;
   string   m_lockReason;

public:
   CGuards()
   {
      m_symbol = "";
      m_magicNumber = 0;
      m_maxSpreadPoints = 350;
      m_maxDailyLossPct = 2.0;
      m_circuitBreakerDDPct = 8.0;
      m_maxConsecLosses = 3;
      m_cooldownSeconds = 1800;
      m_lastDay = 0;
      m_dayBaselineEquity = 0.0;
      m_peakEquity = 0.0;
      m_consecLosses = 0;
      m_lastLossTime = 0;
      m_lockedToday = false;
      m_lockReason = "";
   }

   void Init(const string symbol,
             const int magicNumber,
             const int maxSpreadPoints = 350,
             const double maxDailyLossPct = 2.0,
             const double circuitBreakerDDPct = 8.0,
             const int maxConsecLosses = 3,
             const int cooldownSeconds = 1800)
   {
      m_symbol = symbol;
      m_magicNumber = magicNumber;
      m_maxSpreadPoints = maxSpreadPoints;
      m_maxDailyLossPct = maxDailyLossPct;
      m_circuitBreakerDDPct = circuitBreakerDDPct;
      m_maxConsecLosses = maxConsecLosses;
      m_cooldownSeconds = cooldownSeconds;

      double eq = AccountInfoDouble(ACCOUNT_EQUITY);
      m_dayBaselineEquity = eq;
      m_peakEquity = eq;
      m_consecLosses = 0;
      m_lastLossTime = 0;
      m_lockedToday = false;
      m_lockReason = "";
   }

   void CheckNewDay(const datetime dayStart, const double currentEquity)
   {
      if(dayStart != m_lastDay)
      {
         m_lastDay = dayStart;
         m_dayBaselineEquity = currentEquity;
         m_lockedToday = false;
         m_lockReason = "";
      }
      if(currentEquity > m_peakEquity)
         m_peakEquity = currentEquity;
   }

   void RegisterDealClose(const double profit, const datetime dealTime)
   {
      if(profit < 0.0)
      {
         m_consecLosses++;
         m_lastLossTime = dealTime;
      }
      else if(profit > 0.0)
      {
         m_consecLosses = 0;
      }
   }

   bool AllowTrade(CTradeExecutor &trade,
                   const double currentSpreadPoints,
                   const datetime currentTime,
                   string &blockReason)
   {
      blockReason = "";

      // 1. Check if circuit breaker locked today
      if(m_lockedToday)
      {
         blockReason = "Guards blocked: locked for day (" + m_lockReason + ")";
         return false;
      }

      // 2. Max 1 position open
      if(trade.CountOpenPositions(m_symbol) > 0)
      {
         blockReason = "Guards blocked: position already open for " + m_symbol;
         return false;
      }

      // 3. Spread check
      if(currentSpreadPoints > (double)m_maxSpreadPoints)
      {
         blockReason = StringFormat("Guards blocked: spread %.0f > max %d points",
                                    currentSpreadPoints, m_maxSpreadPoints);
         return false;
      }

      // 4. Consecutive Loss Cooldown
      if(m_consecLosses >= m_maxConsecLosses)
      {
         int elapsed = (int)(currentTime - m_lastLossTime);
         if(elapsed < m_cooldownSeconds)
         {
            blockReason = StringFormat("Guards blocked: cooldown after %d consecutive losses (%d/%ds left)",
                                       m_consecLosses, m_cooldownSeconds - elapsed, m_cooldownSeconds);
            return false;
         }
         else
         {
            // Cooldown expired, reset counter
            m_consecLosses = 0;
         }
      }

      double eq = AccountInfoDouble(ACCOUNT_EQUITY);

      // 5. Daily Loss Limit Check
      if(m_dayBaselineEquity > 0.0)
      {
         double dailyLossPct = (m_dayBaselineEquity - eq) / m_dayBaselineEquity * 100.0;
         if(dailyLossPct >= m_maxDailyLossPct)
         {
            m_lockedToday = true;
            m_lockReason = StringFormat("Daily loss %.2f%% reached limit %.2f%%", dailyLossPct, m_maxDailyLossPct);
            blockReason = "Guards tripped: " + m_lockReason;
            return false;
         }
      }

      // 6. Total Equity Circuit Breaker
      if(m_peakEquity > 0.0)
      {
         double totalDDPct = (m_peakEquity - eq) / m_peakEquity * 100.0;
         if(totalDDPct >= m_circuitBreakerDDPct)
         {
            m_lockedToday = true;
            m_lockReason = StringFormat("Equity DD %.2f%% exceeded breaker %.2f%%", totalDDPct, m_circuitBreakerDDPct);
            trade.CloseAllPositions(m_symbol);
            blockReason = "Guards CIRCUIT BREAKER TRIPPED: " + m_lockReason;
            return false;
         }
      }

      return true;
   }

   bool IsLocked() const { return m_lockedToday; }
   string GetLockReason() const { return m_lockReason; }
};

#endif // TM_EA_GUARDS_MQH
