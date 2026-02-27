#!/bin/bash
set -e

# MariaDB initialization script for Inception project.
# Initializes the data directory if empty, creates database and users,
# then hands off to the CMD (mariadbd).

DATADIR="/var/lib/mysql"

# ── First-run initialization ──────────────────────────────────────────
if [ ! -d "$DATADIR/mysql" ]; then
    echo "[init_db] First run detected — initializing data directory..."

    # Initialize the system tables
    mysql_install_db --user=mysql --datadir="$DATADIR" > /dev/null

    echo "[init_db] Starting temporary MariaDB for bootstrap..."
    # Start MariaDB temporarily without networking so only local socket works
    mariadbd --user=mysql --skip-networking --socket=/var/run/mysqld/mysqld.sock &
    TEMP_PID=$!

    # Wait for the temporary server to be ready
    for i in $(seq 1 30); do
        if mariadb-admin ping --socket=/var/run/mysqld/mysqld.sock > /dev/null 2>&1; then
            break
        fi
        echo "[init_db] Waiting for temporary server... ($i/30)"
        sleep 1
    done

    # Run the SQL to create database, user, set root password, lock down
    echo "[init_db] Creating database '${MYSQL_DATABASE}' and user '${MYSQL_USER}'..."
    mariadb --socket=/var/run/mysqld/mysqld.sock <<-EOSQL
        -- Remove anonymous users and test database
        DELETE FROM mysql.user WHERE User='';
        DROP DATABASE IF EXISTS test;
        DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';

        -- Create the application database
        CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;

        -- Create the application user with full access to the database
        CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
        GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';

        -- Set the root password (root can only connect locally)
        ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';

        FLUSH PRIVILEGES;
EOSQL

    echo "[init_db] Bootstrap complete — shutting down temporary server..."
    mariadb-admin --user=root --password="${MYSQL_ROOT_PASSWORD}" \
        --socket=/var/run/mysqld/mysqld.sock shutdown

    # Wait for the temp process to actually exit
    wait "$TEMP_PID" 2>/dev/null || true

    echo "[init_db] Initialization finished."
else
    echo "[init_db] Data directory already exists — skipping initialization."
fi

# ── Hand off to CMD (mariadbd) ─────────────────────────────────────────
echo "[init_db] Starting MariaDB daemon..."
exec "$@"
