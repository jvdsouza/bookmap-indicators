@echo off
REM Script to locate Bookmap API JAR files on Windows

echo Searching for Bookmap installation...
echo.

set BOOKMAP_FOUND=0

REM Check common installation paths
if exist "C:\Program Files\Bookmap\lib" (
    set BOOKMAP_DIR=C:\Program Files\Bookmap\lib
    set BOOKMAP_FOUND=1
)

if exist "C:\Program Files (x86)\Bookmap\lib" (
    set BOOKMAP_DIR=C:\Program Files ^(x86^)\Bookmap\lib
    set BOOKMAP_FOUND=1
)

if "%BOOKMAP_FOUND%"=="0" (
    echo ERROR: Bookmap installation not found in standard locations.
    echo.
    echo Please check these locations manually:
    echo   - C:\Program Files\Bookmap\lib
    echo   - C:\Program Files ^(x86^)\Bookmap\lib
    echo.
    echo Or locate your Bookmap installation directory and look in the 'lib' folder.
    pause
    exit /b 1
)

echo Found Bookmap at: %BOOKMAP_DIR%
echo.
echo API JAR files:
echo ================================================================================

dir /b "%BOOKMAP_DIR%\api-*.jar" 2>nul
if errorlevel 1 (
    echo No api-*.jar files found!
    echo.
    echo All JAR files in lib directory:
    dir /b "%BOOKMAP_DIR%\*.jar"
) else (
    echo.
    echo ================================================================================
    echo.
    echo To build a Bookmap indicator, use:
    echo.
    for /f "delims=" %%f in ('dir /b "%BOOKMAP_DIR%\api-core*.jar" 2^>nul') do (
        echo build.bat YourIndicator.java YourIndicator "%BOOKMAP_DIR%\%%f"
        goto :found_core
    )
    :found_core
)

echo.
pause
