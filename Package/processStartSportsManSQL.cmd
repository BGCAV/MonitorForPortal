@echo off
setlocal
    ::-- warm the local DNS cache before involving the Portal process
    call dnsResolutionCheckPeakSoftware.cmd
    if not %errorlevel% == 0 (
        endlocal
        exit /b 1
    )
    start "portal.exe" /B "%ProgramFiles(x86)%\Peak Software Systems\SportSQL\portal.exe"
    if not %errorlevel% == 0 (
        endlocal
        exit /b 1
    )
endlocal
exit /b 0