#!/bin/bash

# This script generates a self-signed SSL certificate for Nginx.

# Exit immediately if a command exits with a non-zero status.
set -e

# Define paths for the certificate and key.
SSL_DIR="/etc/nginx/ssl"
SSL_KEY_PATH="$SSL_DIR/inception.key"
SSL_CERT_PATH="$SSL_DIR/inception.crt"

# Check if the certificate already exists. If so, do nothing.
if [ -f "$SSL_CERT_PATH" ]; then
    echo "SSL certificate already exists. Skipping generation."
    exit 0
fi

echo "Generating self-signed SSL certificate..."

# Create the SSL directory if it doesn't exist.
mkdir -p "$SSL_DIR"

# Generate the certificate and key using openssl.
# -x509: Creates a self-signed certificate.
# -nodes: Skips passphrase protection for the key.
# -days 365: Sets the certificate validity period.
# -newkey rsa:2048: Generates a new 2048-bit RSA private key.
# -keyout: Specifies the output file for the private key.
# -out: Specifies the output file for the certificate.
# -subj: Provides the subject information non-interactively.
#   - CN (Common Name) is set to the DOMAIN_NAME, which is crucial.
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout "$SSL_KEY_PATH" \
    -out "$SSL_CERT_PATH" \
    -subj "/C=DE/ST=Berlin/L=Berlin/O=42/OU=Student/CN=${DOMAIN_NAME}"

echo "SSL certificate and key generated successfully."
