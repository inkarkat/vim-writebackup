@echo off %debug%

if "%TEMP%" == "" exit /B 1
set testdir=%TEMP%\WriteBackupTest
if exist "%testDir%" (rmdir /S /Q "%testDir%")
mkdir "%testDir%" || exit /B 1

call unix /quiet
unzip "%~dp0testdata.zip" -d "%testDir%"

