@echo off
setlocal
cd /d "%~dp0"
title DEEPDSP-AMC Demo App

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0run_app.ps1"
if errorlevel 1 (
  echo.
  echo [ERROR] DEEPDSP-AMC could not start. Review the message above.
  pause
)
