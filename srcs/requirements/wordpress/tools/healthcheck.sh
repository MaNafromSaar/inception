#!/bin/bash
# Inception WordPress Healthcheck Script

# Exit immediately if a command exits with a non-zero status.
set -e

# 1. Check if php-fpm is listening on port 9000.
# cgi-fcgi is a tool to interact with FastCGI applications.
# We use it to ping the php-fpm process. If it's running, the command succeeds.
cgi-fcgi -bind -connect localhost:9000

# 2. Check if the WordPress configuration is complete.
# The main configuration script (configure_wp.sh) will create this file as its last step.
# Its existence signals that the database, users, and Redis are fully configured.
if [ ! -f /var/www/html/.wp-configured ]; then
    echo "WordPress is not configured yet."
    exit 1
fi

# If both checks pass, exit with 0 to indicate the container is healthy.
exit 0
