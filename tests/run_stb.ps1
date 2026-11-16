param(
  [Parameter(Mandatory=$true)][string]$Name,
  [string]$Sym='XAUUSDm',
  [double]$Deposit=5000,
  [double]$Risk=1.0,
  [int]$LotType=1,
  [int]$UseSession=1,
  [double]$SlAtr=1.5,
  [double]$TrailAtr=1.2,
  [double]$TrailAct=1.0,
  [double]$DailyCap=4.0,
  [int]$MaxSpread=350,
  [int]$Enable=1,
  [string]$From='2025.11.01',
  [string]$To='2026.10.31',
  [int]$Model=4,
  [string]$Comment='TM_STB_V1'
)
$exe='C:\Program Files\MetaTrader 5 EXNESS\terminal64.exe'
$common='C:\Users\tuanmjnh\AppData\Roaming\MetaQuotes\Terminal\Common\Files'
$csv="$common\TM_EA_tester_report_$Sym.csv"
$cfg="D:\Applications\TM-EA\config\test_stb_run.ini"
$outDir='D:\Applications\TM-EA\reports\backtests\_stb'
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
Remove-Item $csv -ErrorAction SilentlyContinue
$ini = @"
[Common]

[Tester]
Expert=TM_ScopeTB.ex5
Symbol=$Sym
Period=M5
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
InpEnableTrading=$(if($Enable -eq 1){'true'}else{'false'})||false||0||true||N
InpMagicNumber=777001||777001||1||7770010||N
InpTradeComment=$Comment
InpLotType=$LotType||0||1||1||N
InpRiskPercent=$Risk||$Risk||0.05||5.0||N
InpFixedLot=0.01||0.01||0.001||0.1||N
InpBBPeriod=20||20||1||100||N
InpBBDev=2.0||2.0||0.1||5.0||N
InpATRPeriod=14||14||1||140||N
InpADXPeriod=14||14||1||140||N
InpADXThreshold=20.0||20.0||1.0||100.0||N
InpHTF_EMA_Fast=20||20||1||200||N
InpHTF_EMA_Slow=50||50||1||500||N
InpD1_EMA_Fast=50||50||1||500||N
InpD1_EMA_Slow=200||200||1||1000||N
InpUseSessionFilter=$(if($UseSession -eq 1){'true'}else{'false'})||false||0||true||N
InpLondonStart=8||8||1||23||N
InpLondonEnd=16||16||1||23||N
InpNYStart=13||13||1||23||N
InpNYEnd=21||21||1||23||N
InpSL_ATR_Mult=$SlAtr||$SlAtr||0.1||10.0||N
InpTrail_ATR_Mult=$TrailAtr||$TrailAtr||0.1||10.0||N
InpTrailActivateATR=$TrailAct||$TrailAct||0.1||10.0||N
InpPivotLeft=3||3||1||10||N
InpMinPivotGap=5||5||1||50||N
InpDailyLossCapPct=$DailyCap||$DailyCap||0.1||50.0||N
InpMaxSpreadPts=$MaxSpread||350||1||1000||N
"@
Set-Content -Path $cfg -Value $ini -Encoding Ascii
$sw=[Diagnostics.Stopwatch]::StartNew()
$p=Start-Process -FilePath $exe -ArgumentList "/config:`"$cfg`"" -PassThru
$p.WaitForExit(900000) | Out-Null
$sw.Stop()
$dst="$outDir\$Name.csv"
if(Test-Path $csv){ Copy-Item $csv $dst -Force; "DONE $Name seconds=$([math]::Round($sw.Elapsed.TotalSeconds,1))"; Get-Content $dst | Select-String 'net_profit|profit_factor|trades|wins|largest_win|largest_loss|max_equity_dd_pct' } else { "FAILED $Name - no CSV" }
