@echo off
chcp 65001 > nul
title TM-EA AI Trade - RESUME TRADING
echo =================================================================
echo  TM-EA AI TRADE — MỞ LẠI HỆ THỐNG GIAO DỊCH
echo =================================================================
echo.

cd /d "%~dp0\.."

if exist "config\ai\KILL" (
    del /f /q "config\ai\KILL"
    echo [OK] Đã xóa file cờ config\ai\KILL.
) else (
    echo [INFO] File config\ai\KILL không tồn tại. Hệ thống đang ở trạng thái bình thường.
)

python -c "from ai_trade.core.watchdog import SystemWatchdog; w = SystemWatchdog(); w.pulse('RESUMED', {'action': 'manual_resume'}); print('[OK] Đã phát xung nhịp Watchdog RESUMED.')"

echo.
echo Hệ thống đã sẵn sàng. Bạn có thể bật lại runner bằng scripts\run_live.bat hoặc scripts\run_paper.bat.
echo.
pause
