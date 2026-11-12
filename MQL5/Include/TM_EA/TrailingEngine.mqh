//+------------------------------------------------------------------+
//| TrailingEngine.mqh                                               |
//| ATR trailing stop management. No Take Profit.                    |
//+------------------------------------------------------------------+
#ifndef TM_EA_TRAILINGENGINE_MQH
#define TM_EA_TRAILINGENGINE_MQH

#include "TradeExecutor.mqh"

class CTrailingEngine
{
private:
   string m_symbol;
   int    m_magicNumber;
   double m_point;

public:
   CTrailingEngine()
   {
      m_symbol = "";
      m_magicNumber = 0;
      m_point = 0.0;
   }

   bool Init(const string symbol, const int magicNumber, const double point)
   {
      m_symbol = symbol;
      m_magicNumber = magicNumber;
      m_point = point;
      return (point > 0.0);
   }

   int Update(CTradeExecutor &executor,
              const double atrValue,
              const double atrMultiplier,
              const double activateAfterProfitPips,
              const double trailStepPips,
              const double breakevenAfterPips,
              const double tickSize,
              const int stopLevelPoints,
              const int freezeLevelPoints)
   {
      if(atrValue <= 0.0 || atrMultiplier <= 0.0 || m_point <= 0.0)
         return 0;

      double trailDistance = atrValue * atrMultiplier;
      double activateDistance = m_point * activateAfterProfitPips * 10.0;
      double stepDistance = m_point * trailStepPips * 10.0;
      double breakevenDistance = m_point * breakevenAfterPips * 10.0;

      double bid = SymbolInfoDouble(m_symbol, SYMBOL_BID);
      double ask = SymbolInfoDouble(m_symbol, SYMBOL_ASK);
      double spread = ask - bid;

      int modifiedCount = 0;

      for(int i = PositionsTotal() - 1; i >= 0; i--)
      {
         ulong ticket = PositionGetTicket(i);
         if(ticket == 0)
            continue;
         if(PositionGetString(POSITION_SYMBOL) != m_symbol)
            continue;
         if((int)PositionGetInteger(POSITION_MAGIC) != m_magicNumber)
            continue;

         ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
         double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
         double currentSL = PositionGetDouble(POSITION_SL);

         if(type == POSITION_TYPE_BUY)
         {
            double profitDistance = bid - openPrice;
            if(profitDistance < activateDistance)
               continue;

            double newSL = bid - trailDistance;

            if(profitDistance >= breakevenDistance)
            {
               double breakEvenSL = openPrice + spread;
               if(breakEvenSL > newSL)
                  newSL = breakEvenSL;
            }

            newSL = MathFloor(newSL / tickSize) * tickSize;
            newSL = NormalizeDouble(newSL, 8);

            double minimumDistance = (double)stopLevelPoints * m_point;
            if(bid - newSL < minimumDistance)
               newSL = NormalizeDouble(bid - minimumDistance, 8);

            if(newSL <= currentSL)
               continue;
            if(currentSL > 0.0 && (newSL - currentSL) < stepDistance)
               continue;
            if((bid - newSL) < (double)freezeLevelPoints * m_point)
               continue;

            if(executor.ModifyStopLoss(ticket, newSL))
               modifiedCount++;
         }
         else if(type == POSITION_TYPE_SELL)
         {
            double profitDistance = openPrice - ask;
            if(profitDistance < activateDistance)
               continue;

            double newSL = ask + trailDistance;

            if(profitDistance >= breakevenDistance)
            {
               double breakEvenSL = openPrice - spread;
               if(breakEvenSL < newSL)
                  newSL = breakEvenSL;
            }

            newSL = MathCeil(newSL / tickSize) * tickSize;
            newSL = NormalizeDouble(newSL, 8);

            double minimumDistance = (double)stopLevelPoints * m_point;
            if(newSL - ask < minimumDistance)
               newSL = NormalizeDouble(ask + minimumDistance, 8);

            if(currentSL > 0.0 && newSL >= currentSL)
               continue;
            if(currentSL > 0.0 && (currentSL - newSL) < stepDistance)
               continue;
            if((newSL - ask) < (double)freezeLevelPoints * m_point)
               continue;

            if(executor.ModifyStopLoss(ticket, newSL))
               modifiedCount++;
         }
      }

      return modifiedCount;
   }
};

#endif // TM_EA_TRAILINGENGINE_MQH
