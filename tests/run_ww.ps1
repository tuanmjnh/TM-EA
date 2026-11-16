param(
  [Parameter(Mandatory=$true)][string]$Name,
  [string]$Sym='XAUUSDm',
  [double]$Deposit=5000,
  [int]$EntryTf=15,          # ENUM_TIMEFRAMES: 5=M5,15=M15,30=M30,16385=H1
  [int]$Mode=0,              # 0 PSAR,1 EMA,2 SAR+EMA,3 SAR+EMA+ATR
  [double]$Risk=1.0,
  [int]$SlMode=2,            # 0 none,1 fixed,2 atr,3 psar
  [double]$SlVal=2.0,
  [int]$TpMode=2,            # 0 none,1 fixed,2 RR
  [double]$TpVal=2.0,
  [int]$PosPol=0,            # 0 one-ignore,1 close-opp,2 close-and-reverse
  [int]$MaxTradesDay=0,
  [int]$MaxSpread=350,
  [bool]$UseTrail=$true,
  [double]$TrailAct=1.0,
  [double]$TrailMult=1.5,
  [bool]$UseBE=$false,
  [double]$BEafter=1.0,
  [bool]$SignalOnly=$false,
  [bool]$EnableTrading=$true,
  [string]$From='2025.11.01',
  [string]$To='2026.10.31',
  [int]$Model=4,
  [string]$Comment='TM_WW_V1'
)
$exe='C:\Program Files\MetaTrader 5 EXNESS\terminal64.exe'
$common='C:\Users\tuanmjnh\AppData\Roaming\MetaQuotes\Terminal\Common\Files'
$csv="$common\TM_EA_tester_report_$Sym.csv"
$cfg="D:\Applications\TM-EA\config\test_ww_run.ini"
$outDir='D:\Applications\TM-EA\reports\backtests\_ww'
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
Remove-Item $csv -ErrorAction SilentlyContinue
$tfName = switch($EntryTf){ 5{'M5'} 15{'M15'} 30{'M30'} 16385{'H1'} 16388{'H4'} default{'M15'} }
$ini = @"
[Common]

[Tester]
Expert=TM_Wonderwhales.ex5
Symbol=$Sym
Period=$tfName
Optimization=0
Model=$Model
FromDate=$From
ToDate=$To
ForwardMode=0
Deposit=$Deposit
Currency=USD
Leverage=100
ExecutionMode=0
Visual=0
ReplaceReport=1
ShutdownTerminal=1

[TesterInputs]
InpSignalOnly=$(if($SignalOnly){'true'}else{'false'})||false||0||true||N
InpEnableTrading=$(if($EnableTrading){'true'}else{'false'})||false||0||true||N
InpSignalMode=$Mode||0||1||3||N
InpConfirmOnBarClose=true||false||0||true||N
InpSignalTimeframe=$EntryTf||0||0||49153||N
InpPSARStart=0.02||0.02||0.005||0.2||N
InpPSARInc=0.02||0.02||0.005||0.2||N
InpPSARMax=0.2||0.2||0.05||1.0||N
InpFastEMA=20||20||1||200||N
InpSlowEMA=50||50||1||500||N
InpATRLen=14||14||1||140||N
InpMinATRPct=0.5||0.5||0.1||10.0||N
InpPositionPolicy=$PosPol||0||1||2||N
InpLotMode=1||0||1||1||N
InpFixedLot=0.01||0.01||0.001||0.1||N
InpRiskPercent=$Risk||$Risk||0.05||5.0||N
InpStopLossMode=$SlMode||0||1||3||N
InpStopLossValue=$SlVal||$SlVal||0.1||50.0||N
InpTakeProfitMode=$TpMode||0||1||2||N
InpTakeProfitValue=$TpVal||$TpVal||0.1||50.0||N
InpUseTrailing=$(if($UseTrail){'true'}else{'false'})||false||0||true||N
InpTrailActivateATR=$TrailAct||$TrailAct||0.1||10.0||N
InpTrailATR_Mult=$TrailMult||$TrailMult||0.1||10.0||N
InpUseBreakeven=$(if($UseBE){'true'}else{'false'})||false||0||true||N
InpBreakevenAfterATR=$BEafter||$BEafter||0.1||10.0||N
InpAllowNoStopLoss=false||false||0||true||N
InpMaxSpreadPoints=$MaxSpread||350||1||1000||N
InpMaxTradesPerDay=$MaxTradesDay||0||1||100||N
InpMagicNumber=666001||666001||1||6660010||N
InpTradeComment=$Comment
"@
Set-Content -Path $cfg -Value $ini -Encoding Ascii
$sw=[Diagnostics.Stopwatch]::StartNew()
$p=Start-Process -FilePath $exe -ArgumentList "/config:`"$cfg`"" -PassThru
$p.WaitForExit(900000) | Out-Null
$sw.Stop()
$dst="$outDir\$Name.csv"
if(Test-Path $csv){ Copy-Item $csv $dst -Force; "DONE $Name seconds=$([math]::Round($sw.Elapsed.TotalSeconds,1))"; Get-Content $dst -ErrorAction SilentlyContinue | Select-String 'net_profit|profit_factor|trades|wins|largest_win|largest_loss|max_equity_dd_pct' } else { "FAILED $Name - no CSV" }
