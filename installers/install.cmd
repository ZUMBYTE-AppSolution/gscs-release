@echo off
setlocal
set "GSCS_INSTALL_SCRIPT=%~dp0install.ps1"
powershell.exe -NoProfile -Command "& ([scriptblock]::Create([IO.File]::ReadAllText($env:GSCS_INSTALL_SCRIPT)))"
if errorlevel 1 pause
