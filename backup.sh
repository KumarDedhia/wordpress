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

# Create backup directory if it doesn't exist
mkdir -p "${BACKUP_DIR}"

# Create timestamped backup directory
BACKUP_PATH="${BACKUP_DIR}/${BACKUP_NAME}"
mkdir -p "${BACKUP_PATH}"

echo -e "${YELLOW}Backing up WordPress files...${NC}"
docker-compose run --rm backup tar czf /backups/${BACKUP_NAME}/wordpress_files.tar.gz -C /var/www/html .

echo -e "${YELLOW}Backing up MySQL database...${NC}"
docker-compose exec -T db mysqldump -u ${MYSQL_USER:-wpuser} -p${MYSQL_PASSWORD} ${MYSQL_DATABASE:-wordpress} > "${BACKUP_PATH}/database.sql"

# Compress database backup
gzip "${BACKUP_PATH}/database.sql"

echo -e "${YELLOW}Creating backup archive...${NC}"
cd "${BACKUP_DIR}"
tar czf "${BACKUP_NAME}.tar.gz" "${BACKUP_NAME}"
rm -rf "${BACKUP_NAME}"

echo -e "${GREEN}Backup completed: ${BACKUP_PATH}.tar.gz${NC}"

# Optional: Keep only last 7 days of backups
echo -e "${YELLOW}Cleaning up old backups (keeping last 7 days)...${NC}"
find "${BACKUP_DIR}" -name "wordpress_backup_*.tar.gz" -mtime +7 -delete

echo -e "${GREEN}Backup process completed successfully!${NC}"
