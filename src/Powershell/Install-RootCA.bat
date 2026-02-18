@echo off
:: Install Root CA Certificate - Requires Administrator privileges
:: This script must be run as Administrator

:: Check for admin privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Requesting Administrator privileges...
    powershell -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

:: Run the PowerShell script
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Install-RootCA.ps1"
pause
