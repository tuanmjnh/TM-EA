# TM-EA AI Trade - Emergency Kill-Switch (Panic Button)
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location (Join-Path $ScriptDir "..")

Write-Host "=================================================================" -ForegroundColor Red
Write-Host " 🛑 TM-EA AI TRADE — NÚT DỪNG KHẨN CẤP (EMERGENCY KILL-SWITCH)" -ForegroundColor Yellow
Write-Host "=================================================================" -ForegroundColor Red
Write-Host " CẢNH BÁO: Thao tác này sẽ:" -ForegroundColor White
Write-Host " 1. Tạo file cờ vật lý: config\ai\KILL để ngắt toàn bộ AI Runner ngay lập tức" -ForegroundColor Gray
Write-Host " 2. Hủy toàn bộ lệnh chờ (Pending orders) trên tài khoản MT5" -ForegroundColor Gray
Write-Host " 3. Đóng ngay lập tức toàn bộ các vị thế đang mở để bảo vệ vốn tối đa" -ForegroundColor Gray
Write-Host "=================================================================" -ForegroundColor Red

$confirm = Read-Host "Bạn có chắc chắn muốn KÍCH HOẠT KILL-SWITCH? (Nhập 'y' để xác nhận)"
if ($confirm -ne "y") {
    Write-Host "`n[INFO] Đã hủy thao tác. Hệ thống không thay đổi.`n" -ForegroundColor Yellow
    Read-Host "Nhấn phím Enter để thoát"
    exit 0
}

Write-Host "`nĐang kích hoạt quy trình ngắt khẩn cấp..." -ForegroundColor Yellow
python -m ai_trade.runner --kill

Write-Host "`n=================================================================" -ForegroundColor Green
Write-Host " ✅ HỆ THỐNG ĐÃ ĐƯỢC NGẮT TOÀN DIỆN VÀ ĐÓNG SẠCH VỊ THẾ BẢO VỆ VỐN." -ForegroundColor Green
Write-Host " Để mở lại hệ thống sau khi kiểm tra, hãy chạy scripts\resume_trading.bat" -ForegroundColor Cyan
Write-Host "=================================================================`n" -ForegroundColor Green

Read-Host "Nhấn phím Enter để đóng cửa sổ"
