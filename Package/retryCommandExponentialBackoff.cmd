@echo off
::-----------------------------------------------------------------------------
::--
::--  Purpose:
::--    Exponential retry delay.  Execute command and if it fails, apply
::--    exponential delay before reexecuting it.  Once exponential delay
::--    exceedes maximum retry interval, continue retrying the command
::--    but limit retry interval to this maximum.
::--
::--  Out:
::--    Writes countdown timer to SYSOUT.
::--    Also any messages issued by provided command to SYSOUT or SYSERR.
::--
::-----------------------------------------------------------------------------
setlocal
    set RETRY_BASE=2
    set RETRY_INTERVAL_MAX_MINUTE=15
    call :retry %*
endlocal
exit /b %errorlevel%


:retry:
setlocal
    ::-- since there isn't a means to extract starting arguments from %*
    ::-- use variables defined in outer scope of this function.
    set /a RETRY_INTERVAL_MAX_SEC=%RETRY_INTERVAL_MAX_MINUTE% * 60
    set RETRY_INTERVAL_SEC=1
    :tryagain:
        call %*
        if %errorlevel% == 0 (
            endlocal
            exit /b
        )
        timeout /NOBREAK /T %RETRY_INTERVAL_SEC%
        ::-- each loop iteration multiplies the current interval by the base 
        ::-- to calculate the next retry interval.
        set /a RETRY_INTERVAL_SEC=%RETRY_INTERVAL_SEC% * %RETRY_BASE%
        if %RETRY_INTERVAL_SEC% GTR %RETRY_INTERVAL_MAX_SEC% (
            set RETRY_INTERVAL_SEC=%RETRY_INTERVAL_MAX_SEC%
        )
goto tryagain