#!/bin/bash

# Simple script to test connectivity between containers

# ANSI color codes
BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}--- Inception Connectivity Test ---${NC}"

# 1. Check if Nginx can reach WordPress
echo -n "Testing Nginx -> WordPress connection... "
if docker exec nginx nc -z wordpress 9000; then
    echo -e "${GREEN}Success!${NC}"
else
    echo -e "${RED}Failed!${NC}"
fi

# 2. Check if WordPress can reach MariaDB
echo -n "Testing WordPress -> MariaDB connection... "
if docker exec wordpress nc -z mariadb 3306; then
    echo -e "${GREEN}Success!${NC}"
else
    echo -e "${RED}Failed!${NC}"
fi

# 3. Check if the domain name resolves and Nginx is serving HTTPS
DOMAIN_NAME=$(grep DOMAIN_NAME srcs/.env | cut -d '=' -f2)
if [ -z "$DOMAIN_NAME" ]; then
    echo -e "${RED}Could not read DOMAIN_NAME from srcs/.env${NC}"
    exit 1
fi

echo -n "Testing external access to https://$DOMAIN_NAME... "
# We add the domain to /etc/hosts to ensure it resolves to localhost for the test
if curl -s -k --resolve "$DOMAIN_NAME:443:127.0.0.1" https://$DOMAIN_NAME/ | grep -q "WordPress"; then
    echo -e "${GREEN}Success! WordPress site is up.${NC}"
else
    echo -e "${RED}Failed! Could not access the WordPress site via Nginx.${NC}"
fi

echo -e "${BLUE}--- Test Complete ---${NC}"
