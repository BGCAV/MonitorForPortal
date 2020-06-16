@echo off
::-----------------------------------------------------------------------------
::--
::--  Purpose
::--    Perform DNS resolution request on Peak Software gateway URL.  Portal 
::--    process fails on startup because it's not able to resolve DNS request.
::--    This command ensures gateway URL resolves before starting the Portal.
::--    Successfull execution of this script primes local host's DNS cache
::--    so Portal may (not should) succeed.  Script will not yeild control until
::--    DNS successfully resolves.  It applies an exponential backoff retry 
::--    strategy that's limited by a maximum retry interval.
::--
::--    Unfortunately there are potentially several DNS resolution requests
::--    that may fail.  For example, portal.exe embeds certificate URLs in
::--    its executable which it might use?  Peak isn't transparent concerning
::--    the URLs it connects to.  All I can confirm is even after a successful
::--    gateway ping, the Portal process can still fail due to unsuccessful
::--    DNS resolution request.  Portal.exe may consume a "config" file with
::--    specifying additional URLs, but I haven't searched for this file.  So
::--    far manually restaring the Portal process has "always" successfully
::--    connected to the backend servers.  Therefore, unless continued failures
::--    drive a search for all URLs required by Portal.exe, I'll refrain from
::--    mining them. 
::--
::--  Assume
::--    It's dependent commands are accessible by either being installed to
::--    the same directory or available through PATH
::--
::--  Out
::--    Any messages issued by provided command to SYSOUT or SYSERR.
::--
::-----------------------------------------------------------------------------
setlocal
    call retryCommandExponentialBackoff.cmd dnsResolutionCheck.cmd gateway.activityreg.com
    if not %errorlevel% == 0 (
        endlocal
        exit /b 1
    )
endlocal
exit /b 0