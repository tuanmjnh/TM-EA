//+------------------------------------------------------------------+
//| SymbolSpecs.mqh                                                  |
//| Read and validate symbol properties used by risk sizing.          |
//+------------------------------------------------------------------+
#ifndef TM_EA_SYMBOLSPECS_MQH
#define TM_EA_SYMBOLSPECS_MQH

class CSymbolSpecs
{
private:
   string m_symbol;
   bool   m_ready;

public:
   double Point;
   double TickSize;
   double TickValue;
   int    Digits;
   double VolumeMin;
   double VolumeMax;
   double VolumeStep;
   int    StopLevelPoints;
   int    FreezeLevelPoints;
   bool   TradeAllowed;

   CSymbolSpecs()
   {
      m_symbol = "";
      m_ready = false;
      Point = 0.0;
      TickSize = 0.0;
      TickValue = 0.0;
      Digits = 0;
      VolumeMin = 0.0;
      VolumeMax = 0.0;
      VolumeStep = 0.0;
      StopLevelPoints = 0;
      FreezeLevelPoints = 0;
      TradeAllowed = false;
   }

   bool Refresh(const string symbol)
   {
      m_symbol = symbol;
      m_ready = false;

      if(!SymbolSelect(symbol, true))
         return false;

      Point = SymbolInfoDouble(symbol, SYMBOL_POINT);
      TickSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
      TickValue = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
      Digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
      VolumeMin = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
      VolumeMax = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
      VolumeStep = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
      StopLevelPoints = (int)SymbolInfoInteger(symbol, SYMBOL_TRADE_STOPS_LEVEL);
      FreezeLevelPoints = (int)SymbolInfoInteger(symbol, SYMBOL_TRADE_FREEZE_LEVEL);
      TradeAllowed = ((int)SymbolInfoInteger(symbol, SYMBOL_TRADE_MODE) != SYMBOL_TRADE_MODE_DISABLED);

      if(Point <= 0.0 || TickSize <= 0.0 || VolumeStep <= 0.0 || VolumeMin <= 0.0)
         return false;

      m_ready = true;
      return true;
   }

   bool IsReady() const { return m_ready; }
   string Symbol() const { return m_symbol; }
};

#endif // TM_EA_SYMBOLSPECS_MQH
