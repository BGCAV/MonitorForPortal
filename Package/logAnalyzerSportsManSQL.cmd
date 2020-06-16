@echo off
::-----------------------------------------------------------------------------
::--
::--  Purpose
::--    Reviews recent SportsManSQL's Portal log entries to determine if 
::--    the process is running normally or could benefit from restarting.
::--
::--  In
::--    %1 - (required) Framework provides process id of running instance.
::--         However, this valuen isn't important to identifying the correct
::--         log for SportsManSQL.  Note argument value can be "test".  When
::--         so run tests on private functions.
::--    %2 - (optional) Log Pathfile name written to by the Portal process.
::--         Default: %ProgramFiles(x86)%\Peak Software Systems\SportSQL\Portal.ERR
::--    %3 - (optional) Relavent Interval expressed in seconds.  The maximum
::--         elapsed interval between the generation of a log file entry and
::--         and the current time.  Log entries within this interval are
::--         considered when determining the recommended action.
::--         Default: 10sec
::--    Running without specifying any arguments runs unit tests.
::--
::--  Out
::--    %errorlevel% - Recommended actions are defined and performed by
::--       "processMonitorRunning.cmd". At the time of this module's last commit
::--       the errorlevel returned by this component had to return the following:
::--          1 - analyzer failed - do nothing
::--          0 - program execution normal - do nothing.
::--         -1 - program impared, try restarting.
::--         -2 - unable to determine next course of action - do nothing.
::--    SYSOUT - log messages.  Perhaps they should also be
::--       consumed as feedback.
::--
::-----------------------------------------------------------------------------
setlocal
    :: Global Constants:
    set REGEX_MM_DD_YYYY=[0-1][0-9].[0-3][0-9].[2][0-9][0-9][0-9]
    set REGEX_HH_MM_SS=[0-2][0-9]:[0-5][0-9]:[0-5][0-9]
    set REGEX_HH_MM_SS_XM=%REGEX_HH_MM_SS%..M
    if "%~1" == "test" (
        :: run function level tests
        call :testRun
        exit /b
    )
    set LOG_PATHFILE_NAME=%~2
    if "%LOG_PATHFILE_NAME%" == "" (
        :: use set "varname=varvalue" when good chance varvalue will have ()s or other special batch characters 
        set "LOG_PATHFILE_NAME=%ProgramFiles(x86)%\Peak Software Systems\SportSQL\Portal.ERR"
    )
    if not exist "%LOG_PATHFILE_NAME%" (
        call :log "Error: Log file='%LOG_PATHFILE_NAME%' missing or inaccessible due to permissions."
        endlocal
        exit /b 1
    )
    set INTERVAL_RELEVANT_SEC=%~3
    if "%INTERVAL_RELEVANT_SEC%" == "" (
        set INTERVAL_RELEVANT_SEC=10
    )
    call :logNoError "%LOG_PATHFILE_NAME%"
    if %errorlevel% == 0 (
        endlocal
        exit /b 0
    )
    call :logEntryRecentMostValid "%LOG_PATHFILE_NAME%" LOG_ENTRY LOG_DATE LOG_TIME
    if not %errorlevel% == 0 (
        endlocal
        exit /b -2
    )
    set TIME_OF_REVIEW=%TIME:~0,8%
    if "%TIME_OF_REVIEW:~0,1%" == " " (
        :: ensure hour format "NN:" not " N:"
        set TIME_OF_REVIEW=0%TIME_OF_REVIEW:~1%
    )
    call :logEntryRelevant "%INTERVAL_RELEVANT_SEC%" "%DATE%" "%TIME_OF_REVIEW%" "%LOG_DATE%" "%LOG_TIME%"
    if not %errorlevel% == 0 (
        :: no relevant log entries - assume running fine
        endlocal
        exit /b 0
    )
    call :logEntryRetry "%LOG_ENTRY%"
    if %errorlevel% == 0 (
        endlocal
        exit /b -1
    )
endlocal
exit /b -2


:testRun:
setlocal
    call :logNoError_test
    if not %errorlevel% == 0 (
        endlocal
        exit /b 1
    )
    call :timeNormalize_HH_MM_SS_AMPM_test
    if not %errorlevel% == 0 (
        endlocal
        exit /b 1
    )
    call :date_DAY_MM_DD_YYYY_MM_DD_YY_test
    if not %errorlevel% == 0 (
        endlocal
        exit /b 1
    )
    call :date_MM_DD_YYYY_MM_DD_YY_test
    if not %errorlevel% == 0 (
        endlocal
        exit /b 1
    )
    call :logEntryRelevant_test
    if not %errorlevel% == 0 (
        endlocal
        exit /b 1
    )
    call :logEntryRecentMostValidFind_test
    if not %errorlevel% == 0 (
        endlocal
        exit /b 1
    )
    call :logEntryRetry_test
    if not %errorlevel% == 0 (
        endlocal
        exit /b 1
    )
endlocal
exit /b 0


:logNoError:
setlocal
    set LOG_PATHFILE_NAME=%~1

    if not exist "%LOG_PATHFILE_NAME%" (
        endlocal
        exit /b 1
    )
    call :logEntryRecentMost 1 "%LOG_PATHFILE_NAME%" LOG_ENTRY
    if not %errorlevel% == 0 (
        endlocal
        exit /b 1
    )
    echo %LOG_ENTRY% | findstr /r /c:"^Portal.*Started">nul
    if not %errorlevel% == 0 (
        endlocal
        exit /b 1
    )
endlocal
exit /b 0


:logNoError_test:
setlocal
    call :testExpectErrorCapture :logNoError "sportsManSQLAnalyzer.cmd.Test.Files\LogDoesNotExist"
    if not %errorlevel% == 0 (
        endlocal
        exit /b 1
    )
    call :testExpect0Capture :logNoError "sportsManSQLAnalyzer.cmd.Test.Files\LogNewIndicatesOK"
    if not %errorlevel% == 0 (
        endlocal
        exit /b 1
    )
    call :testExpectErrorCapture :logNoError "sportsManSQLAnalyzer.cmd.Test.Files\LogRequiresFurtherProcessing"
    if not %errorlevel% == 0 (
        endlocal
        exit /b 1
    )
endlocal
exit /b 0


:logEntryRecentMostValid:
setlocal EnableDelayedExpansion
    set LOG_PATHFILE_NAME=%~1
    set LOG_ENTRY_RTN=%~2
    set LOG_DATE_RTN=%~3
    set LOG_TIME_RTN=%~4

    for /l %%i in (1,1,3) do (
        call :logEntryRecentMostValidFind %%i "%LOG_PATHFILE_NAME%" LOG_ENTRY LOG_DATE LOG_TIME
        if !errorlevel! == 0 (
            goto :logEntryRecentMostValid_OK:
        )
    )
    endlocal
    exit /b 1
    :logEntryRecentMostValid_OK:
(
endlocal
set "%LOG_ENTRY_RTN%=%LOG_ENTRY%"
set %LOG_DATE_RTN%=%LOG_DATE%
set %LOG_TIME_RTN%=%LOG_TIME%
)
exit /b 0



:logEntryRecentMostValidFind:
setlocal
    set LINE_FROM_BOTTTOM=%~1
    set LOG_PATHFILE_NAME=%~2
    set LOG_ENTRY_RTN=%~3
    set LOG_DATE_RTN=%~4
    set LOG_TIME_RTN=%~5

    call :logEntryRecentMost %LINE_FROM_BOTTTOM% "%LOG_PATHFILE_NAME%" LOG_ENTRY
    if not %errorlevel% == 0 (
        endlocal
        exit /b 1
    )
    call :logEntryTimeExtract "%LOG_ENTRY%" LOG_TIME
    if not %errorlevel% == 0 (
        endlocal
        exit /b 1
    )
    call :logEntryDateExtract "%LOG_ENTRY%" LOG_DATE
    if not %errorlevel% == 0 (
        endlocal
        exit /b 1
    )
(
endlocal
set "%LOG_ENTRY_RTN%=%LOG_ENTRY%"
set %LOG_DATE_RTN%=%LOG_DATE%
set %LOG_TIME_RTN%=%LOG_TIME%
)
exit /b 0


:logEntryRecentMostValidFind_test:
setlocal
    call :testExpect0Capture :logEntryRecentMostValidFind 1 "sportsManSQLAnalyzer.cmd.Test.Files\RecentMostValidFind" LOG_ENTRY LOG_DATE LOG_TIME
    if not %errorlevel% == 0 (
        endlocal
        exit /b 1
    )
    call :assert "05/13/2020 09:26:42 PM Log most recent" == "%LOG_ENTRY%"
    if not %errorlevel% == 0 (
        endlocal
        exit /b 1
    )
    call :assert "05/13/2020" == "%LOG_DATE%"
    if not %errorlevel% == 0 (
        endlocal
        exit /b 1
    )
    call :assert "09:26:42 PM" == "%LOG_TIME%"
    if not %errorlevel% == 0 (
        endlocal
        exit /b 1
    )
    call :testExpect0Capture :logEntryRecentMostValidFind 2 "sportsManSQLAnalyzer.cmd.Test.Files\RecentMostValidFind" LOG_ENTRY LOG_DATE LOG_TIME
    if not %errorlevel% == 0 (
        endlocal
        exit /b 1
    )
    call :assert "05/12/2020 10:00:00 AM Log recent-1" == "%LOG_ENTRY%"
    if not %errorlevel% == 0 (
        endlocal
        exit /b 1
    )
    call :assert "05/12/2020" == "%LOG_DATE%"
    if not %errorlevel% == 0 (
        endlocal
        exit /b 1
    )
    call :assert "10:00:00 AM" == "%LOG_TIME%"
    if not %errorlevel% == 0 (
        endlocal
        exit /b 1
    )
    call :testExpect0Capture :logEntryRecentMostValidFind 3 "sportsManSQLAnalyzer.cmd.Test.Files\RecentMostValidFind" LOG_ENTRY LOG_DATE LOG_TIME
    if not %errorlevel% == 0 (
        endlocal
        exit /b 1
    )
    call :assert "05/11/2020 08:00:08 AM Log recent-2" == "%LOG_ENTRY%"
    if not %errorlevel% == 0 (
        endlocal
        exit /b 1
    )
    call :assert "05/11/2020" == "%LOG_DATE%"
    if not %errorlevel% == 0 (
        endlocal
        exit /b 1
    )
    call :assert "08:00:08 AM" == "%LOG_TIME%"
    if not %errorlevel% == 0 (
        endlocal
        exit /b 1
    )
    call :testExpect0Capture :logEntryRecentMostValidFind 4 "sportsManSQLAnalyzer.cmd.Test.Files\RecentMostValidFind" LOG_ENTRY LOG_DATE LOG_TIME
    if not %errorlevel% == 0 (
        endlocal
        exit /b 1
    )
    call :assert "05/11/2020 08:00:08 AM Log recent-2" == "%LOG_ENTRY%"
    if not %errorlevel% == 0 (
        endlocal
        exit /b 1
    )
endlocal
exit /b 0


:logEntryRecentMost:
setlocal
    set LINE_FROM_EOF=%~1
    set PATHFILE_NAME=%~2
    set ENTRY_RTN=%~3

    for /F "tokens=*" %%t in ( 'call fileTxtTail "%PATHFILE_NAME%" %LINE_FROM_EOF%' ) do (
         (
         endlocal
         set %ENTRY_RTN%=%%t
         )
         exit /b 0
    )
endlocal
exit /b 1


:logEntryTimeExtract:
setlocal
    set "LOG_ENTRY=%~1"
    set LOG_TIME_RTN=%~2

    set TIME_EXTRACT=%LOG_ENTRY:~11,11%
    echo %TIME_EXTRACT% | findstr /r /c:"^%REGEX_HH_MM_SS_XM%">nul
    if not %errorlevel% == 0 (
        endlocal
        exit /b 1
    )
(
endlocal
set %LOG_TIME_RTN%=%TIME_EXTRACT%
exit /b 0
)


:logEntryDateExtract:
setlocal
    set "LOG_ENTRY=%~1"
    set LOG_DATE_RTN=%~2

    set LOG_DATE=%LOG_ENTRY:~0,10%
    echo %LOG_DATE% | findstr /r /c:"^%REGEX_MM_DD_YYYY%">nul
(
endlocal
set %LOG_DATE_RTN%=%LOG_DATE%
)
exit /b 0


:logEntryRelevant:
setlocal
    set LOG_INTERVAL_RELEVANT_SEC=%~1
    set DATE_OF_REVIEW=%~2
    set TIME_OF_REVIEW=%~3
    set LOG_DATE=%~4
    set LOG_TIME=%~5

    call :timeNormalize_HH_MM_SS_AMPM "%LOG_TIME%" LOG_TIME_SEC_FROM_MDNIGHTH
    call :timeNormalize_HH_MM_SS_TO_SEC "%TIME_OF_REVIEW%" TIME_OF_REVIEW_SEC_FROM_MDNIGHT
    set /A  LOG_INTERVAL=%TIME_OF_REVIEW_SEC_FROM_MDNIGHT%-%LOG_TIME_SEC_FROM_MDNIGHTH%
    if %LOG_INTERVAL% LSS 0 (
        set LOG_INTERVAL=%LOG_INTERVAL:~1%
    )
    if %LOG_INTERVAL% GTR %LOG_INTERVAL_RELEVANT_SEC% (
        :: exceeds relevant interval even if in same day
        endlocal
        exit /b 1
    )
    call :date_MM_DD_YYYY_MM_DD_YY "%LOG_DATE%" LOG_DATE_MM_DD_YY
    call :date_DAY_MM_DD_YYYY_MM_DD_YY "%DATE_OF_REVIEW%" DATE_OF_REVIEW_MM_DD_YY
    call :dateDiffSec_MM_DD_YY-MM_DD_YY "%DATE_OF_REVIEW_MM_DD_YY%" "%LOG_DATE_MM_DD_YY%"  DATE_DIFF_SEC
    set /A LOG_INTERVAL=%LOG_INTERVAL% + %DATE_DIFF_SEC%
    if %LOG_INTERVAL% GTR %LOG_INTERVAL_RELEVANT_SEC%  (
        :: exceeds relevant interval
        endlocal
        exit /b 1
    )
endlocal
exit /b 0


:logEntryRelevant_test:
setlocal

    call :testExpect0Capture :logEntryRelevant 10 "mon 05/18/2020" "22:06:23" "05/18/2020" "10:06:13 PM"
    if not %errorlevel% == 0 (
        endlocal
        exit /b 1
    )
    call :testExpect0Capture :logEntryRelevant 10 "mon 05/18/2020" "10:06:23" "05/18/2020" "10:06:13 AM"
    if not %errorlevel% == 0 (
        endlocal
        exit /b 1
    )
    call :testExpectErrorCapture :logEntryRelevant 10 "Tue 05/19/2020" "22:06:23" "05/18/2020" "10:06:13 PM"
    if not %errorlevel% == 0 (
        endlocal
        exit /b 1
    )
endlocal
exit /b 0


:timeNormalize_HH_MM_SS_AMPM:
setlocal
    set TIME_HH_MM_SS_AMPM=%~1
    set TIME_SEC_FROM_MDNIGHTH_RTN=%~2

    set INTERVAL_SEC=0
    set AMPM_LABEL=%TIME_HH_MM_SS_AMPM:~9,2%
    if /I "%AMPM_LABEL%"=="PM" (
        set /A INTERVAL_SEC=12*60*60
    ) else (
        if /I not "%AMPM_LABEL%" == "AM"  (
            endlocal
            exit /b 1
        )
    )
    call :timeNormalize_HH_MM_SS_TO_SEC  "%TIME_HH_MM_SS_AMPM:~0,8%" SECS
    if not %errorlevel% == 0 (
        endlocal
        exit /b 1
    )
    set /A INTERVAL_SEC=%INTERVAL_SEC% + %SECS%
(
endlocal
set %TIME_SEC_FROM_MDNIGHTH_RTN%=%INTERVAL_SEC%
)
exit /b 0


:timeNormalize_HH_MM_SS_AMPM_test:
setlocal

    call :testExpectErrorCapture  :timeNormalize_HH_MM_SS_AMPM "09:10" "INTERVAL_SEC"
    if not %errorlevel% == 0 (
        endlocal
        exit /b 1
    )
    call :testExpect0Capture  :timeNormalize_HH_MM_SS_AMPM "09:10:56:am" INTERVAL_SEC
    if not %errorlevel% == 0 (
        endlocal
        exit /b 1
    )
    call :assert "%INTERVAL_SEC%" == "33056"
    call :testExpect0Capture  :timeNormalize_HH_MM_SS_AMPM "09:10:56:PM" INTERVAL_SEC
    if not %errorlevel% == 0 (
        endlocal
        exit /b 1
    )
    call :assert "%INTERVAL_SEC%" == "76256"
    call :testExpectErrorCapture  :timeNormalize_HH_MM_SS_AMPM "30:10:56:PM" INTERVAL_SEC
    if not %errorlevel% == 0 (
        endlocal
        exit /b 1
    )
endlocal
exit /b 0


:timeNormalize_HH_MM_SS_TO_SEC:
setlocal
    set TIME_HH_MM_SS=%~1
    set SS_RTN=%~2

    echo %TIME_HH_MM_SS% | findstr /r /c:"^%REGEX_HH_MM_SS%">nul
    if not %errorlevel% == 0 (
        endlocal
        exit /b 1
    )
    for /f "tokens=1,2,3 delims=:" %%t in ( 'echo %TIME_HH_MM_SS%' ) do (
        set HH=%%t
        set MM=%%u
        set SS=%%v
    )
    :: add 100 then sub 100 to eliminate batch numberic
    :: exception dur to leading zeroes
    set /A HH_SEC=(1%HH%-100)*60*60
    set /A MM_SEC=(1%MM%-100)*60
    set /A SS=1%SS%-100
    set /A SS=%HH_SEC%+%MM_SEC%+%SS%
(
endlocal
set %SS_RTN%=%SS%
)
exit /b 0


:date_DAY_MM_DD_YYYY_MM_DD_YY:
setlocal
    set DATE_DAY_MM_DD_YYYY=%~1
    set DATE_MM_DD_YY_RTN=%~2

    echo %DATE_DAY_MM_DD_YYYY% | findstr /i /r /c:"^[a-z][a-z][a-z].%REGEX_MM_DD_YYYY%" >nul
    if not %errorlevel% == 0 (
        endlocal
        exit /b 1
   )
(
endlocal
set %DATE_MM_DD_YY_RTN%=%DATE_DAY_MM_DD_YYYY:~4,6%%DATE_DAY_MM_DD_YYYY:~12,2%
)
exit /b 0


:date_DAY_MM_DD_YYYY_MM_DD_YY_test:
setlocal

    call :testExpect0Capture :date_DAY_MM_DD_YYYY_MM_DD_YY "Mon 05/18/2120" DATE_MM_DD_YY
    if not %errorlevel% == 0 (
        endlocal
        exit /b 1
    )
    call :assert "05/18/20" == "%DATE_MM_DD_YY%"
    call :testExpect0Capture :date_DAY_MM_DD_YYYY_MM_DD_YY "Mon 01/01/2020" DATE_MM_DD_YY
    if not %errorlevel% == 0 (
        endlocal
        exit /b 1
    )
    call :assert "01/01/20" == "%DATE_MM_DD_YY%"
    call :testExpect0Capture :date_DAY_MM_DD_YYYY_MM_DD_YY "Mon 12/31/2029" DATE_MM_DD_YY
    if not %errorlevel% == 0 (
        endlocal
        exit /b 1
    )
    call :assert "12/31/29" == "%DATE_MM_DD_YY%"
    call :testExpectErrorCapture :date_DAY_MM_DD_YYYY_MM_DD_YY "05/18/2120" DATE_MM_DD_YY
    if not %errorlevel% == 0 (
        endlocal
        exit /b 1
    )
endlocal
exit /b 0


:date_MM_DD_YYYY_MM_DD_YY:
setlocal
    set DATE_MM_DD_YYYY=%~1
    set DATE_MM_DD_YY_RTN=%~2

    echo %DATE_MM_DD_YYYY% | findstr /r /c:"^%REGEX_MM_DD_YYYY%">nul
    if not %errorlevel% == 0 (
        endlocal
        exit /b 1
    )
(
endlocal
set %DATE_MM_DD_YY_RTN%=%DATE_MM_DD_YYYY:~0,6%%DATE_MM_DD_YYYY:~8,2%
)
exit /b 0


:date_MM_DD_YYYY_MM_DD_YY_test:
setlocal
    call :testExpect0Capture :date_MM_DD_YYYY_MM_DD_YY "05/18/2120" DATE_MM_DD_YY
    if not %errorlevel% == 0 (
        endlocal
        exit /b 1
    )
    call :assert "05/18/20" == "%DATE_MM_DD_YY%"
    call :testExpect0Capture :date_MM_DD_YYYY_MM_DD_YY "12/31/2099" DATE_MM_DD_YY
    if not %errorlevel% == 0 (
        endlocal
        exit /b 1
    )
    call :assert "12/31/99" == "%DATE_MM_DD_YY%"

endlocal
exit /b 0


:dateDiffSec_MM_DD_YY-MM_DD_YY:
setlocal
    set DATE_START=%~1
    set DATE_END=%~2
    set DATE_DIFF_SEC_RTN=%~3

    set YY_MM_DD_START=%DATE_START:~6,2% %DATE_START:~0,2% %DATE_START:~3,2%
    set YY_MM_DD_END=%DATE_END:~6,2% %DATE_END:~0,2% %DATE_END:~3,2%
    if "%YY_MM_DD_START%" == "%YY_MM_DD_END%" (
        endlocal
        set %DATE_DIFF_SEC_RTN%=0
        exit /b 0
    )
    call dateMath.cmd %YY_MM_DD_START% - %YY_MM_DD_END%>nul
    if not %errorlevel% == 0 (
        endlocal
        exit /b 1
    )
    :: ensure absolute value
    if %_dd_int% LSS 0 (
        set _dd_int=%_dd_int:~1%
    )
(
endlocal
set /A %DATE_DIFF_SEC_RTN%=%_dd_int%*86400
)
exit /b 0


:logEntryRetry:
setlocal
    set "LOG_ENTRY=%~1"

    echo %LOG_ENTRY% | findstr /i /r /c:"error.*1429.*the remote host address is invalid.*0.0.0.0">nul
    if %errorlevel% == 0 (
        endlocal
        exit /b 0
    )
    echo %LOG_ENTRY% | findstr /i /r /c:"valid name.*no data record.*check DNS setup">nul
    if %errorlevel% == 0 (
        endlocal
        exit /b 0
    )
endlocal
exit /b 1


:logEntryRetry_test:
setlocal

    call :testExpect0Capture :logEntryRetry "05/13/2020 09:26:42 PM Error 1429 The remote Host address is invalid (0.0.0.0) module init line #285"
    if not %errorlevel% == 0 (
        endlocal
        exit /b 1
    )
    call :testExpect0Capture :logEntryRetry "05/13/2020 09:26:42 PM error detected valid name, no data record (check DNS setup) module init line #125"
    if not %errorlevel% == 0 (
        endlocal
        exit /b 1
    )
    call :testExpectErrorCapture :logEntryRetry "Portal process started"
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

 
:assert
setlocal

    if %* (
        endlocal
        exit /b 0  
    ) 
    echo Assert failed: %*
endlocal
exit /b 1