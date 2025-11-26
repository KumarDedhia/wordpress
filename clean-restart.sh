#!/bin/bash

# Clean restart script to fix port conflicts

set -e

echo "Checking for local changes..."
if git diff --quiet && git diff --cached --quiet; then
    echo "No local changes detected"
else
    echo "Stashing local changes..."
    git stash push -m "Auto-stashed by clean-restart.sh on $(date +%Y-%m-%d_%H:%M:%S)" || echo "Warning: git stash failed, continuing..."
fi

echo "Pulling latest changes from git..."
git pull || echo "Warning: git pull failed or not a git repository, continuing..."

echo "Setting all .sh files to executable..."
find . -maxdepth 1 -name "*.sh" -type f -exec chmod +x {} \;
echo "✓ All shell scripts are now executable"

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
