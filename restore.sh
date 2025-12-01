#!/bin/bash

# WordPress Restore Script
# Usage: ./restore.sh <backup_file.tar.gz>

set -e

# Load environment variables
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

if [ -z "$1" ]; then
    echo "Usage: $0 <backup_file.tar.gz>"
    echo "Example: $0 backups/wordpress_backup_20240101_120000.tar.gz"
    exit 1
fi

BACKUP_FILE="$1"
BACKUP_DIR="./backups"
TEMP_DIR="${BACKUP_DIR}/restore_temp"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

if [ ! -f "$BACKUP_FILE" ]; then
    echo -e "${RED}Error: Backup file not found: $BACKUP_FILE${NC}"
    exit 1
fi

echo -e "${YELLOW}WARNING: This will overwrite your current WordPress installation!${NC}"
read -p "Are you sure you want to continue? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Restore cancelled."
    exit 0
fi

echo -e "${GREEN}Starting WordPress restore...${NC}"

# Extract backup
mkdir -p "${TEMP_DIR}"
tar xzf "$BACKUP_FILE" -C "${TEMP_DIR}" --strip-components=1

# Stop WordPress container
echo -e "${YELLOW}Stopping WordPress container...${NC}"
docker-compose stop wordpress

# Restore WordPress files
echo -e "${YELLOW}Restoring WordPress files...${NC}"
docker-compose run --rm backup sh -c "rm -rf /var/www/html/* && tar xzf /backups/restore_temp/wordpress_files.tar.gz -C /var/www/html"

# Restore WordPress config fix if it exists in backup
if [ -f "${TEMP_DIR}/wordpress-config-fix.php" ]; then
    echo -e "${YELLOW}Restoring WordPress config fix...${NC}"
    cp "${TEMP_DIR}/wordpress-config-fix.php" ./wordpress-config-fix.php
    # Ensure mu-plugins directory exists and fix is in place
    docker-compose exec wordpress mkdir -p /var/www/html/wp-content/mu-plugins 2>/dev/null || true
    docker-compose cp wordpress-config-fix.php wordpress:/var/www/html/wp-content/mu-plugins/wordpress-config-fix.php 2>/dev/null || true
    docker-compose exec wordpress chown www-data:www-data /var/www/html/wp-content/mu-plugins/wordpress-config-fix.php 2>/dev/null || true
    docker-compose exec wordpress chmod 644 /var/www/html/wp-content/mu-plugins/wordpress-config-fix.php 2>/dev/null || true
fi

# Restore database
echo -e "${YELLOW}Restoring MySQL database...${NC}"
gunzip -c "${TEMP_DIR}/database.sql.gz" | docker-compose exec -T db mysql -u ${MYSQL_USER:-wpuser} -p${MYSQL_PASSWORD} ${MYSQL_DATABASE:-wordpress}

# Cleanup
rm -rf "${TEMP_DIR}"

# Start WordPress container
echo -e "${YELLOW}Starting WordPress container...${NC}"
docker-compose start wordpress

# Wait a moment for container to be ready
sleep 5

# Ensure WordPress filesystem fix is installed
echo -e "${YELLOW}Ensuring WordPress filesystem fix is installed...${NC}"
if [ -f "./fix-wordpress-filesystem.sh" ]; then
    ./fix-wordpress-filesystem.sh 2>/dev/null || echo "Note: Filesystem fix installation skipped (may already be installed)"
fi

echo -e "${GREEN}Restore completed successfully!${NC}"
echo -e "${YELLOW}Note: If you have issues installing plugins, run: ./fix-wordpress-filesystem.sh${NC}"
