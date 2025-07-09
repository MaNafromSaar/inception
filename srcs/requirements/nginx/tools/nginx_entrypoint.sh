#!/bin/sh

# Exit immediately if a command exits with a non-zero status.
set -e

# First, generate the SSL certificate. This script will check if the certificate
# already exists and skip generation if it does. It needs to be run at startup
# to ensure it can access runtime environment variables like DOMAIN_NAME.
/usr/local/bin/generate_ssl.sh

# Use `envsubst` to substitute environment variables in the template file.
# We only want to substitute the DOMAIN_NAME and other potential variables
# we might add later. We must specify the variables to avoid substituting
# Nginx's own internal variables like $uri, $host, etc.

# Note: The single quotes around '${DOMAIN_NAME}' are important.
envsubst '${DOMAIN_NAME} ${STATIC_SITE_DOMAIN_NAME}' < /etc/nginx/templates/nginx.conf.template > /etc/nginx/nginx.conf

# Now that the configuration is generated, execute the command passed to this script.
# This will be the `CMD` from the Dockerfile (e.g., `nginx -g "daemon off;"`).
# Using `exec "$@"` is a best practice that ensures the main process (Nginx)
# receives signals correctly and the container stops gracefully.
exec "$@"
