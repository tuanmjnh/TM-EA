# TM-EA AI Trade - PowerShell Live Runner
param (
    [string]$Symbol = "XAUUSDm",
    [double]$Lot = 0.01,
    [int]$Interval = 30
)

$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location (Join-Path $ScriptDir "..")

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host " 🚀 TM-EA AI TRADE ORCHESTRATOR — LIVE FORWARD DEMO RUNNER (v5.2)" -ForegroundColor Green
Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host " 🎯 Thực thi lệnh trực tiếp vào MT5 Exness Demo Cent" -ForegroundColor White
Write-Host " 📊 Cặp giao dịch: $Symbol | Lot ban đầu: $Lot | Tần suất quét: ${Interval}s" -ForegroundColor Yellow
Write-Host " 🛡️ Chốt chặn an toàn: Hard RiskGate 6 lớp, 0.25x Live Probing, Max Risk 2.0%" -ForegroundColor Gray
Write-Host "=================================================================`n" -ForegroundColor Cyan

if (Test-Path "config\ai\KILL") {
    Write-Host "🛑 [CẢNH BÁO KHẨN CẤP] Phát hiện file cờ ngắt khẩn cấp: config\ai\KILL!" -ForegroundColor Red
    Write-Host "Hệ thống đang bị khóa an toàn. Vui lòng chạy scripts\resume_trading.bat để mở khóa.`n" -ForegroundColor Yellow
    Read-Host "Nhấn phím Enter để thoát"
    exit 1
}

python -m ai_trade.runner --mode live --symbol $Symbol --lot $Lot --interval $Interval
