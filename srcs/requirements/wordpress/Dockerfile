FROM wordpress:6.2.2-fpm

# Set the working directory.
WORKDIR /var/www/html

# Install dependencies needed for the configuration script and health checks.
# - curl: to download wp-cli
# - mariadb-client: to wait for the database to be ready
# - less, procps: for healthcheck command
# - netcat: for the database wait loop
# Install system dependencies and PHP extensions
RUN apt-get update && apt-get install -y \
    libfcgi-bin \
    curl \
    mariadb-client \
    less \
    procps \
    netcat \
    sendmail \
    redis-tools \
    && rm -rf /var/lib/apt/lists/*

# Install PHP Redis extension using PECL (works across all versions)
RUN pecl install redis && docker-php-ext-enable redis

# Install WP-CLI
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp

# Set the working directory again before copying files to ensure context.
WORKDIR /var/www/html

# Copy the WordPress configuration script into the entrypoint initialization directory.
# Scripts in this directory are automatically executed by the entrypoint script.
COPY ./tools/configure_wp.sh /docker-entrypoint-initwp.d/
COPY ./tools/healthcheck.sh /usr/local/bin/healthcheck.sh
COPY ./tools/custom_entrypoint.sh /usr/local/bin/custom_entrypoint.sh

# Make the scripts executable.
RUN chmod +x /docker-entrypoint-initwp.d/configure_wp.sh
RUN chmod +x /usr/local/bin/healthcheck.sh
RUN chmod +x /usr/local/bin/custom_entrypoint.sh

# Set the custom entrypoint.
ENTRYPOINT ["/usr/local/bin/custom_entrypoint.sh"]

# Expose the port for PHP-FPM.
EXPOSE 9000

# The base image's entrypoint will run the init scripts and then start php-fpm.
# No need to override CMD or ENTRYPOINT.
CMD ["php-fpm"]
