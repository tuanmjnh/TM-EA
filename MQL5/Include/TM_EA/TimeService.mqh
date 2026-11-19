//+------------------------------------------------------------------+
//| TimeService.mqh                                                  |
//| Time & Kill-Zone manager with automatic GMT offset detection.    |
//| Standardized for TM_GoldSweepScalper (SPEC_GOLD_SCALPER.md)      |
//+------------------------------------------------------------------+
#ifndef TM_EA_TIMESERVICE_MQH
#define TM_EA_TIMESERVICE_MQH

enum ENUM_KILL_ZONE
{
   KZ_NONE = 0,
   KZ_ASIA,       // 00:00 - 07:00 GMT (Range formation)
   KZ_LONDON,     // 07:00 - 10:00 GMT (London Open Kill-Zone)
   KZ_NEWYORK     // 12:30 - 15:00 GMT (NY Open Kill-Zone)
};

class CTimeService
{
private:
   int  m_inputOffset;
   int  m_detectedOffset;
   int  m_effectiveOffset;

public:
   CTimeService()
   {
      m_inputOffset = 999;
      m_detectedOffset = 0;
      m_effectiveOffset = 0;
   }

   void Init(const int brokerGmtOffset = 999)
   {
      m_inputOffset = brokerGmtOffset;
      RefreshOffset();
   }

   int RefreshOffset()
   {
      if(m_inputOffset != 999)
      {
         m_effectiveOffset = m_inputOffset;
         return m_effectiveOffset;
      }

      datetime srv = TimeTradeServer();
      datetime gmt = TimeGMT();
      if(srv > 0 && gmt > 0)
      {
         int diffSeconds = (int)(srv - gmt);
         m_detectedOffset = (int)MathRound((double)diffSeconds / 3600.0);
         m_effectiveOffset = m_detectedOffset;
      }
      else
      {
         m_effectiveOffset = 0;
      }
      return m_effectiveOffset;
   }

   int GetGMTOffset() const { return m_effectiveOffset; }

   int GMTtoServerHour(const int gmtHour) const
   {
      int h = (gmtHour + m_effectiveOffset) % 24;
      if(h < 0) h += 24;
      return h;
   }

   int ServerToGMTHour(const int serverHour) const
   {
      int h = (serverHour - m_effectiveOffset) % 24;
      if(h < 0) h += 24;
      return h;
   }

   datetime GetGMTTime(const datetime serverTime) const
   {
      return serverTime - (datetime)(m_effectiveOffset * 3600);
   }

   bool IsTradeSessionOpen(const string symbol, const datetime time) const
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

   ENUM_KILL_ZONE GetCurrentKillZone(const datetime serverTime, string &zoneName) const
   {
      datetime gmt = GetGMTTime(serverTime);
      MqlDateTime dt;
      TimeToStruct(gmt, dt);
      int minOfDay = dt.hour * 60 + dt.min;

      // Asia: 00:00 - 07:00 GMT (0 - 420 mins)
      if(minOfDay >= 0 && minOfDay < 420)
      {
         zoneName = "Asia";
         return KZ_ASIA;
      }
      // London KZ: 07:00 - 10:00 GMT (420 - 600 mins)
      if(minOfDay >= 420 && minOfDay < 600)
      {
         zoneName = "London KZ";
         return KZ_LONDON;
      }
      // NY KZ: 12:30 - 15:00 GMT (750 - 900 mins)
      if(minOfDay >= 750 && minOfDay < 900)
      {
         zoneName = "New York KZ";
         return KZ_NEWYORK;
      }

      zoneName = "Outside KZ";
      return KZ_NONE;
   }

   bool IsInActiveTradingKillZone(const datetime serverTime, string &zoneName) const
   {
      ENUM_KILL_ZONE kz = GetCurrentKillZone(serverTime, zoneName);
      return (kz == KZ_LONDON || kz == KZ_NEWYORK);
   }
};

#endif // TM_EA_TIMESERVICE_MQH
