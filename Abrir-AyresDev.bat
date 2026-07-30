@echo off
setlocal
chcp 65001 >nul
title AYRES DEV MASKED CONTROL 4.2.5
set "AYRES_SCRIPT=%~dp0AYRES-PAINEL.ps1"

where pwsh.exe >nul 2>&1
if %errorlevel% equ 0 (
    pwsh.exe -NoLogo -NoProfile -STA -ExecutionPolicy Bypass -File "%AYRES_SCRIPT%"
) else (
    powershell.exe -NoLogo -NoProfile -STA -ExecutionPolicy Bypass -File "%AYRES_SCRIPT%"
)

if errorlevel 1 (
    echo.
    echo O Ayres Dev foi encerrado com erro.
    pause
)
endlocal
