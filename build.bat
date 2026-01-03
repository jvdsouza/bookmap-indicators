@echo off
setlocal enabledelayedexpansion
REM Script to compile Java projects using Docker and output a JAR file (Windows version)
REM Supports: single files, multi-file projects, Maven projects, and Gradle projects

if "%~1"=="" (
    echo Usage: build.bat ^<path-to-file-or-directory^> [main-class-name] [classpath-jar]
    echo.
    echo Examples:
    echo   build.bat MyApp.java                              - Single Java file
    echo   build.bat MyApp.java com.example.MyApp            - Single file with explicit main class
    echo   build.bat MyApp.java com.example.MyApp lib.jar    - With external JAR dependency
    echo   build.bat ./my-project                            - Multi-file Java project
    echo   build.bat ./my-maven-project                      - Maven project ^(has pom.xml^)
    echo   build.bat ./my-gradle-project                     - Gradle project ^(has build.gradle^)
    exit /b 1
)

set INPUT_PATH=%~1
set CONTAINER_NAME=java-build-%RANDOM%
set PROJECT_TYPE=unknown
set OUTPUT_JAR=output.jar
set CLASSPATH_JAR=%~3

REM Determine if input is a file or directory
if exist "%INPUT_PATH%\*" (
    set IS_DIRECTORY=true
    REM Get absolute path for directory
    pushd "%INPUT_PATH%"
    set PROJECT_DIR=!CD!
    popd
) else if exist "%INPUT_PATH%" (
    set IS_DIRECTORY=false
    REM Get absolute path for file
    for %%F in ("%INPUT_PATH%") do set JAVA_FILE=%%~fF
    set JAVA_FILENAME=%~nx1
    set JAVA_CLASSNAME=%~n1
) else (
    echo Error: Path '%INPUT_PATH%' not found
    exit /b 1
)

REM Detect project type
if "!IS_DIRECTORY!"=="true" (
    if exist "!PROJECT_DIR!\pom.xml" (
        set PROJECT_TYPE=maven
        echo Detected: Maven project
    ) else if exist "!PROJECT_DIR!\build.gradle" (
        set PROJECT_TYPE=gradle
        echo Detected: Gradle project
    ) else if exist "!PROJECT_DIR!\build.gradle.kts" (
        set PROJECT_TYPE=gradle
        echo Detected: Gradle project ^(Kotlin DSL^)
    ) else (
        set PROJECT_TYPE=multifile
        echo Detected: Multi-file Java project
        if "%~2"=="" (
            echo Error: Main class name required for multi-file projects
            echo Usage: build.bat %INPUT_PATH% com.example.MainClass
            exit /b 1
        )
        set MAIN_CLASS=%~2
    )
) else (
    set PROJECT_TYPE=single
    echo Detected: Single Java file
    if not "%~2"=="" (
        set MAIN_CLASS=%~2
    ) else (
        set MAIN_CLASS=%JAVA_CLASSNAME%
    )
)

REM Build based on project type
if "!PROJECT_TYPE!"=="single" (
    call :build_single_file
) else if "!PROJECT_TYPE!"=="multifile" (
    call :build_multifile
) else if "!PROJECT_TYPE!"=="maven" (
    call :build_maven
) else if "!PROJECT_TYPE!"=="gradle" (
    call :build_gradle
)

if %ERRORLEVEL% neq 0 (
    echo Build failed!
    exit /b 1
)

echo.
echo ========================================
echo Build successful!
echo JAR file: !OUTPUT_JAR!
echo ========================================
echo.
echo To run: java -jar !OUTPUT_JAR!
exit /b 0

:build_single_file
    echo Building single Java file: %JAVA_FILE%
    echo Main class: %MAIN_CLASS%

    set BUILD_DIR=%TEMP%\java-build-%RANDOM%
    mkdir "%BUILD_DIR%"

    copy "%JAVA_FILE%" "%BUILD_DIR%\"

    if not "%CLASSPATH_JAR%"=="" (
        echo Using classpath: %CLASSPATH_JAR%
        for %%F in ("%CLASSPATH_JAR%") do set CLASSPATH_FILENAME=%%~nxF
        copy "%CLASSPATH_JAR%" "%BUILD_DIR%\"
        (
        echo FROM eclipse-temurin:8-jdk
        echo WORKDIR /build
        echo COPY ["%JAVA_FILENAME%", "."]
        echo COPY ["!CLASSPATH_FILENAME!", "."]
        echo RUN javac -cp "!CLASSPATH_FILENAME!" "%JAVA_FILENAME%"
        echo RUN echo "Main-Class: %MAIN_CLASS%" ^> manifest.txt
        echo RUN jar cfm output.jar manifest.txt *.class
        echo CMD ["echo", "Build complete"]
        ) > "%BUILD_DIR%\Dockerfile"
    ) else (
        (
        echo FROM eclipse-temurin:8-jdk
        echo WORKDIR /build
        echo COPY ["%JAVA_FILENAME%", "."]
        echo RUN javac "%JAVA_FILENAME%"
        echo RUN echo "Main-Class: %MAIN_CLASS%" ^> manifest.txt
        echo RUN jar cfm output.jar manifest.txt *.class
        echo CMD ["echo", "Build complete"]
        ) > "%BUILD_DIR%\Dockerfile"
    )

    docker build -t java-compiler-temp "%BUILD_DIR%"
    docker create --name %CONTAINER_NAME% java-compiler-temp

    set OUTPUT_JAR=%JAVA_CLASSNAME%.jar
    docker cp %CONTAINER_NAME%:/build/output.jar ".\%OUTPUT_JAR%"

    docker rm %CONTAINER_NAME%
    docker rmi java-compiler-temp
    rmdir /s /q "%BUILD_DIR%"
    exit /b 0

:build_multifile
    echo Building multi-file Java project: !PROJECT_DIR!
    echo Main class: !MAIN_CLASS!

    copy Dockerfile.multifile "!PROJECT_DIR!\Dockerfile.tmp"

    docker build --build-arg MAIN_CLASS=!MAIN_CLASS! -f "!PROJECT_DIR!\Dockerfile.tmp" -t java-compiler-temp "!PROJECT_DIR!"
    docker create --name !CONTAINER_NAME! java-compiler-temp

    for %%F in ("!PROJECT_DIR!") do set PROJECT_NAME=%%~nxF
    set OUTPUT_JAR=!PROJECT_NAME!.jar
    docker cp !CONTAINER_NAME!:/build/output.jar ".\!OUTPUT_JAR!"

    docker rm !CONTAINER_NAME!
    docker rmi java-compiler-temp
    del "!PROJECT_DIR!\Dockerfile.tmp"
    exit /b 0

:build_maven
    echo Building Maven project: !PROJECT_DIR!

    copy Dockerfile.maven "!PROJECT_DIR!\Dockerfile.tmp"

    docker build -f "!PROJECT_DIR!\Dockerfile.tmp" -t java-compiler-temp "!PROJECT_DIR!"
    docker create --name !CONTAINER_NAME! java-compiler-temp

    for %%F in ("!PROJECT_DIR!") do set PROJECT_NAME=%%~nxF
    set OUTPUT_JAR=!PROJECT_NAME!.jar
    docker cp !CONTAINER_NAME!:/build/output.jar ".\!OUTPUT_JAR!"

    docker rm !CONTAINER_NAME!
    docker rmi java-compiler-temp
    del "!PROJECT_DIR!\Dockerfile.tmp"
    exit /b 0

:build_gradle
    echo Building Gradle project: !PROJECT_DIR!

    copy Dockerfile.gradle "!PROJECT_DIR!\Dockerfile.tmp"

    docker build -f "!PROJECT_DIR!\Dockerfile.tmp" -t java-compiler-temp "!PROJECT_DIR!"
    docker create --name !CONTAINER_NAME! java-compiler-temp

    for %%F in ("!PROJECT_DIR!") do set PROJECT_NAME=%%~nxF
    set OUTPUT_JAR=!PROJECT_NAME!.jar
    docker cp !CONTAINER_NAME!:/build/output.jar ".\!OUTPUT_JAR!"

    docker rm !CONTAINER_NAME!
    docker rmi java-compiler-temp
    del "!PROJECT_DIR!\Dockerfile.tmp"
    exit /b 0
