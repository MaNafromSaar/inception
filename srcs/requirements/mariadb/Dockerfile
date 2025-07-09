FROM mariadb:latest

# Copy the custom configuration file
COPY ./conf/my.cnf /etc/mysql/conf.d/my.cnf

# Set proper permissions for the config file to avoid warnings
RUN chmod 644 /etc/mysql/conf.d/my.cnf

# Expose the default MariaDB port
EXPOSE 3306

# Healthcheck to make sure the container is running
HEALTHCHECK --interval=10s --timeout=5s --start-period=30s --retries=3 \
  CMD mariadb-admin ping -h localhost -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}" || exit 1
