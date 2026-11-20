@echo off
chcp 65001 > nul
title TM-EA AI Trade - PAPER FORWARD DEMO RUNNER
echo =================================================================
echo  TM-EA AI TRADE ORCHESTRATOR — PAPER FORWARD DEMO RUNNER (v5.2)
echo =================================================================
echo  Chế độ phân tích mô phỏng ảo:
echo  - Quét nến real-time từ MT5
echo  - Hội đồng AI phân xử và ra quyết định
echo  - Kiểm duyệt qua Hard RiskGate
echo  - Ghi log ảo vào data\results.db (KHÔNG VÀO LỆNH THẬT)
echo =================================================================
echo.

cd /d "%~dp0\.."

python -m ai_trade.runner --mode paper --symbol XAUUSDm --interval 30

pause
