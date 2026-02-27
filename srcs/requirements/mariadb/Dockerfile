FROM debian:bookworm

# Install MariaDB server and client
RUN apt-get update && apt-get install -y \
    mariadb-server \
    mariadb-client \
    procps \
    && rm -rf /var/lib/apt/lists/*

# Copy custom MariaDB configuration
COPY ./conf/my.cnf /etc/mysql/mariadb.conf.d/99-inception.cnf
RUN chmod 644 /etc/mysql/mariadb.conf.d/99-inception.cnf

# Copy initialization and healthcheck scripts
COPY ./tools/init_db.sh /usr/local/bin/init_db.sh
COPY ./tools/healthcheck.sh /usr/local/bin/healthcheck.sh
RUN chmod +x /usr/local/bin/init_db.sh /usr/local/bin/healthcheck.sh

# The mariadb-server package auto-initializes /var/lib/mysql during install.
# Remove it so our entrypoint (init_db.sh) controls first-run initialization.
RUN rm -rf /var/lib/mysql/* \
    && mkdir -p /var/run/mysqld /var/lib/mysql \
    && chown -R mysql:mysql /var/run/mysqld /var/lib/mysql

EXPOSE 3306

ENTRYPOINT ["/usr/local/bin/init_db.sh"]
CMD ["mariadbd", "--user=mysql"]
