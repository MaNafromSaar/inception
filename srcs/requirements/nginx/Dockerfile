FROM debian:bullseye

# Install Nginx, OpenSSL, and envsubst utility
RUN apt-get update && apt-get install -y \
    nginx \
    openssl \
    gettext-base \
    && rm -rf /var/lib/apt/lists/*

# Copy the configuration template and the entrypoint/helper scripts
COPY ./conf/nginx.conf.template /etc/nginx/templates/nginx.conf.template
COPY ./tools/nginx_entrypoint.sh /usr/local/bin/nginx_entrypoint.sh
COPY ./tools/generate_ssl.sh /usr/local/bin/generate_ssl.sh

# Make scripts executable
RUN chmod +x /usr/local/bin/nginx_entrypoint.sh
RUN chmod +x /usr/local/bin/generate_ssl.sh

# Expose the HTTPS port
EXPOSE 443

# Set the entrypoint. The entrypoint script will prepare the config and then run the CMD.
ENTRYPOINT ["/usr/local/bin/nginx_entrypoint.sh"]

# The default command to start Nginx in the foreground.
# This will be executed by the entrypoint script.
CMD ["nginx", "-g", "daemon off;"]
