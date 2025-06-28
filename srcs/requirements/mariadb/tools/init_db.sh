#!/bin/bash
set -e

# Function to check if MariaDB is up and running
is_mysql_ready() {
    mysqladmin ping -hlocalhost --silent
}

# Ensure /var/run/mysqld exists and has correct permissions
if [ ! -d "/var/run/mysqld" ]; then
    mkdir -p /var/run/mysqld
    chown -R mysql:mysql /var/run/mysqld
    chmod 700 /var/run/mysqld
fi

# Same for /var/lib/mysql if it\'s not automatically handled by volume mount
if [ ! -d "/var/lib/mysql/mysql" ]; then # Check for a common subdirectory
    chown -R mysql:mysql /var/lib/mysql
    chmod 700 /var/lib/mysql
fi


# Initialize MariaDB data directory if it\'s empty
# This is crucial for the first run.
if [ -z "$(ls -A /var/lib/mysql)" ]; then
    echo "Initializing MariaDB data directory..."
    # mysql_install_db is deprecated in newer MariaDB versions,
    # mariadb-install-db should be used or it happens automatically.
    # For Debian buster\'s MariaDB 10.3, it might still be relevant or handled by the package.
    # If issues, check specific MariaDB version docs.
    # Typically, just starting mysqld_safe or mysqld bootstraps it.
    # We will let the initial mysqld startup handle this.
    # However, we need to ensure permissions are correct.
    chown -R mysql:mysql /var/lib/mysql
    chmod 700 /var/lib/mysql
    mariadb-install-db --user=mysql --datadir=/var/lib/mysql
    echo "MariaDB data directory initialized."

    # Start MariaDB server in the background temporarily for setup
    echo "Starting MariaDB server for setup..."
    # mysqld_safe --user=mysql --datadir=/var/lib/mysql &
    # Using mysqld directly as it's often preferred for containers
    mysqld --user=mysql --datadir=/var/lib/mysql &
    pid="$!"

    # Wait for MariaDB to be ready
    echo "Waiting for MariaDB to start..."
    for i in {30..0}; do
        if is_mysql_ready; then
            echo "MariaDB is ready."
            break
        fi
        echo "MariaDB not yet ready, waiting... ($i)"
        sleep 1
    done
    if [ "$i" = 0 ]; then
        echo >&2 "MariaDB setup timed out."
        # Print logs if available
        if [ -f /var/log/mysql/error.log ]; then
            cat /var/log/mysql/error.log
        fi
        exit 1
    fi

    # Perform setup using SQL commands
    # Note: Using environment variables for credentials.
    echo "Running MariaDB setup SQL..."

    # SQL to execute. Using temp file for heredoc.
    SQL_COMMANDS=$(mktemp)
    cat > "$SQL_COMMANDS" <<-EOSQL
		-- Create database if it doesn't exist
		CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;

		-- Create user if it doesn't exist and grant privileges
		-- Note: MariaDB syntax for IF NOT EXISTS with CREATE USER might vary or not be direct.
		-- It's safer to attempt creation and handle potential errors or check first.
		-- For simplicity, we assume it's the first setup.
		-- If you need idempotency, you might need more complex SQL.

		-- Change root password
		ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';

		-- Create the WordPress user
		CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
		GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';

		-- Flush privileges to ensure changes take effect
		FLUSH PRIVILEGES;
	EOSQL

    # Execute the SQL commands
    echo "Executing SQL: "
    cat "$SQL_COMMANDS"
    if mysql -u root < "$SQL_COMMANDS"; then
        echo "SQL commands executed successfully."
    else
        echo >&2 "SQL commands failed."
        # Print logs if available
        if [ -f /var/log/mysql/error.log ]; then
            cat /var/log/mysql/error.log
        fi
        # Attempt to shut down the temporary server before exiting
        if ! kill -s TERM "$pid" || ! wait "$pid"; then
            echo >&2 "Failed to shutdown temporary MariaDB server."
        fi
        rm -f "$SQL_COMMANDS"
        exit 1
    fi

    rm -f "$SQL_COMMANDS"

    # Shut down the temporary MariaDB server
    echo "Shutting down temporary MariaDB server..."
    if ! kill -s TERM "$pid" || ! wait "$pid"; then
        echo >&2 "Failed to shutdown temporary MariaDB server."
        exit 1
    fi
    echo "Temporary MariaDB server shut down."
fi

# Now, execute the command passed to the entrypoint (e.g., CMD in Dockerfile)
# This will start MariaDB in the foreground as the main container process.
echo "Starting MariaDB with command: $@"
exec "$@"
