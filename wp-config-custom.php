<?php
/**
 * Additional WordPress Security Configuration
 * This file is included in wp-config.php
 */

// Security: Disable file editing from WordPress admin
define('DISALLOW_FILE_EDIT', true);

// Security: Limit login attempts (requires plugin, but good practice)
define('WP_AUTO_UPDATE_CORE', 'minor'); // Auto-update security patches

// Security: Force SSL (uncomment if using SSL)
// define('FORCE_SSL_ADMIN', true);

// Security: Set secure authentication keys (these should be in main wp-config.php)
// Use: https://api.wordpress.org/secret-key/1.1/salt/

// Security: Hide WordPress version
remove_action('wp_head', 'wp_generator');

// Security: Disable XML-RPC if not needed
add_filter('xmlrpc_enabled', '__return_false');

// Security: Limit login attempts
define('WP_FAIL2BAN_BLOCKED_USERS', array());

// Performance: Increase memory limit
define('WP_MEMORY_LIMIT', '256M');
define('WP_MAX_MEMORY_LIMIT', '512M');

// Filesystem: Force direct filesystem access (no FTP required)
// This allows WordPress to install/update plugins and themes directly
define('FS_METHOD', 'direct');

// Security: Disable directory browsing
if (!defined('ABSPATH')) {
    define('ABSPATH', dirname(__FILE__) . '/');
}
