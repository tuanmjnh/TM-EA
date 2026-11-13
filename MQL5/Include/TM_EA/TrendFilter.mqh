//+------------------------------------------------------------------+
//| TrendFilter.mqh                                                  |
//| Higher-timeframe trend classification using completed bars.       |
//+------------------------------------------------------------------+
#ifndef TM_EA_TRENDFILTER_MQH
#define TM_EA_TRENDFILTER_MQH

#include "Types.mqh"

class CTrendFilter
{
private:
   string             m_symbol;
   ENUM_TIMEFRAMES    m_timeframe;
   int                m_fastPeriod;
   int                m_slowPeriod;
   int                m_adxPeriod;
   double             m_adxThreshold;

   int                m_hFastEma;
   int                m_hSlowEma;
   int                m_hAdx;

   ENUM_TREND_STATE   m_state;
   double             m_fastValue;
   double             m_slowValue;
   double             m_adxValue;
   datetime           m_lastCompletedBarTime;
   bool               m_ready;
   bool               m_useSlope;
   string             m_reason;

public:
   CTrendFilter()
   {
      m_symbol = "";
      m_timeframe = PERIOD_CURRENT;
      m_fastPeriod = 0;
      m_slowPeriod = 0;
      m_adxPeriod = 0;
      m_adxThreshold = 0.0;
      m_hFastEma = INVALID_HANDLE;
      m_hSlowEma = INVALID_HANDLE;
      m_hAdx = INVALID_HANDLE;
      m_state = TREND_STATE_NONE;
      m_fastValue = 0.0;
      m_slowValue = 0.0;
      m_adxValue = 0.0;
      m_lastCompletedBarTime = 0;
      m_ready = false;
      m_useSlope = false;
      m_reason = "not initialized";
   }

   bool Init(const string symbol,
             const ENUM_TIMEFRAMES timeframe,
             const int fastPeriod,
             const int slowPeriod,
             const int adxPeriod,
             const double adxThreshold,
             const bool useSlope = false)
   {
      m_symbol = symbol;
      m_timeframe = timeframe;
      m_fastPeriod = fastPeriod;
      m_slowPeriod = slowPeriod;
      m_adxPeriod = adxPeriod;
      m_adxThreshold = adxThreshold;
      m_useSlope = useSlope;

      if(fastPeriod <= 0 || slowPeriod <= 0 || adxPeriod <= 0 || adxThreshold <= 0.0)
      {
         m_reason = "invalid trend-filter inputs";
         return false;
      }

      m_hFastEma = iMA(symbol, timeframe, fastPeriod, 0, MODE_EMA, PRICE_CLOSE);
      m_hSlowEma = iMA(symbol, timeframe, slowPeriod, 0, MODE_EMA, PRICE_CLOSE);
      m_hAdx = iADX(symbol, timeframe, adxPeriod);

      if(m_hFastEma == INVALID_HANDLE || m_hSlowEma == INVALID_HANDLE || m_hAdx == INVALID_HANDLE)
      {
         m_reason = "failed to create trend indicator handles";
         Deinit();
         return false;
      }

      m_reason = "initialized";
      return true;
   }

   void Deinit()
   {
      if(m_hFastEma != INVALID_HANDLE) { IndicatorRelease(m_hFastEma); m_hFastEma = INVALID_HANDLE; }
      if(m_hSlowEma != INVALID_HANDLE) { IndicatorRelease(m_hSlowEma); m_hSlowEma = INVALID_HANDLE; }
      if(m_hAdx != INVALID_HANDLE) { IndicatorRelease(m_hAdx); m_hAdx = INVALID_HANDLE; }
      m_ready = false;
   }

   bool Refresh()
   {
      m_ready = false;

      if(m_hFastEma == INVALID_HANDLE || m_hSlowEma == INVALID_HANDLE || m_hAdx == INVALID_HANDLE)
      {
         m_reason = "indicator handles are invalid";
         m_state = TREND_STATE_NONE;
         return false;
      }

      int requiredBars = m_slowPeriod + 5;
      if(BarsCalculated(m_hFastEma) < requiredBars ||
         BarsCalculated(m_hSlowEma) < requiredBars ||
         BarsCalculated(m_hAdx) < requiredBars)
      {
         m_reason = "indicators are still calculating";
         m_state = TREND_STATE_NONE;
         return false;
      }

      double fastBuffer[2];
      double slowBuffer[2];
      double adxBuffer[2];
      double closeBuffer[2];

      if(CopyBuffer(m_hFastEma, 0, 0, 2, fastBuffer) != 2 ||
         CopyBuffer(m_hSlowEma, 0, 0, 2, slowBuffer) != 2 ||
         CopyBuffer(m_hAdx, 0, 0, 2, adxBuffer) != 2 ||
         CopyClose(m_symbol, m_timeframe, 0, 2, closeBuffer) != 2)
      {
         m_reason = "failed to copy trend indicator buffers";
         m_state = TREND_STATE_NONE;
         return false;
      }

      // Index 1 is the last completed bar. Index 0 is the current, possibly incomplete bar.
      double fastEma = fastBuffer[1];
      double slowEma = slowBuffer[1];
      double adxValue = adxBuffer[1];
      double completedClose = closeBuffer[1];

      m_fastValue = fastEma;
      m_slowValue = slowEma;
      m_adxValue = adxValue;
      m_lastCompletedBarTime = iTime(m_symbol, m_timeframe, 1);

      // fastBuffer[1] = last completed bar, fastBuffer[0] = bar before it.
      bool slopeUp = (fastBuffer[1] > fastBuffer[0]);
      bool slopeDown = (fastBuffer[1] < fastBuffer[0]);

      if(fastEma > slowEma && adxValue > m_adxThreshold && completedClose > fastEma &&
         (!m_useSlope || slopeUp))
      {
         m_state = TREND_STATE_UP;
         m_reason = "uptrend";
      }
      else if(fastEma < slowEma && adxValue > m_adxThreshold && completedClose < fastEma &&
              (!m_useSlope || slopeDown))
      {
         m_state = TREND_STATE_DOWN;
         m_reason = "downtrend";
      }
      else
      {
         m_state = TREND_STATE_NONE;
         m_reason = "sideways or insufficient trend strength";
      }

      m_ready = true;
      return true;
   }

   ENUM_TREND_STATE State() const { return m_state; }
   bool IsReady() const { return m_ready; }
   string Reason() const { return m_reason; }
   double FastEma() const { return m_fastValue; }
   double SlowEma() const { return m_slowValue; }
   double Adx() const { return m_adxValue; }
   datetime LastCompletedBarTime() const { return m_lastCompletedBarTime; }
};

#endif // TM_EA_TRENDFILTER_MQH
