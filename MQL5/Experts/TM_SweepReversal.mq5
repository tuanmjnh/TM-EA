//+------------------------------------------------------------------+
//| TM_SweepReversal.mq5                                             |
//| Liquidity-sweep reversal: a closed bar pierces a recent swing     |
//| high/low then closes back inside -> reversal entry. SL beyond the |
//| sweep extreme, ATR trailing. Research only.                       |
//+------------------------------------------------------------------+
#property copyright "TM-EA"
#property version   "1.00"
#property strict

#include "..\Include\TM_EA\SymbolSpecs.mqh"
#include "..\Include\TM_EA\Logger.mqh"
#include "..\Include\TM_EA\RiskManager.mqh"
#include "..\Include\TM_EA\TradeExecutor.mqh"

input bool   InpEnableTrading   = true;
input int    InpMagicNumber     = 999001;
input string InpTradeComment    = "TM_SW_V1";
input ENUM_TIMEFRAMES InpTF     = PERIOD_M5;

input int    InpSwingLookback   = 10;    // bars forming the swing level (excludes signal bar)
input double InpSweepBufferATR  = 0.10;  // level must be pierced by >= this * ATR
input double InpSL_BufferATR    = 0.20;  // SL placed this * ATR beyond the sweep extreme
input int    InpATRPeriod       = 14;

input bool   InpUseHTF_Filter   = true;  // only take sweeps aligned with H1 EMA
input ENUM_TIMEFRAMES InpHtfTF  = PERIOD_H1;
input int    InpHtfEMA          = 50;

input bool   InpUseTrailing     = true;
input double InpTrailActivateATR= 1.0;   // start trailing after profit >= this * ATR
input double InpTrailATR_Mult   = 1.5;   // trail distance = this * ATR
input bool   InpUseBreakeven    = false;
input double InpBreakevenAfterATR=1.0;

input bool   InpUseSession      = false;
input int    InpStartHour       = 7;
input int    InpEndHour         = 21;

input int    InpLotType         = 1;     // 1 risk%, 0 fixed
input double InpRiskPercent     = 1.0;
input double InpFixedLot        = 0.01;
input int    InpMaxSpreadPts    = 350;

CSymbolSpecs   g_symbol;
CLogger        g_logger;
CTradeExecutor g_trade;

int g_mAtr=-1, g_mHtfEma=-1;
datetime g_lastBar=0;
double g_initBalance=0.0,g_peakEquity=0.0,g_maxDD=0.0;

//+------------------------------------------------------------------+
void DumpTesterStats()
{
   if(!(bool)MQLInfoInteger(MQL_TESTER)) return;
   double fb=AccountInfoDouble(ACCOUNT_BALANCE); double gp=0,gl=0; int tr=0,w=0,l=0,cl=0,mcl=0; double lw=0,ll=0;
   HistorySelect(0,TimeCurrent());
   for(int i=0;i<HistoryDealsTotal();i++){ ulong d=HistoryDealGetTicket(i); if(d==0) continue;
      if(HistoryDealGetString(d,DEAL_SYMBOL)!=_Symbol) continue;
      if((int)HistoryDealGetInteger(d,DEAL_MAGIC)!=InpMagicNumber) continue;
      if((int)HistoryDealGetInteger(d,DEAL_ENTRY)!=DEAL_ENTRY_OUT) continue;
      double p=HistoryDealGetDouble(d,DEAL_PROFIT)+HistoryDealGetDouble(d,DEAL_COMMISSION)+HistoryDealGetDouble(d,DEAL_SWAP);
      tr++; if(p>0){w++;gp+=p;if(p>lw)lw=p;cl=0;} else if(p<0){l++;gl+=p;if(p<ll)ll=p;cl++;if(cl>mcl)mcl=cl;} }
   double pf=(gl<0)?gp/MathAbs(gl):0.0; double dd=(g_peakEquity>0)?g_maxDD/g_peakEquity*100.0:0.0;
   int fh=FileOpen("TM_EA_tester_report_"+_Symbol+".csv",FILE_WRITE|FILE_CSV|FILE_ANSI|FILE_COMMON,';'); if(fh==INVALID_HANDLE) return;
   FileWrite(fh,"key","value"); FileWrite(fh,"symbol",_Symbol); FileWrite(fh,"expert","TM_SweepReversal");
   FileWrite(fh,"end_time",TimeToString(TimeCurrent(),TIME_DATE|TIME_SECONDS));
   FileWrite(fh,"deposit",DoubleToString(g_initBalance,2)); FileWrite(fh,"final_balance",DoubleToString(fb,2));
   FileWrite(fh,"net_profit",DoubleToString(fb-g_initBalance,2)); FileWrite(fh,"gross_profit",DoubleToString(gp,2));
   FileWrite(fh,"gross_loss",DoubleToString(gl,2)); FileWrite(fh,"profit_factor",DoubleToString(pf,3));
   FileWrite(fh,"trades",IntegerToString(tr)); FileWrite(fh,"wins",IntegerToString(w)); FileWrite(fh,"losses",IntegerToString(l));
   FileWrite(fh,"largest_win",DoubleToString(lw,2)); FileWrite(fh,"largest_loss",DoubleToString(ll,2));
   FileWrite(fh,"max_consec_losses",IntegerToString(mcl)); FileWrite(fh,"max_equity_dd_abs",DoubleToString(g_maxDD,2));
   FileWrite(fh,"max_equity_dd_pct",DoubleToString(dd,3)); FileClose(fh);
   PrintFormat("SW stats: net=%.2f PF=%.3f trades=%d DD=%.2f%%",fb-g_initBalance,pf,tr,dd);
}

//+------------------------------------------------------------------+
void Trail(const double atr)
{
   if(atr<=0.0) return;
   for(int i=PositionsTotal()-1;i>=0;i--){
      ulong t=PositionGetTicket(i); if(t==0) continue;
      if(PositionGetString(POSITION_SYMBOL)!=_Symbol) continue;
      if((int)PositionGetInteger(POSITION_MAGIC)!=InpMagicNumber) continue;
      ENUM_POSITION_TYPE pt=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      double open=PositionGetDouble(POSITION_PRICE_OPEN), sl=PositionGetDouble(POSITION_SL);
      double bid=SymbolInfoDouble(_Symbol,SYMBOL_BID), ask=SymbolInfoDouble(_Symbol,SYMBOL_ASK); double spread=ask-bid;
      if(pt==POSITION_TYPE_BUY){
         double prof=bid-open; double cand=(sl>0)?sl:0.0;
         if(InpUseBreakeven && prof>=InpBreakevenAfterATR*atr){ double be=open+spread; if(be>=bid)be=open; if(be>cand)cand=be; }
         if(InpUseTrailing && prof>=InpTrailActivateATR*atr){ double tr=bid-InpTrailATR_Mult*atr; if(tr>cand)cand=tr; }
         double nsl=NormalizeDouble(MathFloor(cand/g_symbol.TickSize)*g_symbol.TickSize,8);
         if(nsl>sl && nsl<bid && g_trade.ModifyStopLoss(t,nsl)) g_logger.Log("sw sl BUY "+DoubleToString(nsl,5));
      } else if(pt==POSITION_TYPE_SELL){
         double prof=open-ask; double cand=(sl>0)?sl:DBL_MAX;
         if(InpUseBreakeven && prof>=InpBreakevenAfterATR*atr){ double be=open-spread; if(be<=ask)be=open; if(be<cand)cand=be; }
         if(InpUseTrailing && prof>=InpTrailActivateATR*atr){ double tr=ask+InpTrailATR_Mult*atr; if(tr<cand)cand=tr; }
         double nsl=NormalizeDouble(MathCeil(cand/g_symbol.TickSize)*g_symbol.TickSize,8);
         if((sl<=0||nsl<sl) && nsl>ask && g_trade.ModifyStopLoss(t,nsl)) g_logger.Log("sw sl SELL "+DoubleToString(nsl,5));
      }
   }
}

//+------------------------------------------------------------------+
int OnInit()
{
   if(!g_symbol.Refresh(_Symbol)){ Print("INIT FAILED: symbol"); return INIT_FAILED; }
   if(!g_trade.Init(InpMagicNumber,10)){ Print("INIT FAILED: executor"); return INIT_FAILED; }
   g_mAtr=iATR(_Symbol,InpTF,InpATRPeriod);
   g_mHtfEma=iMA(_Symbol,InpHtfTF,InpHtfEMA,0,MODE_EMA,PRICE_CLOSE);
   if(g_mAtr==INVALID_HANDLE||g_mHtfEma==INVALID_HANDLE){ Print("INIT FAILED: handles"); return INIT_FAILED; }
   g_logger.Init(_Symbol,InpMagicNumber); g_initBalance=AccountInfoDouble(ACCOUNT_BALANCE); g_peakEquity=AccountInfoDouble(ACCOUNT_EQUITY);
   g_logger.Log("TM_SweepReversal init.");
   return INIT_SUCCEEDED;
}
//+------------------------------------------------------------------+
void OnDeinit(const int r){ DumpTesterStats(); IndicatorRelease(g_mAtr); IndicatorRelease(g_mHtfEma); g_logger.Deinit(); }

//+------------------------------------------------------------------+
void OnTick()
{
   if((bool)MQLInfoInteger(MQL_TESTER)){ double eq=AccountInfoDouble(ACCOUNT_EQUITY); if(eq>g_peakEquity)g_peakEquity=eq; double dd=g_peakEquity-eq; if(dd>g_maxDD)g_maxDD=dd; }
   if(!InpEnableTrading) return;
   MqlDateTime dt; TimeToStruct(TimeCurrent(),dt);
   if(InpUseSession && (dt.hour<InpStartHour||dt.hour>=InpEndHour)) return;

   double atr=0.0; { double b[2]; if(CopyBuffer(g_mAtr,0,0,2,b)==2) atr=b[1]; }
   Trail(atr);
   if(atr<=0) return;

   datetime bt=iTime(_Symbol,InpTF,0); if(bt==0||bt==g_lastBar) return; g_lastBar=bt;

   // swing level from previous bars (exclude the signal bar = bar1)
   int ih=iHighest(_Symbol,InpTF,MODE_HIGH,InpSwingLookback,2);
   int il=iLowest(_Symbol,InpTF,MODE_LOW,InpSwingLookback,2);
   if(ih<0||il<0) return;
   double swHigh=iHigh(_Symbol,InpTF,ih);
   double swLow =iLow(_Symbol,InpTF,il);

   double o1=iOpen(_Symbol,InpTF,1), h1=iHigh(_Symbol,InpTF,1), l1=iLow(_Symbol,InpTF,1), c1=iClose(_Symbol,InpTF,1);
   if(c1<=0) return;
   double buf=InpSweepBufferATR*atr;

   bool sell = (h1 > swHigh + buf) && (c1 < swHigh) && (c1 < o1);
   bool buy  = (l1 < swLow  - buf) && (c1 > swLow)  && (c1 > o1);
   if(!buy && !sell) return;

   if(InpUseHTF_Filter){
      double e[2]; if(CopyBuffer(g_mHtfEma,0,0,2,e)!=2) return;
      if(sell && !(c1 < e[1])) return;   // short only below H1 EMA
      if(buy  && !(c1 > e[1])) return;   // long only above H1 EMA
   }

   if(g_trade.CountOpenPositions(_Symbol)>0) return;
   double bid=SymbolInfoDouble(_Symbol,SYMBOL_BID), ask=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   if((ask-bid)/g_symbol.Point > (double)InpMaxSpreadPts) return;

   int dir = buy?1:-1;
   double entry=(dir>0)?ask:bid;
   double sl  =(dir>0)? (l1 - InpSL_BufferATR*atr) : (h1 + InpSL_BufferATR*atr);
   sl=NormalizeDouble((dir>0)?MathFloor(sl/g_symbol.TickSize)*g_symbol.TickSize:MathCeil(sl/g_symbol.TickSize)*g_symbol.TickSize,8);

   string rr=""; double vol;
   if(InpLotType==0) vol=InpFixedLot;
   else vol=CRiskManager::CalculateVolume(_Symbol,dir,InpRiskPercent,AccountInfoDouble(ACCOUNT_BALANCE),entry,sl,g_symbol.VolumeMin,g_symbol.VolumeMax,g_symbol.VolumeStep,rr);
   if(vol<=0){ g_logger.Log("sw skip vol "+rr); return; }

   ulong tk=0; bool ok=(dir>0)?g_trade.OpenBuy(_Symbol,vol,sl,0.0,InpTradeComment+"_BUY",tk):g_trade.OpenSell(_Symbol,vol,sl,0.0,InpTradeComment+"_SELL",tk);
   if(!ok){ g_logger.Log("sw order failed rc="+IntegerToString(g_trade.LastRetcode())); return; }
   g_logger.Log("SW "+(dir>0?"BUY":"SELL")+" vol="+DoubleToString(vol,2)+" SL="+DoubleToString(sl,5)+" swHi="+DoubleToString(swHigh,5)+" swLo="+DoubleToString(swLow,5));
}
