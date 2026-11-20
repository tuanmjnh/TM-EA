# TM-EA AI Trade - Emergency Kill-Switch (Panic Button)
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location (Join-Path $ScriptDir "..")

Write-Host "=================================================================" -ForegroundColor Red
Write-Host " 🛑 TM-EA AI TRADE — NÚT DỪNG KHẨN CẤP (EMERGENCY KILL-SWITCH)" -ForegroundColor Yellow
Write-Host "=================================================================" -ForegroundColor Red
Write-Host " Thao tác này sẽ:"
Write-Host " 1. Tạo file cờ vật lý config\ai\KILL để ngắt toàn bộ AI Runner"
Write-Host " 2. Hủy toàn bộ lệnh chờ (Pending orders) trên tài khoản"
Write-Host " 3. Đóng ngay lập tức toàn bộ các vị thế đang mở bảo vệ vốn"
Write-Host "=================================================================" -ForegroundColor Red

$confirm = Read-Host "Bạn có chắc chắn muốn KÍCH HOẠT KILL-SWITCH? (y/n)"
if ($confirm -ne "y") {
    Write-Host "Đã hủy thao tác." -ForegroundColor Yellow
    exit 0
}

python -m ai_trade.runner --kill

Write-Host "`n[OK] Hệ thống đã được ngắt hoàn toàn và đóng sạch vị thế." -ForegroundColor Green
Write-Host "Để mở lại hệ thống, hãy chạy: scripts\resume_trading.ps1" -ForegroundColor Cyan
