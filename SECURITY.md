# Security Hardening Guide

This document outlines security measures implemented and additional recommendations.

## Implemented Security Features

### 1. Container Security
- ✅ **Non-root execution**: Containers run with limited privileges
- ✅ **No new privileges**: `no-new-privileges:true` prevents privilege escalation
- ✅ **Read-only filesystem**: WordPress container uses read-only root with tmpfs for /tmp
- ✅ **Network isolation**: Services communicate through isolated Docker network

### 2. WordPress Security
- ✅ **File editing disabled**: `DISALLOW_FILE_EDIT` prevents code editing from admin
- ✅ **XML-RPC disabled**: Reduces attack surface
- ✅ **Version hiding**: WordPress version not exposed in headers
- ✅ **Debug mode**: Disabled by default (set `WORDPRESS_DEBUG=0`)

### 3. Database Security
- ✅ **Separate user**: WordPress uses dedicated database user (not root)
- ✅ **Strong passwords**: Enforced through setup script
- ✅ **Health checks**: Database availability monitored

### 4. FTP Security
- ✅ **Isolated access**: FTP only accesses WordPress files directory
- ✅ **Strong passwords**: Enforced through setup script
- ✅ **Passive mode**: Configurable for firewall compatibility

## Additional Security Recommendations

### 1. Change Default Passwords Immediately

```bash
# Generate new passwords
openssl rand -base64 32

# Update .env file
nano .env
```

### 2. Use Strong WordPress Admin Credentials

When setting up WordPress:
- Use a unique admin username (not "admin")
- Generate strong password (minimum 20 characters)
- Enable two-factor authentication (2FA) plugin

### 3. Regular Updates

```bash
# Update Docker images
docker-compose pull
docker-compose up -d

# Update WordPress plugins/themes from admin panel
# Or via WP-CLI:
docker-compose run --rm wordpress wp plugin update --all
docker-compose run --rm wordpress wp theme update --all
docker-compose run --rm wordpress wp core update
```

### 4. Add Reverse Proxy with SSL

For production, add nginx or Traefik with SSL certificates:

```yaml
# Add to docker-compose.yml
nginx:
  image: nginx:alpine
  ports:
    - "80:80"
    - "443:443"
  volumes:
    - ./nginx.conf:/etc/nginx/nginx.conf:ro
    - ./ssl:/etc/nginx/ssl:ro
  depends_on:
    - wordpress
```

### 5. Firewall Configuration

```bash
# Allow only necessary ports
# WordPress web: 8080 (or your chosen port)
# FTP: 21, 21100-21110 (if needed externally)
# Block all other ports
```

### 6. WordPress Security Plugins

Recommended plugins:
- **Wordfence**: Firewall and malware scanner
- **iThemes Security**: Multiple security features
- **Limit Login Attempts**: Prevent brute force attacks
- **Two-Factor Authentication**: Add 2FA to login

### 7. Database Security

```bash
# Regularly backup database
./backup.sh

# Review database users
docker-compose exec db mysql -u root -p -e "SELECT user, host FROM mysql.user;"

# Remove unnecessary users
docker-compose exec db mysql -u root -p -e "DROP USER IF EXISTS 'olduser'@'%';"
```

### 8. File Permissions

```bash
# Set correct permissions
docker-compose exec wordpress chown -R www-data:www-data /var/www/html
docker-compose exec wordpress find /var/www/html -type d -exec chmod 755 {} \;
docker-compose exec wordpress find /var/www/html -type f -exec chmod 644 {} \;

# Protect wp-config.php
docker-compose exec wordpress chmod 600 /var/www/html/wp-config.php
```

### 9. Monitor Logs

```bash
# Check for suspicious activity
docker-compose logs wordpress | grep -i "error\|warning\|hack\|attack"
docker-compose logs db | grep -i "error\|access denied"
docker-compose logs ftp | grep -i "failed\|error"
```

### 10. Disable Unnecessary Services

- Only enable FTP when needed
- Consider removing FTP service if not required
- Disable WordPress REST API if not used: Add to `wp-config.php`:
  ```php
  add_filter('rest_authentication_errors', function($result) {
      if (!empty($result)) {
          return $result;
      }
      if (!is_user_logged_in()) {
          return new WP_Error('rest_not_logged_in', 'You are not currently logged in.', array('status' => 401));
      }
      return $result;
  });
  ```

### 11. Regular Security Audits

- Review installed plugins/themes monthly
- Remove unused plugins/themes
- Check for known vulnerabilities: https://wpscan.com/
- Review user accounts and remove inactive ones

### 12. Backup Security

- Store backups in secure location
- Encrypt backups if containing sensitive data
- Test restore process regularly
- Keep backups off-site

### 13. Environment Variables

- Never commit `.env` file to version control
- Rotate passwords every 90 days
- Use different passwords for each environment

### 14. Network Security

- Use VPN for remote access
- Restrict FTP access to specific IPs (if possible)
- Consider using SFTP instead of FTP (more secure)

### 15. WordPress Hardening

Add to `wp-config.php` or `wp-config-custom.php`:

```php
// Disable file editing
define('DISALLOW_FILE_EDIT', true);

// Force SSL (if using HTTPS)
define('FORCE_SSL_ADMIN', true);

// Limit post revisions
define('WP_POST_REVISIONS', 3);

// Disable automatic updates (manage manually)
define('WP_AUTO_UPDATE_CORE', false);

// Increase security keys rotation
// Regenerate at: https://api.wordpress.org/secret-key/1.1/salt/
```

## Incident Response

If you suspect a compromise:

1. **Immediately isolate**: Stop containers
   ```bash
   docker-compose down
   ```

2. **Preserve evidence**: Create backup before changes
   ```bash
   ./backup.sh
   ```

3. **Review logs**: Check for unauthorized access
   ```bash
   docker-compose logs > incident_logs.txt
   ```

4. **Change all passwords**: Update `.env` with new passwords

5. **Clean installation**: Consider fresh install from backup

6. **Review and restore**: Restore from known-good backup

## Security Checklist

- [ ] Changed all default passwords
- [ ] Generated strong passwords (32+ characters)
- [ ] Disabled file editing in WordPress
- [ ] Installed security plugins
- [ ] Set up regular backups
- [ ] Configured firewall
- [ ] Enabled SSL/HTTPS (for production)
- [ ] Removed unused plugins/themes
- [ ] Limited user accounts
- [ ] Set up log monitoring
- [ ] Tested backup/restore process
- [ ] Documented incident response plan

## Resources

- [WordPress Security Hardening](https://wordpress.org/support/article/hardening-wordpress/)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [Docker Security Best Practices](https://docs.docker.com/engine/security/)
- [WPScan Vulnerability Database](https://wpscan.com/)
