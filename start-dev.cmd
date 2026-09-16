@echo off
setlocal
cd /d "%~dp0"
for /d %%D in ("%~dp0.tools\node-*-win-x64") do set "PATH=%%~fD;%PATH%"
where npm.cmd >nul 2>nul
if errorlevel 1 (
  echo Please install Node.js 22.12+ with npm, then reopen this script.
  pause
  exit /b 1
)
if not exist node_modules (
  call npm.cmd install
  if errorlevel 1 (
    pause
    exit /b 1
  )
)
call npm.cmd run dev
pause
