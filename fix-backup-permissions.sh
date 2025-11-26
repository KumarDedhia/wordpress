#!/bin/bash

# Fix backup directory permissions

set -e

BACKUP_DIR="./backups"

echo "Fixing backup directory permissions..."

# Create directory if it doesn't exist
mkdir -p "${BACKUP_DIR}"

# Set permissions so Docker containers can write
chmod 777 "${BACKUP_DIR}"

# Fix ownership (optional, adjust UID/GID if needed)
# chown -R $(id -u):$(id -g) "${BACKUP_DIR}"

echo "Backup directory permissions fixed!"
echo "Directory: ${BACKUP_DIR}"
ls -ld "${BACKUP_DIR}"
