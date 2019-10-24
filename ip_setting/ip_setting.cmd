@cls
@echo off

set current=%~dp0
set datadir=%current%data\

for /f "tokens=*" %%a in ('whoami /groups ^| findstr /c:"Mandatory Label\High Mandatory Level"') do set runas=0

if not "%runas%"=="0" (
start /min powershell start-process -Verb "RunAs" -FilePath '%~dp0%~nx0'
exit
)

powershell -ExecutionPolicy RemoteSigned -File "%datadir%ip_setting.ps1"
exit
