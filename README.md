# WordPress Docker Setup with Security & Backup

A secure, production-ready WordPress Docker setup with MySQL, FTP support, and automated backups.

## Features

- ✅ **Security Hardened**: Non-root containers, security headers, file editing disabled
- ✅ **Easy Backups**: Automated backup scripts for files and database
- ✅ **FTP Support**: Integrated FTP server for file management
- ✅ **Health Checks**: Automatic container health monitoring
- ✅ **Volume Management**: Persistent data storage with Docker volumes

## Prerequisites

- **Docker Engine**: Version 20.10+ recommended. Verify with:

```bash
docker --version
```

- **Docker Compose**: Prefer the Compose v2 plugin (`docker compose`) or the standalone `docker-compose`. Verify with:

```bash
docker compose version
# or for legacy
docker-compose --version
```

- **System resources**: At least 2 GB RAM, 2 CPU cores, and ~10 GB free disk space for images/volumes.

- **Open ports**: Ensure the host ports you plan to use are available (default values used by this setup):
    - WordPress: `8081` (map to container port 80)
    - FTP control: `2121`
    - FTP passive range: `21100-21110`

- **Firewall / NAT**: If the server is behind a firewall or NAT, open/forward the ports above and set `FTP_PASV_ADDRESS` in your `.env` to the public IP.

- **Recommended installs**:
    - macOS (Docker Desktop):

        ```bash
        brew install --cask docker
        open /Applications/Docker.app
        ```

    - Ubuntu/Debian - **Method 1: Official Docker Repository (Recommended)**:

        ```bash
        # Remove old/snap versions first
        sudo snap remove docker 2>/dev/null || true
        sudo apt remove docker docker-engine docker.io containerd runc 2>/dev/null || true

        # Install from official Docker repository
        curl -fsSL https://get.docker.com -o get-docker.sh
        sudo sh get-docker.sh

        # Enable and start
        sudo systemctl enable --now docker
        sudo usermod -aG docker $USER
        # Log out/in for group to take effect
        ```

    - Ubuntu/Debian - **Method 2: Ubuntu Repository (Simpler)**:

        ```bash
        # Remove snap version first if exists
        sudo snap remove docker 2>/dev/null || true

        # Install from Ubuntu repos
        sudo apt update
        sudo apt install -y docker.io docker-compose-plugin


        sudo systemctl enable --now docker
        sudo usermod -aG docker $USER
        # Log out/in for group to take effect
        ```

    - **⚠️ AVOID**: `snap install docker` - Snap Docker has AppArmor restrictions that cause permission issues

- **Install Docker Compose (if missing)**:
    - **Preferred (Compose v2 plugin)** — already included in both methods above. If you still need it:

        ```bash
        sudo apt update
        sudo apt install -y docker-compose-plugin
        docker compose version
        ```

    - **Legacy `docker-compose` (v1)** — only if required by older scripts:

        ```bash
        sudo apt update
        sudo apt install -y docker-compose
        docker-compose --version
        ```

- **Verify setup**:

```bash
docker --version
docker compose version
docker info | head -n 20
```

If you plan to run a second instance (prod) on the same host, reserve a different set of host ports (for example, `8082`, `2222`, and `21120-21130`) and use a separate `.env` file as described later in this README.

## Getting Started

**New Installation?** Start here:

1. **Run `./setup.sh`** - This automated script:
    - Creates your `.env` configuration file

    - Generates secure random passwords automatically
    - Sets up all necessary directories
    - Saves you from manual password generation

2. **Run `docker-compose up -d`** - Start

s WordPress, MySQL, and FTP

3. **Open http://localhost:8081** - Complete WordPress installation

That's it! See [Quick Start](#quick-start) below for detailed steps.

## Quick Start

### Step 1: Run Setup Script (Recommended)

The `setup.sh` script automatically:

- Creates `.env` file with secure configuration
- **Generates strong random passwords** for MySQL and FTP
- Creates necessary directories
- Sets up file permissions

```bash
# Make setup script executable and run it
chmod +x setup.sh
./setup.sh
```

**Important**: The script will display your generated passwords. **Save them securely!** You'll need them later.

### Step 2: Start Docker Containers

```bash
# Start all services (WordPress, MySQL, FTP)
docker-compose up -d

# View logs to see if everything started correctly
docker-compose logs -f
```

Wait for all containers to be healthy (check with `docker-compose ps`).

### Step 3: Access WordPress

Open your browser and go to:

- **WordPress**: http://localhost:8081

Complete the WordPress installation wizard. You'll need:

- Database name: `wordpress` (from `.env`)
- Database user: `wpuser` (from `.env`)
- Database password: The `MYSQL_PASSWORD` from Step 1
- Database host: `db` (already configured)

### Step 4: Access FTP (Optional)

Use any FTP client with these settings:

- **Host**: `localhost` (or your server IP)
- **Port**: `2121`
- **Username**: `ftpuser` (from `.env`)
- **Password**: The `FTP_PASS` from Step 1
- **Mode**: Passive (PASV)

---

## Manual Setup (Alternative)

If you prefer to set up manually instead of using `setup.sh`:

```bash
# 1. Copy the template file
cp env.template .env

# 2. Edit .env and replace all "CHANGE_THIS" passwords with strong passwords
nano .env

# Generate strong passwords:
openssl rand -base64 32

# 3. Start services
docker-compose up -d
```

## Configuration

### Environment Variables

Edit `.env` file to customize:

- `WORDPRESS_PORT`: WordPress web port (default: 8081)
- `MYSQL_DATABASE`: Database name
- `MYSQL_USER`: Database user
- `MYSQL_PASSWORD`: Database password (CHANGE THIS!)
- `MYSQL_ROOT_PASSWORD`: MySQL root password (CHANGE THIS!)
- `FTP_USER`: FTP username
- `FTP_PASS`: FTP password (CHANGE THIS!)
- `FTP_PORT`: FTP port (default: 2121)
- `FTP_PASV_ADDRESS`: Your server's public IP for passive FTP

### Security Settings

The setup includes:

- Non-root container execution
- File editing disabled in WordPress admin
- XML-RPC disabled
- Security headers configured
- Limited container privileges

## Backups

### Manual Backup

```bash
# Make script executable (first time only)
chmod +x backup.sh

# Run backup
./backup.sh
```

The backup script creates a compressed archive containing:

- All WordPress files
- Complete MySQL database dump
- Stored in `./backups/` with timestamp
- Automatically cleans up backups older than 7 days

## URL Migration (Beta → Prod)

Use this script to safely replace the site URL in the database for future migrations.
It runs a dry run by default; pass `--apply` to execute changes.

```bash
chmod +x migrate-url.sh

# Dry run
./migrate-url.sh https://beta.example.com https://example.com

# Apply changes
./migrate-url.sh https://beta.example.com https://example.com --apply
```

Backups are stored in `./backups/` directory with timestamp.

### Automated Backups (Cron)

Add to crontab for daily backups at 2 AM:

```bash
crontab -e

# Add this line:
0 2 * * * cd /path/to/wordpress && ./backup.sh >> backups/backup.log 2>&1
```

### Restore from Backup

```bash
# Make script executable (first time only)
chmod +x restore.sh

# Restore from backup (replace with your actual backup filename)
./restore.sh backups/wordpress_backup_20240101_120000.tar.gz
```

**Warning**: This will overwrite your current WordPress installation. Make sure to backup first!

## FTP Access

### FTP Client Configuration

- **Host**: localhost (or your server IP)
- **Port**: 2121 (or port from `.env`)
- **Username**: From `FTP_USER` in `.env`
- **Password**: From `FTP_PASS` in `.env`
- **Mode**: Passive (PASV)

### FTP Passive Mode

If accessing FTP from outside your network:

1. Set `FTP_PASV_ADDRESS` to your public IP
2. Open ports 2121 and 21100-21110 in your firewall
3. Configure port forwarding if behind NAT

## Maintenance

### Update WordPress

```bash
# Pull latest images
docker-compose pull

# Recreate containers
docker-compose up -d
```

### View Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f wordpress
docker-compose logs -f db
docker-compose logs -f ftp
```

### Database Access

```bash
# MySQL CLI
docker-compose exec db mysql -u wpuser -p wordpress

# Or as root
docker-compose exec db mysql -u root -p
```

### WordPress CLI

```bash
# Run WP-CLI commands
docker-compose run --rm wordpress wp --info
docker-compose run --rm wordpress wp plugin list
```

## Security Best Practices

1. **Change Default Passwords**: Always change all passwords in `.env`
2. **Use Strong Passwords**: Minimum 32 characters, use password generator
3. **Regular Updates**: Keep Docker images updated
4. **Backup Regularly**: Set up automated backups
5. **Limit FTP Access**: Only enable FTP when needed
6. **Firewall**: Restrict access to necessary ports only
7. **SSL/HTTPS**: Consider adding reverse proxy with SSL (nginx/traefik)
8. **Monitor Logs**: Regularly check container logs for suspicious activity

## Troubleshooting

### Containers won't start

```bash
# Check logs
docker-compose logs

# Check if ports are in use
lsof -i :8081
lsof -i :2121
```

### Database connection errors

- Verify MySQL container is healthy: `docker-compose ps`
- Check database credentials in `.env`
- Ensure MySQL container started first (health check)

### FTP connection issues

- Verify passive mode is enabled in FTP client
- Check `FTP_PASV_ADDRESS` matches your public IP
- Ensure ports 2121 and 21100-21110 are open

### Permission issues

```bash
# Fix WordPress file permissions
docker-compose exec wordpress chown -R www-data:www-data /var/www/html
docker-compose exec wordpress chmod -R 755 /var/www/html
```

### Snap Docker Issues (Permission Denied)

If you get "permission denied" errors when stopping/removing containers, you likely have snap Docker installed. Check with:

```bash
ls -la /usr/bin/docker
snap list | grep docker
```

If snap Docker is detected (symlink or snap list shows it), migrate to native Docker:

```bash
# 1. List volumes to preserve data
docker volume ls

# 2. Stop and remove snap Docker
snap stop docker
snap remove docker

# 3. Install native Docker (choose one method)

# Method A: Official Docker (recommended)
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Method B: Ubuntu repository
sudo apt update
sudo apt install -y docker.io docker-compose-plugin

# 4. Enable and verify
sudo systemctl enable --now docker
docker --version
which docker  # Should show /usr/bin/docker (not snap)
ls -la /usr/bin/docker  # Should be a real binary, not a symlink

# 5. Restart your containers
cd /path/to/wordpress
docker compose up -d
```

### Plugin/Theme Installation Issues (FTP Error)

If you get FTP connection errors when installing plugins or themes:

The setup includes a must-use plugin that forces direct filesystem access. If you still have issues:

```bash
# Ensure the mu-plugins directory exists
docker-compose exec wordpress mkdir -p /var/www/html/wp-content/mu-plugins

# Verify the fix is installed
docker-compose exec wordpress ls -la /var/www/html/wp-content/mu-plugins/

# Restart WordPress container
docker-compose restart wordpress
```

WordPress should now use direct filesystem access instead of FTP for plugin/theme operations.

## Clean Installation

To completely remove and reinstall:

```bash
# Stop and remove containers
docker-compose down

# Remove volumes (WARNING: This deletes all data!)
docker-compose down -v

# Remove images
docker-compose down --rmi all

# Start fresh
docker-compose up -d
```

## Backup Locations

- **WordPress Files**: `wordpress_data` Docker volume
- **Database**: `db_data` Docker volume
- **Backup Archives**: `./backups/` directory

## Support

For issues or questions:

1. Check container logs: `docker-compose logs`
2. Verify `.env` configuration
3. Ensure Docker has sufficient resources
4. Check disk space: `df -h`

## License

This setup is provided as-is for secure WordPress hosting.
