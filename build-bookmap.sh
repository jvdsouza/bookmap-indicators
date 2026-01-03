#!/bin/bash

# Wrapper script for building Bookmap indicators with automatic API detection

if [ $# -eq 0 ]; then
    echo "Usage: ./build-bookmap.sh <indicator.java> [main-class-name]"
    echo ""
    echo "This script automatically finds the Bookmap API and builds your indicator."
    echo ""
    echo "Examples:"
    echo "  ./build-bookmap.sh MyIndicator.java"
    echo "  ./build-bookmap.sh MyIndicator.java MyIndicator"
    echo ""
    echo "For manual classpath control, use: ./build.sh <file> <main-class> <jar-path>"
    exit 1
fi

INPUT_FILE=$1
MAIN_CLASS=$2
ORIGINAL_FILENAME=$(basename "$INPUT_FILE")
ORIGINAL_BASENAME=$(basename "$INPUT_FILE" .java)

# Extract the actual class name from the Java file
ACTUAL_CLASS_NAME=$(grep -oP '^public class \K[A-Za-z0-9_]+' "$INPUT_FILE" 2>/dev/null | head -1)

# Check if filename matches class name
NEEDS_RENAME=0
JAVA_FILE=$INPUT_FILE
TEMP_FILE_CREATED=0

if [ -n "$ACTUAL_CLASS_NAME" ] && [ "$ORIGINAL_BASENAME" != "$ACTUAL_CLASS_NAME" ]; then
    echo ""
    echo "WARNING: File name \"$ORIGINAL_FILENAME\" does not match class name \"$ACTUAL_CLASS_NAME\""
    echo "Creating temporary copy with correct name..."
    NEEDS_RENAME=1
    TEMP_FILE_CREATED=1
    TEMP_DIR=$(dirname "$INPUT_FILE")
    JAVA_FILE="$TEMP_DIR/$ACTUAL_CLASS_NAME.java"
    cp "$INPUT_FILE" "$JAVA_FILE"
    echo ""
fi

# If main class not provided, use actual class name or derive from filename
if [ -z "$MAIN_CLASS" ]; then
    if [ -n "$ACTUAL_CLASS_NAME" ]; then
        MAIN_CLASS=$ACTUAL_CLASS_NAME
    else
        MAIN_CLASS=$ORIGINAL_BASENAME
    fi
fi

echo "=========================================="
echo "Bookmap Indicator Builder"
echo "=========================================="
echo ""

# Check if required Docker images exist
echo "Checking Docker environment..."

IMAGES_MISSING=0

if ! docker image inspect eclipse-temurin:8-jdk &>/dev/null; then
    IMAGES_MISSING=1
fi

if ! docker image inspect maven:3.9-eclipse-temurin-8 &>/dev/null; then
    IMAGES_MISSING=1
fi

if ! docker image inspect gradle:8.5-jdk17 &>/dev/null; then
    IMAGES_MISSING=1
fi

if [ "$IMAGES_MISSING" -eq 1 ]; then
    echo ""
    echo "One or more required Docker base images are missing."
    echo "Required images:"
    echo "  - eclipse-temurin:8-jdk"
    echo "  - maven:3.9-eclipse-temurin-8"
    echo "  - gradle:8.5-jdk17"
    echo ""
    echo "Downloading required Docker images automatically..."
    echo "This may take a few minutes depending on your connection."
    echo ""
    ./rebuild-image.sh
    if [ $? -ne 0 ]; then
        echo ""
        echo "ERROR: Failed to download Docker images."
        echo "Please ensure Docker is running and try again."
        exit 1
    fi
    echo ""
    echo "Docker images ready. Continuing with build..."
    echo ""
fi

echo "Searching for Bookmap installation..."

BOOKMAP_FOUND=0
BOOKMAP_DIR=""

# First check common installation paths (faster)
if [ -d "/opt/bookmap/lib" ]; then
    BOOKMAP_DIR="/opt/bookmap/lib"
    BOOKMAP_FOUND=1
elif [ -d "$HOME/bookmap/lib" ]; then
    BOOKMAP_DIR="$HOME/bookmap/lib"
    BOOKMAP_FOUND=1
elif [ -d "$HOME/Bookmap/lib" ]; then
    BOOKMAP_DIR="$HOME/Bookmap/lib"
    BOOKMAP_FOUND=1
elif [ -d "/usr/local/bookmap/lib" ]; then
    BOOKMAP_DIR="/usr/local/bookmap/lib"
    BOOKMAP_FOUND=1
elif [ -d "/Applications/Bookmap.app/Contents/lib" ]; then
    BOOKMAP_DIR="/Applications/Bookmap.app/Contents/lib"
    BOOKMAP_FOUND=1
elif [ -d "/c/Bookmap/lib" ]; then
    BOOKMAP_DIR="/c/Bookmap/lib"
    BOOKMAP_FOUND=1
elif [ -d "/c/Program_Files/Bookmap/lib" ]; then
    BOOKMAP_DIR="/c/Program_Files/Bookmap/lib"
    BOOKMAP_FOUND=1
elif [ -d "/c/Program Files/Bookmap/lib" ]; then
    BOOKMAP_DIR="/c/Program Files/Bookmap/lib"
    BOOKMAP_FOUND=1
fi

# If not found in common paths, search for Bookmap folder
if [ "$BOOKMAP_FOUND" -eq 0 ]; then
    echo "Common paths not found, searching filesystem..."
    echo "This may take a moment..."

    # Search common locations for Bookmap directory
    for search_path in "$HOME" "/opt" "/usr/local" "/c" "/c/Program Files" "/c/Program_Files"; do
        if [ -d "$search_path" ]; then
            found_dir=$(find "$search_path" -maxdepth 3 -type d -name "Bookmap" 2>/dev/null | head -1)
            if [ -n "$found_dir" ] && [ -d "$found_dir/lib" ]; then
                # Verify it contains Bookmap API JARs
                if [ -f "$found_dir/lib/bm-l1api.jar" ] || ls "$found_dir/lib/api-core"*.jar >/dev/null 2>&1; then
                    BOOKMAP_DIR="$found_dir/lib"
                    BOOKMAP_FOUND=1
                    break
                fi
            fi
        fi
    done
fi

if [ "$BOOKMAP_FOUND" -eq 0 ]; then
    echo "ERROR: Bookmap installation not found!"
    echo ""
    echo "Searched locations:"
    echo "  - /opt/bookmap/lib"
    echo "  - $HOME/bookmap/lib"
    echo "  - $HOME/Bookmap/lib"
    echo "  - /usr/local/bookmap/lib"
    echo "  - /Applications/Bookmap.app/Contents/lib (Mac)"
    echo "  - /c/Bookmap/lib (Windows via Git Bash)"
    echo "  - /c/Program_Files/Bookmap/lib (Windows via Git Bash)"
    echo ""
    echo "Please install Bookmap or use build.sh with manual classpath:"
    echo "  ./build.sh \"$JAVA_FILE\" \"$MAIN_CLASS\" \"path/to/api-core.jar\""
    echo ""
    echo "Or run ./find-bookmap-api.sh to locate your installation."
    exit 1
fi

echo "Found Bookmap at: $BOOKMAP_DIR"
echo ""
echo "Detecting required API JARs from imports..."

# Build classpath with all relevant Bookmap API JARs
CLASSPATH_JARS=""

# Add core API JARs (free version)
if [ -f "$BOOKMAP_DIR/bm-l1api.jar" ]; then
    CLASSPATH_JARS="${CLASSPATH_JARS}${BOOKMAP_DIR}/bm-l1api.jar:"
    echo "  + bm-l1api.jar"
fi

if [ -f "$BOOKMAP_DIR/bm-simplified-api-wrapper.jar" ]; then
    CLASSPATH_JARS="${CLASSPATH_JARS}${BOOKMAP_DIR}/bm-simplified-api-wrapper.jar:"
    echo "  + bm-simplified-api-wrapper.jar"
fi

# Add commercial version JARs
for jar in "$BOOKMAP_DIR"/api-core*.jar; do
    if [ -f "$jar" ]; then
        CLASSPATH_JARS="${CLASSPATH_JARS}${jar}:"
        echo "  + $(basename "$jar")"
    fi
done

for jar in "$BOOKMAP_DIR"/api-simplified*.jar; do
    if [ -f "$jar" ]; then
        CLASSPATH_JARS="${CLASSPATH_JARS}${jar}:"
        echo "  + $(basename "$jar")"
    fi
done

# Remove trailing colon
CLASSPATH_JARS="${CLASSPATH_JARS%:}"

if [ -z "$CLASSPATH_JARS" ]; then
    echo "ERROR: No Bookmap API JARs found in $BOOKMAP_DIR"
    echo "Looking for: bm-l1api.jar, bm-simplified-api-wrapper.jar, api-core*.jar, or api-simplified*.jar"
    echo ""
    echo "Available JAR files:"
    ls -1 "$BOOKMAP_DIR"/*.jar
    echo ""
    echo "Please specify the JAR manually:"
    echo "  ./build.sh \"$JAVA_FILE\" \"$MAIN_CLASS\" \"$BOOKMAP_DIR/your-api.jar\""
    exit 1
fi

echo ""
echo "Using classpath: $CLASSPATH_JARS"
echo ""
echo "Building indicator: $JAVA_FILE"
echo "Main class: $MAIN_CLASS"
echo ""
echo "=========================================="
echo ""

# Call the main build script with the detected classpath
./build.sh "$JAVA_FILE" "$MAIN_CLASS" "$CLASSPATH_JARS"

BUILD_RESULT=$?

# Handle file renaming if needed
if [ "$TEMP_FILE_CREATED" -eq 1 ]; then
    if [ $BUILD_RESULT -eq 0 ]; then
        echo ""
        echo "Renaming output JAR to match original filename..."
        if [ -f "$ACTUAL_CLASS_NAME.jar" ]; then
            mv "$ACTUAL_CLASS_NAME.jar" "$ORIGINAL_BASENAME.jar"
            echo "Output: $ORIGINAL_BASENAME.jar"
        fi
    fi

    # Delete the temporary file
    if [ -f "$JAVA_FILE" ]; then
        rm "$JAVA_FILE"
    fi
fi

exit $BUILD_RESULT
