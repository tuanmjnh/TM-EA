# TM-EA AI Trade - PowerShell Operational Suite Launcher
param (
    [string]$Mode = "live",
    [string]$Symbol = "XAUUSDm",
    [double]$Lot = 0.01,
    [int]$Interval = 30
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location (Join-Path $ScriptDir "..")

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host " TM-EA AI TRADE ORCHESTRATOR — FORWARD DEMO RUNNER (v5.2)" -ForegroundColor Green
Write-Host " Chế độ: $($Mode.ToUpper()) | Cặp: $Symbol | Lot: $Lot | Interval: ${Interval}s" -ForegroundColor Yellow
Write-Host "=================================================================" -ForegroundColor Cyan

if (Test-Path "config\ai\KILL") {
    Write-Host "[CẢNH BÁO] Phát hiện file cờ ngắt khẩn cấp config\ai\KILL!" -ForegroundColor Red
    Write-Host "Vui lòng chạy scripts\resume_trading.ps1 trước khi khởi động runner." -ForegroundColor Red
    exit 1
}

python -m ai_trade.runner --mode $Mode --symbol $Symbol --lot $Lot --interval $Interval
