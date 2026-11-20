@echo off
setlocal

rem Enable UTF-8 for Vietnamese diacritics
chcp 65001 >nul
set "PYTHONIOENCODING=utf-8"

cd /d "%~dp0\.."

title TM-EA AI Trade - EMERGENCY KILL-SWITCH

echo =================================================================
echo  [STOP] TM-EA AI TRADE - NUT DUNG KHAN CAP (EMERGENCY KILL-SWITCH)
echo =================================================================
echo  CANH BAO: Thao tac nay se:
echo  1. Tao file co vat ly config\ai\KILL de ngat toan bo AI Runner
echo  2. Huy toan bo lenh cho (Pending orders) tren tai khoan
echo  3. Dong ngay lap tuc toan bo cac vi the dang mo bao ve von
echo =================================================================
echo.

set /p confirm="Ban co chac chan muon KICH HOAT KILL-SWITCH? (Nhap 'y' de xac nhan): "
if /i not "%confirm%"=="y" (
    echo Da huy thao tac. He thong khong thay doi.
    pause
    exit /b 0
)

echo.
echo Dang kich hoat ngat khan cap...
python -m ai_trade.runner --kill

echo.
echo =================================================================
echo  HE THONG DA DUOC NGAT TOAN DIEN VA DONG SACH VI THE BAO VE VON.
echo  De mo lai he thong, hay chay scripts\resume_trading.bat
echo =================================================================
pause
endlocal
