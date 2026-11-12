//+------------------------------------------------------------------+
//| RiskGuard.mqh                                                    |
//| Entry-only risk guards. Does not manage open positions.          |
//+------------------------------------------------------------------+
#ifndef TM_EA_RISKGUARD_MQH
#define TM_EA_RISKGUARD_MQH

class CRiskGuard
{
private:
   string   m_symbol;
   int      m_magicNumber;
   double   m_point;
   string   m_baseCurrency;
   string   m_profitCurrency;
   datetime m_lastHistoryCheck;
   ulong    m_lastProcessedDeal;

   string DailyBaselineVar() const { return "TM_EA_DailyBaseline_" + IntegerToString(m_magicNumber) + "_" + m_symbol; }
   string DailyDateVar() const { return "TM_EA_DailyDate_" + IntegerToString(m_magicNumber) + "_" + m_symbol; }
   string CooldownVar() const { return "TM_EA_CooldownUntil_" + IntegerToString(m_magicNumber) + "_" + m_symbol; }
   string ConsecutiveLossVar() const { return "TM_EA_ConsecutiveLosses_" + IntegerToString(m_magicNumber) + "_" + m_symbol; }

   datetime BrokerDayStart() const
   {
      MqlDateTime dt;
      TimeToStruct(TimeCurrent(), dt);
      dt.hour = 0;
      dt.min = 0;
      dt.sec = 0;
      return StructToTime(dt);
   }

   void EnsureDailyBaseline()
   {
      datetime today = BrokerDayStart();
      double storedDate = GlobalVariableGet(DailyDateVar());
      if((datetime)storedDate != today)
      {
         GlobalVariableSet(DailyDateVar(), (double)today);
         GlobalVariableSet(DailyBaselineVar(), AccountInfoDouble(ACCOUNT_EQUITY));
         GlobalVariableSet(ConsecutiveLossVar(), 0);
      }
      if(GlobalVariableGet(DailyBaselineVar()) <= 0.0)
         GlobalVariableSet(DailyBaselineVar(), AccountInfoDouble(ACCOUNT_EQUITY));
   }

   void RefreshClosedTradeHistory(const int maxConsecutiveLosses, const int cooldownMinutes)
   {
      datetime fromTime = BrokerDayStart();
      if(!HistorySelect(fromTime, TimeCurrent()))
         return;

      int deals = HistoryDealsTotal();
      for(int i = 0; i < deals; i++)
      {
         ulong dealTicket = HistoryDealGetTicket(i);
         if(dealTicket == 0 || dealTicket <= m_lastProcessedDeal)
            continue;
         if(HistoryDealGetString(dealTicket, DEAL_SYMBOL) != m_symbol)
            continue;
         if((int)HistoryDealGetInteger(dealTicket, DEAL_MAGIC) != m_magicNumber)
            continue;
         if(HistoryDealGetInteger(dealTicket, DEAL_ENTRY) != DEAL_ENTRY_OUT)
            continue;

         m_lastProcessedDeal = dealTicket;

         double profit = HistoryDealGetDouble(dealTicket, DEAL_PROFIT) +
                         HistoryDealGetDouble(dealTicket, DEAL_SWAP) +
                         HistoryDealGetDouble(dealTicket, DEAL_COMMISSION);

         if(profit < 0.0)
         {
            double losses = GlobalVariableGet(ConsecutiveLossVar()) + 1.0;
            GlobalVariableSet(ConsecutiveLossVar(), losses);
            if(losses >= (double)maxConsecutiveLosses)
            {
               GlobalVariableSet(CooldownVar(), (double)(TimeCurrent() + cooldownMinutes * 60));
               GlobalVariableSet(ConsecutiveLossVar(), 0.0);
            }
         }
         else if(profit > 0.0)
         {
            GlobalVariableSet(ConsecutiveLossVar(), 0.0);
         }
      }
   }

public:
   CRiskGuard()
   {
      m_symbol = "";
      m_magicNumber = 0;
      m_point = 0.0;
      m_baseCurrency = "";
      m_profitCurrency = "";
      m_lastHistoryCheck = 0;
      m_lastProcessedDeal = 0;
   }

   bool Init(const string symbol, const int magicNumber, const double point)
   {
      m_symbol = symbol;
      m_magicNumber = magicNumber;
      m_point = point;
      m_baseCurrency = SymbolInfoString(symbol, SYMBOL_CURRENCY_BASE);
      m_profitCurrency = SymbolInfoString(symbol, SYMBOL_CURRENCY_PROFIT);
      m_lastHistoryCheck = 0;
      m_lastProcessedDeal = 0;
      EnsureDailyBaseline();
      return (point > 0.0);
   }

   void Refresh(const int maxConsecutiveLosses, const int cooldownMinutes)
   {
      EnsureDailyBaseline();
      if(TimeCurrent() - m_lastHistoryCheck >= 5)
      {
         RefreshClosedTradeHistory(maxConsecutiveLosses, cooldownMinutes);
         m_lastHistoryCheck = TimeCurrent();
      }
   }

   bool CanOpenNewEntry(const double maxDailyLossPercent,
                        const int maxSpreadPoints,
                        const bool useSessionFilter,
                        const bool newsEnable,
                        const int newsBufferMinutes,
                        const double volumeForMarginCheck,
                        string &reason) const
   {
      double cooldownUntil = GlobalVariableGet(CooldownVar());
      if(cooldownUntil > (double)TimeCurrent())
      {
         reason = "cooldown active after consecutive losses";
         return false;
      }

      double baseline = GlobalVariableGet(DailyBaselineVar());
      double equity = AccountInfoDouble(ACCOUNT_EQUITY);
      if(baseline > 0.0)
      {
         double lossPercent = (baseline - equity) / baseline * 100.0;
         if(lossPercent >= maxDailyLossPercent)
         {
            reason = "daily loss limit reached";
            return false;
         }
      }

      double bid = SymbolInfoDouble(m_symbol, SYMBOL_BID);
      double ask = SymbolInfoDouble(m_symbol, SYMBOL_ASK);
      double spreadPoints = (ask - bid) / m_point;
      if(spreadPoints > (double)maxSpreadPoints)
      {
         reason = "spread too high";
         return false;
      }

      if(useSessionFilter)
      {
         MqlDateTime dt;
         TimeToStruct(TimeCurrent(), dt);
         if(dt.day_of_week == 0 || dt.day_of_week == 6)
         {
            reason = "weekend session blocked";
            return false;
         }
         if(dt.hour < 7 || dt.hour >= 20)
         {
            reason = "outside configured session hours";
            return false;
         }
      }

      if(newsEnable)
      {
         datetime fromTime = TimeCurrent() - newsBufferMinutes * 60;
         datetime toTime = TimeCurrent() + newsBufferMinutes * 60;
         MqlCalendarValue values[];
         int calendarResult = CalendarValueHistory(values, fromTime, toTime, NULL, NULL);
         if(calendarResult < 0)
         {
            reason = "news calendar unavailable";
            return false;
         }
         int count = ArraySize(values);
         for(int i = 0; i < count; i++)
         {
            MqlCalendarEvent event;
            if(!CalendarEventById(values[i].event_id, event))
               continue;
            if(event.importance != CALENDAR_IMPORTANCE_HIGH)
               continue;

            MqlCalendarCountry country;
            string eventCurrency = "";
            if(CalendarCountryById(event.country_id, country))
               eventCurrency = country.currency;

            if(eventCurrency != m_baseCurrency && eventCurrency != m_profitCurrency)
               continue;

            reason = "high-impact news buffer";
            return false;
         }
      }

      if(volumeForMarginCheck > 0.0)
      {
         double margin = 0.0;
         ENUM_ORDER_TYPE orderType = ORDER_TYPE_BUY;
         if(!OrderCalcMargin(orderType, m_symbol, volumeForMarginCheck, ask, margin))
         {
            reason = "margin calculation failed";
            return false;
         }
         if(AccountInfoDouble(ACCOUNT_MARGIN_FREE) < margin)
         {
            reason = "insufficient margin";
            return false;
         }
      }

      reason = "ok";
      return true;
   }
};

#endif // TM_EA_RISKGUARD_MQH
