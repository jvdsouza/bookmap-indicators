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
elif [ -d "/usr/local/bookmap/lib" ]; then
    BOOKMAP_DIR="/usr/local/bookmap/lib"
    BOOKMAP_FOUND=1
elif [ -d "/Applications/Bookmap.app/Contents/lib" ]; then
    BOOKMAP_DIR="/Applications/Bookmap.app/Contents/lib"
    BOOKMAP_FOUND=1
fi

if [ "$BOOKMAP_FOUND" -eq 0 ]; then
    echo "ERROR: Bookmap installation not found in standard locations."
    echo ""
    echo "Please check these locations manually:"
    echo "  - /opt/bookmap/lib"
    echo "  - $HOME/bookmap/lib"
    echo "  - /usr/local/bookmap/lib"
    echo "  - /Applications/Bookmap.app/Contents/lib (Mac)"
    echo ""
    echo "Or locate your Bookmap installation directory and look in the 'lib' folder."
    exit 1
fi

echo "Found Bookmap at: $BOOKMAP_DIR"
echo ""
echo "API JAR files:"
echo "================================================================================"

if ls "$BOOKMAP_DIR"/api-*.jar 1> /dev/null 2>&1; then
    ls -1 "$BOOKMAP_DIR"/api-*.jar
    echo ""
    echo "================================================================================"
    echo ""
    echo "To build a Bookmap indicator, use:"
    echo ""

    API_CORE=$(ls "$BOOKMAP_DIR"/api-core*.jar 2>/dev/null | head -1)
    if [ -n "$API_CORE" ]; then
        echo "./build.sh YourIndicator.java YourIndicator \"$API_CORE\""
    fi
else
    echo "No api-*.jar files found!"
    echo ""
    echo "All JAR files in lib directory:"
    ls -1 "$BOOKMAP_DIR"/*.jar
fi

echo ""
