@echo off
setlocal enabledelayedexpansion
REM Wrapper script for building Bookmap indicators with automatic API detection

if "%~1"=="" (
    echo Usage: build-bookmap.bat ^<indicator.java^> [main-class-name]
    echo.
    echo This script automatically finds the Bookmap API and builds your indicator.
    echo.
    echo Examples:
    echo   build-bookmap.bat MyIndicator.java
    echo   build-bookmap.bat MyIndicator.java MyIndicator
    echo.
    echo For manual classpath control, use: build.bat ^<file^> ^<main-class^> ^<jar-path^>
    exit /b 1
)

set INPUT_FILE=%~1
set MAIN_CLASS=%~2
set ORIGINAL_FILENAME=%~nx1
set ORIGINAL_BASENAME=%~n1

REM Extract the actual class name from the Java file
set ACTUAL_CLASS_NAME=
for /f "tokens=2 delims= " %%a in ('findstr /r /c:"^public class [A-Za-z]" "%INPUT_FILE%"') do (
    if "%%a"=="class" (
        for /f "tokens=3 delims= " %%b in ('findstr /r /c:"^public class [A-Za-z]" "%INPUT_FILE%"') do (
            set ACTUAL_CLASS_NAME=%%b
        )
    )
)

REM Check if filename matches class name
set NEEDS_RENAME=0
set JAVA_FILE=%INPUT_FILE%
set TEMP_FILE_CREATED=0

if not "%ACTUAL_CLASS_NAME%"=="" (
    if not "%ORIGINAL_BASENAME%"=="%ACTUAL_CLASS_NAME%" (
        echo.
        echo WARNING: File name "%ORIGINAL_FILENAME%" does not match class name "%ACTUAL_CLASS_NAME%"
        echo Creating temporary copy with correct name...
        set NEEDS_RENAME=1
        set TEMP_FILE_CREATED=1
        for %%F in ("%INPUT_FILE%") do set TEMP_DIR=%%~dpF
        set JAVA_FILE=!TEMP_DIR!%ACTUAL_CLASS_NAME%.java
        copy "%INPUT_FILE%" "!JAVA_FILE!" >nul
        echo.
    )
)

REM If main class not provided, use actual class name or derive from filename
if "%MAIN_CLASS%"=="" (
    if not "%ACTUAL_CLASS_NAME%"=="" (
        set MAIN_CLASS=%ACTUAL_CLASS_NAME%
    ) else (
        set MAIN_CLASS=%ORIGINAL_BASENAME%
    )
)

echo ==========================================
echo Bookmap Indicator Builder
echo ==========================================
echo.

REM Check if required Docker images exist
echo Checking Docker environment...

set IMAGES_MISSING=0

docker image inspect eclipse-temurin:8-jdk >nul 2>&1
if errorlevel 1 set IMAGES_MISSING=1

docker image inspect maven:3.9-eclipse-temurin-8 >nul 2>&1
if errorlevel 1 set IMAGES_MISSING=1

docker image inspect gradle:8.5-jdk17 >nul 2>&1
if errorlevel 1 set IMAGES_MISSING=1

if "!IMAGES_MISSING!"=="1" (
    echo.
    echo One or more required Docker base images are missing.
    echo Required images:
    echo   - eclipse-temurin:8-jdk
    echo   - maven:3.9-eclipse-temurin-8
    echo   - gradle:8.5-jdk17
    echo.
    echo Downloading required Docker images automatically...
    echo This may take a few minutes depending on your connection.
    echo.
    call rebuild-image.bat
    if errorlevel 1 (
        echo.
        echo ERROR: Failed to download Docker images.
        echo Please ensure Docker is running and try again.
        exit /b 1
    )
    echo.
    echo Docker images ready. Continuing with build...
    echo.
)

echo Searching for Bookmap API...

set BOOKMAP_FOUND=0
set API_JAR=
set BOOKMAP_DIR=

REM Check common installation paths
if exist "C:\Program Files\Bookmap\lib" (
    set "BOOKMAP_DIR=C:\Program Files\Bookmap\lib"
    set BOOKMAP_FOUND=1
)

if exist "C:\Program Files (x86)\Bookmap\lib" (
    set "BOOKMAP_DIR=C:\Program Files (x86)\Bookmap\lib"
    set BOOKMAP_FOUND=1
)

REM Check user profile and other common locations
if exist "%USERPROFILE%\Bookmap\lib" (
    set "BOOKMAP_DIR=%USERPROFILE%\Bookmap\lib"
    set BOOKMAP_FOUND=1
)

if exist "C:\Bookmap\lib" (
    set "BOOKMAP_DIR=C:\Bookmap\lib"
    set BOOKMAP_FOUND=1
)

if "!BOOKMAP_FOUND!"=="0" (
    echo ERROR: Bookmap installation not found!
    echo.
    echo Searched locations:
    echo   - C:\Program Files\Bookmap\lib
    echo   - C:\Program Files ^(x86^)\Bookmap\lib
    echo   - %USERPROFILE%\Bookmap\lib
    echo   - C:\Bookmap\lib
    echo.
    echo Please install Bookmap or use build.bat with manual classpath:
    echo   build.bat "!JAVA_FILE!" "!MAIN_CLASS!" "path\to\api-core.jar"
    echo.
    echo Or run find-bookmap-api.bat to locate your installation.
    exit /b 1
)

echo Found Bookmap at: !BOOKMAP_DIR!

REM Find api-core JAR
for /f "delims=" %%f in ('dir /b "!BOOKMAP_DIR!\api-core*.jar" 2^>nul') do (
    set API_JAR=!BOOKMAP_DIR!\%%f
    goto :found_jar
)

:found_jar
if not defined API_JAR (
    echo ERROR: api-core*.jar not found in !BOOKMAP_DIR!
    echo.
    echo Available JAR files:
    dir /b "!BOOKMAP_DIR!\*.jar"
    echo.
    echo Please specify the JAR manually:
    echo   build.bat "!JAVA_FILE!" "!MAIN_CLASS!" "!BOOKMAP_DIR!\your-api.jar"
    exit /b 1
)

REM Verify the JAR file exists
if not exist "!API_JAR!" (
    echo ERROR: API JAR file not found: !API_JAR!
    echo.
    echo Please check your Bookmap installation or specify the JAR manually:
    echo   build.bat "!JAVA_FILE!" "!MAIN_CLASS!" "path\to\api-core.jar"
    exit /b 1
)

echo Using API JAR: !API_JAR!
echo.
echo Building indicator: %JAVA_FILE%
echo Main class: %MAIN_CLASS%
echo.
echo ==========================================
echo.

REM Call the main build script with the detected API JAR
call build.bat "%JAVA_FILE%" "%MAIN_CLASS%" "!API_JAR!"

set BUILD_RESULT=%ERRORLEVEL%

REM Handle file renaming if needed
if "!TEMP_FILE_CREATED!"=="1" (
    if !BUILD_RESULT! equ 0 (
        echo.
        echo Renaming output JAR to match original filename...
        if exist "%ACTUAL_CLASS_NAME%.jar" (
            move "%ACTUAL_CLASS_NAME%.jar" "%ORIGINAL_BASENAME%.jar" >nul
            echo Output: %ORIGINAL_BASENAME%.jar
        )
    )

    REM Delete the temporary file
    if exist "!JAVA_FILE!" (
        del "!JAVA_FILE!" >nul
    )
)

exit /b !BUILD_RESULT!
