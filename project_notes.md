# Project Notes

## MariaDB and WordPress Connectivity Debugging

**Date:** 2025-07-02

### Problem Description
The Docker Compose stack failed to start because the `wordpress` container was unable to connect to the `mariadb` container. The `wordpress` container would get stuck in a "Waiting for MariaDB..." loop, and the `mariadb` container would eventually be marked as unhealthy, causing a `dependency failed to start` error.

### Debugging Journey & Resolutions

1.  **Initial Approach (Custom Init Scripts):**
    *   **Issue:** An attempt was made to use a custom `init_db.sh` script as an `ENTRYPOINT` to create the database and user. This failed because commands like `mysqld_safe` and `mysqladmin` were not in the script's `PATH`, and it conflicted with the official MariaDB image's own startup logic.

2.  **Refined Approach (Using `docker-entrypoint-initdb.d`):**
    *   **Issue:** The `init_db.sh` script was moved to `/docker-entrypoint-initdb.d/`, which is the correct mechanism for initialization in the official image. However, the script still failed with `mysql: command not found`. This highlighted that manually scripting the database setup was overly complex and unnecessary.

3.  **Simplification (Relying on Official Image Behavior):**
    *   **Solution:** The custom `init_db.sh` script was removed entirely. The official MariaDB image is designed to automatically create the database and user specified by the `MYSQL_DATABASE`, `MYSQL_USER`, `MYSQL_PASSWORD`, and `MYSQL_ROOT_PASSWORD` environment variables passed from the `.env` file. This is the standard and most reliable method.

4.  **Final Hurdle (Healthcheck Race Condition):**
    *   **Issue:** After simplifying the initialization, the `mariadb` container was still unhealthy. The `HEALTHCHECK` in `docker-compose.yml` was configured to use the `wp_user` (`${MYSQL_USER}`) credentials to ping the database.
    *   **Root Cause:** This created a race condition. The healthcheck would run and fail because it was trying to authenticate as `wp_user` *before* the MariaDB initialization process had actually created that user.
    *   **Final Solution:** The `mariadb` healthcheck was modified to use the `root` user and `${MYSQL_ROOT_PASSWORD}`. The `root` user is guaranteed to exist as soon as the server is running. This provides a reliable signal that the database is ready for connections, allowing the `wordpress` container (which depends on a healthy MariaDB service) to start at the correct time.

This iterative process resolved the connectivity issues and led to a more robust and standard configuration for the MariaDB service.

---

## Inception Bonus: Full Stack Debugging and Refactoring

**Date:** 2025-07-03

### Initial State & Goal
The project was a Docker Compose stack (Nginx, WordPress, MariaDB, Redis, Adminer) for the 42 "Inception" project. The initial state suffered from multiple issues, including service startup failures, incorrect configurations, and race conditions. The goal was to debug, refactor, and make the entire stack robust, portable, and compliant with the project subject.

### Debugging Journey & Key Resolutions

1.  **MariaDB Initialization:**
    *   **Problem:** The MariaDB container failed to initialize correctly due to faulty custom scripts (`init_db.sh`).
    *   **Solution:** We removed all custom database initialization scripts and adopted the standard practice of using the official MariaDB image's environment variables (`MYSQL_DATABASE`, `MYSQL_USER`, etc.) for automatic, reliable database and user creation. The healthcheck was also updated to use the `root` user to avoid race conditions during startup.

2.  **WordPress Configuration (`configure_wp.sh`):**
    *   **Problem:** The script responsible for setting up WordPress had several issues: incorrect environment variable names, missing dependencies, and a failure to create the second, non-admin user required by the subject.
    *   **Solution:** The script was completely overhauled. Environment variable names were corrected, robust checks were added, and the logic to create the second user via WP-CLI was implemented. We also added the installation of the PHP Redis extension (`phpredis`) and `redis-tools` to the WordPress Dockerfile.

3.  **Startup Deadlock (The Core Issue):**
    *   **Problem:** A critical deadlock prevented the stack from ever becoming healthy. The WordPress entrypoint script would run the lengthy `configure_wp.sh` *before* starting the `php-fpm` service. Nginx, in turn, was configured to wait for WordPress to be healthy. This created a circular dependency: Nginx waited for a healthy WordPress, but WordPress couldn't become healthy because its `php-fpm` service wasn't running to pass the healthcheck.
    *   **Solution:** We created a `custom_entrypoint.sh` for the WordPress container. This new entrypoint does two things: it launches the `configure_wp.sh` script in the **background** and then immediately executes the original WordPress entrypoint to start `php-fpm`. This broke the deadlock.

4.  **Race Condition (Configuration vs. File Copy):**
    *   **Problem:** With the deadlock solved, a new race condition appeared. The background configuration script would sometimes start *before* the official entrypoint had finished copying the WordPress core files into the shared volume, causing `wp-cli` to fail.
    *   **Solution:** We added a wait loop to the beginning of `configure_wp.sh` that explicitly waits for the `wp-load.php` file to exist before proceeding. This ensures the WordPress files are in place before any configuration is attempted.

5.  **Healthcheck Failure (`cgi-fcgi`):**
    *   **Problem:** Even with all services running, the WordPress container remained `unhealthy`. The healthcheck script relied on the `cgi-fcgi` command to ping the `php-fpm` service, but this command was not installed in the container.
    *   **Solution:** We added the `libfcgi-bin` package to the `apt-get install` list in the WordPress `Dockerfile`, making the healthcheck command available and finally allowing the container to report a healthy status.

### Final Outcome
Through this iterative debugging process, we transformed a fragile and non-functional stack into a stable, correctly configured, and fully operational system. All services now start reliably, are properly interconnected, and fulfill the requirements of the Inception project, including the main WordPress site, the static bonus site, and the Redis cache.

---

## Static Site Deployment and Nginx Debugging

**Date:** 2025-07-04

### Goal
With the primary stack (WordPress, MariaDB, Redis) stable, the final step was to enable the bonus static website, which needed to be served by the existing Nginx container on a separate port (8081).

### Debugging Journey & Key Resolutions

1.  **Nginx Configuration Conflict (`duplicate default server`):**
    *   **Problem:** After adding the new `server` block for the static site, the Nginx container failed to start, logging a `nginx: [emerg] a duplicate default server` error.
    *   **Root Cause:** The original Nginx configuration template contained a catch-all `default_server` on port 80. When the new server block for the static site was added (also listening on an HTTP port, albeit a different one), it created a conflict.
    *   **Solution:** The unnecessary `default_server` block was removed from the `nginx.conf.template`, as our setup only requires the specific WordPress (port 443) and static site (port 8081) server blocks.

2.  **Incorrect Port Mapping (`Empty reply from server`):**
    *   **Problem:** After fixing the config conflict, requests to `http://static.mnaumann.42.fr:8081` resulted in an "Empty reply from server" error.
    *   **Root Cause:** The `docker-compose.yml` file had an incorrect port mapping for Nginx: `- "8081:444"`. This forwarded requests from the host's port 8081 to port 444 inside the container, but the Nginx server was configured to listen on port 8081.
    *   **Solution:** The port mapping was corrected to `- "8081:8081"` to ensure traffic from the host correctly reached the listening port inside the container.

3.  **Incorrect File Path (`404 Not Found`):**
    *   **Problem:** With the port mapping fixed, Nginx was now reachable, but it returned a `404 Not Found` error for the static HTML file.
    *   **Root Cause:** A path mismatch existed between the Docker volume mount and the Nginx configuration. The `docker-compose.yml` mounted the static content to `/var/www/static` inside the container, but the `root` directive in the Nginx server block was mistakenly pointing to `/var/www/html/static`.
    *   **Solution:** The `root` directive in `nginx.conf.template` was corrected to `/var/www/static`, aligning the Nginx configuration with the actual file location inside the container.

### Final Outcome
With these final configuration corrections, the static bonus site became fully accessible at `http://static.mnaumann.42.fr:8081`, running in parallel with the main WordPress application from the same Nginx container. The entire Inception stack is now complete, stable, and robust.

---

## FTP Server Implementation and Debugging

**Date:** 2025-07-04

### Goal
The final bonus requirement was to add a secure FTP server (`vsftpd`) that would allow file access to the WordPress volume.

### Debugging Journey & Key Resolutions

1.  **Build-Time Environment Variables (`useradd` failure):**
    *   **Problem:** The initial Docker build for the `ftp` container failed with an error in the `useradd` command. The `${FTP_USER}` and `${FTP_PASS}` variables, defined in the `.env` file, were not being passed into the build environment.
    *   **Root Cause:** The `env_file` directive in `docker-compose.yml` only makes variables available to the *running container*, not to the *build process*.
    *   **Solution:** The `docker-compose.yml` file was modified to include a `build.args` section for the `ftp` service. This explicitly passes the variables from the `.env` file into the Docker build, making them accessible to the `RUN` instructions in the `Dockerfile`.

2.  **Incorrect `docker-compose.yml` Syntax:**
    *   **Problem:** Even after adding `build.args`, the build continued to fail. My initial attempts used an incorrect list syntax (`- FTP_USER=${FTP_USER}`).
    *   **Root Cause:** The `args` section in Docker Compose requires a key-value map, not a list.
    *   **Solution:** The syntax was corrected to the proper map format (`FTP_USER: ${FTP_USER}`), which finally allowed the variables to be correctly interpolated during the build.

3.  **IPv6 Socket Binding Error (`500 OOPS`):**
    *   **Problem:** With the build succeeding, the `ftp` container would start but then immediately exit. Manually running the entrypoint script inside the container revealed the root cause: `500 OOPS: could not bind listening IPv6 socket`.
    *   **Root Cause:** By default, `vsftpd` attempts to bind to an IPv6 socket, which is often not available or configured in a standard Docker network, causing the server to crash.
    *   **Solution:** The `vsftpd_entrypoint.sh` script was updated to generate a `vsftpd.conf` file that explicitly disables IPv6 listening (`listen_ipv6=NO`) and enables IPv4 listening (`listen=YES`). This ensures the server binds to the correct network interface within the container.

### Final Outcome
After resolving the build-time variable injection and the IPv6 configuration issue, the FTP container started successfully and became fully operational. The final, stable stack now includes all required core services and bonus features, is fully documented, and can be reliably managed via the `Makefile`.
