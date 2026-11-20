# TM-EA AI Trade - Go-Live Readiness Dashboard
param (
    [switch]$Sync = $true,
    [int]$Days = 30
)

$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location (Join-Path $ScriptDir "..")

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host " 📊 TM-EA AI TRADE — BẢNG ĐIỀU KHIỂN & ĐÁNH GIÁ GO-LIVE (PHASE 4)" -ForegroundColor Green
Write-Host "=================================================================`n" -ForegroundColor Cyan

if ($Sync) {
    python -m ai_trade.reporting.dashboard --sync --days $Days
} else {
    python -m ai_trade.reporting.dashboard
}

Write-Host "`n"
Read-Host "Nhấn phím Enter để đóng cửa sổ"
