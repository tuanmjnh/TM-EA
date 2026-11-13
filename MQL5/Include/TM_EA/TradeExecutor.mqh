//+------------------------------------------------------------------+
//| TradeExecutor.mqh                                                |
//| Order execution helper with initial Stop Loss and optional TP.    |
//+------------------------------------------------------------------+
#ifndef TM_EA_TRADEEXECUTOR_MQH
#define TM_EA_TRADEEXECUTOR_MQH

#include <Trade\Trade.mqh>

class CTradeExecutor
{
private:
   CTrade  m_trade;
   int     m_magicNumber;
   int     m_deviationPoints;

public:
   CTradeExecutor()
   {
      m_magicNumber = 0;
      m_deviationPoints = 10;
   }

   bool Init(const int magicNumber, const int deviationPoints)
   {
      m_magicNumber = magicNumber;
      m_deviationPoints = deviationPoints;

      m_trade.SetExpertMagicNumber(magicNumber);
      m_trade.SetDeviationInPoints(deviationPoints);
      m_trade.SetTypeFilling(ORDER_FILLING_FOK);
      m_trade.LogLevel(LOG_LEVEL_ERRORS);
      return true;
   }

   int CountOpenPositions(const string symbol) const
   {
      int count = 0;
      for(int i = PositionsTotal() - 1; i >= 0; i--)
      {
         ulong ticket = PositionGetTicket(i);
         if(ticket == 0)
            continue;
         if(PositionGetString(POSITION_SYMBOL) != symbol)
            continue;
         if((int)PositionGetInteger(POSITION_MAGIC) != m_magicNumber)
            continue;
         count++;
      }
      return count;
   }

   // Circuit breaker: market-close every position owned by this EA on the symbol.
   int CloseAllPositions(const string symbol)
   {
      int closed = 0;
      for(int i = PositionsTotal() - 1; i >= 0; i--)
      {
         ulong ticket = PositionGetTicket(i);
         if(ticket == 0)
            continue;
         if(PositionGetString(POSITION_SYMBOL) != symbol)
            continue;
         if((int)PositionGetInteger(POSITION_MAGIC) != m_magicNumber)
            continue;
         if(m_trade.PositionClose(ticket))
            closed++;
      }
      return closed;
   }

   bool OpenBuy(const string symbol, const double volume, const double stopLoss, const double takeProfit,
                const string comment, ulong &ticket)
   {
      ticket = 0;
      if(volume <= 0.0 || stopLoss <= 0.0)
         return false;

      if(!m_trade.Buy(volume, symbol, 0.0, stopLoss, takeProfit, comment))
         return false;

      if(m_trade.ResultRetcode() != TRADE_RETCODE_DONE)
         return false;

      ticket = m_trade.ResultDeal();
      return true;
   }

   bool OpenSell(const string symbol, const double volume, const double stopLoss, const double takeProfit,
                 const string comment, ulong &ticket)
   {
      ticket = 0;
      if(volume <= 0.0 || stopLoss <= 0.0)
         return false;

      if(!m_trade.Sell(volume, symbol, 0.0, stopLoss, takeProfit, comment))
         return false;

      if(m_trade.ResultRetcode() != TRADE_RETCODE_DONE)
         return false;

      ticket = m_trade.ResultDeal();
      return true;
   }

   bool ClosePartial(const ulong ticket, const double volume)
   {
      if(volume <= 0.0)
         return false;
      return m_trade.PositionClosePartial(ticket, volume);
   }

   bool ModifyStopLoss(const ulong ticket, const double newStopLoss)
   {
      if(newStopLoss <= 0.0)
         return false;
      return m_trade.PositionModify(ticket, newStopLoss, 0.0);
   }

   uint LastRetcode() const { return m_trade.ResultRetcode(); }
   double LastPrice() const { return m_trade.ResultPrice(); }
};

#endif // TM_EA_TRADEEXECUTOR_MQH
