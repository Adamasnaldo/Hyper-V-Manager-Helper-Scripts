@echo off

@chcp 65001

echo Starting powershell with admin privileges in "%~dp0"...
powershell.exe -WindowStyle Normal -ExecutionPolicy Unrestricted Start-Process powershell.exe -Verb RunAs -ArgumentList '-NoExit', '-Command', 'cd "%~dp0"'