//+------------------------------------------------------------------+
//| TM_EA_UnitTests.mq5                                              |
//| Self-check for TM-EA pure logic. Run in MetaEditor (F5) or copy  |
//| to MQL5/Scripts/ and run on any chart.                            |
//|                                                                  |
//| Tests that CANNOT run offline (need indicators/broker/tester):   |
//|   - Trend state, Pullback, Breakout, Both-mode, RiskGuard,       |
//|     state recovery: see docs/TECHNICAL_AUDIT.md and               |
//|     tests/VALIDATION_RESULTS.md for the manual/tester procedure.  |
//| This script exercises the ACTUAL compiled headers (no copies).    |
//+------------------------------------------------------------------+
#property script_show_inputs

#include "../../MQL5/Include/TM_EA/InitialStop.mqh"
#include "../../MQL5/Include/TM_EA/RiskManager.mqh"

int g_pass = 0;
int g_fail = 0;

void Check(const string name, const bool ok, const string expected, const string actual)
{
   if(ok) { g_pass++; Print("PASS  ", name, "  expected=", expected, " actual=", actual); }
   else   { g_fail++; Print("FAIL  ", name, "  expected=", expected, " actual=", actual); }
}

bool Near(const double a, const double b, const double eps = 1e-7)
{
   return MathAbs(a - b) <= eps;
}

//--- SL calculation: BUY -------------------------------------------------
void TestBuySL()
{
   double sl = CInitialStop::CalculateBuySL(2000.000, 1999.000, 1.0, 2.0, 0.001, 0.001, 0);
   // structural=1.0, atr*mult=2.0 -> distance=2.0 -> 1998.000
   Check("CalculateBuySL normal", Near(sl, 1998.000), "1998.000", DoubleToString(sl, 3));

   // invalid: invalidation above entry -> must reject (0.0)
   double bad = CInitialStop::CalculateBuySL(2000.000, 2001.000, 1.0, 2.0, 0.001, 0.001, 0);
   Check("CalculateBuySL invalid invalidation", Near(bad, 0.0), "0.000", DoubleToString(bad, 3));

   // stop level floor: entry-sl must be >= stopLevelPoints*point
   double sl2 = CInitialStop::CalculateBuySL(2000.000, 1999.990, 0.001, 1.0, 0.001, 0.001, 500);
   // structural=0.010, atr=0.001 -> distance=0.010; min=500*0.001=0.5 -> sl=1999.5
   Check("CalculateBuySL stop-level floor", Near(sl2, 1999.500), "1999.500", DoubleToString(sl2, 3));
}

//--- SL calculation: SELL ------------------------------------------------
void TestSellSL()
{
   double sl = CInitialStop::CalculateSellSL(2000.000, 2001.000, 1.0, 2.0, 0.001, 0.001, 0);
   Check("CalculateSellSL normal", Near(sl, 2002.000), "2002.000", DoubleToString(sl, 3));

   double bad = CInitialStop::CalculateSellSL(2000.000, 1999.000, 1.0, 2.0, 0.001, 0.001, 0);
   Check("CalculateSellSL invalid invalidation", Near(bad, 0.0), "0.000", DoubleToString(bad, 3));
}

//--- NormalizeToTick -----------------------------------------------------
void TestNormalize()
{
   double p = CInitialStop::NormalizeToTick(2000.1234, 0.001);
   Check("NormalizeToTick", Near(p, 2000.123), "2000.123", DoubleToString(p, 4));
}

//--- Volume rounding (uses real OrderCalcProfit; needs symbol data) ------
void TestVolumeRounding(const string symbol)
{
   if(!SymbolSelect(symbol, true)) { Print("SKIP  volume tests: symbol '", symbol, "' not available"); return; }

   double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
   if(point <= 0.0) point = 0.001;
   double step  = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
   double vmin  = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
   double vmax  = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);

   double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
   double entry = bid;
   double sl = bid - 5.0;   // 5.0 price distance (gold)
   string reason = "";

   // Very large risk -> should produce a positive, step-rounded volume.
   double v = CRiskManager::CalculateVolume(symbol, 1, 100.0, 1000000.0, entry, sl, vmin, vmax, step, reason);
   double mod = (step > 0.0) ? MathMod(v, step) : 0.0;
   Check("Volume rounded down to step", (v > 0.0 && Near(mod, 0.0, 1e-9)), "v>0 and v%step==0",
         DoubleToString(v, 4) + " step=" + DoubleToString(step, 4));

   // Tiny risk -> below minimum -> must skip (0.0)
   double v2 = CRiskManager::CalculateVolume(symbol, 1, 0.0000001, 1.0, entry, sl, vmin, vmax, step, reason);
   Check("Volume below minimum skips", Near(v2, 0.0), "0.0", DoubleToString(v2, 4) + " reason=" + reason);
}

void OnStart()
{
   Print("=== TM-EA unit tests ===");
   TestBuySL();
   TestSellSL();
   TestNormalize();
   TestVolumeRounding(_Symbol);
   PrintFormat("=== DONE: %d passed, %d failed ===", g_pass, g_fail);
   if(g_fail > 0) Alert("TM-EA unit tests: ", g_fail, " FAILED");
}
