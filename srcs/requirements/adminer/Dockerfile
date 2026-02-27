FROM alpine:3.20

# Install PHP and the MySQL extension needed by Adminer
RUN apk add --no-cache \
    php82 \
    php82-session \
    php82-mysqli \
    php82-pdo_mysql \
    curl

# Download Adminer (single PHP file)
RUN mkdir -p /var/www/adminer && \
    curl -L -o /var/www/adminer/index.php \
    "https://github.com/vrana/adminer/releases/download/v4.8.1/adminer-4.8.1.php"

EXPOSE 8080

WORKDIR /var/www/adminer

# Run PHP's built-in web server — lightweight, no nginx needed
CMD ["php82", "-S", "0.0.0.0:8080", "-t", "/var/www/adminer"]
