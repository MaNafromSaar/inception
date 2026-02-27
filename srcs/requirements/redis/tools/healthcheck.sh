#!/bin/sh
# Redis healthcheck — verifies the server responds to PING.
exec redis-cli -a "$REDIS_PASSWORD" ping | grep -q PONG
