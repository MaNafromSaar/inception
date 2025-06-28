#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Robust Database Initialization Script ---
# This script is the container's entrypoint. It initializes the MariaDB database
# only if it hasn't been initialized yet. This is crucial for data persistence
# across container restarts.

# Define the data directory
DATADIR="/var/lib/mysql"

# 1. Check if the database directory is already initialized
# We check for the presence of the 'mysql' database directory, which is a core component.
if [ -d "$DATADIR/mysql" ]; then
    echo "[INFO] Database directory found. Skipping initialization."
else
    echo "[INFO] Database directory not found. Initializing database..."
    # The 'mysql_install_db' script initializes the data directory, creates system tables, etc.
    # We specify the user to run as and the data directory.
    mysql_install_db --user=mysql --datadir="$DATADIR"
    echo "[INFO] Database initialized."
fi

# 2. Start the MariaDB server in the background
# We use 'exec' to replace the shell process with the mysqld process, but we send it to the background (&).
# The 'mysqld_safe' script is often used as it monitors the server and restarts it if it crashes.
# We will temporarily start it to perform setup, then shut it down to restart it in the foreground.
mysqld_safe --user=mysql --datadir="$DATADIR" &
pid="$!"

# 3. Wait for the database server to be ready
echo "[INFO] Waiting for MariaDB server to start..."
# We ping the server until it responds successfully.
# The 'mysqladmin' tool is perfect for this.
until mysqladmin ping -h localhost --silent; do
    echo -n "."
    sleep 1
done
echo "\n[INFO] MariaDB server is running."

# 4. Check if the WordPress database exists and create it if it doesn't
# We use a 'mysql' command to check the information_schema for our database name.
# The output is redirected to /dev/null, and we check the exit code.
if ! mysql -u root -e "USE \`${MYSQL_DATABASE}\`;" &> /dev/null; then
    echo "[INFO] WordPress database '${MYSQL_DATABASE}' not found. Creating database and user..."

    # Create the database and user using the credentials from the .env file.
    # Using a here-document (<<EOF) makes the SQL commands clean and readable.
    mysql -u root <<-EOF
        CREATE DATABASE \`${MYSQL_DATABASE}\`;
        CREATE USER \`${MYSQL_USER}\`@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
        GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO \`${MYSQL_USER}\`@'%';
        FLUSH PRIVILEGES;
        ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
EOF
    echo "[INFO] Database '${MYSQL_DATABASE}' and user '${MYSQL_USER}' created."
else
    echo "[INFO] WordPress database '${MYSQL_DATABASE}' already exists. Skipping creation."
fi

# 5. Shut down the temporary server
echo "[INFO] Shutting down temporary MariaDB server..."
if ! mysqladmin -u root -p"${MYSQL_ROOT_PASSWORD}" shutdown; then
    echo "[WARN] Failed to shut down server with root password. Trying without password..."
    mysqladmin -u root shutdown
fi

# Wait for the server process to truly stop
wait "$pid"
echo "[INFO] Temporary server shut down."

# 6. Start the final MariaDB server in the foreground
# This is the main process of the container. 'exec' is important as it makes
# 'mysqld' the container's PID 1, allowing it to receive signals correctly.
echo "[INFO] Restarting MariaDB server in the foreground..."
exec mysqld --user=mysql --console
