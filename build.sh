#!/bin/bash

# Script to compile Java projects using Docker and output a JAR file
# Supports: single files, multi-file projects, Maven projects, and Gradle projects

if [ $# -eq 0 ]; then
    echo "Usage: ./build.sh <path-to-file-or-directory> [main-class-name]"
    echo ""
    echo "Examples:"
    echo "  ./build.sh MyApp.java                    - Single Java file"
    echo "  ./build.sh MyApp.java com.example.MyApp  - Single file with explicit main class"
    echo "  ./build.sh ./my-project                  - Multi-file Java project"
    echo "  ./build.sh ./my-maven-project            - Maven project (has pom.xml)"
    echo "  ./build.sh ./my-gradle-project           - Gradle project (has build.gradle)"
    exit 1
fi

INPUT_PATH=$1
CONTAINER_NAME="java-build-$(date +%s)"
PROJECT_TYPE="unknown"
OUTPUT_JAR="output.jar"

# Determine if input is a file or directory
if [ -d "$INPUT_PATH" ]; then
    IS_DIRECTORY=true
    # Get absolute path for directory
    PROJECT_DIR="$(cd "$INPUT_PATH" && pwd)"
elif [ -f "$INPUT_PATH" ]; then
    IS_DIRECTORY=false
    # Get absolute path for file
    JAVA_FILE="$(cd "$(dirname "$INPUT_PATH")" && pwd)/$(basename "$INPUT_PATH")"
    JAVA_FILENAME=$(basename "$JAVA_FILE")
    JAVA_CLASSNAME="${JAVA_FILENAME%.java}"
else
    echo "Error: Path '$INPUT_PATH' not found"
    exit 1
fi

# Detect project type
if [ "$IS_DIRECTORY" = true ]; then
    if [ -f "$PROJECT_DIR/pom.xml" ]; then
        PROJECT_TYPE="maven"
        echo "Detected: Maven project"
    elif [ -f "$PROJECT_DIR/build.gradle" ] || [ -f "$PROJECT_DIR/build.gradle.kts" ]; then
        PROJECT_TYPE="gradle"
        echo "Detected: Gradle project"
    else
        PROJECT_TYPE="multifile"
        echo "Detected: Multi-file Java project"
        if [ -z "$2" ]; then
            echo "Error: Main class name required for multi-file projects"
            echo "Usage: ./build.sh $INPUT_PATH com.example.MainClass"
            exit 1
        fi
        MAIN_CLASS=$2
    fi
else
    PROJECT_TYPE="single"
    echo "Detected: Single Java file"
    if [ -n "$2" ]; then
        MAIN_CLASS=$2
    else
        MAIN_CLASS=$JAVA_CLASSNAME
    fi
fi

# Build functions
build_single_file() {
    echo "Building single Java file: $JAVA_FILE"
    echo "Main class: $MAIN_CLASS"

    BUILD_DIR=$(mktemp -d)
    cp "$JAVA_FILE" "$BUILD_DIR/"

    cat > "$BUILD_DIR/Dockerfile" << EOF
FROM eclipse-temurin:8-jdk
WORKDIR /build
COPY $JAVA_FILENAME .
RUN javac $JAVA_FILENAME
RUN echo "Main-Class: $MAIN_CLASS" > manifest.txt
RUN jar cfm output.jar manifest.txt *.class
CMD ["echo", "Build complete"]
EOF

    docker build -t java-compiler-temp "$BUILD_DIR"
    docker create --name "$CONTAINER_NAME" java-compiler-temp

    OUTPUT_JAR="${JAVA_CLASSNAME}.jar"
    docker cp "$CONTAINER_NAME:/build/output.jar" "./$OUTPUT_JAR"

    docker rm "$CONTAINER_NAME"
    docker rmi java-compiler-temp
    rm -rf "$BUILD_DIR"
}

build_multifile() {
    echo "Building multi-file Java project: $PROJECT_DIR"
    echo "Main class: $MAIN_CLASS"

    SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
    cp "$SCRIPT_DIR/Dockerfile.multifile" "$PROJECT_DIR/Dockerfile.tmp"

    docker build --build-arg MAIN_CLASS="$MAIN_CLASS" -f "$PROJECT_DIR/Dockerfile.tmp" -t java-compiler-temp "$PROJECT_DIR"
    docker create --name "$CONTAINER_NAME" java-compiler-temp

    PROJECT_NAME=$(basename "$PROJECT_DIR")
    OUTPUT_JAR="${PROJECT_NAME}.jar"
    docker cp "$CONTAINER_NAME:/build/output.jar" "./$OUTPUT_JAR"

    docker rm "$CONTAINER_NAME"
    docker rmi java-compiler-temp
    rm "$PROJECT_DIR/Dockerfile.tmp"
}

build_maven() {
    echo "Building Maven project: $PROJECT_DIR"

    SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
    cp "$SCRIPT_DIR/Dockerfile.maven" "$PROJECT_DIR/Dockerfile.tmp"

    docker build -f "$PROJECT_DIR/Dockerfile.tmp" -t java-compiler-temp "$PROJECT_DIR"
    docker create --name "$CONTAINER_NAME" java-compiler-temp

    PROJECT_NAME=$(basename "$PROJECT_DIR")
    OUTPUT_JAR="${PROJECT_NAME}.jar"
    docker cp "$CONTAINER_NAME:/build/output.jar" "./$OUTPUT_JAR"

    docker rm "$CONTAINER_NAME"
    docker rmi java-compiler-temp
    rm "$PROJECT_DIR/Dockerfile.tmp"
}

build_gradle() {
    echo "Building Gradle project: $PROJECT_DIR"

    SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
    cp "$SCRIPT_DIR/Dockerfile.gradle" "$PROJECT_DIR/Dockerfile.tmp"

    docker build -f "$PROJECT_DIR/Dockerfile.tmp" -t java-compiler-temp "$PROJECT_DIR"
    docker create --name "$CONTAINER_NAME" java-compiler-temp

    PROJECT_NAME=$(basename "$PROJECT_DIR")
    OUTPUT_JAR="${PROJECT_NAME}.jar"
    docker cp "$CONTAINER_NAME:/build/output.jar" "./$OUTPUT_JAR"

    docker rm "$CONTAINER_NAME"
    docker rmi java-compiler-temp
    rm "$PROJECT_DIR/Dockerfile.tmp"
}

# Build based on project type
case "$PROJECT_TYPE" in
    single)
        build_single_file
        ;;
    multifile)
        build_multifile
        ;;
    maven)
        build_maven
        ;;
    gradle)
        build_gradle
        ;;
    *)
        echo "Unknown project type"
        exit 1
        ;;
esac

if [ $? -eq 0 ]; then
    echo ""
    echo "========================================"
    echo "Build successful!"
    echo "JAR file: $OUTPUT_JAR"
    echo "========================================"
    echo ""
    echo "To run: java -jar $OUTPUT_JAR"
else
    echo "Build failed!"
    exit 1
fi
