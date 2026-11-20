@echo off
setlocal

rem Enable UTF-8 for Vietnamese diacritics
chcp 65001 >nul
set "PYTHONIOENCODING=utf-8"

cd /d "%~dp0\.."

title TM-EA AI Trade - MO LAI HE THONG GIAO DICH

if exist "config\ai\KILL" (
    del /f /q "config\ai\KILL"
    echo [OK] Da xoa file co khap cap config\ai\KILL.
) else (
    echo [INFO] File config\ai\KILL khong ton tai. He thong dang o trang thai binh thuong.
)

python -c "from ai_trade.core.watchdog import SystemWatchdog; w = SystemWatchdog(); w.pulse('RESUMED', {'action': 'manual_resume'}); print('[OK] Da phat xung nhip Watchdog RESUMED.')"

echo.
echo He thong da san sang. Ban co the bat lai runner bang scripts\run_live.cmd
echo.
pause
endlocal
