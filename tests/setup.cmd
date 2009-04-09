@echo off %debug%

if "%TEMP%" == "" exit /B 1
set testdir=%TEMP%\WriteBackupTest
if exist "%testDir%" (rmdir /S /Q "%testDir%")
mkdir "%testDir%" || exit /B 1

xcopy /E "%~dp0testdata\*" "%testDir%"

