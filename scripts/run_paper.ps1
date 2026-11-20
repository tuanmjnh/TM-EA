# TM-EA AI Trade - Paper Runner
param (
    [string]$Symbol = "XAUUSDm",
    [int]$Interval = 30
)

$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location (Join-Path $ScriptDir "..")

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host " 📝 TM-EA AI TRADE ORCHESTRATOR — PAPER FORWARD DEMO (v5.2)" -ForegroundColor Green
Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host " 🔍 Chế độ phân tích mô phỏng ảo:" -ForegroundColor White
Write-Host " - Quét nến thời gian thực từ MT5 Exness" -ForegroundColor Gray
Write-Host " - Triệu tập Hội đồng AI 5 tác tử phân tích & bỏ phiếu" -ForegroundColor Gray
Write-Host " - Thẩm định an toàn qua Hard RiskGate" -ForegroundColor Gray
Write-Host " - Ghi nhận bằng chứng vào data/results.db (KHÔNG VÀO LỆNH THẬT)" -ForegroundColor Yellow
Write-Host "=================================================================`n" -ForegroundColor Cyan

python -m ai_trade.runner --mode paper --symbol $Symbol --interval $Interval
