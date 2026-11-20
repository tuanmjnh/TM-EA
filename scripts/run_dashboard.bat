@echo off
setlocal

rem Enable UTF-8 for Vietnamese diacritics
chcp 65001 >nul
set "PYTHONIOENCODING=utf-8"

cd /d "%~dp0\.."

title TM-EA AI Trade - BANG DIEU KHIEN VA DANH GIA GO-LIVE (PHASE 4)

python -m ai_trade.reporting.dashboard --sync --days 30

echo.
pause
endlocal
