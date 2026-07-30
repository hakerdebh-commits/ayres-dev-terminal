@echo off
setlocal
chcp 65001 >nul
title AYRES DEV TERMINAL 4.2
set "AYRES_SCRIPT=%~dp0AYRES-TERMINAL.ps1"

where pwsh.exe >nul 2>&1
if %errorlevel% equ 0 (
    pwsh.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%AYRES_SCRIPT%"
) else (
    powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%AYRES_SCRIPT%"
)

if errorlevel 1 (
    echo.
    echo O Ayres Dev foi encerrado com erro.
    pause
)
endlocal
