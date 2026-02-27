#!/bin/bash
# MariaDB healthcheck — verifies the server is accepting connections.
# Uses root because the application user may not exist during first init.
exec mariadb-admin ping -h localhost -u root -p"${MYSQL_ROOT_PASSWORD}"
