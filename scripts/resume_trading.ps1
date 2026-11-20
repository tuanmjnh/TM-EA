# TM-EA AI Trade - Resume Trading Script
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location (Join-Path $ScriptDir "..")

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host " TM-EA AI TRADE — MỞ LẠI HỆ THỐNG GIAO DỊCH" -ForegroundColor Green
Write-Host "=================================================================" -ForegroundColor Cyan

if (Test-Path "config\ai\KILL") {
    Remove-Item -Force "config\ai\KILL"
    Write-Host "[OK] Đã xóa file cờ config\ai\KILL." -ForegroundColor Green
} else {
    Write-Host "[INFO] File config\ai\KILL không tồn tại. Hệ thống đang bình thường." -ForegroundColor Yellow
}

python -c "from ai_trade.core.watchdog import SystemWatchdog; w = SystemWatchdog(); w.pulse('RESUMED', {'action': 'manual_resume'}); print('[OK] Đã phát xung nhịp Watchdog RESUMED.')"

Write-Host "`nHệ thống đã sẵn sàng. Bạn có thể bật lại runner bằng scripts\run_live.ps1 hoặc scripts\run_live.bat." -ForegroundColor Green
