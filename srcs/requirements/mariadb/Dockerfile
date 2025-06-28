# Use the penultimate stable version of Debian: Bullseye (Debian 11)
FROM debian:bullseye-slim

# ARG for build-time variables if needed
# ARG MARIADB_VERSION=10.5 # MariaDB version in Bullseye is typically 10.5

# Environment variables that can be overridden at runtime (e.g., from .env file)
# These are defaults if not provided by docker-compose env_file
ENV MYSQL_DATABASE=wordpress_db
ENV MYSQL_USER=wp_user
ENV MYSQL_PASSWORD=changeme_db_password
ENV MYSQL_ROOT_PASSWORD=changeme_db_root_password

LABEL maintainer="mnaumann@student.42.fr" \
      project="Inception - MariaDB"

# Install MariaDB and necessary tools
# procps for `ps`, netcat for healthchecks/wait scripts if needed
RUN apt-get update && \
    apt-get install -y mariadb-server procps netcat-traditional && \
    rm -rf /var/lib/apt/lists/* && \
    sed -i 's/^bind-address\s*=\s*127.0.0.1/bind-address = 0.0.0.0/' /etc/mysql/mariadb.conf.d/50-server.cnf

# Remove pre-installed database directory content if any (MariaDB handles initialization)
# RUN rm -rf /var/lib/mysql/* # This is often handled by the init script or first run

# Copy initialization/entrypoint script
COPY ./tools/init_db.sh /usr/local/bin/init_db.sh
RUN chmod +x /usr/local/bin/init_db.sh

# Copy MariaDB custom configurations if any
COPY ./conf/my.cnf /etc/mysql/conf.d/my.cnf
RUN chmod 644 /etc/mysql/conf.d/my.cnf

# Set the entrypoint to our custom initialization script
ENTRYPOINT ["/usr/local/bin/init_db.sh"]

# The default command to run after the entrypoint script finishes
# The entrypoint script will execute this command using 'exec "$@"'
CMD ["mysqld", "--user=mysql", "--console"]
