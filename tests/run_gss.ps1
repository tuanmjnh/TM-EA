param(
  [Parameter(Mandatory=$true)][string]$Name,
  [double]$Deposit=5000,
  [double]$Risk=0.5,
  [double]$SweepRR=2.0,
  [double]$ORBRR=4.0,
  [string]$From='2026.01.01',
  [string]$To='2026.07.31',
  [int]$Model=4,
  [string]$Sym='XAUUSDm',
  [string]$Comment='TM_GSS',
  [bool]$OnlyKZ=$true,
  [bool]$EnableSweep=$true,
  [bool]$EnableORB=$true,
  [double]$Commission=0.0,
  [int]$Offset=0
)

$exe='C:\Program Files\MetaTrader 5 EXNESS\terminal64.exe'
$common='C:\Users\tuanmjnh\AppData\Roaming\MetaQuotes\Terminal\Common\Files'
$csv="$common\TM_EA_tester_report_$Sym.csv"
$cfg="D:\Applications\TM-EA\config\test_gss_run.ini"
$outDir='D:\Applications\TM-EA\reports\backtests\_gss'
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
Remove-Item $csv -ErrorAction SilentlyContinue

$ini = @"
[Common]

[Tester]
Expert=TM_GoldSweepScalper.ex5
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
Visual=0
ReplaceReport=1
ShutdownTerminal=1

[TesterInputs]
Enabled=true||false||0||true||N
MagicNumber=777001||777001||1||7770010||N
TradeComment=$Comment
BrokerGMTOffset=$Offset||$Offset||1||12||N
OnlyTradeInKillZones=$(if($OnlyKZ){'true'}else{'false'})||false||0||true||N
OneTradePerKillZone=true||false||0||true||N
Enable_SweepReversal=$(if($EnableSweep){'true'}else{'false'})||false||0||true||N
Sweep_RR=$SweepRR||$SweepRR||0.25||10.0||N
Enable_ORB=$(if($EnableORB){'true'}else{'false'})||false||0||true||N
ORB_RR=$ORBRR||$ORBRR||0.25||10.0||N
Min_Range_ATR=0.5||0.5||0.1||10.0||N
Max_Range_ATR=8.0||8.0||0.1||20.0||N
RiskPercentPerTrade=$Risk||$Risk||0.05||5.0||N
CommissionPerLot=$Commission||$Commission||0.5||10.0||N
Min_Volume=0.01||0.01||0.01||0.1||N
Max_Volume=0.50||0.50||0.01||1.0||N
Max_Spread_Points=350||350||1||1000||N
Max_Daily_Loss_Pct=2.0||2.0||0.1||10.0||N
Circuit_Breaker_DD_Pct=8.0||8.0||0.5||20.0||N
Max_Consec_Losses=3||3||1||10||N
Cooldown_Seconds=1800||1800||60||7200||N
Enable_Trailing=true||false||0||true||N
Trailing_ATR_Mult=2.0||2.0||0.1||10.0||N
Breakeven_ATR_Mult=1.0||1.0||0.1||5.0||N
Breakeven_After_Pips=30.0||30.0||1.0||100.0||N
Trail_Step_Pips=10.0||10.0||1.0||50.0||N
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
  "FAILED $Name - no CSV"
}
