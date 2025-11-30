#!/bin/bash

# Fix WordPress filesystem access for plugin/theme installation

set -e

echo "Installing WordPress filesystem fix..."

# Check if containers are running
if ! docker-compose ps | grep -q "wordpress_app.*Up"; then
    echo "Error: WordPress container is not running. Start it first with: docker-compose up -d"
    exit 1
fi

# Ensure mu-plugins directory exists (the file is already mounted via docker-compose)
docker-compose exec wordpress mkdir -p /var/www/html/wp-content/mu-plugins 2>/dev/null || true

# Verify the fix file is in place (it should be mounted, but let's ensure it's there)
if docker-compose exec -T wordpress test -f /var/www/html/wp-content/mu-plugins/wordpress-config-fix.php; then
    echo "✓ WordPress filesystem fix is already installed (mounted via docker-compose)"
else
    # If not mounted, copy it manually
    echo "Copying filesystem fix to mu-plugins directory..."
    docker-compose cp wordpress-config-fix.php wordpress:/var/www/html/wp-content/mu-plugins/wordpress-config-fix.php
    docker-compose exec wordpress chown www-data:www-data /var/www/html/wp-content/mu-plugins/wordpress-config-fix.php
    docker-compose exec wordpress chmod 644 /var/www/html/wp-content/mu-plugins/wordpress-config-fix.php
    echo "✓ WordPress filesystem fix installed!"
fi

echo ""
echo "WordPress will now use direct filesystem access (no FTP required)"
echo "You can now install/update plugins and themes from the WordPress admin"
