@echo off
setlocal
cd /d "%~dp0"
"%~dp0GSCS.exe" --configure-node --data-root "%LOCALAPPDATA%\GSCS-Node"
if errorlevel 1 goto error
"%~dp0GSCS.exe" --data-root "%LOCALAPPDATA%\GSCS-Node"
:error
if errorlevel 1 pause
