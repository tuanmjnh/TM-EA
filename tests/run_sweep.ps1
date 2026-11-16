param(
  [Parameter(Mandatory=$true)][string]$Name,
  [string]$Sym='XAUUSDm',
  [double]$Deposit=5000,
  [int]$EntryTf=5,
  [double]$Risk=1.0,
  [int]$Swing=10,
  [double]$SweepBuf=0.10,
  [double]$SlBuf=0.20,
  [int]$UseHTF=1,
  [int]$UseTrail=1,
  [double]$TrailAct=1.0,
  [double]$TrailMult=1.5,
  [int]$UseBE=0,
  [int]$MaxSpread=350,
  [string]$From='2025.11.01',
  [string]$To='2026.10.31',
  [int]$Model=4,
  [string]$Comment='TM_SW_V1'
)
$exe='C:\Program Files\MetaTrader 5 EXNESS\terminal64.exe'
$common='C:\Users\tuanmjnh\AppData\Roaming\MetaQuotes\Terminal\Common\Files'
$csv="$common\TM_EA_tester_report_$Sym.csv"
$cfg="D:\Applications\TM-EA\config\test_sweep_run.ini"
$outDir='D:\Applications\TM-EA\reports\backtests\_sw'
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
Remove-Item $csv -ErrorAction SilentlyContinue
$tfName = switch($EntryTf){ 5{'M5'} 15{'M15'} 30{'M30'} 16385{'H1'} default{'M5'} }
$ini = @"
[Common]

[Tester]
Expert=TM_SweepReversal.ex5
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
InpEnableTrading=true||false||0||true||N
InpMagicNumber=999001||999001||1||9990010||N
InpTradeComment=$Comment
InpTF=$EntryTf||5||0||49153||N
InpSwingLookback=$Swing||10||1||100||N
InpSweepBufferATR=$SweepBuf||$SweepBuf||0.01||2.0||N
InpSL_BufferATR=$SlBuf||$SlBuf||0.01||2.0||N
InpATRPeriod=14||14||1||140||N
InpUseHTF_Filter=$(if($UseHTF -eq 1){'true'}else{'false'})||false||0||true||N
InpHtfTF=16385||16385||0||49153||N
InpHtfEMA=50||50||1||500||N
InpUseTrailing=$(if($UseTrail -eq 1){'true'}else{'false'})||false||0||true||N
InpTrailActivateATR=$TrailAct||$TrailAct||0.1||10.0||N
InpTrailATR_Mult=$TrailMult||$TrailMult||0.1||10.0||N
InpUseBreakeven=$(if($UseBE -eq 1){'true'}else{'false'})||false||0||true||N
InpBreakevenAfterATR=1.0||1.0||0.1||10.0||N
InpUseSession=false||false||0||true||N
InpStartHour=7||7||1||23||N
InpEndHour=21||21||1||23||N
InpLotType=1||0||1||1||N
InpRiskPercent=$Risk||$Risk||0.05||5.0||N
InpFixedLot=0.01||0.01||0.001||0.1||N
InpMaxSpreadPts=$MaxSpread||350||1||1000||N
"@
Set-Content -Path $cfg -Value $ini -Encoding Ascii
$sw=[Diagnostics.Stopwatch]::StartNew()
$p=Start-Process -FilePath $exe -ArgumentList "/config:`"$cfg`"" -PassThru
$p.WaitForExit(900000) | Out-Null
$sw.Stop()
$dst="$outDir\$Name.csv"
if(Test-Path $csv){ Copy-Item $csv $dst -Force; "DONE $Name seconds=$([math]::Round($sw.Elapsed.TotalSeconds,1))"; Get-Content $dst | Select-String 'net_profit|profit_factor|trades|wins|largest_win|largest_loss|max_equity_dd_pct' } else { "FAILED $Name - no CSV" }
