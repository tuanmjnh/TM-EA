@echo off
title TM-EA AI Trade - LIVE FORWARD DEMO RUNNER
echo =================================================================
echo  TM-EA AI TRADE ORCHESTRATOR - LIVE FORWARD DEMO RUNNER (v5.2)
echo =================================================================
echo  Executing live demo orders on MT5 Exness (Fixed 0.01 lot)
echo  Scanning setups: M5 London KZ Sweep and H1 Asian Breakout
echo  Safety: Hard RiskGate 6 layers, 0.25x Live Probing, Max Risk 2.0%%
echo =================================================================
echo.

cd /d "%~dp0\.."

if exist "config\ai\KILL" (
    echo [CANH BAO] Phat hien file config\ai\KILL dang duoc bat!
    echo Vui long chay scripts\resume_trading.bat de mo lai he thong.
    pause
    exit /b 1
)

python -m ai_trade.runner --mode live --symbol XAUUSDm --lot 0.01 --interval 30

pause
