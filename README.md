# WordPress Docker Setup with Security & Backup

A secure, production-ready WordPress Docker setup with MySQL, FTP support, and automated backups.

## Features

-   ✅ **Security Hardened**: Non-root containers, security headers, file editing disabled
-   ✅ **Easy Backups**: Automated backup scripts for files and database
-   ✅ **FTP Support**: Integrated FTP server for file management
-   ✅ **Health Checks**: Automatic container health monitoring
-   ✅ **Volume Management**: Persistent data storage with Docker volumes

## Getting Started

**New Installation?** Start here:

1. **Run `./setup.sh`** - This automated script:

    - Creates your `.env` configuration file
    - Generates secure random passwords automatically
    - Sets up all necessary directories
    - Saves you from manual password generation

2. **Run `docker-compose up -d`** - Starts WordPress, MySQL, and FTP

3. **Open http://localhost:8081** - Complete WordPress installation

That's it! See [Quick Start](#quick-start) below for detailed steps.

## Quick Start

### Step 1: Run Setup Script (Recommended)

The `setup.sh` script automatically:

-   Creates `.env` file with secure configuration
-   **Generates strong random passwords** for MySQL and FTP
-   Creates necessary directories
-   Sets up file permissions

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

-   **WordPress**: http://localhost:8081

Complete the WordPress installation wizard. You'll need:

-   Database name: `wordpress` (from `.env`)
-   Database user: `wpuser` (from `.env`)
-   Database password: The `MYSQL_PASSWORD` from Step 1
-   Database host: `db` (already configured)

### Step 4: Access FTP (Optional)

Use any FTP client with these settings:

-   **Host**: `localhost` (or your server IP)
-   **Port**: `21`
-   **Username**: `ftpuser` (from `.env`)
-   **Password**: The `FTP_PASS` from Step 1
-   **Mode**: Passive (PASV)

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

-   `WORDPRESS_PORT`: WordPress web port (default: 8081)
-   `MYSQL_DATABASE`: Database name
-   `MYSQL_USER`: Database user
-   `MYSQL_PASSWORD`: Database password (CHANGE THIS!)
-   `MYSQL_ROOT_PASSWORD`: MySQL root password (CHANGE THIS!)
-   `FTP_USER`: FTP username
-   `FTP_PASS`: FTP password (CHANGE THIS!)
-   `FTP_PORT`: FTP port (default: 21)
-   `FTP_PASV_ADDRESS`: Your server's public IP for passive FTP

### Security Settings

The setup includes:

-   Non-root container execution
-   File editing disabled in WordPress admin
-   XML-RPC disabled
-   Security headers configured
-   Limited container privileges

## Backups

### Manual Backup

```bash
# Make script executable (first time only)
chmod +x backup.sh

# Run backup
./backup.sh
```

The backup script creates a compressed archive containing:

-   All WordPress files
-   Complete MySQL database dump
-   Stored in `./backups/` with timestamp
-   Automatically cleans up backups older than 7 days

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

-   **Host**: localhost (or your server IP)
-   **Port**: 21 (or port from `.env`)
-   **Username**: From `FTP_USER` in `.env`
-   **Password**: From `FTP_PASS` in `.env`
-   **Mode**: Passive (PASV)

### FTP Passive Mode

If accessing FTP from outside your network:

1. Set `FTP_PASV_ADDRESS` to your public IP
2. Open ports 21 and 21100-21110 in your firewall
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
lsof -i :21
```

### Database connection errors

-   Verify MySQL container is healthy: `docker-compose ps`
-   Check database credentials in `.env`
-   Ensure MySQL container started first (health check)

### FTP connection issues

-   Verify passive mode is enabled in FTP client
-   Check `FTP_PASV_ADDRESS` matches your public IP
-   Ensure ports 21 and 21100-21110 are open

### Permission issues

```bash
# Fix WordPress file permissions
docker-compose exec wordpress chown -R www-data:www-data /var/www/html
docker-compose exec wordpress chmod -R 755 /var/www/html
```

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

-   **WordPress Files**: `wordpress_data` Docker volume
-   **Database**: `db_data` Docker volume
-   **Backup Archives**: `./backups/` directory

## Support

For issues or questions:

1. Check container logs: `docker-compose logs`
2. Verify `.env` configuration
3. Ensure Docker has sufficient resources
4. Check disk space: `df -h`

## License

This setup is provided as-is for secure WordPress hosting.
