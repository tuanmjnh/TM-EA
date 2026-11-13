param(
  [Parameter(Mandatory=$true)][string]$Name,
  [double]$Deposit=500,
  [double]$Risk=1.0,
  [double]$RR=2.0,
  [int]$RangeStart=0,
  [int]$RangeEnd=7,
  [int]$TradeStart=7,
  [int]$TradeEnd=20,
  [double]$MaxVol=0.50,
  [int]$MaxSpread=350,
  [string]$From='2026.05.01',
  [string]$To='2026.07.31',
  [int]$Model=4,
  [string]$Sym='XAUUSDm',
  [string]$Comment='TM_SB',
  [bool]$UseADX=$false,
  [double]$ADXMin=20.0,
  [double]$MinRangeAtr=0.0,
  [double]$MaxRangeAtr=100.0
)

$exe='C:\Program Files\MetaTrader 5 EXNESS\terminal64.exe'
$common='C:\Users\tuanmjnh\AppData\Roaming\MetaQuotes\Terminal\Common\Files'
$csv="$common\TM_EA_tester_report_$Sym.csv"
$cfg="D:\Applications\TM-EA\config\test_sb_run.ini"
$outDir='D:\Applications\TM-EA\reports\backtests\_sb'
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
Remove-Item $csv -ErrorAction SilentlyContinue

$ini = @"
[Common]

[Tester]
Expert=TM_SessionBreakout.ex5
Symbol=$Sym
Period=H1
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
MagicNumber=555001||555001||1||5550010||N
TradeComment=$Comment
RangeStartHour=$RangeStart||0||1||23||N
RangeEndHour=$RangeEnd||7||1||23||N
TradeStartHour=$TradeStart||7||1||23||N
TradeEndHour=$TradeEnd||20||1||23||N
RiskPercentPerTrade=$Risk||$Risk||0.05||5.0||N
RR=$RR||$RR||0.25||10.0||N
Min_Volume=0.01||0.01||0.01||0.1||N
Max_Volume=$MaxVol||$MaxVol||0.01||1.0||N
Max_Spread_Points=$MaxSpread||350||1||1000||N
OneTradePerDay=true||false||0||true||N
Use_ADX_Filter=$(if($UseADX){'true'}else{'false'})||false||0||true||N
ADX_Period=14||14||1||140||N
ADX_Min=$ADXMin||$ADXMin||1.0||100.0||N
Min_Range_ATR=$MinRangeAtr||$MinRangeAtr||0.05||10.0||N
Max_Range_ATR=$MaxRangeAtr||$MaxRangeAtr||0.1||100.0||N
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
