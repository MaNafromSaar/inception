#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

#
# This script is executed by the official WordPress entrypoint. It waits for the
# database to be ready, then installs WordPress, creates a user, and sets up
# a Redis cache.
#
# The following environment variables are expected to be set:
# - WP_DB_HOST: The hostname of the database server.
# - WP_DB_NAME: The name of the database.
# - WP_DB_USER: The username for the database.
# - WP_DB_PASSWORD: The password for the database.
# - WP_ADMIN_USER: The desired WordPress admin username.
# - WP_ADMIN_PASSWORD: The desired WordPress admin password.
# - WP_ADMIN_EMAIL: The email address for the WordPress admin user.
# - WP_USER_USER: The desired WordPress user username.
# - WP_USER_PASSWORD: The desired WordPress user password.
# - WP_USER_EMAIL: The email address for the WordPress user.
# - REDIS_HOST: The hostname of the Redis server.
# - REDIS_PORT: The port of the Redis server.
# - REDIS_PASSWORD: The password for the Redis server.
# - DOMAIN_NAME: The domain name for the WordPress site.

# Function to log messages with a timestamp.
log() {
    echo "[WP-BONUS-CONFIG] - [$(date '+%Y-%m-%d %H:%M:%S')] - $1"
}

# Start of the script.
log "Starting bonus WordPress configuration script..."

# set HOST
export HTTP_HOST="${DOMAIN_NAME:-localhost}"

# Wait for the database to be ready before proceeding.
log "Waiting for database connection at $WP_DB_HOST..."
while ! nc -z "$WP_DB_HOST" 3306; do
    log "Database is unavailable - sleeping"
    sleep 1
done
log "Database is up - executing command"

# The official wordpress entrypoint copies files to /var/www/html.
# We need to wait for this to complete before running wp-cli commands.
# We'll wait for the wp-load.php file to exist.
log "Waiting for WordPress files to be copied..."
while [ ! -f "/var/www/html/wp-load.php" ]; do
    log "WordPress files not found yet - sleeping"
    sleep 1
done
log "WordPress files are present."

# Check if wp-config.php exists. If not, create it.
if [ ! -f "wp-config.php" ]; then
    log "wp-config.php not found. Creating it now..."
    wp config create --allow-root \
        --dbname="$WP_DB_NAME" \
        --dbuser="$WP_DB_USER" \
        --dbpass="$WP_DB_PASSWORD" \
        --dbhost="$WP_DB_HOST" \
        --path='/var/www/html'
    log "wp-config.php created successfully."
fi

# Check if WordPress is already installed.
if wp core is-installed --allow-root; then
    log "WordPress is already installed. Skipping installation."
else
    # Install WordPress using WP-CLI.
    log "Installing WordPress..."
    wp core install --url="$DOMAIN_NAME" --title="Inception" \
        --admin_user="$WP_ADMIN_USER" --admin_password="$WP_ADMIN_PASSWORD" --admin_email="$WP_ADMIN_EMAIL" \
        --skip-email --allow-root
    log "WordPress installed successfully."

    # Create a new user.
    log "Creating user..."
    wp user create "$WP_USER_USER" "$WP_USER_EMAIL" --role=author --user_pass="$WP_USER_PASSWORD" --allow-root
    log "User created successfully."

    # Configure Redis cache.
    log "Configuring Redis cache..."
    wp config set WP_REDIS_HOST "redis" --allow-root
    wp config set WP_REDIS_PORT "6379" --allow-root
    wp config set WP_REDIS_PASSWORD "$REDIS_PASSWORD" --allow-root
    wp config set WP_CACHE_KEY_SALT "$DOMAIN_NAME" --allow-root
    wp config set WP_REDIS_CLIENT "phpredis" --allow-root
    wp plugin install redis-cache --activate --allow-root
    wp redis enable --allow-root
    log "Redis cache configured successfully."
fi

log "Verifying PHP Redis extension..."
if ! php -m | grep -q redis; then
    log "ERROR: PHP Redis extension not loaded"
    exit 1
fi

log "WordPress bonus configuration script finished."

# Create a marker file to indicate that the configuration is complete.
# The healthcheck script will look for this file.
touch /var/www/html/.wp-configured
log "Created .wp-configured marker file."

