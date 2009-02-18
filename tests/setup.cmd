@echo off %debug%

if "%TEMP%" == "" exit /B 1
set testdir=%TEMP%\WriteBackupTest
if exist "%testDir%" (rmdir /S /Q "%testDir%")
mkdir "%testDir%

xcopy /E "%~dp0testdata\*" "%testDir%"

