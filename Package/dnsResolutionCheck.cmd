@echo off
::-----------------------------------------------------------------------------
::--
::--  Purpose
::--    Insure network viability by querying well known IP & DNS.  IP verifies
::--    TCP/IP connectivity while DNS request exersizes domain resolution.
::--
::--  In
::--    %1 URL to resolve.
::--
::--  Out
::--    Writes log file messages to SYSOUT.
::--
::-----------------------------------------------------------------------------
setlocal
    if "%1" == "" (
        call :log "Error: URL not specified"
        exit /b 1
    )
    set URL_TO_RESOLVE=%1
    ::-- use google dns server as well known IP
    set WELL_KNOWN_PING=8.8.8.8
    call :netviable "%WELL_KNOWN_PING%" "%URL_TO_RESOLVE%"
    if not %errorlevel% == 0 (
        call :log "Error: Network not viable."
        endlocal
        exit /b 1
    )
endlocal
exit /b 0

:netviable:
setlocal
    set PING_IP=%~1
    set URL_TO_RESOLVE=%~2
    ping -n 3 %PING_IP% >nul
    if %ERRORLEVEL% == 0 (
        set PING_STATUS=successful
    ) else (
        set PING_STATUS=failed
    )
    call :log "ping to IP='%PING_IP%' status='%PING_STATUS%'"
    ping -n 3 %URL_TO_RESOLVE% >nul
    if %ERRORLEVEL% == 0 (
        set PING_STATUS=successful
    ) else (
        set PING_STATUS=failed
    )
    call :log "ping to URL='%URL_TO_RESOLVE%' status='%PING_STATUS%'"
    if not "%PING_STATUS%" == "successful" (
        endlocal
        exit /b 1
    ) 
endlocal
exit /b 0

:log:
setlocal
    set LOG_TIME=%TIME%
    if "%LOG_TIME:~0,1%" == " " (
        :: ensure hour format "NN:" not " N:"
        set LOG_TIME=0%LOG_TIME:~1%
    )
    echo %DATE:~4% %LOG_TIME%: msg=%1%2%3%4%5%6%7%8%9
endlocal
exit /b
