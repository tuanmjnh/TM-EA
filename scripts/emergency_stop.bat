@echo off
chcp 65001 > nul
title TM-EA AI Trade - EMERGENCY KILL-SWITCH
echo =================================================================
echo  🛑 TM-EA AI TRADE — NÚT DỪNG KHẨN CẤP (EMERGENCY KILL-SWITCH)
echo =================================================================
echo  CẢNH BÁO: Thao tác này sẽ:
echo  1. Tạo file cờ vật lý config\ai\KILL để ngắt toàn bộ AI Runner
echo  2. Hủy toàn bộ lệnh chờ (Pending orders) trên tài khoản
echo  3. Đóng ngay lập tức toàn bộ các vị thế đang mở bảo vệ vốn
echo =================================================================
echo.

set /p confirm="Ban co chac chan muon KICH HOAT KILL-SWITCH? (y/n): "
if /i not "%confirm%"=="y" (
    echo Đã hủy thao tác.
    pause
    exit /b 0
)

cd /d "%~dp0\.."

python -m ai_trade.runner --kill

echo.
echo =================================================================
echo  🛑 HỆ THỐNG ĐÃ ĐƯỢC NGẮT HOÀN TOÀN VÀ ĐÓNG TOÀN BỘ VỊ THẾ.
echo  Để mở lại hệ thống sau khi kiểm tra, hãy chạy scripts\resume_trading.bat
echo =================================================================
pause
