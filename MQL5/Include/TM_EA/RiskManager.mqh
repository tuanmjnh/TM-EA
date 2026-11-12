//+------------------------------------------------------------------+
//| RiskManager.mqh                                                  |
//| Cash-risk based volume calculation.                              |
//+------------------------------------------------------------------+
#ifndef TM_EA_RISKMANAGER_MQH
#define TM_EA_RISKMANAGER_MQH

class CRiskManager
{
public:
   static double CalculateVolume(const string symbol,
                                const int direction,
                                const double riskPercent,
                                const double balance,
                                const double entryPrice,
                                const double stopLossPrice,
                                const double volumeMin,
                                const double volumeMax,
                                const double volumeStep,
                                string &reason)
   {
      reason = "unknown";

      if(riskPercent <= 0.0 || balance <= 0.0 || entryPrice <= 0.0 || stopLossPrice <= 0.0)
      {
         reason = "invalid risk or price inputs";
         return 0.0;
      }

      if(direction != 1 && direction != -1)
      {
         reason = "invalid trade direction";
         return 0.0;
      }

      ENUM_ORDER_TYPE orderType = (direction > 0) ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;

      double riskMoney = balance * riskPercent / 100.0;

      double lossForOneLot = 0.0;
      if(!OrderCalcProfit(orderType, symbol, 1.0, entryPrice, stopLossPrice, lossForOneLot))
      {
         reason = "OrderCalcProfit failed";
         return 0.0;
      }
      lossForOneLot = MathAbs(lossForOneLot);

      if(lossForOneLot <= 0.0)
      {
         reason = "estimated loss per lot is zero";
         return 0.0;
      }

      // Verify that even the broker minimum does not breach the risk cap.
      double minimumLotLoss = 0.0;
      if(OrderCalcProfit(orderType, symbol, volumeMin, entryPrice, stopLossPrice, minimumLotLoss))
      {
         minimumLotLoss = MathAbs(minimumLotLoss);
         if(minimumLotLoss > riskMoney)
         {
            reason = "minimum lot exceeds risk cap";
            return 0.0;
         }
      }

      double volume = riskMoney / lossForOneLot;

      if(volumeStep > 0.0)
         volume = MathFloor(volume / volumeStep) * volumeStep;

      if(volume < volumeMin)
      {
         reason = "calculated volume below minimum";
         return 0.0;
      }

      if(volume > volumeMax)
         volume = volumeMax;

      if(volume < volumeMin)
      {
         reason = "volume capped below minimum";
         return 0.0;
      }

      reason = "ok";
      return volume;
   }
};

#endif // TM_EA_RISKMANAGER_MQH
