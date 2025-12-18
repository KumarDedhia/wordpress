#!/bin/bash

# Fix Docker volume permissions on Linux
# Run this script if you encounter "operation not permitted" errors

set -e

# Detect if we need sudo for docker commands
DOCKER_CMD="docker"
DOCKER_COMPOSE_CMD="docker-compose"

# Check if docker command works without sudo
if ! $DOCKER_CMD ps >/dev/null 2>&1; then
    # Try with sudo
    if sudo $DOCKER_CMD ps >/dev/null 2>&1; then
        DOCKER_CMD="sudo docker"
        DOCKER_COMPOSE_CMD="sudo docker-compose"
    else
        echo "Error: Cannot access Docker. Make sure Docker is running and you have permissions."
        echo "Try: sudo usermod -aG docker $USER (then log out and back in)"
        exit 1
    fi
fi

echo "Fixing Docker volume permissions..."

# Stop containers (ignore errors if already stopped)
echo "Stopping containers..."
$DOCKER_COMPOSE_CMD down 2>/dev/null || true

# Force stop any remaining containers
echo "Force stopping any remaining containers..."
$DOCKER_CMD stop wordpress_app wordpress_db wordpress_ftp 2>/dev/null || true
$DOCKER_CMD rm -f wordpress_app wordpress_db wordpress_ftp 2>/dev/null || true

# Remove the problematic volume
echo "Removing wordpress_data volume..."
$DOCKER_CMD volume rm wordpress_wordpress_data 2>/dev/null || true

# Recreate with proper permissions
echo "Recreating volume..."
$DOCKER_CMD volume create wordpress_wordpress_data

# Set proper ownership (www-data user is 33:33)
echo "Setting volume permissions..."
$DOCKER_CMD run --rm -v wordpress_wordpress_data:/var/www/html alpine chown -R 33:33 /var/www/html

echo "Done! Now try: docker-compose up -d"
