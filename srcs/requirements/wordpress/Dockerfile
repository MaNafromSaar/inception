FROM debian:bookworm

# Install PHP 8.2 (Bookworm default), PHP-FPM, and all extensions WordPress needs
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    php8.2-fpm \
    php8.2-mysql \
    php8.2-curl \
    php8.2-gd \
    php8.2-intl \
    php8.2-mbstring \
    php8.2-xml \
    php8.2-zip \
    php8.2-soap \
    php8.2-redis \
    php8.2-imagick \
    libfcgi-bin \
    curl \
    mariadb-client \
    less \
    procps \
    netcat-openbsd \
    redis-tools \
    tar \
    && rm -rf /var/lib/apt/lists/*

# Configure PHP-FPM to listen on port 9000 (TCP) instead of unix socket
RUN sed -i 's|listen = /run/php/php8.2-fpm.sock|listen = 0.0.0.0:9000|' \
        /etc/php/8.2/fpm/pool.d/www.conf && \
    sed -i 's|;clear_env = no|clear_env = no|' \
        /etc/php/8.2/fpm/pool.d/www.conf

# Install WP-CLI
RUN curl -o /usr/local/bin/wp \
    https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x /usr/local/bin/wp

# Create working directory
RUN mkdir -p /var/www/html && chown -R www-data:www-data /var/www/html
WORKDIR /var/www/html

# Download WordPress core files at build time so they are baked into the image
RUN su -s /bin/bash www-data -c \
    "wp core download --path=/var/www/html --locale=en_US"

# Copy scripts
COPY ./tools/configure_wp.sh /usr/local/bin/configure_wp.sh
COPY ./tools/healthcheck.sh  /usr/local/bin/healthcheck.sh
COPY ./tools/wp_entrypoint.sh /usr/local/bin/wp_entrypoint.sh

RUN chmod +x /usr/local/bin/configure_wp.sh \
              /usr/local/bin/healthcheck.sh \
              /usr/local/bin/wp_entrypoint.sh

EXPOSE 9000

ENTRYPOINT ["/usr/local/bin/wp_entrypoint.sh"]
CMD ["php-fpm8.2", "--nodaemonize"]
