@echo off
chcp 65001 > nul
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0run_live.ps1"
if %errorlevel% neq 0 pause
