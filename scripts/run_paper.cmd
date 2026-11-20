@echo off
setlocal

rem Enable UTF-8 for Vietnamese diacritics
chcp 65001 >nul
set "PYTHONIOENCODING=utf-8"

cd /d "%~dp0\.."

title TM-EA AI Trade - PAPER FORWARD DEMO RUNNER

python -m ai_trade.runner --mode paper --symbol XAUUSDm --interval 30

pause
endlocal
