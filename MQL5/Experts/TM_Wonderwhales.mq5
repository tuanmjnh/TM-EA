//+------------------------------------------------------------------+
//| TM_Wonderwhales.mq5                                             |
//| Port of the Wonderwhales Pine indicator (PSAR / EMA / ATR).     |
//| Signal-only by default. No profitability claim.                 |
//+------------------------------------------------------------------+
#property copyright "TM-EA"
#property version   "1.00"
#property strict

#include "..\Include\TM_EA\SymbolSpecs.mqh"
#include "..\Include\TM_EA\Logger.mqh"
#include "..\Include\TM_EA\RiskManager.mqh"
#include "..\Include\TM_EA\TradeExecutor.mqh"

enum EwwMode   { WW_PSAR_REVERSAL=0, WW_EMA_CROSSOVER=1, WW_SAR_EMA=2, WW_SAR_EMA_ATR=3 };
enum EPosPol   { PP_ONE_IGNORE=0, PP_CLOSE_ON_OPPOSITE=1, PP_CLOSE_AND_REVERSE=2 };
enum EwwLot    { LOT_FIXED=0, LOT_RISK_PERCENT=1 };
enum EwwSL     { SL_NONE=0, SL_FIXED_POINTS=1, SL_ATR_MULTIPLE=2, SL_PSAR_LEVEL=3 };
enum EwwTP     { TP_NONE=0, TP_FIXED_POINTS=1, TP_RISK_REWARD=2 };

input bool            InpSignalOnly        = true;
input bool            InpEnableTrading     = false;
input EwwMode         InpSignalMode        = WW_PSAR_REVERSAL;
input bool            InpConfirmOnBarClose = true;
input ENUM_TIMEFRAMES InpSignalTimeframe   = PERIOD_CURRENT; // 0 = chart TF
input double          InpPSARStart         = 0.02;
input double          InpPSARInc           = 0.02;
input double          InpPSARMax           = 0.2;
input int             InpFastEMA           = 20;
input int             InpSlowEMA           = 50;
input int             InpATRLen            = 14;
input double          InpMinATRPct         = 0.5;
input EPosPol         InpPositionPolicy    = PP_ONE_IGNORE;
input EwwLot          InpLotMode           = LOT_RISK_PERCENT;
input double          InpFixedLot          = 0.01;
input double          InpRiskPercent       = 1.0;
input EwwSL           InpStopLossMode      = SL_ATR_MULTIPLE;
input double          InpStopLossValue     = 2.0;
input EwwTP           InpTakeProfitMode    = TP_RISK_REWARD;
input double          InpTakeProfitValue   = 2.0;
input bool            InpUseTrailing       = true;   // ATR trailing
input double          InpTrailActivateATR  = 1.0;    // start trailing after profit >= this * ATR
input double          InpTrailATR_Mult     = 1.5;    // trailing distance = this * ATR
input bool            InpUseBreakeven      = false;  // move SL to entry (ATR-gated)
input double          InpBreakevenAfterATR = 1.0;    // ...only after profit >= this * ATR
input bool            InpAllowNoStopLoss   = false;
input int             InpMaxSpreadPoints   = 350;
input int             InpMaxTradesPerDay   = 0;
input int             InpMagicNumber       = 666001;
input string          InpTradeComment      = "TM_WW_V1";

CSymbolSpecs   g_symbol;
CLogger        g_logger;
CTradeExecutor g_trade;

int      g_hSar = INVALID_HANDLE, g_hFast = INVALID_HANDLE, g_hSlow = INVALID_HANDLE, g_hAtr = INVALID_HANDLE;
ENUM_TIMEFRAMES g_tf = PERIOD_CURRENT;
datetime g_lastBar = 0;
datetime g_lastDay = 0;
int      g_tradesToday = 0;
double   g_initBalance = 0.0, g_peakEquity = 0.0, g_maxDD = 0.0;

//+------------------------------------------------------------------+
void DumpTesterStats()
{
   if(!(bool)MQLInfoInteger(MQL_TESTER)) return;
   double finalBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   double gp=0, gl=0; int tr=0, w=0, l=0, cl=0, mcl=0; double lw=0, ll=0;
   HistorySelect(0, TimeCurrent());
   for(int i=0;i<HistoryDealsTotal();i++){
      ulong d=HistoryDealGetTicket(i); if(d==0) continue;
      if(HistoryDealGetString(d,DEAL_SYMBOL)!=_Symbol) continue;
      if((int)HistoryDealGetInteger(d,DEAL_MAGIC)!=InpMagicNumber) continue;
      if((int)HistoryDealGetInteger(d,DEAL_ENTRY)!=DEAL_ENTRY_OUT) continue;
      double p=HistoryDealGetDouble(d,DEAL_PROFIT)+HistoryDealGetDouble(d,DEAL_COMMISSION)+HistoryDealGetDouble(d,DEAL_SWAP);
      tr++;
      if(p>0){w++;gp+=p;if(p>lw)lw=p;cl=0;} else if(p<0){l++;gl+=p;if(p<ll)ll=p;cl++;if(cl>mcl)mcl=cl;}
   }
   double pf=(gl<0)?gp/MathAbs(gl):0.0;
   double dd=(g_peakEquity>0)?g_maxDD/g_peakEquity*100.0:0.0;
   int fh=FileOpen("TM_EA_tester_report_"+_Symbol+".csv",FILE_WRITE|FILE_CSV|FILE_ANSI|FILE_COMMON,';');
   if(fh==INVALID_HANDLE) return;
   FileWrite(fh,"key","value");
   FileWrite(fh,"symbol",_Symbol);
   FileWrite(fh,"expert","TM_Wonderwhales");
   FileWrite(fh,"end_time",TimeToString(TimeCurrent(),TIME_DATE|TIME_SECONDS));
   FileWrite(fh,"deposit",DoubleToString(g_initBalance,2));
   FileWrite(fh,"final_balance",DoubleToString(finalBalance,2));
   FileWrite(fh,"net_profit",DoubleToString(finalBalance-g_initBalance,2));
   FileWrite(fh,"gross_profit",DoubleToString(gp,2));
   FileWrite(fh,"gross_loss",DoubleToString(gl,2));
   FileWrite(fh,"profit_factor",DoubleToString(pf,3));
   FileWrite(fh,"trades",IntegerToString(tr));
   FileWrite(fh,"wins",IntegerToString(w));
   FileWrite(fh,"losses",IntegerToString(l));
   FileWrite(fh,"largest_win",DoubleToString(lw,2));
   FileWrite(fh,"largest_loss",DoubleToString(ll,2));
   FileWrite(fh,"max_consec_losses",IntegerToString(mcl));
   FileWrite(fh,"max_equity_dd_abs",DoubleToString(g_maxDD,2));
   FileWrite(fh,"max_equity_dd_pct",DoubleToString(dd,3));
   FileClose(fh);
   PrintFormat("WW stats: net=%.2f PF=%.3f trades=%d DD=%.2f%%",finalBalance-g_initBalance,pf,tr,dd);
}

//+------------------------------------------------------------------+
//| Parabolic SAR computed to match Pine ta.sar(start, inc, max).    |
//+------------------------------------------------------------------+
bool WwPSAR(const int N, const double start, const double inc, const double maxAF,
            int &dirRecent, int &dirPrev, double &sarRecent)
{
   MqlRates r[];
   int got = CopyRates(_Symbol, g_tf, 1, N, r);
   if(got < 5) return false;
   double hi[], lo[], cl[];
   ArrayResize(hi, got); ArrayResize(lo, got); ArrayResize(cl, got);
   for(int k = 0; k < got; k++)
   {
      int idx = got - 1 - k;            // ascending: k=0 oldest, k=got-1 = bar1
      hi[k] = r[idx].high; lo[k] = r[idx].low; cl[k] = r[idx].close;
   }
   double sar[]; int dir[];
   ArrayResize(sar, got); ArrayResize(dir, got);
   bool up = (cl[1] >= cl[0]);
   double af = start;
   double ep = up ? hi[1] : lo[1];
   double s  = up ? lo[0] : hi[0];
   sar[1] = s; dir[1] = up ? 1 : -1;
   for(int i = 2; i < got; i++)
   {
      s = s + af * (ep - s);
      if(up)
      {
         s = MathMin(s, MathMin(lo[i-1], lo[i-2]));
         if(lo[i] < s) { up = false; s = ep; ep = lo[i]; af = start; }
         else if(hi[i] > ep) { ep = hi[i]; af = MathMin(af + inc, maxAF); }
      }
      else
      {
         s = MathMax(s, MathMax(hi[i-1], hi[i-2]));
         if(hi[i] > s) { up = true; s = ep; ep = hi[i]; af = start; }
         else if(lo[i] < ep) { ep = lo[i]; af = MathMin(af + inc, maxAF); }
      }
      sar[i] = s; dir[i] = up ? 1 : -1;
   }
   dirRecent = dir[got-1];
   dirPrev   = dir[got-2];
   sarRecent = sar[got-1];
   return true;
}

//+------------------------------------------------------------------+
//| Breakeven (ATR-gated) + ATR trailing, ratchet one way only.      |
void ManagePositions(const double atr)
{
   if(atr <= 0.0) return;
   for(int i = PositionsTotal()-1; i >= 0; i--)
   {
      ulong t = PositionGetTicket(i); if(t==0) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      if((int)PositionGetInteger(POSITION_MAGIC) != InpMagicNumber) continue;
      ENUM_POSITION_TYPE pt = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      double open = PositionGetDouble(POSITION_PRICE_OPEN), sl = PositionGetDouble(POSITION_SL);
      double bid = SymbolInfoDouble(_Symbol,SYMBOL_BID), ask = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
      double spread = ask - bid;
      if(pt == POSITION_TYPE_BUY)
      {
         double prof = bid - open;
         double cand = (sl>0)? sl : 0.0;
         if(InpUseBreakeven && prof >= InpBreakevenAfterATR*atr){ double be=open+spread; if(be>=bid) be=open; if(be>cand) cand=be; }
         if(InpUseTrailing  && prof >= InpTrailActivateATR*atr){ double tr=bid-InpTrailATR_Mult*atr; if(tr>cand) cand=tr; }
         double nsl = NormalizeDouble(MathFloor(cand/g_symbol.TickSize)*g_symbol.TickSize,8);
         if(nsl>sl && nsl<bid && g_trade.ModifyStopLoss(t,nsl)) g_logger.Log("ww sl BUY "+DoubleToString(nsl,5));
      }
      else if(pt == POSITION_TYPE_SELL)
      {
         double prof = open - ask;
         double cand = (sl>0)? sl : DBL_MAX;
         if(InpUseBreakeven && prof >= InpBreakevenAfterATR*atr){ double be=open-spread; if(be<=ask) be=open; if(be<cand) cand=be; }
         if(InpUseTrailing  && prof >= InpTrailActivateATR*atr){ double tr=ask+InpTrailATR_Mult*atr; if(tr<cand) cand=tr; }
         double nsl = NormalizeDouble(MathCeil(cand/g_symbol.TickSize)*g_symbol.TickSize,8);
         if((sl<=0 || nsl<sl) && nsl>ask && g_trade.ModifyStopLoss(t,nsl)) g_logger.Log("ww sl SELL "+DoubleToString(nsl,5));
      }
   }
}

//+------------------------------------------------------------------+
int OnInit()
{
   g_tf = (InpSignalTimeframe==PERIOD_CURRENT) ? (ENUM_TIMEFRAMES)Period() : InpSignalTimeframe;
   if(!g_symbol.Refresh(_Symbol)){ Print("INIT FAILED: symbol"); return INIT_FAILED; }
   if(!g_trade.Init(InpMagicNumber, 10)){ Print("INIT FAILED: executor"); return INIT_FAILED; }

   // PSAR is computed in-code (WwPSAR) to match Pine ta.sar(start, inc, max).
   g_hFast = iMA(_Symbol, g_tf, InpFastEMA, 0, MODE_EMA, PRICE_CLOSE);
   g_hSlow = iMA(_Symbol, g_tf, InpSlowEMA, 0, MODE_EMA, PRICE_CLOSE);
   g_hAtr  = iATR(_Symbol, g_tf, InpATRLen);
   if(g_hFast==INVALID_HANDLE||g_hSlow==INVALID_HANDLE||g_hAtr==INVALID_HANDLE)
   { Print("INIT FAILED: indicator handles"); return INIT_FAILED; }

   g_logger.Init(_Symbol, InpMagicNumber);
   g_initBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   g_peakEquity = AccountInfoDouble(ACCOUNT_EQUITY);
   g_logger.Log("TM_Wonderwhales init. mode="+IntegerToString((int)InpSignalMode)+" tf="+IntegerToString((int)g_tf)+" signalOnly="+IntegerToString((int)InpSignalOnly));
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   DumpTesterStats();
   if(g_hFast!=INVALID_HANDLE) IndicatorRelease(g_hFast);
   if(g_hSlow!=INVALID_HANDLE) IndicatorRelease(g_hSlow);
   if(g_hAtr!=INVALID_HANDLE) IndicatorRelease(g_hAtr);
   g_logger.Deinit();
}

//+------------------------------------------------------------------+
bool GetTriple(const int handle, double &v1, double &v2)
{
   double b[3];
   if(CopyBuffer(handle,0,0,3,b)!=3) return false;
   v1=b[1]; v2=b[2]; return true;
}

//+------------------------------------------------------------------+
void OnTick()
{
   if((bool)MQLInfoInteger(MQL_TESTER)){
      double eq=AccountInfoDouble(ACCOUNT_EQUITY);
      if(eq>g_peakEquity) g_peakEquity=eq;
      double dd=g_peakEquity-eq; if(dd>g_maxDD) g_maxDD=dd;
   }

   MqlDateTime dt; TimeToStruct(TimeCurrent(),dt);
   datetime day = TimeCurrent()-(dt.hour*3600+dt.min*60+dt.sec);
   if(day!=g_lastDay){ g_lastDay=day; g_tradesToday=0; }

   double mgrAtr=0.0; { double b[2]; if(CopyBuffer(g_hAtr,0,0,2,b)==2) mgrAtr=b[1]; }
   ManagePositions(mgrAtr);

   datetime bt = iTime(_Symbol, g_tf, 0);
   if(bt==0 || bt==g_lastBar) return;   // once per new bar
   g_lastBar = bt;

   double f1,f2,s1,s2,a1,a2, c1;
   if(!GetTriple(g_hFast,f1,f2)) return;
   if(!GetTriple(g_hSlow,s1,s2)) return;
   if(!GetTriple(g_hAtr,a1,a2)) return;
   c1=iClose(_Symbol,g_tf,1);
   if(c1<=0) return;

   int dirRecent, dirPrev; double sarRecent;
   if(!WwPSAR(300, InpPSARStart, InpPSARInc, MathMax(InpPSARStart, InpPSARMax),
              dirRecent, dirPrev, sarRecent)) return;
   double sar1 = sarRecent;

   bool buyFlip  = (dirRecent==1 && dirPrev==-1);
   bool sellFlip = (dirRecent==-1 && dirPrev==1);
   bool emaBull  = (f1>s1), emaBear=(f1<s1);
   bool emaUp    = (f1>s1 && f2<=s2), emaDn=(f1<s1 && f2>=s2);
   double atrPct = (c1>0)?a1/c1*100.0:0.0;
   bool atrOk    = (atrPct>=InpMinATRPct);

   bool rawBuy=false, rawSell=false;
   switch(InpSignalMode){
      case WW_PSAR_REVERSAL: rawBuy=buyFlip; rawSell=sellFlip; break;
      case WW_EMA_CROSSOVER: rawBuy=emaUp;   rawSell=emaDn;   break;
      case WW_SAR_EMA:       rawBuy=buyFlip&&emaBull; rawSell=sellFlip&&emaBear; break;
      case WW_SAR_EMA_ATR:   rawBuy=buyFlip&&emaBull&&atrOk; rawSell=sellFlip&&emaBear&&atrOk; break;
   }
   if(!rawBuy && !rawSell) return;

   int dir = rawBuy?1:-1;
   g_logger.Log("SIGNAL "+(rawBuy?"BUY":"SELL")+" mode="+IntegerToString((int)InpSignalMode)+
                " close="+DoubleToString(c1,5)+" sar="+DoubleToString(sar1,5)+
                " emaF="+DoubleToString(f1,5)+" emaS="+DoubleToString(s1,5)+" atrPct="+DoubleToString(atrPct,2));

   if(InpSignalOnly || !InpEnableTrading) return;

   int open = g_trade.CountOpenPositions(_Symbol);
   if(InpMaxTradesPerDay>0 && g_tradesToday>=InpMaxTradesPerDay) return;

   if(open>0){
      if(InpPositionPolicy==PP_ONE_IGNORE) return;
      if(InpPositionPolicy==PP_CLOSE_ON_OPPOSITE){
         // close positions whose direction opposes the signal
         for(int i=PositionsTotal()-1;i>=0;i--){
            ulong t=PositionGetTicket(i); if(t==0) continue;
            if(PositionGetString(POSITION_SYMBOL)!=_Symbol) continue;
            if((int)PositionGetInteger(POSITION_MAGIC)!=InpMagicNumber) continue;
            ENUM_POSITION_TYPE pt=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
            if((dir>0&&pt==POSITION_TYPE_SELL)||(dir<0&&pt==POSITION_TYPE_BUY)) g_trade.ClosePartial(t,PositionGetDouble(POSITION_VOLUME));
         }
         return;
      }
      if(InpPositionPolicy==PP_CLOSE_AND_REVERSE){
         g_trade.CloseAllPositions(_Symbol);
         if(g_trade.CountOpenPositions(_Symbol)>0){ g_logger.Log("CLOSE_AND_REVERSE: close failed, skip new entry."); return; }
      }
   }

   double bid=SymbolInfoDouble(_Symbol,SYMBOL_BID), ask=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   double spread=(ask-bid)/g_symbol.Point;
   if(InpMaxSpreadPoints>0 && spread>(double)InpMaxSpreadPoints){ g_logger.Log("skip: spread "+DoubleToString(spread,1)); return; }

   double entry = (dir>0)?ask:bid;
   double atrDist = a1*InpStopLossValue;
   double sl=0.0;
   switch(InpStopLossMode){
      case SL_NONE:          sl=0.0; break;
      case SL_FIXED_POINTS:  sl=(dir>0)?entry-InpStopLossValue*g_symbol.Point:entry+InpStopLossValue*g_symbol.Point; break;
      case SL_ATR_MULTIPLE:  sl=(dir>0)?entry-atrDist:entry+atrDist; break;
      case SL_PSAR_LEVEL:    sl=sar1; break;
   }
   if(sl<=0.0 && !InpAllowNoStopLoss){ g_logger.Log("skip: no SL"); return; }
   double riskDist=(sl>0)?MathAbs(entry-sl):0.0;

   double tp=0.0;
   if(InpTakeProfitMode==TP_FIXED_POINTS) tp=(dir>0)?entry+InpTakeProfitValue*g_symbol.Point:entry-InpTakeProfitValue*g_symbol.Point;
   else if(InpTakeProfitMode==TP_RISK_REWARD && riskDist>0) tp=(dir>0)?entry+InpTakeProfitValue*riskDist:entry-InpTakeProfitValue*riskDist;

   double volume=0.0;
   if(InpLotMode==LOT_FIXED){ volume=InpFixedLot; }
   else {
      string r="";
      double slForRisk=(sl>0)?sl:(dir>0?entry-2.0*a1:entry+2.0*a1);
      volume=CRiskManager::CalculateVolume(_Symbol,dir,InpRiskPercent,AccountInfoDouble(ACCOUNT_BALANCE),entry,slForRisk,g_symbol.VolumeMin,g_symbol.VolumeMax,g_symbol.VolumeStep,r);
      if(volume<=0.0){ g_logger.Log("skip: volume "+r); return; }
   }

   ulong ticket=0; bool ok=false;
   string cmt=InpTradeComment+"_"+(dir>0?"BUY":"SELL");
   if(dir>0) ok=g_trade.OpenBuy(_Symbol,volume,sl,tp,cmt,ticket);
   else      ok=g_trade.OpenSell(_Symbol,volume,sl,tp,cmt,ticket);
   if(!ok){ g_logger.Log("order failed. retcode="+IntegerToString(g_trade.LastRetcode())); return; }
   g_tradesToday++;
   g_logger.Log("ORDER "+(dir>0?"BUY":"SELL")+" vol="+DoubleToString(volume,2)+" SL="+DoubleToString(sl,5)+" TP="+DoubleToString(tp,5));
}
