#!/bin/bash
set -e

# WordPress entrypoint for Inception project.
# 1. Launch the configuration script in the background
#    (it waits for MariaDB, creates wp-config, installs WP, sets up Redis).
# 2. Start PHP-FPM in the foreground as PID 1.

# Ensure correct ownership of the WordPress directory
chown -R www-data:www-data /var/www/html

# Create the PHP-FPM run directory
mkdir -p /run/php

# Run configuration in the background so PHP-FPM can start immediately
/usr/local/bin/configure_wp.sh > /proc/1/fd/1 2>/proc/1/fd/2 &

# Hand off to CMD (php-fpm7.4 --nodaemonize)
exec "$@"
