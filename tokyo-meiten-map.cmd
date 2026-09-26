@echo off
rem Tokyo Meiten Map launcher - double-click to run.
rem Starts a local web server (minimized window) and opens the app in your browser.
rem To stop the server, close the minimized "tokyo-meiten-map server" window.
cd /d "%~dp0"
if "%PORT%"=="" set PORT=8765
set URL=http://127.0.0.1:%PORT%/

rem If a server is already listening on this port, just open the browser.
netstat -ano | findstr /r /c:":%PORT% .*LISTENING" >nul
if %errorlevel%==0 goto open

set PY=python
where python >nul 2>nul || set PY=py
where %PY% >nul 2>nul || (
  echo Python was not found. Install it from https://www.python.org/
  pause
  exit /b 1
)
start "tokyo-meiten-map server (port %PORT%)" /min %PY% -m http.server %PORT% --bind 127.0.0.1
ping -n 2 127.0.0.1 >nul

:open
if "%NOBROWSER%"=="" start "" "%URL%"
echo Tokyo Meiten Map: %URL%
