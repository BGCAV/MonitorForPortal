@echo off 
::-----------------------------------------------------------------------------
::--
::--  Purpose
::--    Monitor the execution of SportsManSQL's Portal process by reviewing
::--    its log.  Under circumstances that indicate connection failures to
::--    backend Peak Software servers, restart the Portal process.
::--
::--  Motivation
::--    After months of flawlessly reconnecting to backend Peak Servers following 
::--    nightly maintenance, sporatic failures occuring during Portal's initial
::--    DNS resoultion requests required frequent, manual interaction to restart
::--    the Portal process.  All manual restarts that occurred during normal
::--    business hours successfully resolved DNS entries and connected to the
::--    backend servers.  Note the problem is unlikely to be related to a
::--    local configuration setting as the configuration information is restored
::--    to the last "golden" state by a VMWare snapshot.  Furthermore, one
::--    can manually and successfully reconnect after a failure.
::--
::--    The problem's most likely triggers involve Portal's inability to 
::--    retry the initially failed DNS requests and some issue with the
::--    DNS latency in Comcast's network or perhaps Peak's Servers also happen
::--    to be unavailable for new connections.
::--
::-----------------------------------------------------------------------------
setlocal
    call processMonitorRunning.cmd "portal.exe" "processStartSportsManSQL.cmd" "logAnalyzerSportsManSQL.cmd" 60
    if not %errorlevel% == 0 (
        endlocal
        exit /b 1
    )
endlocal
exit /b 0