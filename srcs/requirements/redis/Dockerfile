FROM alpine:3.20

# Install Redis server
RUN apk add --no-cache redis

# Copy custom Redis configuration
COPY ./conf/redis.conf /etc/redis/redis.conf

# Copy entrypoint and healthcheck scripts
COPY ./tools/redis_entrypoint.sh /usr/local/bin/redis_entrypoint.sh
COPY ./tools/healthcheck.sh /usr/local/bin/healthcheck.sh
RUN chmod +x /usr/local/bin/redis_entrypoint.sh /usr/local/bin/healthcheck.sh

# Create data directory for persistence
RUN mkdir -p /data && chown redis:redis /data
WORKDIR /data

EXPOSE 6379

ENTRYPOINT ["/usr/local/bin/redis_entrypoint.sh"]
CMD ["redis-server", "/etc/redis/redis.conf"]
