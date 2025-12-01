#!/bin/bash

# Fix WordPress filesystem access for plugin/theme installation

set -e

echo "Installing WordPress filesystem fix..."

# Check if containers are running
if ! docker-compose ps | grep -q "wordpress_app.*Up"; then
    echo "Error: WordPress container is not running. Start it first with: docker-compose up -d"
    exit 1
fi

# Reset permissions so WordPress can write to wp-content (plugins/themes/uploads/upgrade)
echo "Resetting wp-content ownership and permissions..."
# Work as root inside the container so ownership changes succeed
# Skip the read-only mu-plugins mount to avoid errors
docker-compose exec --user root wordpress sh -c \
  "find /var/www/html/wp-content -path /var/www/html/wp-content/mu-plugins -prune -o -exec chown www-data:www-data {} +"

docker-compose exec --user root wordpress sh -c \
  "find /var/www/html/wp-content -path /var/www/html/wp-content/mu-plugins -prune -o -type d -exec chmod 775 {} \;"

docker-compose exec --user root wordpress sh -c \
  "find /var/www/html/wp-content -path /var/www/html/wp-content/mu-plugins -prune -o -type f -exec chmod 664 {} \;"

docker-compose exec --user root wordpress mkdir -p /var/www/html/wp-content/upgrade
docker-compose exec --user root wordpress chmod 775 /var/www/html/wp-content/upgrade
echo "✓ wp-content directory is writable by WordPress"

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
