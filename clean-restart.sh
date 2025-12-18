#!/bin/bash

# Clean restart script to fix port conflicts

set -e

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
  echo "Checking system memory vs PHP/WordPress limits..."

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
    echo "  Could not detect total system memory. Skipping resource check."
    return 0
  fi

  # Read PHP limits from uploads.ini if present
  local php_mem="512M"
  local php_post="256M"
  local php_upload="256M"

  if [ -f "uploads.ini" ]; then
    php_mem=$(grep -i '^memory_limit' uploads.ini | awk -F'=' '{gsub(/ /,"",$2);print $2}' || echo "$php_mem")
    php_post=$(grep -i '^post_max_size' uploads.ini | awk -F'=' '{gsub(/ /,"",$2);print $2}' || echo "$php_post")
    php_upload=$(grep -i '^upload_max_filesize' uploads.ini | awk -F'=' '{gsub(/ /,"",$2);print $2}' || echo "$php_upload")
  fi

  local php_mem_mb php_post_mb php_upload_mb
  php_mem_mb=$(to_mb "$php_mem")
  php_post_mb=$(to_mb "$php_post")
  php_upload_mb=$(to_mb "$php_upload")

  echo "  System memory:        ${total_mb} MB"
  echo "  PHP memory_limit:     ${php_mem} (${php_mem_mb} MB)"
  echo "  PHP post_max_size:    ${php_post} (${php_post_mb} MB)"
  echo "  PHP upload_max_filesize: ${php_upload} (${php_upload_mb} MB)"

  if [ "$php_post_mb" -gt "$php_mem_mb" ] || [ "$php_upload_mb" -gt "$php_mem_mb" ]; then
    echo "  Warning: post_max_size / upload_max_filesize are larger than memory_limit."
    echo "           Consider increasing memory_limit or reducing these sizes."
  fi

  if [ "$php_mem_mb" -gt $(( total_mb - 256 )) ]; then
    echo "  Warning: PHP memory_limit is close to or above available system memory."
    echo "           You may want to lower memory_limit or increase server RAM."
  fi

  if [ "$total_mb" -lt 1024 ]; then
    echo "  Warning: Total system memory (${total_mb} MB) is below the recommended 1024 MB for this setup."
  fi
}

check_memory_resources

echo "Checking for local changes..."
if git diff --quiet && git diff --cached --quiet; then
    echo "No local changes detected"
else
    echo "Stashing local changes..."
    git stash push -m "Auto-stashed by clean-restart.sh on $(date +%Y-%m-%d_%H:%M:%S)" || echo "Warning: git stash failed, continuing..."
fi

echo "Pulling latest changes from git..."
git pull || echo "Warning: git pull failed or not a git repository, continuing..."

echo "Setting all .sh files to executable..."
find . -maxdepth 1 -name "*.sh" -type f -exec chmod +x {} \;
echo "✓ All shell scripts are now executable"

echo "Stopping all containers..."
if ! docker-compose down 2>/dev/null; then
    echo "Warning: docker-compose down failed, trying force stop..."
    # Force stop containers individually
    docker stop wordpress_app wordpress_db wordpress_ftp 2>/dev/null || true
    docker rm -f wordpress_app wordpress_db wordpress_ftp 2>/dev/null || true
    # Try docker-compose down again
    docker-compose down 2>/dev/null || true
fi

echo "Removing FTP container if it exists..."
docker rm -f wordpress_ftp 2>/dev/null || true

echo "Checking for port conflicts..."
if lsof -i :2121 >/dev/null 2>&1; then
    echo "WARNING: Port 2121 is already in use!"
    echo "Processes using port 2121:"
    lsof -i :2121
    echo ""
    read -p "Continue anyway? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo "Starting containers with new configuration..."
docker-compose up -d

echo "Checking container status..."
docker-compose ps

echo ""
echo "FTP should now be running on port 2121"
echo "Check with: docker-compose ps"

if [ -x "./fix-wordpress-filesystem.sh" ]; then
    echo ""
    echo "Reapplying WordPress filesystem permissions/fix..."
    if ./fix-wordpress-filesystem.sh; then
        echo "✓ WordPress filesystem fix re-applied successfully."
    else
        echo "Warning: fix-wordpress-filesystem.sh encountered an error. Run it manually if needed."
    fi
else
    echo ""
    echo "Note: fix-wordpress-filesystem.sh not found or not executable. Run it manually if plugin installs fail."
fi
