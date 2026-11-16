//+------------------------------------------------------------------+
//| TM_ScopeTB.mq5                                                   |
//| Scope Trendline Bollinger (STB): D1+H1 bias, M5 BB + trendline,  |
//| ATR trail, no fixed TP, re-entry. Research only.                 |
//+------------------------------------------------------------------+
#property copyright "TM-EA"
#property version   "1.00"
#property strict

#include "..\Include\TM_EA\SymbolSpecs.mqh"
#include "..\Include\TM_EA\Logger.mqh"
#include "..\Include\TM_EA\RiskManager.mqh"
#include "..\Include\TM_EA\TradeExecutor.mqh"

input bool   InpEnableTrading    = true;
input int    InpMagicNumber      = 777001;
input string InpTradeComment     = "TM_STB_V1";

input int    InpLotType          = 1;      // 0 fixed, 1 risk-percent
input double InpRiskPercent      = 1.0;
input double InpFixedLot         = 0.01;

input int    InpBBPeriod         = 20;
input double InpBBDev            = 2.0;
input int    InpATRPeriod        = 14;
input int    InpADXPeriod        = 14;
input double InpADXThreshold     = 20.0;

input int    InpHTF_EMA_Fast     = 20;     // H1
input int    InpHTF_EMA_Slow     = 50;     // H1
input int    InpD1_EMA_Fast      = 50;     // D1
input int    InpD1_EMA_Slow      = 200;    // D1

input bool   InpUseSessionFilter = true;
input int    InpLondonStart      = 8;
input int    InpLondonEnd        = 16;
input int    InpNYStart          = 13;
input int    InpNYEnd            = 21;

input double InpSL_ATR_Mult      = 1.5;
input double InpTrail_ATR_Mult   = 1.2;
input double InpTrailActivateATR = 1.0;
input int    InpPivotLeft        = 3;      // pivot strength (bars each side)
input int    InpMinPivotGap      = 5;      // min bars between the 2 unique pivots

input double InpDailyLossCapPct  = 4.0;    // 0 = off
input int    InpMaxSpreadPts     = 350;

CSymbolSpecs   g_symbol;
CLogger        g_logger;
CTradeExecutor g_trade;

int g_mId=-1,g_mD1f=-1,g_mD1s=-1,g_mH1f=-1,g_mH1s=-1,g_mBands=-1,g_mAtr=-1;
datetime g_lastBar=0, g_dayStart=0;
double   g_dayBaseline=0.0, g_initBalance=0.0, g_peakEquity=0.0, g_maxDD=0.0;

//+------------------------------------------------------------------+
void DumpTesterStats()
{
   if(!(bool)MQLInfoInteger(MQL_TESTER)) return;
   double fb=AccountInfoDouble(ACCOUNT_BALANCE);
   double gp=0,gl=0; int tr=0,w=0,l=0,cl=0,mcl=0; double lw=0,ll=0;
   HistorySelect(0,TimeCurrent());
   for(int i=0;i<HistoryDealsTotal();i++){
      ulong d=HistoryDealGetTicket(i); if(d==0) continue;
      if(HistoryDealGetString(d,DEAL_SYMBOL)!=_Symbol) continue;
      if((int)HistoryDealGetInteger(d,DEAL_MAGIC)!=InpMagicNumber) continue;
      if((int)HistoryDealGetInteger(d,DEAL_ENTRY)!=DEAL_ENTRY_OUT) continue;
      double p=HistoryDealGetDouble(d,DEAL_PROFIT)+HistoryDealGetDouble(d,DEAL_COMMISSION)+HistoryDealGetDouble(d,DEAL_SWAP);
      tr++; if(p>0){w++;gp+=p;if(p>lw)lw=p;cl=0;} else if(p<0){l++;gl+=p;if(p<ll)ll=p;cl++;if(cl>mcl)mcl=cl;}
   }
   double pf=(gl<0)?gp/MathAbs(gl):0.0; double dd=(g_peakEquity>0)?g_maxDD/g_peakEquity*100.0:0.0;
   int fh=FileOpen("TM_EA_tester_report_"+_Symbol+".csv",FILE_WRITE|FILE_CSV|FILE_ANSI|FILE_COMMON,';');
   if(fh==INVALID_HANDLE) return;
   FileWrite(fh,"key","value"); FileWrite(fh,"symbol",_Symbol); FileWrite(fh,"expert","TM_ScopeTB");
   FileWrite(fh,"end_time",TimeToString(TimeCurrent(),TIME_DATE|TIME_SECONDS));
   FileWrite(fh,"deposit",DoubleToString(g_initBalance,2)); FileWrite(fh,"final_balance",DoubleToString(fb,2));
   FileWrite(fh,"net_profit",DoubleToString(fb-g_initBalance,2)); FileWrite(fh,"gross_profit",DoubleToString(gp,2));
   FileWrite(fh,"gross_loss",DoubleToString(gl,2)); FileWrite(fh,"profit_factor",DoubleToString(pf,3));
   FileWrite(fh,"trades",IntegerToString(tr)); FileWrite(fh,"wins",IntegerToString(w)); FileWrite(fh,"losses",IntegerToString(l));
   FileWrite(fh,"largest_win",DoubleToString(lw,2)); FileWrite(fh,"largest_loss",DoubleToString(ll,2));
   FileWrite(fh,"max_consec_losses",IntegerToString(mcl)); FileWrite(fh,"max_equity_dd_abs",DoubleToString(g_maxDD,2));
   FileWrite(fh,"max_equity_dd_pct",DoubleToString(dd,3)); FileClose(fh);
   PrintFormat("STB stats: net=%.2f PF=%.3f trades=%d DD=%.2f%%",fb-g_initBalance,pf,tr,dd);
}

//+------------------------------------------------------------------+
bool Triple(const int h,double &v1,double &v2){ double b[3]; if(CopyBuffer(h,0,0,3,b)!=3) return false; v1=b[1]; v2=b[2]; return true; }

//+------------------------------------------------------------------+
bool SessionOk(const MqlDateTime &dt)
{
   if(!InpUseSessionFilter) return true;
   int h=dt.hour;
   bool london=(h>=InpLondonStart && h<InpLondonEnd);
   bool ny=(h>=InpNYStart && h<InpNYEnd);
   return (london||ny) && dt.day_of_week>=1 && dt.day_of_week<=5;
}

//+------------------------------------------------------------------+
//| Find the two most recent pivot highs (for a resistance line) or  |
//| pivot lows (for a support line). Returns shifts (>=1).           |
//+------------------------------------------------------------------+
bool FindTrendline(const bool wantHigh, int &shiftA, double &priceA, int &shiftB, double &priceB)
{
   int lookback = 60;
   int found = 0;
   for(int s = InpPivotLeft + 1; s <= lookback && found < 2; s++)
   {
      double p = wantHigh ? iHigh(_Symbol, PERIOD_M5, s) : iLow(_Symbol, PERIOD_M5, s);
      bool isPivot = true;
      for(int k = 1; k <= InpPivotLeft; k++)
      {
         double up = wantHigh ? iHigh(_Symbol, PERIOD_M5, s-k) : iLow(_Symbol, PERIOD_M5, s-k);
         double dn = wantHigh ? iHigh(_Symbol, PERIOD_M5, s+k) : iLow(_Symbol, PERIOD_M5, s+k);
         if(wantHigh){ if(!(p > up && p > dn)) { isPivot=false; break; } }
         else       { if(!(p < up && p < dn)) { isPivot=false; break; } }
      }
      if(!isPivot) continue;
      if(found == 0){ shiftA = s; priceA = p; found = 1; }
      else if(s - shiftA >= InpMinPivotGap){ shiftB = s; priceB = p; found = 2; }
   }
   return (found == 2);
}

//+------------------------------------------------------------------+
double LineValueAt(const int shiftA,const double priceA,const int shiftB,const double priceB,const int atShift)
{
   if(shiftA==shiftB) return priceA;
   return priceA + (priceB - priceA) * (double)(atShift - shiftA) / (double)(shiftB - shiftA);
}

//+------------------------------------------------------------------+
void TrailPositions(const double atr)
{
   if(atr<=0) return;
   for(int i=PositionsTotal()-1;i>=0;i--){
      ulong t=PositionGetTicket(i); if(t==0) continue;
      if(PositionGetString(POSITION_SYMBOL)!=_Symbol) continue;
      if((int)PositionGetInteger(POSITION_MAGIC)!=InpMagicNumber) continue;
      ENUM_POSITION_TYPE pt=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      double open=PositionGetDouble(POSITION_PRICE_OPEN), sl=PositionGetDouble(POSITION_SL);
      double bid=SymbolInfoDouble(_Symbol,SYMBOL_BID), ask=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
      if(pt==POSITION_TYPE_BUY){
         double prof=bid-open;
         if(prof < InpTrailActivateATR*atr) continue;
         double nsl=bid - InpTrail_ATR_Mult*atr;
         nsl=NormalizeDouble(MathFloor(nsl/g_symbol.TickSize)*g_symbol.TickSize,8);
         if(nsl<=sl || nsl>=bid) continue;
         if(g_trade.ModifyStopLoss(t,nsl)) g_logger.Log("trail BUY sl="+DoubleToString(nsl,5));
      } else {
         double prof=open-ask;
         if(prof < InpTrailActivateATR*atr) continue;
         double nsl=ask + InpTrail_ATR_Mult*atr;
         nsl=NormalizeDouble(MathCeil(nsl/g_symbol.TickSize)*g_symbol.TickSize,8);
         if(sl>0 && nsl>=sl) continue; if(nsl<=ask) continue;
         if(g_trade.ModifyStopLoss(t,nsl)) g_logger.Log("trail SELL sl="+DoubleToString(nsl,5));
      }
   }
}

//+------------------------------------------------------------------+
int OnInit()
{
   if(!g_symbol.Refresh(_Symbol)){ Print("INIT FAILED: symbol"); return INIT_FAILED; }
   if(!g_trade.Init(InpMagicNumber,10)){ Print("INIT FAILED: executor"); return INIT_FAILED; }
   g_mId  = iADX(_Symbol,PERIOD_D1,InpADXPeriod);
   g_mD1f = iMA(_Symbol,PERIOD_D1,InpD1_EMA_Fast,0,MODE_EMA,PRICE_CLOSE);
   g_mD1s = iMA(_Symbol,PERIOD_D1,InpD1_EMA_Slow,0,MODE_EMA,PRICE_CLOSE);
   g_mH1f = iMA(_Symbol,PERIOD_H1,InpHTF_EMA_Fast,0,MODE_EMA,PRICE_CLOSE);
   g_mH1s = iMA(_Symbol,PERIOD_H1,InpHTF_EMA_Slow,0,MODE_EMA,PRICE_CLOSE);
   g_mBands = iBands(_Symbol,PERIOD_M5,InpBBPeriod,0,InpBBDev,PRICE_CLOSE);
   g_mAtr = iATR(_Symbol,PERIOD_M5,InpATRPeriod);
   if(g_mId==INVALID_HANDLE||g_mD1f==INVALID_HANDLE||g_mD1s==INVALID_HANDLE||g_mH1f==INVALID_HANDLE||
      g_mH1s==INVALID_HANDLE||g_mBands==INVALID_HANDLE||g_mAtr==INVALID_HANDLE)
   { Print("INIT FAILED: handles"); return INIT_FAILED; }
   g_logger.Init(_Symbol,InpMagicNumber);
   g_initBalance=AccountInfoDouble(ACCOUNT_BALANCE); g_peakEquity=AccountInfoDouble(ACCOUNT_EQUITY);
   g_logger.Log("TM_ScopeTB init.");
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   DumpTesterStats();
   IndicatorRelease(g_mId); IndicatorRelease(g_mD1f); IndicatorRelease(g_mD1s);
   IndicatorRelease(g_mH1f); IndicatorRelease(g_mH1s); IndicatorRelease(g_mBands); IndicatorRelease(g_mAtr);
   g_logger.Deinit();
}

//+------------------------------------------------------------------+
void OnTick()
{
   if((bool)MQLInfoInteger(MQL_TESTER)){
      double eq=AccountInfoDouble(ACCOUNT_EQUITY);
      if(eq>g_peakEquity) g_peakEquity=eq; double dd=g_peakEquity-eq; if(dd>g_maxDD) g_maxDD=dd;
   }
   MqlDateTime dt; TimeToStruct(TimeCurrent(),dt);
   datetime day=TimeCurrent()-(dt.hour*3600+dt.min*60+dt.sec);
   if(day!=g_dayStart){ g_dayStart=day; g_dayBaseline=AccountInfoDouble(ACCOUNT_EQUITY); }

   double atr=0.0; { double b[2]; if(CopyBuffer(g_mAtr,0,0,2,b)==2) atr=b[1]; }

   datetime bt=iTime(_Symbol,PERIOD_M5,0);
   if(bt==0||bt==g_lastBar){ TrailPositions(atr); return; }
   g_lastBar=bt;

   if(!InpEnableTrading) return;
   if(!SessionOk(dt)) return;
   if(InpDailyLossCapPct>0 && g_dayBaseline>0){
      if((g_dayBaseline-AccountInfoDouble(ACCOUNT_EQUITY))/g_dayBaseline*100.0 >= InpDailyLossCapPct) return;
   }
   if(atr<=0) return;

   // --- bias D1 + H1 ---
   double d1f1,d1f2,d1s1,d1s2,adx1,adx2,h1f1,h1f2,h1s1,h1s2;
   if(!Triple(g_mD1f,d1f1,d1f2)) return;
   if(!Triple(g_mD1s,d1s1,d1s2)) return;
   if(!Triple(g_mId,adx1,adx2)) return;
   if(!Triple(g_mH1f,h1f1,h1f2)) return;
   if(!Triple(g_mH1s,h1s1,h1s2)) return;
   int bias=0;
   if(adx1>InpADXThreshold && d1f1>d1s1 && h1f1>h1s1) bias=1;
   else if(adx1>InpADXThreshold && d1f1<d1s1 && h1f1<h1s1) bias=-1;
   if(bias==0) return;

   // --- BB (mid/upper/lower) on M5 closed bar ---
   double mid[],up[],lo[];
   if(CopyBuffer(g_mBands,0,0,3,mid)!=3) return;
   if(CopyBuffer(g_mBands,1,0,3,up)!=3) return;
   if(CopyBuffer(g_mBands,2,0,3,lo)!=3) return;
   double mid1=mid[1], mid2=mid[2];
   double o1=iOpen(_Symbol,PERIOD_M5,1), h1=iHigh(_Symbol,PERIOD_M5,1), l1=iLow(_Symbol,PERIOD_M5,1), c1=iClose(_Symbol,PERIOD_M5,1);
   if(c1<=0) return;

   // --- trendline ---
   int sA,sB; double pA,pB;
   bool tl=false; double tlVal=0.0;
   if(bias>0){
      if(!FindTrendline(true,sA,pA,sB,pB)) return;
      tlVal=LineValueAt(sA,pA,sB,pB,1);   // resistance line value at bar1
      tl=(c1>tlVal);
   } else {
      if(!FindTrendline(false,sA,pA,sB,pB)) return;
      tlVal=LineValueAt(sA,pA,sB,pB,1);   // support line value at bar1
      tl=(c1<tlVal);
   }

   bool sig=false;
   if(bias>0) sig = (c1>mid1) && (l1 <= mid1 + 0.5*atr) && (c1>o1) && tl;
   else       sig = (c1<mid1) && (h1 >= mid1 - 0.5*atr) && (c1<o1) && tl;
   if(!sig) return;

   if(g_trade.CountOpenPositions(_Symbol)>0) return;   // max 1 position

   double bid=SymbolInfoDouble(_Symbol,SYMBOL_BID), ask=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   double spread=(ask-bid)/g_symbol.Point;
   if(InpMaxSpreadPts>0 && spread>(double)InpMaxSpreadPts){ g_logger.Log("skip spread"); return; }

   int dir=bias; double entry=(dir>0)?ask:bid;
   double slDist=InpSL_ATR_Mult*atr;
   double sl=(dir>0)?entry-slDist:entry+slDist;
   sl=NormalizeDouble((dir>0)?MathFloor(sl/g_symbol.TickSize)*g_symbol.TickSize:MathCeil(sl/g_symbol.TickSize)*g_symbol.TickSize,8);

   double vol=0.0;
   if(InpLotType==0) vol=InpFixedLot;
   else { string r=""; vol=CRiskManager::CalculateVolume(_Symbol,dir,InpRiskPercent,AccountInfoDouble(ACCOUNT_BALANCE),entry,sl,g_symbol.VolumeMin,g_symbol.VolumeMax,g_symbol.VolumeStep,r); if(vol<=0){ g_logger.Log("skip vol "+r); return; } }

   ulong tk=0; bool ok=false; string cmt=InpTradeComment+"_"+(dir>0?"BUY":"SELL");
   if(dir>0) ok=g_trade.OpenBuy(_Symbol,vol,sl,0.0,cmt,tk);   // no TP
   else      ok=g_trade.OpenSell(_Symbol,vol,sl,0.0,cmt,tk);
   if(!ok){ g_logger.Log("order failed rc="+IntegerToString(g_trade.LastRetcode())); return; }
   g_logger.Log("STB "+(dir>0?"BUY":"SELL")+" vol="+DoubleToString(vol,2)+" SL="+DoubleToString(sl,5)+" bias="+IntegerToString(bias));
}
