@echo off
title TM-EA AI Trade - GO-LIVE READINESS DASHBOARD
echo =================================================================
echo  TM-EA AI TRADE - BANG DIEU KHIEN VA DANH GIA GO-LIVE (PHASE 4)
echo =================================================================
echo.

cd /d "%~dp0\.."

python -m ai_trade.reporting.dashboard --sync --days 30

echo.
pause
