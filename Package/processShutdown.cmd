@echo off
::-----------------------------------------------------------------------------
::--
::--  Purpose
::--    Attempt to gracefully shutdown windows process, however, if it won't,
::--    after a certain number of attempts/elapsed time, then forceably
::--    terminate it.
::--
::--  In
::--    %1 - (required) processID to close.
::--    %2 - (optional) Timeout in seconds to wait for for graceful termination
::--         after which the process will be forceably killed.  Default 300sec=5min
::--
::--  Out
::--    Writes log file messages to SYSOUT.
::
::-----------------------------------------------------------------------------
setlocal
    if "%~1" == "" (
        call :log "Error: processID to close not specified"
        exit /b 1
    )
    set PROCESS_ID=%~1
    set TIMEOUT_GRACEFUL_SEC=300
    if not "%~2" == "" (
        set TIMEOUT_GRACEFUL_SEC=%~2
    )
    call :log "Info: Attempting to gracefully terminate processID=%PROCESS_ID%"
    call :processShutdownGraceful %PROCESS_ID% %TIMEOUT_GRACEFUL_SEC%
    if  %errorlevel% == 0 (
        call :log "Info: Successful graceful termination of processID=%PROCESS_ID%"
        exit /b 0
    )
    call :log "Error: unable to gracefully terminate processID=%PROCESS_ID% after graceful timeout:%TIMEOUT_GRACEFUL_SEC%"
    call :log "Info: Attempting to foreably terminate processID=%PROCESS_ID%"
    call :processShutdownForce %PROCESS_ID%
    if %errorlevel% == 0 (
        call :log "Info: Successful forced termination of processID=%PROCESS_ID%"
        exit /b 0
    )
    call :log "Error: unable to forceablly terminate processID=%PROCESS_ID%"
    call :errorRTNcd
endlocal
exit /b


:processShutdownGraceful:
setlocal
    set PROCESS_ID=%~1
    set TIMEOUT_GRACEFUL_SEC=%~2
    set MONITOR_INTERVAL_SEC=3
    taskkill /PID %PROCESS_ID% 2>&1
    if not %errorlevel% == 0 (
        :: unable to send close signal to process
        endlocal
        exit /b 1
    )    
    :: Successfully received signal to close did it really close?
    call :processMonitorClose %PROCESS_ID% %MONITOR_INTERVAL_SEC% %TIMEOUT_GRACEFUL_SEC%
endlocal
exit /b 


:processMonitorClose:
setlocal
    set PROCESS_ID=%~1
    set MONITOR_INTERVAL_SEC=%~2
    if %MONITOR_INTERVAL_SEC% LSS 1 (
        set MONITOR_INTERVAL_SEC=3
    )
    set /A MONITOR_INTERVAL_TIMEOUT_SEC=%~3 - %MONITOR_INTERVAL_SEC%
    :retryMonitor
    timeout /NOBREAK /T %MONITOR_INTERVAL_SEC%
    tasklist /FO LIST /FI "PID eq %PROCESS_ID%" | findstr /b /r /c:"PID: *%PROCESS_ID%$" > nul
    if not %errorlevel% == 0 (
        :: Process ID not found - assumed terminated.
        endlocal
        exit /b 0
    )
    if %MONITOR_INTERVAL_TIMEOUT_SEC% LSS 1 (
        endlocal
        exit /b 1
    )
    if %MONITOR_INTERVAL_TIMEOUT_SEC% LSS %MONITOR_INTERVAL_SEC% (
       set /A MONITOR_INTERVAL_SEC=%MONITOR_INTERVAL_TIMEOUT_SEC%
       set MONITOR_INTERVAL_TIMEOUT_SEC=0
       goto :retryMonitor  
    )
    set /A MONITOR_INTERVAL_TIMEOUT_SEC=%MONITOR_INTERVAL_TIMEOUT_SEC% - %MONITOR_INTERVAL_SEC%
goto :retryMonitor


:processShutdownForce:
setlocal
    set PROCESS_ID=%~1
    taskkill /F /PID %PROCESS_ID% 2>&1
endlocal
exit /b 


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


:errorRTNcd:
exit /b 1