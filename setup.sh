#!/bin/bash

# WordPress Docker Setup Script

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Convert memory string like 512M/1G to MB
to_mb() {
  local val="$1"
  local num unit
  num="${val%[MmGg]}"
  unit="${val: -1}"
  if [[ "$unit" == "G" || "$unit" == "g" ]]; then
    echo $((num * 1024))
  else
    echo "$num"
  fi
}

check_memory_resources() {
  echo -e "${GREEN}Checking system memory vs PHP/WordPress limits...${NC}"

  # Detect total system memory (MB)
  local total_mb="0"
  if [ -r /proc/meminfo ]; then
    # Linux
    local kb
    kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    total_mb=$((kb / 1024))
  else
    # macOS / other (best-effort)
    if command -v sysctl >/dev/null 2>&1; then
      local bytes
      bytes=$(sysctl -n hw.memsize 2>/dev/null || echo 0)
      total_mb=$((bytes / 1024 / 1024))
    fi
  fi

  if [ "$total_mb" -le 0 ]; then
    echo -e "${YELLOW}Could not detect total system memory. Skipping resource check.${NC}"
    return 0
  fi

  # Read PHP limits from uploads.ini if present
  local php_mem="512M"
  local php_post="256M"
  local php_upload="256M"
  local php_input_vars="5000"

  if [ -f "uploads.ini" ]; then
    php_mem=$(grep -i '^memory_limit' uploads.ini | awk -F'=' '{gsub(/ /,"",$2);print $2}' || echo "$php_mem")
    php_post=$(grep -i '^post_max_size' uploads.ini | awk -F'=' '{gsub(/ /,"",$2);print $2}' || echo "$php_post")
    php_upload=$(grep -i '^upload_max_filesize' uploads.ini | awk -F'=' '{gsub(/ /,"",$2);print $2}' || echo "$php_upload")
    php_input_vars=$(grep -i '^max_input_vars' uploads.ini | awk -F'=' '{gsub(/ /,"",$2);print $2}' || echo "$php_input_vars")
  fi

  local php_mem_mb php_post_mb php_upload_mb
  php_mem_mb=$(to_mb "$php_mem")
  php_post_mb=$(to_mb "$php_post")
  php_upload_mb=$(to_mb "$php_upload")

  echo -e "  System memory:        ${total_mb} MB"
  echo -e "  PHP memory_limit:     ${php_mem} (${php_mem_mb} MB)"
  echo -e "  PHP post_max_size:    ${php_post} (${php_post_mb} MB)"
  echo -e "  PHP upload_max_filesize: ${php_upload} (${php_upload_mb} MB)"
  echo -e "  PHP max_input_vars:   ${php_input_vars}"

  # Basic sanity checks
  if [ "$php_post_mb" -gt "$php_mem_mb" ] || [ "$php_upload_mb" -gt "$php_mem_mb" ]; then
    echo -e "${YELLOW}Warning: post_max_size / upload_max_filesize are larger than memory_limit.${NC}"
    echo -e "${YELLOW}         Consider increasing memory_limit or reducing these sizes.${NC}"
  fi

  # Warn if PHP memory_limit is very high compared to system RAM
  if [ "$php_mem_mb" -gt $(( total_mb - 256 )) ]; then
    echo -e "${YELLOW}Warning: PHP memory_limit is close to or above available system memory.${NC}"
    echo -e "${YELLOW}         You may want to lower memory_limit or increase server RAM.${NC}"
  fi

  # Soft recommendation: at least 1 GB RAM for this config
  if [ "$total_mb" -lt 1024 ]; then
    echo -e "${YELLOW}Warning: Total system memory (${total_mb} MB) is below the recommended 1024 MB for this setup.${NC}"
  fi
}

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
chmod +x backup.sh restore.sh fix-wordpress-filesystem.sh 2>/dev/null || true

echo ""
check_memory_resources

echo -e "${GREEN}✓ Setup complete!${NC}"
echo ""
echo "Next steps:"
echo "1. Review .env file and adjust settings if needed"
echo "2. Run: docker-compose up -d"
echo "3. Wait for containers to start (about 30 seconds), then run:"
echo "   ./fix-wordpress-filesystem.sh"
echo "4. Access WordPress at: http://localhost:8081"
echo ""
read -p "Do you want to start containers now and install the filesystem fix? (yes/no): " start_now

if [ "$start_now" = "yes" ]; then
    echo ""
    echo -e "${GREEN}Starting containers...${NC}"
    docker-compose up -d

    echo -e "${YELLOW}Waiting for WordPress container to be ready...${NC}"
    sleep 10

    echo -e "${GREEN}Installing WordPress filesystem fix...${NC}"
    ./fix-wordpress-filesystem.sh

    echo ""
    echo -e "${GREEN}✓ All done! WordPress is ready at http://localhost:8081${NC}"
else
    echo ""
    echo -e "${YELLOW}Remember to run './fix-wordpress-filesystem.sh' after starting containers!${NC}"
fi
echo ""
