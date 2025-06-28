#!/bin/bash
set -e

SSL_DIR="/etc/nginx/ssl"
KEY_FILE="${SSL_DIR}/${DOMAIN_NAME}.key"
CRT_FILE="${SSL_DIR}/${DOMAIN_NAME}.crt"

# Check if DOMAIN_NAME is set
if [ -z "${DOMAIN_NAME}" ]; then
    echo "Error: DOMAIN_NAME environment variable is not set."
    exit 1
fi

# Create SSL directory if it doesn\'t exist
mkdir -p "$SSL_DIR"

# Generate SSL certificate if it doesn\'t exist
if [ ! -f "$KEY_FILE" ] || [ ! -f "$CRT_FILE" ]; then
    echo "Generating self-signed SSL certificate for ${DOMAIN_NAME}..."
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout "$KEY_FILE" \
        -out "$CRT_FILE" \
        -subj "/C=FR/ST=Paris/L=Paris/O=42/OU=student/CN=${DOMAIN_NAME}"
    echo "SSL certificate generated."
else
    echo "SSL certificate already exists."
fi

# Set appropriate permissions
chmod 600 "$KEY_FILE"
chmod 644 "$CRT_FILE"
