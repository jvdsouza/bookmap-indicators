@echo off
REM Script to rebuild/refresh Docker base images used by build.bat
REM This ensures you have the latest base images and clears any cached builds

echo ==========================================
echo Rebuilding Docker Base Images
echo ==========================================
echo.

REM Pull the base images
echo Pulling eclipse-temurin:8-jdk...
docker pull eclipse-temurin:8-jdk

echo.
echo Pulling maven:3.9-eclipse-temurin-8...
docker pull maven:3.9-eclipse-temurin-8

echo.
echo Pulling gradle:8.5-jdk17...
docker pull gradle:8.5-jdk17

echo.
echo ==========================================
echo Cleaning up old build artifacts...
echo ==========================================

REM Remove any leftover java-compiler-temp images/containers
for /f "tokens=*" %%i in ('docker ps -a -q -f name^=java-build-') do docker rm %%i 2>nul
if errorlevel 1 echo No old containers to remove

docker rmi java-compiler-temp 2>nul
if errorlevel 1 echo No old temp images to remove

REM Optional: Prune dangling images
echo.
set /p PRUNE="Do you want to remove dangling Docker images? (y/n) "
if /i "%PRUNE%"=="y" (
    docker image prune -f
    echo Dangling images removed
)

echo.
echo ==========================================
echo Image rebuild complete!
echo ==========================================
echo.
echo Base images ready:
echo   - eclipse-temurin:8-jdk (for single/multi-file Java^)
echo   - maven:3.9-eclipse-temurin-8 (for Maven projects^)
echo   - gradle:8.5-jdk17 (for Gradle projects^)
echo.
pause
