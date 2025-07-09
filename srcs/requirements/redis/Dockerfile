FROM redis:7.0-alpine

# Copy the Redis configuration file
COPY ./conf/redis.conf /usr/local/etc/redis/redis.conf

# The CMD will be executed when the container starts.
# It starts the Redis server using the specified config file and
# overrides the password with the value from the environment variable.
# We use the shell form to ensure the environment variable is substituted.
CMD ["/bin/sh", "-c", "redis-server /usr/local/etc/redis/redis.conf --requirepass \"$REDIS_PASSWORD\""]
