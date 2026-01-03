#!/bin/bash

# Script to locate Bookmap API JAR files on Linux/Mac

echo "Searching for Bookmap installation..."
echo ""

BOOKMAP_FOUND=0
BOOKMAP_DIR=""

# Check common installation paths
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
fi

if [ "$BOOKMAP_FOUND" -eq 0 ]; then
    echo "ERROR: Bookmap installation not found in standard locations."
    echo ""
    echo "Please check these locations manually:"
    echo "  - /opt/bookmap/lib"
    echo "  - $HOME/bookmap/lib"
    echo "  - $HOME/Bookmap/lib"
    echo "  - /usr/local/bookmap/lib"
    echo "  - /Applications/Bookmap.app/Contents/lib (Mac)"
    echo "  - /c/Bookmap/lib (Windows via Git Bash)"
    echo "  - /c/Program_Files/Bookmap/lib (Windows via Git Bash)"
    echo ""
    echo "Or locate your Bookmap installation directory and look in the 'lib' folder."
    exit 1
fi

echo "Found Bookmap at: $BOOKMAP_DIR"
echo ""
echo "API JAR files:"
echo "================================================================================"

API_FOUND=0

# Check for api-core (commercial)
if ls "$BOOKMAP_DIR"/api-core*.jar 1> /dev/null 2>&1; then
    ls -1 "$BOOKMAP_DIR"/api-core*.jar
    API_FOUND=1
fi

# Check for bm-l1api (free)
if ls "$BOOKMAP_DIR"/bm-l1api.jar 1> /dev/null 2>&1; then
    ls -1 "$BOOKMAP_DIR"/bm-l1api.jar
    API_FOUND=1
fi

if [ "$API_FOUND" -eq 0 ]; then
    echo "No Bookmap API JAR files found!"
    echo "Looking for: api-core*.jar or bm-l1api.jar"
    echo ""
    echo "All JAR files in lib directory:"
    ls -1 "$BOOKMAP_DIR"/*.jar
else
    echo ""
    echo "================================================================================"
    echo ""
    echo "To build a Bookmap indicator, use:"
    echo ""

    # Try api-core first
    API_CORE=$(ls "$BOOKMAP_DIR"/api-core*.jar 2>/dev/null | head -1)
    if [ -n "$API_CORE" ]; then
        echo "./build.sh YourIndicator.java YourIndicator \"$API_CORE\""
    else
        # Fall back to bm-l1api
        if [ -f "$BOOKMAP_DIR/bm-l1api.jar" ]; then
            echo "./build.sh YourIndicator.java YourIndicator \"$BOOKMAP_DIR/bm-l1api.jar\""
        fi
    fi
fi

echo ""
