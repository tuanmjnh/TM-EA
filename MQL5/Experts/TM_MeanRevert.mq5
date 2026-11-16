//+------------------------------------------------------------------+
//| TM_MeanRevert.mq5                                                |
//| Mean-reversion scalper: BB(20,2)+RSI extremes inside a range     |
//| regime (low ADX on HTF). Fixed SL/TP. Research only.             |
//+------------------------------------------------------------------+
#property copyright "TM-EA"
#property version   "1.00"
#property strict

#include "..\Include\TM_EA\SymbolSpecs.mqh"
#include "..\Include\TM_EA\Logger.mqh"
#include "..\Include\TM_EA\RiskManager.mqh"
#include "..\Include\TM_EA\TradeExecutor.mqh"

input bool   InpEnableTrading  = true;
input int    InpMagicNumber    = 888001;
input string InpTradeComment   = "TM_MR_V1";
input ENUM_TIMEFRAMES InpTF    = PERIOD_M5;

input int    InpBBPeriod       = 20;
input double InpBBDev          = 2.0;
input int    InpRSIPeriod      = 14;
input double InpRSIBuy         = 30.0;   // oversold threshold
input double InpRSISell        = 70.0;   // overbought threshold
input int    InpATRPeriod      = 14;
input double InpSL_ATR         = 1.2;
input double InpTP_ATR         = 1.2;

input bool   InpUseRangeFilter = true;   // require HTF ADX below threshold (range)
input ENUM_TIMEFRAMES InpRegimeTF = PERIOD_H1;
input int    InpADXPeriod      = 14;
input double InpADXMax         = 25.0;   // only trade when ADX < this

input bool   InpUseSession     = false;
input int    InpStartHour      = 8;
input int    InpEndHour        = 21;

input int    InpLotType        = 1;      // 1 = risk%, 0 = fixed
input double InpRiskPercent    = 1.0;
input double InpFixedLot       = 0.01;
input int    InpMaxSpreadPts   = 20;     // tight for scalp (points / raw)

CSymbolSpecs   g_symbol;
CLogger        g_logger;
CTradeExecutor g_trade;

int g_mBands=-1,g_mRsi=-1,g_mAtr=-1,g_mAdx=-1;
datetime g_lastBar=0, g_dayStart=0;
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
   FileWrite(fh,"key","value"); FileWrite(fh,"symbol",_Symbol); FileWrite(fh,"expert","TM_MeanRevert");
   FileWrite(fh,"end_time",TimeToString(TimeCurrent(),TIME_DATE|TIME_SECONDS));
   FileWrite(fh,"deposit",DoubleToString(g_initBalance,2)); FileWrite(fh,"final_balance",DoubleToString(fb,2));
   FileWrite(fh,"net_profit",DoubleToString(fb-g_initBalance,2)); FileWrite(fh,"gross_profit",DoubleToString(gp,2));
   FileWrite(fh,"gross_loss",DoubleToString(gl,2)); FileWrite(fh,"profit_factor",DoubleToString(pf,3));
   FileWrite(fh,"trades",IntegerToString(tr)); FileWrite(fh,"wins",IntegerToString(w)); FileWrite(fh,"losses",IntegerToString(l));
   FileWrite(fh,"largest_win",DoubleToString(lw,2)); FileWrite(fh,"largest_loss",DoubleToString(ll,2));
   FileWrite(fh,"max_consec_losses",IntegerToString(mcl)); FileWrite(fh,"max_equity_dd_abs",DoubleToString(g_maxDD,2));
   FileWrite(fh,"max_equity_dd_pct",DoubleToString(dd,3)); FileClose(fh);
   PrintFormat("MR stats: net=%.2f PF=%.3f trades=%d DD=%.2f%%",fb-g_initBalance,pf,tr,dd);
}

//+------------------------------------------------------------------+
bool T2(const int h,double &v1,double &v2){ double b[3]; if(CopyBuffer(h,0,0,3,b)!=3) return false; v1=b[1]; v2=b[2]; return true; }

//+------------------------------------------------------------------+
int OnInit()
{
   if(!g_symbol.Refresh(_Symbol)){ Print("INIT FAILED: symbol"); return INIT_FAILED; }
   if(!g_trade.Init(InpMagicNumber,10)){ Print("INIT FAILED: executor"); return INIT_FAILED; }
   g_mBands=iBands(_Symbol,InpTF,InpBBPeriod,0,InpBBDev,PRICE_CLOSE);
   g_mRsi=iRSI(_Symbol,InpTF,InpRSIPeriod,PRICE_CLOSE);
   g_mAtr=iATR(_Symbol,InpTF,InpATRPeriod);
   g_mAdx=iADX(_Symbol,InpRegimeTF,InpADXPeriod);
   if(g_mBands==INVALID_HANDLE||g_mRsi==INVALID_HANDLE||g_mAtr==INVALID_HANDLE||g_mAdx==INVALID_HANDLE)
   { Print("INIT FAILED: handles"); return INIT_FAILED; }
   g_logger.Init(_Symbol,InpMagicNumber); g_initBalance=AccountInfoDouble(ACCOUNT_BALANCE); g_peakEquity=AccountInfoDouble(ACCOUNT_EQUITY);
   g_logger.Log("TM_MeanRevert init.");
   return INIT_SUCCEEDED;
}
//+------------------------------------------------------------------+
void OnDeinit(const int r){ DumpTesterStats(); IndicatorRelease(g_mBands); IndicatorRelease(g_mRsi); IndicatorRelease(g_mAtr); IndicatorRelease(g_mAdx); g_logger.Deinit(); }

//+------------------------------------------------------------------+
void OnTick()
{
   if((bool)MQLInfoInteger(MQL_TESTER)){ double eq=AccountInfoDouble(ACCOUNT_EQUITY); if(eq>g_peakEquity)g_peakEquity=eq; double dd=g_peakEquity-eq; if(dd>g_maxDD)g_maxDD=dd; }
   if(!InpEnableTrading) return;
   MqlDateTime dt; TimeToStruct(TimeCurrent(),dt);
   datetime day=TimeCurrent()-(dt.hour*3600+dt.min*60+dt.sec); if(day!=g_dayStart) g_dayStart=day;
   if(InpUseSession && (dt.hour<InpStartHour||dt.hour>=InpEndHour)) return;

   datetime bt=iTime(_Symbol,InpTF,0); if(bt==0||bt==g_lastBar) return; g_lastBar=bt;

   double up[],lo[],mi[]; if(CopyBuffer(g_mBands,1,0,3,up)!=3) return; if(CopyBuffer(g_mBands,2,0,3,lo)!=3) return; if(CopyBuffer(g_mBands,0,0,3,mi)!=3) return;
   double r1,r2,a1,a2,adx1,adx2;
   if(!T2(g_mRsi,r1,r2)) return; if(!T2(g_mAtr,a1,a2)) return; if(!T2(g_mAdx,adx1,adx2)) return;
   double c1=iClose(_Symbol,InpTF,1), o1=iOpen(_Symbol,InpTF,1); if(c1<=0||a1<=0) return;
   double up1=up[1],lo1=lo[1];

   if(InpUseRangeFilter && adx1>=InpADXMax) return;

   int dir=0;
   if(c1<lo1 && r1<InpRSIBuy) dir=1;
   else if(c1>up1 && r1>InpRSISell) dir=-1;
   if(dir==0) return;
   if(g_trade.CountOpenPositions(_Symbol)>0) return;

   double bid=SymbolInfoDouble(_Symbol,SYMBOL_BID), ask=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   double spread=(ask-bid)/g_symbol.Point; if(InpMaxSpreadPts>0 && spread>(double)InpMaxSpreadPts) return;

   double entry=(dir>0)?ask:bid;
   double sl=(dir>0)?entry-InpSL_ATR*a1:entry+InpSL_ATR*a1;
   double tp=(dir>0)?entry+InpTP_ATR*a1:entry-InpTP_ATR*a1;
   sl=NormalizeDouble((dir>0)?MathFloor(sl/g_symbol.TickSize)*g_symbol.TickSize:MathCeil(sl/g_symbol.TickSize)*g_symbol.TickSize,8);
   tp=NormalizeDouble((dir>0)?MathFloor(tp/g_symbol.TickSize)*g_symbol.TickSize:MathCeil(tp/g_symbol.TickSize)*g_symbol.TickSize,8);

   double vol=0.0;
   if(InpLotType==0) vol=InpFixedLot;
   else { string rr=""; vol=CRiskManager::CalculateVolume(_Symbol,dir,InpRiskPercent,AccountInfoDouble(ACCOUNT_BALANCE),entry,sl,g_symbol.VolumeMin,g_symbol.VolumeMax,g_symbol.VolumeStep,rr); if(vol<=0) return; }

   ulong tk=0; bool ok=(dir>0)?g_trade.OpenBuy(_Symbol,vol,sl,tp,InpTradeComment+"_BUY",tk):g_trade.OpenSell(_Symbol,vol,sl,tp,InpTradeComment+"_SELL",tk);
   if(!ok){ g_logger.Log("MR order failed rc="+IntegerToString(g_trade.LastRetcode())); return; }
   g_logger.Log("MR "+(dir>0?"BUY":"SELL")+" vol="+DoubleToString(vol,2)+" SL="+DoubleToString(sl,5)+" TP="+DoubleToString(tp,5)+" rsi="+DoubleToString(r1,1)+" adx="+DoubleToString(adx1,1));
}
