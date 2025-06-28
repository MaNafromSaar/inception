#!/bin/bash
set -e

# Run SSL generation script
/usr/local/bin/generate_ssl.sh

# Substitute environment variables in Nginx configuration
# This allows using $DOMAIN_NAME in nginx.conf
# Create a temporary config file for substitution
TEMP_NGINX_CONF="/tmp/nginx.conf.template"
cp /etc/nginx/nginx.conf "$TEMP_NGINX_CONF"

# Ensure DOMAIN_NAME is set, default if not (though it should be from .env)
: "${DOMAIN_NAME:=yourlogin.42.fr}"

echo "Substituting DOMAIN_NAME=${DOMAIN_NAME} in Nginx config"
envsubst '${DOMAIN_NAME}' < "$TEMP_NGINX_CONF" > /etc/nginx/nginx.conf
rm "$TEMP_NGINX_CONF"

echo "Nginx configuration after substitution:"
cat /etc/nginx/nginx.conf | grep "server_name" # For verification

echo "Starting Nginx with command: $@"
# Execute the CMD from the Dockerfile (nginx -g 'daemon off;')
exec "$@"
