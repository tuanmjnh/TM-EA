# TM-EA AI Trade - Resume Trading Script
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location (Join-Path $ScriptDir "..")

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host " 🔄 TM-EA AI TRADE — MỞ LẠI HỆ THỐNG GIAO DỊCH" -ForegroundColor Green
Write-Host "=================================================================" -ForegroundColor Cyan

if (Test-Path "config\ai\KILL") {
    Remove-Item -Force "config\ai\KILL"
    Write-Host "[OK] Đã xóa file cờ khẩn cấp config\ai\KILL." -ForegroundColor Green
} else {
    Write-Host "[INFO] File config\ai\KILL không tồn tại. Hệ thống đang ở trạng thái bình thường." -ForegroundColor Yellow
}

python -c "from ai_trade.core.watchdog import SystemWatchdog; w = SystemWatchdog(); w.pulse('RESUMED', {'action': 'manual_resume'}); print('[OK] Đã phát xung nhịp Watchdog RESUMED.')"

Write-Host "`n✅ Hệ thống đã sẵn sàng. Bạn có thể bật lại runner bằng scripts\run_live.bat hoặc scripts\run_paper.bat.`n" -ForegroundColor Green
Read-Host "Nhấn phím Enter để đóng cửa sổ"
