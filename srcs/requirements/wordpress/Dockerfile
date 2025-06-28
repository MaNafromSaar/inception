# Use the penultimate stable version of Debian: Bullseye (Debian 11)
FROM debian:bullseye-slim

# Arguments for WordPress version and paths
ARG WORDPRESS_VERSION=6.4.3 # Specify a recent, non-latest version
ARG WORDPRESS_SHA1=52d5f05c96a9155f78ed84700264307e5dea14b4 # Correct SHA1 for WP 6.4.3
ARG WORDPRESS_URL=https://wordpress.org/wordpress-${WORDPRESS_VERSION}.tar.gz

# Environment variables (can be overridden by docker-compose)
ENV WORDPRESS_PATH=/var/www/html
# Database connection details will be passed via .env file through docker-compose
ENV WP_DB_HOST=mariadb
ENV WP_DB_NAME=wordpress_db
ENV WP_DB_USER=wp_user
ENV WP_DB_PASSWORD=changeme_db_password

# For wp-config.php generation
ENV AUTH_KEY=changeme
ENV SECURE_AUTH_KEY=changeme
ENV LOGGED_IN_KEY=changeme
ENV NONCE_KEY=changeme
ENV AUTH_SALT=changeme
ENV SECURE_AUTH_SALT=changeme
ENV LOGGED_IN_SALT=changeme
ENV NONCE_SALT=changeme

RUN apt-get update && apt-get install -y netcat procps && rm -rf /var/lib/apt/lists/*

LABEL maintainer="mnaumann@student.42.fr" \
      project="Inception - WordPress"

# PHP version for Debian Bullseye is typically 7.4
ENV PHP_VERSION=7.4

# Install dependencies: PHP, php-fpm, common PHP extensions for WordPress, curl, tar, netcat
RUN apt-get update && \
    apt-get install -y \
    php${PHP_VERSION}-fpm \
    php${PHP_VERSION}-mysql \
    php${PHP_VERSION}-gd \
    php${PHP_VERSION}-curl \
    php${PHP_VERSION}-mbstring \
    php${PHP_VERSION}-xml \
    php${PHP_VERSION}-zip \
    php${PHP_VERSION}-intl \
    php${PHP_VERSION}-bcmath \
    curl \
    tar \
    netcat-traditional \
    sudo \
    # For wp-cli if you choose to use it
    # wget \
    # less \
    && rm -rf /var/lib/apt/lists/*

# Install wp-cli (WordPress Command Line Interface)
RUN curl -o /usr/local/bin/wp -SL https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x /usr/local/bin/wp

# Download and extract WordPress
RUN set -eux; \
    mkdir -p ${WORDPRESS_PATH}; \
    curl -o wordpress.tar.gz -SL ${WORDPRESS_URL}; \
    # echo "${WORDPRESS_SHA1} *wordpress.tar.gz" | sha1sum -c -; \
    tar -xzf wordpress.tar.gz -C /tmp; \
    mv /tmp/wordpress/* ${WORDPRESS_PATH}/; \
    rm wordpress.tar.gz; \
    rm -rf /tmp/wordpress && \
    # Set ownership for WordPress files - www-data is common for php-fpm
    chown -R www-data:www-data ${WORDPRESS_PATH}

# Configure php-fpm to listen on port 9000 and run in foreground
# Paths for PHP 7.4 on Debian Bullseye
RUN sed -i "s|listen = /run/php/php${PHP_VERSION}-fpm.sock|listen = 9000|" "/etc/php/${PHP_VERSION}/fpm/pool.d/www.conf" && \
    sed -i 's/;daemonize = yes/daemonize = no/' "/etc/php/${PHP_VERSION}/fpm/php-fpm.conf" && \
    # Ensure error logging is on and goes to stderr for Docker logs
    sed -i 's/;catch_workers_output = yes/catch_workers_output = yes/' "/etc/php/${PHP_VERSION}/fpm/pool.d/www.conf" && \
    # Log to stderr
    echo "php_admin_value[error_log] = /proc/self/fd/2" >> "/etc/php/${PHP_VERSION}/fpm/pool.d/www.conf" && \
    echo "access.log = /proc/self/fd/2" >> "/etc/php/${PHP_VERSION}/fpm/pool.d/www.conf" # For FPM access logs

# Copy entrypoint/configuration script
COPY ./tools/configure_wp.sh /usr/local/bin/configure_wp.sh
RUN chmod +x /usr/local/bin/configure_wp.sh

# Volume for WordPress content (though actual data is mapped from host via docker-compose)
VOLUME ${WORDPRESS_PATH}

# Expose port for php-fpm (for Nginx to connect to within Docker network)
EXPOSE 9000

ENTRYPOINT ["/usr/local/bin/configure_wp.sh"]

# Default command to start php-fpm
CMD ["php-fpm7.4", "-F"]
