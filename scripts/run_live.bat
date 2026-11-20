@echo off
chcp 65001 > nul
title TM-EA AI Trade - LIVE FORWARD DEMO RUNNER
echo =================================================================
echo  TM-EA AI TRADE ORCHESTRATOR — LIVE FORWARD DEMO RUNNER (v5.2)
echo =================================================================
echo  Thực thi lệnh trực tiếp vào MT5 Exness Demo Cent (Khối lượng 0.01 lot)
echo  Quét tín hiệu: M5 London KZ Sweep ^& H1 Asian Breakout
echo  Rào chắn an toàn: Hard RiskGate 6 lớp, 0.25x Live Probing, Max Risk 2.0%%
echo =================================================================
echo.

cd /d "%~dp0\.."

if exist "config\ai\KILL" (
    echo [CANH BAO] Phat hien file config\ai\KILL dang duoc bat!
    echo Vui long kiem tra hoac chay scripts\resume_trading.bat truoc khi bat runner.
    pause
    exit /b 1
)

python -m ai_trade.runner --mode live --symbol XAUUSDm --lot 0.01 --interval 30

pause
