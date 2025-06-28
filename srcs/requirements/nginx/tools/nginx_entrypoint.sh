#!/bin/bash
set -e

# Run SSL generation script which creates certs based on DOMAIN_NAME
/usr/local/bin/generate_ssl.sh

# The nginx.conf file now uses ${DOMAIN_NAME} as a placeholder.
# We use envsubst to replace this placeholder with the actual value from the environment.
# This makes the configuration dynamic and dependent on the .env file.

# Define the source and destination for the config file
CONF_TEMPLATE="/etc/nginx/nginx.conf"
CONF_DEST="/etc/nginx/nginx.conf.substituted"

echo "Substituting DOMAIN_NAME=${DOMAIN_NAME} in Nginx config..."
# Use envsubst to replace the variable and create the final config file
# Note: We are reading from the original and writing to a new file, then replacing.
# This is safer than in-place editing.
envsubst '${DOMAIN_NAME}' < "${CONF_TEMPLATE}" > "${CONF_DEST}"

# Replace the original config with the substituted one
mv "${CONF_DEST}" "${CONF_TEMPLATE}"

echo "Starting Nginx..."
# Execute the CMD from the Dockerfile (e.g., nginx -g 'daemon off;')
exec "$@"
