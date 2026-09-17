@echo off
chcp 65001 >nul
title MedicalGraph Local Server Launcher
cd /d "%~dp0"

REM ============================================================
REM  Auto-select a working way to serve this folder:
REM   1) py launcher (recommended, when real Python is installed)
REM   2) real python (skip the Microsoft Store stub)
REM   3) built-in PowerShell server (no Python needed, fallback)
REM ============================================================

REM 1) py launcher: make sure it finds a registered Python first
where py >nul 2>nul
if not errorlevel 1 (
  py -0p >nul 2>nul
  if not errorlevel 1 (
    echo [1/3] Starting server with py ...
    start "MedicalGraph-Server" py -m http.server 8000
    goto opened
  )
)

REM 2) real python: skip the Store stub located under WindowsApps
where python >nul 2>nul
if not errorlevel 1 (
  for /f "delims=" %%i in ('where python') do set "PY_PATH=%%i"
  echo %PY_PATH%| findstr /i "WindowsApps" >nul
  if errorlevel 1 (
    echo [2/3] Starting server with python ...
    start "MedicalGraph-Server" python -m http.server 8000
    goto opened
  )
)

REM 3) built-in PowerShell server (no Python required)
echo [3/3] No usable Python found, using built-in PowerShell server ...
start "MedicalGraph-Server" powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0server.ps1"
goto opened

:opened
timeout /t 2 /nobreak >nul
start "" "http://localhost:8000/index.html"
echo Server is running: http://localhost:8000/  (close the black window to stop)
exit /b
