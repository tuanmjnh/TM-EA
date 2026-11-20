@echo off
title TM-EA AI Trade - RESUME TRADING
echo =================================================================
echo  TM-EA AI TRADE - MO LAI HE THONG GIAO DICH
echo =================================================================
echo.

cd /d "%~dp0\.."

if exist "config\ai\KILL" (
    del /f /q "config\ai\KILL"
    echo [OK] Da xoa file co config\ai\KILL.
) else (
    echo [INFO] File config\ai\KILL khong ton tai. He thong dang binh thuong.
)

python -c "from ai_trade.core.watchdog import SystemWatchdog; w = SystemWatchdog(); w.pulse('RESUMED', {'action': 'manual_resume'}); print('[OK] Da phat xung nhip Watchdog RESUMED.')"

echo.
echo He thong da san sang. Ban co the bat lai runner bang scripts\run_live.bat
echo.
pause
