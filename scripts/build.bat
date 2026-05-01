@echo off
setlocal

set "SCRIPT_DIR=%~dp0"
set "PS1_SCRIPT=%SCRIPT_DIR%build.ps1"

if not exist "%PS1_SCRIPT%" (
  echo Missing PowerShell wrapper: "%PS1_SCRIPT%" 1>&2
  exit /b 1
)

where pwsh >nul 2>nul
if %ERRORLEVEL% EQU 0 (
  pwsh -NoProfile -ExecutionPolicy Bypass -File "%PS1_SCRIPT%" %*
  exit /b %ERRORLEVEL%
)

where powershell >nul 2>nul
if %ERRORLEVEL% EQU 0 (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1_SCRIPT%" %*
  exit /b %ERRORLEVEL%
)

echo PowerShell was not found in PATH. Install PowerShell or run scripts\build.sh from Git Bash/WSL. 1>&2
exit /b 1