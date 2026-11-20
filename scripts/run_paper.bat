@echo off
title TM-EA AI Trade - PAPER FORWARD DEMO RUNNER
echo =================================================================
echo  TM-EA AI TRADE ORCHESTRATOR - PAPER FORWARD DEMO RUNNER (v5.2)
echo =================================================================
echo  Che do mo phong ao (Virtual Paper Trading):
echo  - Quet nen real-time tu MT5
echo  - Hoi dong AI phan xu va ra quyet dinh
echo  - Kiem duyet qua Hard RiskGate
echo  - Ghi log ao vao data\results.db (KHONG VAO LENH THAT)
echo =================================================================
echo.

cd /d "%~dp0\.."

python -m ai_trade.runner --mode paper --symbol XAUUSDm --interval 30

pause
