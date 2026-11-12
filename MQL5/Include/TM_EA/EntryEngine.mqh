//+------------------------------------------------------------------+
//| EntryEngine.mqh                                                  |
//| Pullback entry detection on completed bars.                      |
//+------------------------------------------------------------------+
#ifndef TM_EA_ENTRYENGINE_MQH
#define TM_EA_ENTRYENGINE_MQH

#include "Types.mqh"

class CEntryEngine
{
private:
   string             m_symbol;
   ENUM_TIMEFRAMES    m_entryTimeframe;
   int                m_pullbackEmaPeriod;
   int                m_pullbackBufferPips;
   int                m_hPullbackEma;
   double             m_point;
   datetime           m_lastSignalBarTime;

public:
   CEntryEngine()
   {
      m_symbol = "";
      m_entryTimeframe = PERIOD_CURRENT;
      m_pullbackEmaPeriod = 0;
      m_pullbackBufferPips = 0;
      m_hPullbackEma = INVALID_HANDLE;
      m_point = 0.0;
      m_lastSignalBarTime = 0;
   }

   bool Init(const string symbol,
             const ENUM_TIMEFRAMES entryTimeframe,
             const int pullbackEmaPeriod,
             const int pullbackBufferPips,
             const double point)
   {
      m_symbol = symbol;
      m_entryTimeframe = entryTimeframe;
      m_pullbackEmaPeriod = pullbackEmaPeriod;
      m_pullbackBufferPips = pullbackBufferPips;
      m_point = point;

      if(pullbackEmaPeriod <= 0 || point <= 0.0)
         return false;

      m_hPullbackEma = iMA(symbol, entryTimeframe, pullbackEmaPeriod, 0, MODE_EMA, PRICE_CLOSE);
      if(m_hPullbackEma == INVALID_HANDLE)
         return false;

      return true;
   }

   void Deinit()
   {
      if(m_hPullbackEma != INVALID_HANDLE)
      {
         IndicatorRelease(m_hPullbackEma);
         m_hPullbackEma = INVALID_HANDLE;
      }
   }

   SSignal EvaluatePullback(const ENUM_TREND_STATE trendState)
   {
      SSignal signal;
      signal.valid = false;
      signal.direction = 0;
      signal.setup = SETUP_NONE;
      signal.signalBarTime = 0;
      signal.entryReference = 0.0;
      signal.invalidationLevel = 0.0;
      signal.reason = "no pullback signal";

      if(trendState == TREND_STATE_NONE)
      {
         signal.reason = "trend state is none";
         return signal;
      }

      if(BarsCalculated(m_hPullbackEma) < m_pullbackEmaPeriod + 2)
      {
         signal.reason = "pullback EMA is still calculating";
         return signal;
      }

      double emaBuffer[2];
      if(CopyBuffer(m_hPullbackEma, 0, 0, 2, emaBuffer) != 2)
      {
         signal.reason = "failed to copy pullback EMA buffer";
         return signal;
      }

      // Index 1 is the last completed bar.
      double emaValue = emaBuffer[1];
      double completedOpen = iOpen(m_symbol, m_entryTimeframe, 1);
      double completedHigh = iHigh(m_symbol, m_entryTimeframe, 1);
      double completedLow = iLow(m_symbol, m_entryTimeframe, 1);
      double completedClose = iClose(m_symbol, m_entryTimeframe, 1);
      datetime completedBarTime = iTime(m_symbol, m_entryTimeframe, 1);

      if(completedBarTime == 0 || completedBarTime == m_lastSignalBarTime)
      {
         signal.reason = "duplicate or unavailable signal bar";
         return signal;
      }

      // Convert the configured pip buffer to a price distance. A standard pip is
      // treated as 10 points for this first implementation and can be refined.
      double bufferPrice = m_point * (double)m_pullbackBufferPips * 10.0;

      if(trendState == TREND_STATE_UP)
      {
         bool touchedPullbackZone = (completedLow <= emaValue + bufferPrice);
         bool bullishConfirmation = (completedClose > completedOpen);

         if(touchedPullbackZone && bullishConfirmation)
         {
            signal.valid = true;
            signal.direction = 1;
            signal.setup = SETUP_PULLBACK;
            signal.signalBarTime = completedBarTime;
            signal.entryReference = completedClose;
            signal.invalidationLevel = completedLow;
            signal.reason = "pullback buy confirmed";
            m_lastSignalBarTime = completedBarTime;
         }
         else
         {
            signal.reason = "pullback buy conditions not met";
         }
      }
      else if(trendState == TREND_STATE_DOWN)
      {
         bool touchedPullbackZone = (completedHigh >= emaValue - bufferPrice);
         bool bearishConfirmation = (completedClose < completedOpen);

         if(touchedPullbackZone && bearishConfirmation)
         {
            signal.valid = true;
            signal.direction = -1;
            signal.setup = SETUP_PULLBACK;
            signal.signalBarTime = completedBarTime;
            signal.entryReference = completedClose;
            signal.invalidationLevel = completedHigh;
            signal.reason = "pullback sell confirmed";
            m_lastSignalBarTime = completedBarTime;
         }
         else
         {
            signal.reason = "pullback sell conditions not met";
         }
      }

      return signal;
   }
};

#endif // TM_EA_ENTRYENGINE_MQH
