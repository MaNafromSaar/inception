#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

#
# WordPress configuration script for Inception (debian:bullseye build).
# WordPress core files are already present (downloaded at build time).
# This script:
#   1. Waits for MariaDB
#   2. Creates wp-config.php
#   3. Installs WordPress (core install + users)
#   4. Configures Redis cache
#

log() {
    echo "[WP-CONFIG] - [$(date '+%Y-%m-%d %H:%M:%S')] - $1"
}

log "Starting WordPress configuration..."

export HTTP_HOST="${DOMAIN_NAME:-localhost}"

# Wait for MariaDB to be ready
log "Waiting for database connection at ${WP_DB_HOST}..."
while ! nc -z "$WP_DB_HOST" 3306; do
    log "Database is unavailable — sleeping"
    sleep 1
done
log "Database is up."

cd /var/www/html

# Create wp-config.php if it doesn't exist
if [ ! -f "wp-config.php" ]; then
    log "Creating wp-config.php..."
    wp config create --allow-root \
        --dbname="$WP_DB_NAME" \
        --dbuser="$WP_DB_USER" \
        --dbpass="$WP_DB_PASSWORD" \
        --dbhost="$WP_DB_HOST" \
        --path='/var/www/html'
    log "wp-config.php created."
fi

# Install WordPress if not yet installed
if wp core is-installed --allow-root 2>/dev/null; then
    log "WordPress already installed — skipping."
else
    log "Installing WordPress..."
    wp core install \
        --url="$DOMAIN_NAME" \
        --title="Inception" \
        --admin_user="$WP_ADMIN_USER" \
        --admin_password="$WP_ADMIN_PASSWORD" \
        --admin_email="$WP_ADMIN_EMAIL" \
        --skip-email --allow-root
    log "WordPress installed."

    # Create the second (non-admin) user
    log "Creating user '${WP_USER_USER}'..."
    wp user create "$WP_USER_USER" "$WP_USER_EMAIL" \
        --role=author \
        --user_pass="$WP_USER_PASSWORD" \
        --allow-root
    log "User created."

    # Configure Redis cache
    log "Configuring Redis cache..."
    wp config set WP_REDIS_HOST  "redis"              --allow-root
    wp config set WP_REDIS_PORT  "6379"               --allow-root
    wp config set WP_REDIS_PASSWORD "$REDIS_PASSWORD"  --allow-root
    wp config set WP_CACHE_KEY_SALT "$DOMAIN_NAME"     --allow-root
    wp config set WP_REDIS_CLIENT "phpredis"           --allow-root
    wp plugin install redis-cache --activate --allow-root
    wp redis enable --allow-root
    log "Redis cache configured."
fi

# Verify PHP Redis extension is loaded
log "Verifying PHP Redis extension..."
if ! php -m | grep -qi redis; then
    log "ERROR: PHP Redis extension not loaded"
    exit 1
fi

# Signal that configuration is complete (used by healthcheck)
touch /var/www/html/.wp-configured
log "Configuration complete — marker file created."

