#!/bin/bash

# Clean restart script to fix port conflicts

set -e

echo "Pulling latest changes from git..."
git pull || echo "Warning: git pull failed or not a git repository, continuing..."

echo "Stopping all containers..."
docker-compose down

echo "Removing FTP container if it exists..."
docker rm -f wordpress_ftp 2>/dev/null || true

echo "Checking for port conflicts..."
if lsof -i :2121 >/dev/null 2>&1; then
    echo "WARNING: Port 2121 is already in use!"
    echo "Processes using port 2121:"
    lsof -i :2121
    echo ""
    read -p "Continue anyway? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo "Starting containers with new configuration..."
docker-compose up -d

echo "Checking container status..."
docker-compose ps

echo ""
echo "FTP should now be running on port 2121"
echo "Check with: docker-compose ps"
