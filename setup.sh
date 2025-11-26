#!/bin/bash

# WordPress Docker Setup Script

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}WordPress Docker Setup${NC}"
echo ""

# Check if .env exists
if [ -f ".env" ]; then
    echo -e "${YELLOW}.env file already exists.${NC}"
    read -p "Do you want to overwrite it? (yes/no): " overwrite
    if [ "$overwrite" != "yes" ]; then
        echo "Setup cancelled."
        exit 0
    fi
fi

# Copy template
cp env.template .env

# Generate passwords
echo -e "${GREEN}Generating secure passwords...${NC}"
MYSQL_PASS=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
MYSQL_ROOT_PASS=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
FTP_PASS=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)

# Update .env with generated passwords
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    sed -i '' "s/MYSQL_PASSWORD=.*/MYSQL_PASSWORD=${MYSQL_PASS}/" .env
    sed -i '' "s/MYSQL_ROOT_PASSWORD=.*/MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASS}/" .env
    sed -i '' "s/FTP_PASS=.*/FTP_PASS=${FTP_PASS}/" .env
else
    # Linux
    sed -i "s/MYSQL_PASSWORD=.*/MYSQL_PASSWORD=${MYSQL_PASS}/" .env
    sed -i "s/MYSQL_ROOT_PASSWORD=.*/MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASS}/" .env
    sed -i "s/FTP_PASS=.*/FTP_PASS=${FTP_PASS}/" .env
fi

echo -e "${GREEN}✓ Passwords generated and saved to .env${NC}"
echo ""
echo -e "${YELLOW}IMPORTANT: Save these passwords securely!${NC}"
echo "MySQL Password: ${MYSQL_PASS}"
echo "MySQL Root Password: ${MYSQL_ROOT_PASS}"
echo "FTP Password: ${FTP_PASS}"
echo ""

# Create directories
echo -e "${GREEN}Creating necessary directories...${NC}"
mkdir -p backups
mkdir -p ftp-logs
touch backups/.gitkeep

# Set permissions
chmod +x backup.sh restore.sh

echo -e "${GREEN}✓ Setup complete!${NC}"
echo ""
echo "Next steps:"
echo "1. Review .env file and adjust settings if needed"
echo "2. Run: docker-compose up -d"
echo "3. Access WordPress at: http://localhost:8080"
echo ""
