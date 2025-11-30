<?php
/**
 * Plugin Name: WordPress Filesystem Fix
 * Description: Forces direct filesystem access and applies security settings
 * Version: 1.0
 * Author: System
 */

// Force direct filesystem access (no FTP required)
if (!defined('FS_METHOD')) {
    define('FS_METHOD', 'direct');
}

// Ensure WordPress can write to filesystem
if (!defined('FS_CHMOD_DIR')) {
    define('FS_CHMOD_DIR', (0755 & ~ umask()));
}
if (!defined('FS_CHMOD_FILE')) {
    define('FS_CHMOD_FILE', (0644 & ~ umask()));
}
