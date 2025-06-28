#!/bin/bash
set -e # Exit immediately if a command exits with a non-zero status.

WORDPRESS_PATH=/var/www/html
WP_CONFIG_FILE=${WORDPRESS_PATH}/wp-config.php

# Function to check if MariaDB is accessible
wait_for_db() {
    echo "Waiting for database host ${WP_DB_HOST}..."
    while ! nc -z "${WP_DB_HOST}" 3306; do
        echo "Database not yet reachable, waiting..."
        sleep 1
    done
    echo "Database host ${WP_DB_HOST} is reachable."
}

# Wait for the database to be ready before proceeding
wait_for_db

# Check if wp-config.php already exists
if [ -f "${WP_CONFIG_FILE}" ]; then
    echo "wp-config.php already exists. Skipping creation."
else
    echo "wp-config.php not found. Creating from sample..."
    # Copy wp-config-sample.php to wp-config.php
    cp "${WORDPRESS_PATH}/wp-config-sample.php" "${WP_CONFIG_FILE}"

    echo "Configuring wp-config.php..."
    # Set database details
    sed -i "s/database_name_here/${WP_DB_NAME}/g" "${WP_CONFIG_FILE}"
    sed -i "s/username_here/${WP_DB_USER}/g" "${WP_CONFIG_FILE}"
    sed -i "s/password_here/${WP_DB_PASSWORD}/g" "${WP_CONFIG_FILE}"
    sed -i "s/localhost/${WP_DB_HOST}/g" "${WP_CONFIG_FILE}" # WordPress connects to MariaDB service name

    # Set WordPress salts and keys from environment variables
    # These should be defined in the Dockerfile or passed via docker-compose from .env
    sed -i "/AUTH_KEY/s/put your unique phrase here/${AUTH_KEY}/" "${WP_CONFIG_FILE}"
    sed -i "/SECURE_AUTH_KEY/s/put your unique phrase here/${SECURE_AUTH_KEY}/" "${WP_CONFIG_FILE}"
    sed -i "/LOGGED_IN_KEY/s/put your unique phrase here/${LOGGED_IN_KEY}/" "${WP_CONFIG_FILE}"
    sed -i "/NONCE_KEY/s/put your unique phrase here/${NONCE_KEY}/" "${WP_CONFIG_FILE}"
    sed -i "/AUTH_SALT/s/put your unique phrase here/${AUTH_SALT}/" "${WP_CONFIG_FILE}"
    sed -i "/SECURE_AUTH_SALT/s/put your unique phrase here/${SECURE_AUTH_SALT}/" "${WP_CONFIG_FILE}"
    sed -i "/LOGGED_IN_SALT/s/put your unique phrase here/${LOGGED_IN_SALT}/" "${WP_CONFIG_FILE}"
    sed -i "/NONCE_SALT/s/put your unique phrase here/${NONCE_SALT}/" "${WP_CONFIG_FILE}"

    # Add FS_METHOD direct to avoid issues with plugin/theme installations
    echo "define('FS_METHOD', 'direct');" >> "${WP_CONFIG_FILE}"

    # Set correct permissions for wp-config.php
    chown www-data:www-data "${WP_CONFIG_FILE}"
    chmod 640 "${WP_CONFIG_FILE}" # More restrictive permissions

    echo "wp-config.php configured."
fi

# Check if WordPress is already installed. We check for the existence of the user.
# The `wp user get` command will fail if the user doesn't exist, and `set -e` will stop the script.
if sudo -u www-data wp core is-installed --path=${WORDPRESS_PATH} > /dev/null 2>&1; then
    echo "WordPress is already installed. Skipping installation."
else
    echo "WordPress is not installed. Starting installation..."

    # Install WordPress using wp-cli
    # The --allow-root flag is often needed when running in Docker containers
    sudo -u www-data wp core install \
        --path=${WORDPRESS_PATH} \
        --url=${WP_SITE_URL} \
        --title="${WP_SITE_TITLE}" \
        --admin_user=${WP_ADMIN_USER} \
        --admin_password=${WP_ADMIN_PASSWORD} \
        --admin_email=${WP_ADMIN_EMAIL}

    echo "WordPress core installed."

    # Create the second user
    sudo -u www-data wp user create \
        --path=${WORDPRESS_PATH} \
        ${WP_USER_USER} \
        ${WP_USER_EMAIL} \
        --role=author \
        --user_pass=${WP_USER_PASSWORD}

    echo "Second WordPress user created."

    echo "WordPress installation complete."
fi

# Ensure correct ownership of all WordPress files
# This is important after wp-cli commands
# This might be redundant if Dockerfile already does it, but good for safety
chown -R www-data:www-data ${WORDPRESS_PATH}

# Create the directory for the PHP-FPM PID file and set correct ownership
if [ ! -d /run/php ]; then
    mkdir -p /run/php
    chown www-data:www-data /run/php
fi

echo "Starting WordPress (php-fpm) with command: $@"
# Execute the command passed to the entrypoint (e.g., CMD in Dockerfile for php-fpm)
exec "$@"
