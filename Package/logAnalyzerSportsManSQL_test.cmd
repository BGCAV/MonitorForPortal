@echo off
::-----------------------------------------------------------------------------
::--
::--  Purpose
::--    Test logAnalyzerSportsManSQL.cmd through its public interface.
::--
::-----------------------------------------------------------------------------
setlocal
    set RANDOM_LOG_ENTRY_GEN="%~1"

    if /i "%~1" == "RANDOM_ENTRY" (
        call :testRandom "%~2"
        exit /b
    )
call :testDeterministic
exit /b 1


:testRandom:
setlocal
    set LOG_FILEPATH=%~1
    
    set /A SITUATION_CHOICE=%RANDOM% %%3
    goto :logEntryGen%SITUATION_CHOICE%
    :logEntryGen0:
        :: Normal execution - no log message generated
        endlocal
        exit /b 0
    :logEntryGen1:
        call :logTimeSimulateNow LOG_TIME
        call :logDateSimulateNow LOG_DATE
        set "LOG_ENTRY=%LOG_DATE% %LOG_TIME% Error 1429 The remote Host address is invalid (0.0.0.0) module init line #285"
    goto :logEntryWrite
    :logEntryGen2:
        call :logTimeSimulateNow LOG_TIME
        call :logDateSimulateNow LOG_DATE
        set "LOG_ENTRY=%LOG_DATE% %LOG_TIME% New log entry - unknown action"
    goto :logEntryWrite

    :logEntryWrite:
    echo %LOG_ENTRY%>>"%LOG_FILEPATH%"
endlocal
exit /b 0


:testDeterministic:
setlocal

    set "RELEVANT_INCONCLUSIVE=sportsManSQLAnalyzer.cmd.Test.Files\__tempRelevant_Inconclusive"
    call :logTimeSimulateNow LOG_TIME
    call :logDateSimulateNow LOG_DATE
    echo %LOG_DATE% %LOG_TIME% Relevant log ok>"%RELEVANT_INCONCLUSIVE%"
    call :testExpect-2Capture logAnalyzerSportsManSQL.cmd 1234 "%RELEVANT_INCONCLUSIVE%"
    if not %errorlevel% == 0 (
        endlocal
        exit /b 1
    )
    del "%RELEVANT_INCONCLUSIVE%">nul
    set RELEVANT_INCONCLUSIVE=
exit /b

    call :testExpect0Capture logAnalyzerSportsManSQL.cmd "sportsManSQLAnalyzer.cmd.Test.Files\LogNewIndicatesOK"
    if not %errorlevel% == 0 (
        endlocal
        exit /b 1
    )
    call :testExpect0Capture logAnalyzerSportsManSQL.cmd "sportsManSQLAnalyzer.cmd.Test.Files\LogNotRelevant"
    if not %errorlevel% == 0 (
        endlocal
        exit /b 1
    )
    set "RELEVANT_INCONCLUSIVE=sportsManSQLAnalyzer.cmd.Test.Files\__tempRelevant_Inconclusive"
    call :logTimeSimulateNow LOG_TIME
    call :logDateSimulateNow LOG_DATE
    echo %LOG_DATE% %LOG_TIME% Relevant log ok>"%RELEVANT_INCONCLUSIVE%"
    call :testExpect-2Capture logAnalyzerSportsManSQL.cmd "%RELEVANT_INCONCLUSIVE%"
    if not %errorlevel% == 0 (
        endlocal
        exit /b 1
    )
    del "%RELEVANT_INCONCLUSIVE%">nul
    set RELEVANT_INCONCLUSIVE=

    set "RELEVANT_RESTART=sportsManSQLAnalyzer.cmd.Test.Files\__tempRelevant_RESTART"
    call :logTimeSimulateNow LOG_TIME
    call :logDateSimulateNow LOG_DATE
    echo %LOG_DATE% %LOG_TIME% Error 1429 The remote Host address is invalid (0.0.0.0) module init line #285>"%RELEVANT_RESTART%"
    call :testExpect-1Capture  logAnalyzerSportsManSQL.cmd "%RELEVANT_RESTART%"
    if not %errorlevel% == 0 (
        endlocal
        exit /b 1
    )
    del "%RELEVANT_RESTART%">nul
    set RELEVANT_RESTART=
endlocal
exit /b 0


:logDateSimulateNow:
setlocal
    set LOG_DATE_RTN=%~1
(
endlocal
set %LOG_DATE_RTN%=%DATE:~4%
)
exit /b 0

:logTimeSimulateNow:
setlocal
    set LOG_TIME_RTN=%~1

    for /F "delims=" %%t in ('time /t') do set LOG_TIME=%%t
    set LOG_TIME=%LOG_TIME:~0,5%%TIME:~5,3%%LOG_TIME:~5%
(
endlocal
set %LOG_TIME_RTN%=%LOG_TIME%
)
exit /b 0


:testExpect0Capture:
    :: no setlocal - need side effects to return appropriate values
    call %*
    if not %errorlevel% == 0 (
        echo Test failure during: call %*>&2
        exit /b 1
    )
exit /b 0


:testExpectErrorCapture:
    :: no setlocal - need side effects to return appropriate values
    call %*
    if %errorlevel% == 0 (
        echo Test failure during: call %*>&2
        exit /b 1
    )
exit /b 0


:testExpect-1Capture:
   :: no setlocal - need side effects to return appropriate values
   :: restart needed
    call %*
    if not %errorlevel% == -1 (
        echo Test failure during: call %*>&2
        exit /b 1
    )
exit /b 0


:testExpect-2Capture:
   :: no setlocal - need side effects to return appropriate values
   :: a relevant log entry but not a definite retry
    call %*
    if not %errorlevel% == -2 (
        echo Test failure during: call %*>&2
        exit /b 1
    )
exit /b 0


:assert
setlocal

    if %* (
        endlocal
        exit /b 0  
    ) 
    echo Assert failed: %*
endlocal
exit /b 1