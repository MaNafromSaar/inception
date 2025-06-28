#!/bin/bash

# Simple script to check for Docker and Docker Compose

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

echo "--- Inception Dependency Check ---"

# --- Check for Docker ---
echo "Checking for Docker..."
if command_exists docker; then
    echo "✅ Docker is installed."
    docker --version
else
    echo "❌ Docker is not installed."
    echo "Please install Docker for your system."
    if [[ "$(uname)" == "Darwin" ]]; then
        echo "On macOS, install Docker Desktop: https://www.docker.com/products/docker-desktop/"
    elif [[ "$(uname)" == "Linux" ]]; then
        echo "On Debian/Ubuntu, follow the official guide: https://docs.docker.com/engine/install/debian/"
    fi
    exit 1
fi

echo ""

# --- Check for Docker Compose ---
echo "Checking for Docker Compose..."
if docker compose version >/dev/null 2>&1; then
    echo "✅ Docker Compose (v2 plugin) is installed."
    docker compose version
elif command_exists docker-compose; then
    echo "✅ Docker Compose (v1 standalone) is installed."
    docker-compose --version
else
    echo "❌ Docker Compose is not installed."
    echo "Please install Docker Compose."
     if [[ "$(uname)" == "Darwin" ]]; then
        echo "On macOS, Docker Compose is included with Docker Desktop. Make sure Docker Desktop is running."
    elif [[ "$(uname)" == "Linux" ]]; then
        echo "Follow the official guide to install the Docker Compose plugin: https://docs.docker.com/compose/install/linux/"
    fi
    exit 1
fi

echo ""
echo "✅ All dependencies are satisfied."
echo "------------------------------------"
