@echo off 
::-----------------------------------------------------------------------------
::--
::--  Purpose
::--    Monitor the execution of a process.
::--    - If process not running start it
::--    - If process log suggests failure:
::--      - Attempt to gracefully close process
::--      - If process won't gracefully close, forceably terminate it.
::--
::--  In
::--    %1 - (required) program name
::--    %2 - (required) FilePathName to startup program which launches program name.
::--          Remember Windows searches current directory before examining PATH.
::--          Suggest using Windows "start" for GUI programs or CMD for command line ones.
::--    %3 - (optional) FilePathName to Log Analyzer for program.  Log Analyzer 
::--         determines subsequent action if any.  An errorlevel of: 
::--            1 - analyzer failed - do nothing
::--            0 - program execution normal - do nothing.
::--           -1 - program impared, try restarting.
::--           -2 - unable to determine next course of action - do nothing.
::--         Encode a value of "" if other parameters need be specified after
::--         this one and there is no Log Analyzer.
::--    %4 - (optional) Graceful shutdown timeout - an interval, specified in
::--         seconds, to wait for a process to gracefully shutdown, before
::--         forceing its shutdown. Default is 300sec=5min.
::--
::--  Out
::--    Writes log file messages to SYSOUT.
::--
::-----------------------------------------------------------------------------
setlocal EnableDelayedExpansion
    set PROGRAM_NAME=%~1
    set PROGRAM_START_FILEPATH=%~2
    set LOG_ANALYZER=%~3
    set SHUTDOWN_GRACEFUL_TIMEOUT_SEC=%~4

    if "%PROGRAM_NAME%" == "" (
        call :log "Error: program name not specified."
        endlocal
        exit /b 1
    )
    if not exist "%PROGRAM_START_FILEPATH%" (
        call :log "Error: Unable to locate start program='%PROGRAM_START_FILEPATH%'"
        endlocal
        exit /b 1
    )
    call :programMonitor "%PROGRAM_NAME%" "%PROGRAM_START_FILEPATH%" PROCESS_ID
    if "%LOG_ANALYZER%" == "" (
        call :log "Info: program="%PROGRAM_NAME%" log analyzer not specified, therefore, cannot determine action to execute."
        endlocal
        exit /b 0
    )
    if not exist "%LOG_ANALYZER%" (
        call :log "Error: Log analyzer specified but unable to locate it='%LOG_ANALYZER%'"
        endlocal
        exit /b 1
    )
    call :log "Info: program='%PROGRAM_NAME%' attempting to run log analyzer='%LOG_ANALYZER%'"
    cmd /C %LOG_ANALYZER% "%PROCESS_ID%"
    if %errorlevel% == 0 (
        call :log "Info: program='%PROGRAM_NAME%' log analyzer='%LOG_ANALYZER%' recommends nothing to do at this time."
        endlocal
        exit /b 0
    )
    if %errorlevel% GTR 0 (
        call :log "Error: program='%PROGRAM_NAME%' log analyzer='%LOG_ANALYZER%' failed."
        endlocal
        exit /b 1
    )
    if %errorlevel% == -1 (
        call :log "Info: program='%PROGRAM_NAME%' log analyzer='%LOG_ANALYZER%' suggests reboot."
        if "%SHUTDOWN_GRACEFUL_TIMEOUT_SEC%" == "" (
            set SHUTDOWN_GRACEFUL_TIMEOUT_SEC=300
        )
        call :processRestart "%PROCESS_ID%" "%PROGRAM_START_FILEPATH%" "!SHUTDOWN_GRACEFUL_TIMEOUT_SEC!"
        if !errorlevel! == 0 (
            call :log "Info: program='%PROGRAM_NAME%' successfully restarted."
            endlocal
            exit /b 0
        )
    )
    call :log "Error: program='%PROGRAM_NAME%' log analyzer='%LOG_ANALYZER%' cannot determine course of action"
endlocal
exit /b 1


:programMonitor:
setlocal
    set PROGRAM_NAME=%~1
    set PROGRAM_START_FILEPATH=%~2
    set PROCESS_ID_RTN=%~3

    call :programToProcessID "%PROGRAM_NAME%" PROCESS_ID
    if %errorlevel% == 0 (
        goto programMonitorRunning
    )
    call :log "Info: program='%PROGRAM_NAME%' started by='%PROGRAM_START_FILEPATH%' not running.  Attempting to start"
    call :processStart "%PROGRAM_START_FILEPATH%"
    if not %errorlevel% == 0 (
        call :log "Error: Unable to start program='%PROGRAM_NAME%'."
        endlocal
        exit /b 1
    )
    call :programToProcessID "%PROGRAM_NAME%" PROCESS_ID
    if not !errorlevel! == 0 (
        call :log "Error: program='%PROGRAM_NAME%' seemed to start but unable to determine PROCESS_ID."
        endlocal
        exit /b 1
    )
    call :log "Info: program='%PROGRAM_START_FILEPATH%' successfully started."
    :programMonitorRunning:
(
endlocal
set %PROCESS_ID_RTN%=%PROCESS_ID%
)
exit /b 0

:programToProcessID:
setlocal
    set PROCESS_NAME=%~1
    set PROCESS_ID_RTN=%~2
    set PROCESS_CNT=0
    :: csv format is ideal to pass parameters in batch.  quoted input
    :: enables names with spaces while commas are treated as delimiters
    :: between arguments.
    for /f "tokens=*" %%o in ( 'tasklist /FO csv /NH /FI "ImageName eq %PROCESS_NAME%"') do call :taskParse PROCESS_ID PROCESS_CNT  %%o 
    if not %errorlevel% == 0 (
        endlocal
        exit /b 1
    )
    if %PROCESS_CNT% GTR 1 (
        :: more than one instance - don't know how to handle
        endlocal
        exit /b 1
    )
    if "%PROCESS_ID%" == "" (
        endlocal
        exit /b 1
    )
(
endlocal
set %PROCESS_ID_RTN%=%PROCESS_ID%
)
exit /b 0


:taskParse:
setlocal
    if not %errorlevel% == 0 (
        exit /b 1
    )
    set PROCESS_ID_RTN=%~1
    set PROCESS_CNT_RTN=%~2
    set PROCESS_NAME=%~3
    set PROCESS_ID=%~4
    
    if "%PROCESS_NAME%" == "INFO:"  (
        exit /b 1
    )
    call :substituteAgain set /A PROCESS_CNT_IT=%%%PROCESS_CNT_RTN%%% + 1
(   
endlocal
set %PROCESS_ID_RTN%=%PROCESS_ID%
set %PROCESS_CNT_RTN%=%PROCESS_CNT_IT%
)
exit /b 0


:processRestart:
setlocal
    set PROCESS_ID=%~1
    set PROCESS_START_FILEPATH=%~2
    set SHUTDOWN_GRACEFUL_TIMEOUT_SEC=%~3
    call processShutdown.cmd "%PROCESS_ID%" "%SHUTDOWN_GRACEFUL_TIMEOUT_SEC%"
        if not %errorlevel% == 0 (
        endlocal
        exit /b 1
    )
    call :processStart "%PROCESS_START_FILEPATH%"
    if not %errorlevel% == 0 (
        endlocal
        exit /b 1
    )
endlocal
exit /b 0


:processStart:
setlocal
    call %1
    if not %errorlevel% == 0 (
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


:errorRTNcd:
exit /b 1


::-- Applies variable substitution one more time before executing the command.
::-- Allows variables to contain other variable references that can then be
::-- dereferenced.
:substituteAgain:
%*
exit /b