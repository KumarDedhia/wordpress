# How to Disable Existing FTP Server on Linux

This guide helps you identify and disable the existing FTP server that's using port 21 on your Linux system.

## Step 1: Identify the FTP Service

### Check what's using port 21:

```bash
sudo lsof -i :21
# or
sudo netstat -tlnp | grep :21
# or
sudo ss -tlnp | grep :21
```

This will show you which process is using port 21.

### Check for common FTP services:

```bash
# Check if vsftpd is running
sudo systemctl status vsftpd

# Check if proftpd is running
sudo systemctl status proftpd

# Check if pure-ftpd is running
sudo systemctl status pure-ftpd

# Check if ftpd is running
sudo systemctl status ftpd
```

## Step 2: Stop the FTP Service

Once you identify which FTP service is running, stop it:

### For vsftpd:
```bash
sudo systemctl stop vsftpd
sudo systemctl disable vsftpd  # Prevent it from starting on boot
```

### For proftpd:
```bash
sudo systemctl stop proftpd
sudo systemctl disable proftpd
```

### For pure-ftpd:
```bash
sudo systemctl stop pure-ftpd
sudo systemctl disable pure-ftpd
```

### For any other FTP service:
```bash
# Replace 'service-name' with the actual service name
sudo systemctl stop service-name
sudo systemctl disable service-name
```

## Step 3: Verify Port 21 is Free

```bash
sudo lsof -i :21
```

If nothing is returned, port 21 is now free.

## Step 4: (Optional) Uninstall the FTP Service

If you don't need the system FTP server at all, you can uninstall it:

### For vsftpd:
```bash
sudo apt remove vsftpd  # Debian/Ubuntu
# or
sudo yum remove vsftpd  # CentOS/RHEL
```

### For proftpd:
```bash
sudo apt remove proftpd  # Debian/Ubuntu
# or
sudo yum remove proftpd  # CentOS/RHEL
```

### For pure-ftpd:
```bash
sudo apt remove pure-ftpd  # Debian/Ubuntu
# or
sudo yum remove pure-ftpd  # CentOS/RHEL
```

## Step 5: Check Firewall Rules

If you have a firewall, you may need to remove FTP rules:

### For UFW (Ubuntu):
```bash
sudo ufw status | grep 21
sudo ufw delete allow 21/tcp  # If rule exists
```

### For firewalld (CentOS/RHEL):
```bash
sudo firewall-cmd --list-all | grep ftp
sudo firewall-cmd --permanent --remove-service=ftp
sudo firewall-cmd --reload
```

### For iptables:
```bash
sudo iptables -L -n | grep 21
# Remove specific rules if needed
```

## Quick One-Liner to Find and Stop FTP Service

```bash
# Find and stop the most common FTP services
for service in vsftpd proftpd pure-ftpd ftpd; do
    if systemctl is-active --quiet $service; then
        echo "Stopping $service..."
        sudo systemctl stop $service
        sudo systemctl disable $service
    fi
done
```

## After Disabling System FTP

Once you've disabled the system FTP server:

1. Verify port 21 is free:
   ```bash
   sudo lsof -i :21
   ```

2. Start your Docker WordPress setup:
   ```bash
   docker-compose up -d
   ```

3. Your Docker FTP will run on port 2121 (to avoid conflicts)

## Notes

- **Don't delete this guide** - You might need it if you want to re-enable the system FTP later
- The Docker FTP service uses port **2121** by default to avoid conflicts
- If you need both system FTP and Docker FTP, you can:
  - Keep system FTP on port 21
  - Use Docker FTP on port 2121 (already configured)

## Re-enable System FTP Later (if needed)

If you need to re-enable the system FTP service later:

```bash
sudo systemctl enable vsftpd  # or proftpd, pure-ftpd, etc.
sudo systemctl start vsftpd
```
