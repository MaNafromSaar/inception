# Project Modules Overview

This document explains each module/service in the Inception project and its role.

---

## NGINX
- Acts as the sole entry point to the infrastructure.
- Handles HTTPS (TLSv1.2/1.3) and reverse proxying to other services.
- Configured via `srcs/requirements/nginx/Dockerfile` and `nginx.conf`.

## WordPress
- Provides the main website, running on php-fpm (no nginx inside container).
- Connects to MariaDB for data storage.
- Configured via `srcs/requirements/wordpress/Dockerfile` and `configure_wp.sh`.

## MariaDB
- Stores WordPress data in a dedicated database.
- Two users are created, one is the admin (not named 'admin').
- Configured via `srcs/requirements/mariadb/Dockerfile` and `init_db.sh`.

## Redis (Bonus)
- Provides caching for WordPress to improve performance.
- Configured via `srcs/requirements/redis/Dockerfile` and `redis.conf`.

## FTP Server (Bonus)
- Allows file transfer to/from the WordPress volume.
- Configured via `srcs/requirements/ftp/Dockerfile` and `vsftpd_entrypoint.sh`.

## Adminer (Bonus)
- Web-based database management tool for MariaDB.
- Configured via `srcs/requirements/adminer/Dockerfile` (if present) and Compose files.

## Static Website (Bonus)
- Simple static site (e.g., HTML/CSS/JS) for showcase or resume.
- Served by NGINX from the `html/` directory.

---

Each module runs in its own container, with dedicated volumes and proper networking as per project requirements.
