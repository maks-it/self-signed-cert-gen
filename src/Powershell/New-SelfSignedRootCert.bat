@echo off
powershell -ExecutionPolicy Bypass -File "%~dp0New-SelfSignedRootCert.ps1"
pause
