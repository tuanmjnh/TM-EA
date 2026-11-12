//+------------------------------------------------------------------+
//| InitialStop.mqh                                                  |
//| Initial stop-loss calculation and validation.                    |
//+------------------------------------------------------------------+
#ifndef TM_EA_INITIALSTOP_MQH
#define TM_EA_INITIALSTOP_MQH

class CInitialStop
{
private:
   static int s_atrHandle;
   static string s_symbol;
   static ENUM_TIMEFRAMES s_timeframe;
   static int s_period;

public:
   static double ATRValue(const string symbol,
                          const ENUM_TIMEFRAMES timeframe,
                          const int period)
   {
      if(period <= 0)
         return 0.0;

      if(s_atrHandle == INVALID_HANDLE ||
         s_symbol != symbol ||
         s_timeframe != timeframe ||
         s_period != period)
      {
         if(s_atrHandle != INVALID_HANDLE)
            IndicatorRelease(s_atrHandle);
         s_atrHandle = iATR(symbol, timeframe, period);
         s_symbol = symbol;
         s_timeframe = timeframe;
         s_period = period;
      }

      if(s_atrHandle == INVALID_HANDLE)
         return 0.0;

      if(BarsCalculated(s_atrHandle) < period + 2)
         return 0.0;

      double buffer[2];
      double result = 0.0;
      if(CopyBuffer(s_atrHandle, 0, 0, 2, buffer) == 2)
         result = buffer[1];

      return result;
   }

   static void ReleaseATRHandle()
   {
      if(s_atrHandle != INVALID_HANDLE)
      {
         IndicatorRelease(s_atrHandle);
         s_atrHandle = INVALID_HANDLE;
      }
   }

   static double NormalizeToTick(const double price, const double tickSize)
   {
      if(tickSize <= 0.0)
         return price;
      return NormalizeDouble(MathRound(price / tickSize) * tickSize, 8);
   }

   static double CalculateBuySL(const double entryPrice,
                               const double invalidationLevel,
                               const double atrValue,
                               const double atrMultiplier,
                               const double point,
                               const double tickSize,
                               const int stopLevelPoints)
   {
      if(entryPrice <= 0.0 || invalidationLevel >= entryPrice || atrValue <= 0.0 || atrMultiplier <= 0.0)
         return 0.0;

      double structuralDistance = entryPrice - invalidationLevel;
      double atrDistance = atrValue * atrMultiplier;
      double distance = MathMax(structuralDistance, atrDistance);

      double sl = entryPrice - distance;
      sl = NormalizeToTick(sl, tickSize);

      double minimumDistance = (double)stopLevelPoints * point;
      if(entryPrice - sl < minimumDistance)
         sl = NormalizeToTick(entryPrice - minimumDistance, tickSize);

      if(sl <= 0.0 || sl >= entryPrice)
         return 0.0;

      return sl;
   }

   static double CalculateSellSL(const double entryPrice,
                                const double invalidationLevel,
                                const double atrValue,
                                const double atrMultiplier,
                                const double point,
                                const double tickSize,
                                const int stopLevelPoints)
   {
      if(entryPrice <= 0.0 || invalidationLevel <= entryPrice || atrValue <= 0.0 || atrMultiplier <= 0.0)
         return 0.0;

      double structuralDistance = invalidationLevel - entryPrice;
      double atrDistance = atrValue * atrMultiplier;
      double distance = MathMax(structuralDistance, atrDistance);

      double sl = entryPrice + distance;
      sl = NormalizeToTick(sl, tickSize);

      double minimumDistance = (double)stopLevelPoints * point;
      if(sl - entryPrice < minimumDistance)
         sl = NormalizeToTick(entryPrice + minimumDistance, tickSize);

      if(sl <= entryPrice)
         return 0.0;

      return sl;
   }
};

int CInitialStop::s_atrHandle = INVALID_HANDLE;
string CInitialStop::s_symbol = "";
ENUM_TIMEFRAMES CInitialStop::s_timeframe = PERIOD_CURRENT;
int CInitialStop::s_period = 0;

#endif // TM_EA_INITIALSTOP_MQH