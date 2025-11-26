# Troubleshooting Guide

## MySQL Container "operation not permitted" Error

If you see the error:

```
exec /usr/local/bin/docker-entrypoint.sh: operation not permitted
```

This is typically a Docker Desktop permission issue on macOS. Try these solutions:

### Solution 1: Restart Docker Desktop

1. Quit Docker Desktop completely
2. Restart Docker Desktop
3. Wait for it to fully start
4. Try `docker-compose up -d` again

### Solution 2: Reset Docker Desktop

1. Open Docker Desktop
2. Go to Settings → Troubleshoot
3. Click "Reset to factory defaults" (WARNING: This removes all containers and volumes)
4. Restart Docker Desktop
5. Run `docker-compose up -d` again

### Solution 3: Check Docker Desktop Resources

1. Open Docker Desktop
2. Go to Settings → Resources
3. Ensure you have at least:
    - 2 GB RAM allocated
    - 1 CPU allocated
4. Apply & Restart

### Solution 4: Clean Start

```bash
# Stop all containers
docker-compose down

# Remove volumes (WARNING: Deletes all data!)
docker-compose down -v

# Remove any orphaned containers
docker container prune -f

# Try starting again
docker-compose up -d
```

### Solution 5: Use Different MySQL Image

If the issue persists, try using a different MySQL version. Edit `docker-compose.yml`:

```yaml
db:
    image: mysql:8.0-debian # or mysql:8.0.33
```

### Solution 6: Check macOS Permissions

1. System Settings → Privacy & Security
2. Ensure Docker Desktop has Full Disk Access
3. Restart Docker Desktop

### Solution 7: Update Docker Desktop

Make sure you're running the latest version of Docker Desktop for macOS.

## Other Common Issues

### Port Already in Use

```bash
# Check what's using the port
lsof -i :8081
lsof -i :8081
lsof -i :2121

# Kill the process or change the port in .env
```

### Database Connection Errors

-   Wait 30-60 seconds after starting containers for MySQL to fully initialize
-   Check logs: `docker-compose logs db`
-   Verify `.env` file has correct passwords

### Permission Denied on Scripts

```bash
# Make scripts executable
chmod +x setup.sh backup.sh restore.sh
```

### Containers Keep Restarting

```bash
# Check logs to see why
docker-compose logs

# Check container status
docker-compose ps
```
