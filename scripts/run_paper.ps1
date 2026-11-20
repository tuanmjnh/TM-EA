# TM-EA AI Trade - Paper Trading Launcher
param (
    [string]$Symbol = "XAUUSDm",
    [int]$Interval = 30
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location (Join-Path $ScriptDir "..")

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host " TM-EA AI TRADE ORCHESTRATOR — PAPER FORWARD DEMO (v5.2)" -ForegroundColor Green
Write-Host " Chế độ: PAPER | Cặp: $Symbol | Interval: ${Interval}s" -ForegroundColor Yellow
Write-Host "=================================================================" -ForegroundColor Cyan

python -m ai_trade.runner --mode paper --symbol $Symbol --interval $Interval
