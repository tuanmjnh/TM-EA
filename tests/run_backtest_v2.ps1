param(
  [Parameter(Mandatory=$true)][string]$Name,
  [double]$Deposit=1000,
  [double]$Risk=0.5,
  [double]$AtrMult=2.0,
  [double]$TpMult=1.5,
  [double]$Activate=4.0,
  [double]$Step=2.0,
  [double]$Breakeven=8.0,
  [double]$MaxDaily=1.5,
  [int]$MaxConsec=4,
  [int]$Cooldown=30,
  [double]$MaxVol=0.05,
  [string]$From='2026.08.01',
  [string]$To='2026.10.31',
  [int]$Model=4,
  [string]$Comment='TM_TFS_V2',
  [bool]$UseTP=$true,
  [bool]$UseBreakout=$true,
  [double]$BreakoutK=0.7,
  [double]$Adx=25.0,
  [int]$Buffer=2,
  [double]$BeAtr=1.0,
  [int]$Direction=0,
  [double]$SlAtr=1.0,
  [int]$EntryTf=5,
  [int]$TrendTf=15,
  [string]$Sym='XAUUSDm',
  [bool]$UseSlope=$true,
  [bool]$Reclaim=$true,
  [bool]$Partial=$true,
  [double]$PartAtr=1.0,
  [double]$PartPct=50.0
)

$exe='C:\Program Files\MetaTrader 5 EXNESS\terminal64.exe'
$common='C:\Users\tuanmjnh\AppData\Roaming\MetaQuotes\Terminal\Common\Files'
$csv="$common\TM_EA_tester_report_$Sym.csv"
$cfg="D:\Applications\TM-EA\config\test_v2_run.ini"
$outDir='D:\Applications\TM-EA\reports\backtests\_v2'
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
Remove-Item $csv -ErrorAction SilentlyContinue

$ini = @"
[Common]

[Tester]
Expert=TM_TrendFollowerScalper.ex5
Symbol=$Sym
Period=M5
Optimization=0
Model=$Model
FromDate=$From
ToDate=$To
ForwardMode=0
Deposit=$Deposit
Currency=USD
ProfitInPips=0
Leverage=100
ExecutionMode=0
OptimizationCriterion=0
Visual=0
ReplaceReport=1
ShutdownTerminal=1

[TesterInputs]
Enabled=true||false||0||true||N
MagicNumber=123456||123456||1||1234560||N
TradeComment=$Comment
Trade_Direction=$Direction||0||0||2||N
Trend_Timeframe=$TrendTf||15||0||49153||N
FastEMA_HTF=50||50||1||500||N
SlowEMA_HTF=200||200||1||2000||N
ADX_Period=14||14||1||140||N
ADX_Threshold=$Adx||$Adx||2.5||250.0||N
Use_EMA_Slope_Filter=$(if($UseSlope){'true'}else{'false'})||false||0||true||N
Entry_Timeframe=$EntryTf||5||0||49153||N
PullbackEMA=20||20||1||200||N
Pullback_Buffer_pips=$Buffer||$Buffer||1||20||N
Use_Breakout=$(if($UseBreakout){'true'}else{'false'})||false||0||true||N
BreakoutK=$BreakoutK||$BreakoutK||0.1||5.0||N
Require_Close_Beyond_EMA=$(if($Reclaim){'true'}else{'false'})||false||0||true||N
Use_TP=$(if($UseTP){'true'}else{'false'})||false||0||true||N
TP_ATR_Mult=$TpMult||$TpMult||0.15||15.0||N
SL_ATR_Mult=$SlAtr||$SlAtr||0.25||10.0||N
Trail_ATR_Mult=$AtrMult||$AtrMult||0.2||20.0||N
Trail_ATR_Period=14||14||1||140||N
Activate_After_Profit_pips=$Activate||$Activate||0.4||40.0||N
Trail_Step_pips=$Step||$Step||0.2||20.0||N
Breakeven_After_pips=$Breakeven||$Breakeven||0.8||80.0||N
Breakeven_ATR_Mult=$BeAtr||$BeAtr||0.25||10.0||N
Use_Partial_Exit=$(if($Partial){'true'}else{'false'})||false||0||true||N
Partial_Exit_ATR_Mult=$PartAtr||$PartAtr||0.25||10.0||N
Partial_Exit_Percent=$PartPct||$PartPct||5.0||90.0||N
RiskPercentPerTrade=$Risk||$Risk||0.05||5.0||N
Min_Volume=0.01||0.01||0.001||0.1||N
Max_Volume=$MaxVol||$MaxVol||0.001||0.1||N
Max_Concurrent_Positions=1||1||1||10||N
Max_Equity_DD_Percent=10.0||10.0||1.0||100.0||N
Max_Daily_Loss_Percent=$MaxDaily||$MaxDaily||0.15||15.0||N
Max_Consecutive_Losses=$MaxConsec||$MaxConsec||1||40||N
CoolDown_Minutes=$Cooldown||$Cooldown||1||300||N
Max_Spread_Points=350||350||1||1000||N
News_Enable=true||false||0||true||N
News_Buffer_Minutes=20||20||1||200||N
Use_Session_Filter=true||false||0||true||N
"@
Set-Content -Path $cfg -Value $ini -Encoding Ascii

$sw=[Diagnostics.Stopwatch]::StartNew()
$p=Start-Process -FilePath $exe -ArgumentList "/config:`"$cfg`"" -PassThru
$p.WaitForExit(900000) | Out-Null
$sw.Stop()

$dst="$outDir\$Name.csv"
if(Test-Path $csv){
  Copy-Item $csv $dst -Force
  "DONE $Name  seconds=$([math]::Round($sw.Elapsed.TotalSeconds,1))"
  Get-Content $dst
} else {
  "FAILED $Name - no CSV produced (seconds=$([math]::Round($sw.Elapsed.TotalSeconds,1)))"
}
