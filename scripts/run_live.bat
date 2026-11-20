@echo off
setlocal

rem Enable UTF-8 for Vietnamese diacritics
chcp 65001 >nul
set "PYTHONIOENCODING=utf-8"

cd /d "%~dp0\.."

title TM-EA AI Trade - LIVE FORWARD DEMO RUNNER

if exist "config\ai\KILL" (
    echo [CANH BAO KHAN CAP] Phat hien file co ngat: config\ai\KILL!
    echo He thong dang bi khoa an toan. Vui long chay scripts\resume_trading.bat de mo lai.
    echo.
    pause
    exit /b 1
)

python -m ai_trade.runner --mode live --symbol XAUUSDm --lot 0.01 --interval 30

pause
endlocal
