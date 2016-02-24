@echo off %debug%
setlocal enableextensions

call unix /quiet
set testdir=%TEMP%\WriteBackupTest
pushd "%testdir%"
for /F "delims=" %%f in ('find .^|sed "s/%%/^%%%%/g"') do call :listfile "%%f"
popd
(goto:EOF)

:listfile
:: Backups from the years 1999, 2006-2008 belong to the testdata and are not
:: canonicalized. 
echo.%~1|sed -e "/\.1999[0-9][0-9][0-9][0-9]/n" -e "/\.200[6-8][0-9][0-9][0-9][0-9]/!s+\.[12][0-9][0-9][0-9][0-9][0-9][0-9][0-9]+.XXXXXXXX+g"
set filespec=%~1
set filespec=%filespec:^^=%
if not exist "%filespec%\" (
    head -n 1 "%filespec%"|sed "s/^/    -> /"
) else (
    echo.    [DIRECTORY]
)
(goto:EOF)

endlocal
