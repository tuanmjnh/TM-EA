param(
  [Parameter(Mandatory=$true)][string]$Name,
  [string]$Sym='EURUSDm',
  [double]$Deposit=5000,
  [int]$EntryTf=5,
  [double]$Risk=1.0,
  [double]$SlAtr=1.2,
  [double]$TpAtr=1.2,
  [double]$RsiBuy=30.0,
  [double]$RsiSell=70.0,
  [int]$UseRange=1,
  [double]$ADXMax=25.0,
  [int]$MaxSpread=0,
  [int]$UseSession=0,
  [string]$From='2025.11.01',
  [string]$To='2026.10.31',
  [int]$Model=4,
  [string]$Comment='TM_MR_V1'
)
$exe='C:\Program Files\MetaTrader 5 EXNESS\terminal64.exe'
$common='C:\Users\tuanmjnh\AppData\Roaming\MetaQuotes\Terminal\Common\Files'
$csv="$common\TM_EA_tester_report_$Sym.csv"
$cfg="D:\Applications\TM-EA\config\test_mr_run.ini"
$outDir='D:\Applications\TM-EA\reports\backtests\_mr'
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
Remove-Item $csv -ErrorAction SilentlyContinue
$tfName = switch($EntryTf){ 1{'M1'} 5{'M5'} 15{'M15'} 30{'M30'} 16385{'H1'} default{'M5'} }
$ini = @"
[Common]

[Tester]
Expert=TM_MeanRevert.ex5
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
InpMagicNumber=888001||888001||1||8880010||N
InpTradeComment=$Comment
InpTF=$EntryTf||5||0||49153||N
InpBBPeriod=20||20||1||100||N
InpBBDev=2.0||2.0||0.1||5.0||N
InpRSIPeriod=14||14||1||140||N
InpRSIBuy=$RsiBuy||$RsiBuy||1.0||50.0||N
InpRSISell=$RsiSell||$RsiSell||1.0||100.0||N
InpATRPeriod=14||14||1||140||N
InpSL_ATR=$SlAtr||$SlAtr||0.1||10.0||N
InpTP_ATR=$TpAtr||$TpAtr||0.1||10.0||N
InpUseRangeFilter=$(if($UseRange -eq 1){'true'}else{'false'})||false||0||true||N
InpRegimeTF=16385||16385||0||49153||N
InpADXPeriod=14||14||1||140||N
InpADXMax=$ADXMax||$ADXMax||1.0||100.0||N
InpUseSession=$(if($UseSession -eq 1){'true'}else{'false'})||false||0||true||N
InpStartHour=8||8||1||23||N
InpEndHour=21||21||1||23||N
InpLotType=1||0||1||1||N
InpRiskPercent=$Risk||$Risk||0.05||5.0||N
InpFixedLot=0.01||0.01||0.001||0.1||N
InpMaxSpreadPts=$MaxSpread||0||1||1000||N
"@
Set-Content -Path $cfg -Value $ini -Encoding Ascii
$sw=[Diagnostics.Stopwatch]::StartNew()
$p=Start-Process -FilePath $exe -ArgumentList "/config:`"$cfg`"" -PassThru
$p.WaitForExit(900000) | Out-Null
$sw.Stop()
$dst="$outDir\$Name.csv"
if(Test-Path $csv){ Copy-Item $csv $dst -Force; "DONE $Name seconds=$([math]::Round($sw.Elapsed.TotalSeconds,1))"; Get-Content $dst | Select-String 'net_profit|profit_factor|trades|wins|largest_win|largest_loss|max_equity_dd_pct' } else { "FAILED $Name - no CSV" }
