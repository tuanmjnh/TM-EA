//+------------------------------------------------------------------+
//| RegimeEngine.mqh                                                 |
//| Market Regime Classification (TREND / RANGE / BREAKOUT)          |
//| with Hysteresis & Multi-Timeframe ADX(H1)/EMA(M5).               |
//| Standardized for TM_GoldSweepScalper (SPEC_GOLD_SCALPER.md)      |
//+------------------------------------------------------------------+
#ifndef TM_EA_REGIMEENGINE_MQH
#define TM_EA_REGIMEENGINE_MQH

enum ENUM_MARKET_REGIME
{
   REGIME_UNKNOWN = 0,
   REGIME_RANGE,        // Sideways / Equilibrium (Optimal for Sweep Reversal)
   REGIME_TREND_BULL,   // Bullish momentum
   REGIME_TREND_BEAR,   // Bearish momentum
   REGIME_BREAKOUT      // High volatility impulse
};

class CRegimeEngine
{
private:
   string             m_symbol;
   ENUM_TIMEFRAMES    m_tf;
   ENUM_TIMEFRAMES    m_htf;
   int                m_hEMA50;
   int                m_hEMA200;
   int                m_hADX_H1;
   int                m_hATR_M5;
   int                m_minHoldBars;
   ENUM_MARKET_REGIME m_currentRegime;
   ENUM_MARKET_REGIME m_candidateRegime;
   int                m_candidateCount;
   int                m_barsInRegime;

public:
   CRegimeEngine()
   {
      m_symbol = "";
      m_tf = PERIOD_M5;
      m_htf = PERIOD_H1;
      m_hEMA50 = INVALID_HANDLE;
      m_hEMA200 = INVALID_HANDLE;
      m_hADX_H1 = INVALID_HANDLE;
      m_hATR_M5 = INVALID_HANDLE;
      m_minHoldBars = 3;
      m_currentRegime = REGIME_UNKNOWN;
      m_candidateRegime = REGIME_UNKNOWN;
      m_candidateCount = 0;
      m_barsInRegime = 0;
   }

   bool Init(const string symbol,
             const ENUM_TIMEFRAMES tf = PERIOD_M5,
             const ENUM_TIMEFRAMES htf = PERIOD_H1,
             const int minHoldBars = 3)
   {
      m_symbol = symbol;
      m_tf = tf;
      m_htf = htf;
      m_minHoldBars = minHoldBars;

      m_hEMA50  = iMA(m_symbol, m_tf, 50, 0, MODE_EMA, PRICE_CLOSE);
      m_hEMA200 = iMA(m_symbol, m_tf, 200, 0, MODE_EMA, PRICE_CLOSE);
      m_hADX_H1 = iADX(m_symbol, m_htf, 14);
      m_hATR_M5 = iATR(m_symbol, m_tf, 14);

      if(m_hEMA50 == INVALID_HANDLE || m_hEMA200 == INVALID_HANDLE ||
         m_hADX_H1 == INVALID_HANDLE || m_hATR_M5 == INVALID_HANDLE)
         return false;

      m_currentRegime = REGIME_RANGE;
      return true;
   }

   void Release()
   {
      if(m_hEMA50 != INVALID_HANDLE)  IndicatorRelease(m_hEMA50);
      if(m_hEMA200 != INVALID_HANDLE) IndicatorRelease(m_hEMA200);
      if(m_hADX_H1 != INVALID_HANDLE) IndicatorRelease(m_hADX_H1);
      if(m_hATR_M5 != INVALID_HANDLE) IndicatorRelease(m_hATR_M5);
   }

   bool IsWarmedUp() const
   {
      return (BarsCalculated(m_hEMA50) >= 52 &&
              BarsCalculated(m_hEMA200) >= 202 &&
              BarsCalculated(m_hADX_H1) >= 16 &&
              BarsCalculated(m_hATR_M5) >= 16);
   }

   ENUM_MARKET_REGIME Update(const double closePrice, double &outADX_H1, double &outATR_M5, string &regimeDescription)
   {
      outADX_H1 = 0.0;
      outATR_M5 = 0.0;
      regimeDescription = "Uninitialized";

      if(!IsWarmedUp())
      {
         regimeDescription = "Warming up";
         return m_currentRegime;
      }

      double ema50Buf[2], ema200Buf[2], adxBuf[2], atrBuf[2];
      if(CopyBuffer(m_hEMA50, 0, 1, 1, ema50Buf) != 1 ||
         CopyBuffer(m_hEMA200, 0, 1, 1, ema200Buf) != 1 ||
         CopyBuffer(m_hADX_H1, 0, 1, 1, adxBuf) != 1 ||
         CopyBuffer(m_hATR_M5, 0, 1, 1, atrBuf) != 1)
      {
         regimeDescription = "CopyBuffer failed";
         return m_currentRegime;
      }

      double ema50  = ema50Buf[0];
      double ema200 = ema200Buf[0];
      outADX_H1     = adxBuf[0];
      outATR_M5     = atrBuf[0];

      ENUM_MARKET_REGIME detected = REGIME_RANGE;

      // Higher Timeframe ADX determines if market is ranging or trending
      if(outADX_H1 < 20.0)
      {
         detected = REGIME_RANGE;
      }
      else if(outADX_H1 >= 22.0)
      {
         if(ema50 > ema200 && closePrice > ema50)
            detected = REGIME_TREND_BULL;
         else if(ema50 < ema200 && closePrice < ema50)
            detected = REGIME_TREND_BEAR;
         else
            detected = REGIME_RANGE;
      }
      else
      {
         detected = m_currentRegime; // Deadband hysteresis
      }

      // Hysteresis Confirmation
      if(detected == m_currentRegime)
      {
         m_candidateCount = 0;
         m_candidateRegime = m_currentRegime;
         m_barsInRegime++;
      }
      else
      {
         if(detected == m_candidateRegime)
         {
            m_candidateCount++;
            if(m_candidateCount >= m_minHoldBars)
            {
               m_currentRegime = detected;
               m_candidateCount = 0;
               m_barsInRegime = 0;
            }
         }
         else
         {
            m_candidateRegime = detected;
            m_candidateCount = 1;
         }
      }

      switch(m_currentRegime)
      {
         case REGIME_RANGE:      regimeDescription = "RANGE (ADX_H1 < 20)"; break;
         case REGIME_TREND_BULL: regimeDescription = "TREND_BULL (EMA50>200, ADX_H1>=22)"; break;
         case REGIME_TREND_BEAR: regimeDescription = "TREND_BEAR (EMA50<200, ADX_H1>=22)"; break;
         default:                regimeDescription = "RANGE"; break;
      }

      return m_currentRegime;
   }

   ENUM_MARKET_REGIME GetCurrentRegime() const { return m_currentRegime; }
   int GetBarsInRegime() const { return m_barsInRegime; }
};

#endif // TM_EA_REGIMEENGINE_MQH
