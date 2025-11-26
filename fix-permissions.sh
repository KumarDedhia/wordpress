#!/bin/bash

# Fix Docker volume permissions on Linux
# Run this script if you encounter "operation not permitted" errors

set -e

echo "Fixing Docker volume permissions..."

# Stop containers
docker-compose down

# Remove the problematic volume
echo "Removing wordpress_data volume..."
docker volume rm wordpress_wordpress_data 2>/dev/null || true

# Recreate with proper permissions
echo "Recreating volume..."
docker volume create wordpress_wordpress_data

# Set proper ownership (www-data user is 33:33)
echo "Setting volume permissions..."
docker run --rm -v wordpress_wordpress_data:/var/www/html alpine chown -R 33:33 /var/www/html

echo "Done! Now try: docker-compose up -d"

