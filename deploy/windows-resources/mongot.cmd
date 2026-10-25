@echo off
rem Runs mongot (MongoDB Search Community Edition) on Windows.
rem
rem Usage:
rem   mongot.cmd --config C:\ProgramData\mongot\config.yml
rem   mongot.cmd --jvm-flags "-Xmx4g -Xms4g" --config C:\ProgramData\mongot\config.yml
rem
rem `--jvm-flags` (or the MONGOT_JVM_FLAGS environment variable) is passed to the JVM.
rem All other arguments are passed through to the MongotCommunity entry point.
rem This script expects to live next to the bin\ (bundled JDK + jar) and lib\ directories.

setlocal EnableExtensions DisableDelayedExpansion

set "MONGOT_HOME=%~dp0"
if "%MONGOT_HOME:~-1%"=="\" set "MONGOT_HOME=%MONGOT_HOME:~0,-1%"
set "JAVA_HOME=%MONGOT_HOME%\bin\jdk"
set "JVM_FLAGS=%MONGOT_JVM_FLAGS%"
set "PASS_THROUGH_ARGS="

:parse_args
if "%~1"=="" goto run_mongot
if /I "%~1"=="--jvm-flags" (
    set "JVM_FLAGS=%JVM_FLAGS% %~2"
    shift
    shift
    goto parse_args
)
set PASS_THROUGH_ARGS=%PASS_THROUGH_ARGS% %1
shift
goto parse_args

:run_mongot
if not exist "%JAVA_HOME%\bin\java.exe" (
    echo ERROR: bundled JDK not found at "%JAVA_HOME%" 1>&2
    exit /b 1
)

rem lib\* comes first on the classpath so the FIPS jars are loaded from there
rem even if they also exist in mongot_community_deploy.jar.
"%JAVA_HOME%\bin\java.exe" ^
    -XX:+ExitOnOutOfMemoryError ^
    -XX:-UseGCOverheadLimit ^
    --add-modules=jdk.incubator.vector ^
    --enable-preview ^
    --enable-native-access=ALL-UNNAMED ^
    -Dstdout.encoding=UTF-8 ^
    -Dstderr.encoding=UTF-8 ^
    %JVM_FLAGS% ^
    -cp "%MONGOT_HOME%\lib\*;%MONGOT_HOME%\bin\mongot_community_deploy.jar" ^
    com.xgen.mongot.community.MongotCommunity%PASS_THROUGH_ARGS%

exit /b %ERRORLEVEL%
