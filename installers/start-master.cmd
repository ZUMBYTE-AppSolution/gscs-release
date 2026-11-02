@echo off
setlocal
cd /d "%~dp0"
"%~dp0GSCS.exe" --configure-portable --data-root "%LOCALAPPDATA%\GSCS"
if errorlevel 1 goto error
"%~dp0GSCS.exe" --data-root "%LOCALAPPDATA%\GSCS"
:error
if errorlevel 1 pause
