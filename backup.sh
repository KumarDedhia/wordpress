#!/bin/bash

# WordPress Backup Script
# This script creates backups of WordPress files and database

set -e

# Load environment variables
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

BACKUP_DIR="./backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="wordpress_backup_${TIMESTAMP}"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting WordPress backup...${NC}"

# Check if containers are running
if ! docker-compose ps | grep -q "wordpress_app.*Up"; then
    echo -e "${YELLOW}Warning: WordPress container is not running. Starting containers...${NC}"
    docker-compose up -d
    sleep 5
fi

# Create backup directory if it doesn't exist
mkdir -p "${BACKUP_DIR}"

# Ensure backups directory is writable
chmod 777 "${BACKUP_DIR}" 2>/dev/null || true

# Create timestamped backup directory
BACKUP_PATH="${BACKUP_DIR}/${BACKUP_NAME}"
mkdir -p "${BACKUP_PATH}"
chmod 777 "${BACKUP_PATH}" 2>/dev/null || true

echo -e "${YELLOW}Backing up WordPress files...${NC}"
# Create directory inside container first, then backup
# This includes wp-content/mu-plugins/wordpress-config-fix.php (filesystem fix)
docker-compose run --rm backup sh -c "mkdir -p /backups/${BACKUP_NAME} && chmod 777 /backups/${BACKUP_NAME} && tar czf /backups/${BACKUP_NAME}/wordpress_files.tar.gz -C /var/www/html ."

# Also backup the local config fix file (in case it's not in the volume)
if [ -f "wordpress-config-fix.php" ]; then
    echo -e "${YELLOW}Backing up local WordPress config fix...${NC}"
    cp wordpress-config-fix.php "${BACKUP_PATH}/wordpress-config-fix.php"
fi

echo -e "${YELLOW}Backing up MySQL database...${NC}"
docker-compose exec -T db mysqldump -u ${MYSQL_USER:-wpuser} -p${MYSQL_PASSWORD} --no-tablespaces --single-transaction --quick --lock-tables=false ${MYSQL_DATABASE:-wordpress} > "${BACKUP_PATH}/database.sql"

# Compress database backup
gzip "${BACKUP_PATH}/database.sql"

echo -e "${YELLOW}Creating backup archive...${NC}"
cd "${BACKUP_DIR}"
tar czf "${BACKUP_NAME}.tar.gz" "${BACKUP_NAME}"
rm -rf "${BACKUP_NAME}"

# Display backup info
BACKUP_SIZE=$(du -h "${BACKUP_NAME}.tar.gz" | cut -f1)
echo -e "${GREEN}Backup size: ${BACKUP_SIZE}${NC}"

echo -e "${GREEN}Backup completed: ${BACKUP_PATH}.tar.gz${NC}"

# Optional: Keep only last 7 days of backups
echo -e "${YELLOW}Cleaning up old backups (keeping last 7 days)...${NC}"
find "${BACKUP_DIR}" -name "wordpress_backup_*.tar.gz" -mtime +7 -delete

echo -e "${GREEN}Backup process completed successfully!${NC}"
