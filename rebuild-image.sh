#!/bin/bash

# Script to rebuild/refresh Docker base images used by build.sh
# This ensures you have the latest base images and clears any cached builds

echo "=========================================="
echo "Rebuilding Docker Base Images"
echo "=========================================="
echo ""

# Pull the base images
echo "Pulling eclipse-temurin:8-jdk..."
docker pull eclipse-temurin:8-jdk

echo ""
echo "Pulling maven:3.9-eclipse-temurin-8..."
docker pull maven:3.9-eclipse-temurin-8

echo ""
echo "Pulling gradle:8.5-jdk17..."
docker pull gradle:8.5-jdk17

echo ""
echo "=========================================="
echo "Cleaning up old build artifacts..."
echo "=========================================="

# Remove any leftover java-compiler-temp images/containers
docker rm $(docker ps -a -q -f name=java-build-) 2>/dev/null || echo "No old containers to remove"
docker rmi java-compiler-temp 2>/dev/null || echo "No old temp images to remove"

# Optional: Prune dangling images
echo ""
read -p "Do you want to remove dangling Docker images? (y/n) " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    docker image prune -f
    echo "Dangling images removed"
fi

echo ""
echo "=========================================="
echo "Image rebuild complete!"
echo "=========================================="
echo ""
echo "Base images ready:"
echo "  - eclipse-temurin:8-jdk (for single/multi-file Java)"
echo "  - maven:3.9-eclipse-temurin-8 (for Maven projects)"
echo "  - gradle:8.5-jdk17 (for Gradle projects)"
echo ""
