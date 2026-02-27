#!/bin/sh
set -e

# Redis entrypoint — injects the password from env var at runtime
# (keeps passwords out of the Dockerfile and config files in Git).

# Append the requirepass directive at startup
exec "$@" --requirepass "$REDIS_PASSWORD"
