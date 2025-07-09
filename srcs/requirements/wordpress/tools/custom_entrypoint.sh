#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# 1. Execute the main configuration script in the background.
#    This allows the main container process (php-fpm) to start immediately,
#    while the configuration (database setup, user creation, etc.) happens.
#    We redirect stdout and stderr to the container's logs for debugging.
/docker-entrypoint-initwp.d/configure_wp.sh > /proc/1/fd/1 2>/proc/1/fd/2 &

# 2. Execute the original entrypoint script of the base WordPress image.
#    This will start php-fpm and handle other standard initializations.
#    We pass along any arguments that were passed to this script.
exec docker-entrypoint.sh "$@"
