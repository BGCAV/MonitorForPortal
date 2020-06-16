@echo off
::-----------------------------------------------------------------------------
::--
::--  Purpose
::--    Extract N lines from the end of a text file.  Assumes newline delimiter.
::--  
::--  Inspired by:
::--    https://stackoverflow.com/questions/187587/a-windows-equivalent-of-the-unix-tail-command
::--
::--  In
::--    %1 - (required) FilePathName to text file.
::--    %2 - (optional) Number of lines to print that are above the
::--         text file's end.  Defaults to 10.  Note, if the file is smaller
::--         than requested line, the entire file is displayed.
::--
::--  Out
::--   SYSOUT will display the stream of lines.
::--
::-----------------------------------------------------------------------------
setlocal
    set TEXT_FILEPATH=%~1
    set LINES_FROM_BOTTOM=%~2

    if not exist "%~1" (
        echo "Error: File not found='%TEXT_FILEPATH%'" >&2
        endlocal
        exit /b 1
    )
    if "%LINES_FROM_BOTTOM%" == "" (
        set LINES_FROM_BOTTOM=10
    )
    call :textFileLengthCalc "%TEXT_FILEPATH%" TEXT_LINE_CNT
    if not %errorlevel% == 0 (
        endlocal
        exit /b 1
    )
    if %TEXT_LINE_CNT% LSS 1 (
        :: file exists but empty
        endlocal
        exit /b 0
    )
    if %TEXT_LINE_CNT% LSS %LINES_FROM_BOTTOM% (
        set LINES_FROM_BOTTOM=%TEXT_LINE_CNT%
    )
    set /A LINES_FROM_TOP=%TEXT_LINE_CNT% - %LINES_FROM_BOTTOM%
    more +%LINES_FROM_TOP% "%TEXT_FILEPATH%"
endlocal
exit /b


:textFileLengthCalc:
setlocal
    set TEXT_FILEPATH=%~1
    set TEST_LINE_CNT_RTN=%~2

    set TEST_LINE_CNT=0
    for /f "delims=" %%t in ('find /c /v "" "%TEXT_FILEPATH%" ^|  findstr /e /r /c:":  *[0-9][0-9]*$"') do call :textFileLenghtExtract TEST_LINE_CNT %%t
    if not %errorlevel% == 0 (
        endlocal
        exit /b 1
    )
(
endlocal
set %TEST_LINE_CNT_RTN%=%TEST_LINE_CNT%
)
exit /b 0


:textFileLenghtExtract:
setlocal
    set TEXT_LINE_CNT_RTN=%~1
    :: extracting can't be reliably performed in for loop due to parens in file/directory names.
    :textFileLenghtExtractShift:
    if "%2" == "" (
        goto :textFileLenghtExtractShiftDone
    )
    set "TEXT_LINE_CNT=%~2"
    shift
    goto :textFileLenghtExtractShift

   :textFileLenghtExtractShiftDone:
    echo %TEXT_LINE_CNT%| findstr /r /c:"^[0-9][0-9]*$">nul
    if not %errorlevel% == 0 (
        exit /b 1
    )
(
endlocal
set %TEXT_LINE_CNT_RTN%=%TEXT_LINE_CNT%
)
exit /b 0