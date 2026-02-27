#!/bin/bash
# WordPress healthcheck for Inception (debian:bullseye build).
set -e

# 1. Check if php-fpm is listening on port 9000
cgi-fcgi -bind -connect localhost:9000 > /dev/null 2>&1

# 2. Check if WordPress configuration has completed
if [ ! -f /var/www/html/.wp-configured ]; then
    echo "WordPress not yet configured."
    exit 1
fi

exit 0
