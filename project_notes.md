# Project Inception: Debugging and Setup Notes

This document tracks the key challenges and solutions encountered during the setup and debugging of the Inception project.

## 1. Initial WordPress Build Failure

*   **Problem:** The initial Docker build for the `wordpress` service failed due to a SHA1 checksum mismatch when downloading the WordPress archive. This prevented the container from being built.
*   **Solution:**
    1.  **Temporary Workaround:** To isolate the problem and make progress, the checksum verification step in the `srcs/requirements/wordpress/Dockerfile` was temporarily commented out.
    2.  **Underlying Cause:** This issue is often caused by network inconsistencies or changes in the downloaded file that are not reflected in the hardcoded checksum.
    3.  **Recommendation:** Once the stack is stable, a more robust verification method should be implemented, such as downloading the official checksum file from WordPress.org and using that for verification.

## 2. Nginx SSL Configuration Error

*   **Problem:** After the initial build, the `nginx` container was in a restart loop. The logs showed an `invalid command` error related to the `ssl_ciphers` directive in `srcs/requirements/nginx/conf/nginx.conf`.
*   **Solution:** The `ssl_ciphers` value in the Nginx configuration file was enclosed in unnecessary single quotes. Removing the quotes resolved the syntax error and allowed Nginx to start.

## 3. MariaDB Container Restart Loop

*   **Problem:** The `mariadb` container was the most persistent issue, getting stuck in a restart loop. The logs showed an `Access denied for user 'root'@'localhost'` error.
*   **Root Causes:**
    1.  **Incorrect Initialization:** The `init_db.sh` script was attempting to connect to the MariaDB server as the `root` user without a password, but the server required one after its initial startup.
    2.  **Flawed Script Logic:** The script was not idempotent, meaning it would fail on subsequent runs after the database was already initialized. It was also using `--skip-grant-tables` incorrectly, which caused further authentication issues.
*   **Solution:**
    1.  **Robust Initialization Script:** The `init_db.sh` script was completely rewritten to follow best practices.
        *   It now uses `mariadb-install-db` to correctly initialize the database directory *only if it's empty*.
        *   It starts a temporary, secure MariaDB server to run the setup commands.
        *   The SQL commands to create the database and user are now idempotent, preventing errors on subsequent runs.
    2.  **Password Configuration:** The user correctly set the `MYSQL_ROOT_PASSWORD` and `MYSQL_PASSWORD` in the `.env` file, which was the final key to allowing the script to authenticate and run successfully.

## 4. Docker Networking and Container Connections

*   **How it Works:** Docker Compose creates a private network for the services defined in `docker-compose.yml`.
*   **Service Discovery:** Containers on this network can find each other using their service names as hostnames (e.g., `wordpress` can connect to `mariadb` at the hostname `mariadb`).
*   **External Access:** The `nginx` container is the only one exposed to the host machine, mapping port 443 to allow access to the website from a browser.

## 5. WordPress to MariaDB Connection Failure

*   **Problem:** Even with the `mariadb` container running, the `wordpress` container failed to connect to it. The logs showed that the database host `mariadb` was not reachable.
*   **Root Causes & Solutions:** This was a multi-faceted problem requiring several fixes.

    1.  **Database Not Ready (Race Condition):**
        *   **Symptom:** The `wordpress` container started and tried to connect to the database *before* the MariaDB server process within its container was fully initialized and ready to accept connections.
        *   **Initial Solution:** The `configure_wp.sh` script was intended to wait for the database using `nc` (netcat). However, the `netcat` package was not installed in the WordPress container.
        *   **Fix:** The `srcs/requirements/wordpress/Dockerfile` was updated to install the `netcat-openbsd` package.

    2.  **MariaDB Network Binding:**
        *   **Symptom:** Even after adding the wait script, the connection failed. Deeper inspection of the MariaDB container logs revealed it was only listening for connections on `127.0.0.1` (localhost) and not on the Docker network interface.
        *   **Fix:**
            *   A custom configuration file, `srcs/requirements/mariadb/conf/my.cnf`, was created to set `bind-address = 0.0.0.0`, telling MariaDB to listen on all available network interfaces.
            *   The `srcs/requirements/mariadb/Dockerfile` was modified to copy this `my.cnf` file into the container's configuration directory.
            *   As a fallback, a `sed` command was also added to the MariaDB Dockerfile to directly patch the main `50-server.cnf` file, ensuring the `bind-address` was correctly set.

    3.  **Improved Wait Script Logic:**
        *   **Symptom:** The initial database wait script had a fixed number of retries and could time out if the database took longer than expected to start.
        *   **Fix:** The `wait_for_db` function in `srcs/requirements/wordpress/tools/configure_wp.sh` was rewritten to use a `while` loop, ensuring it waits indefinitely until the database port is confirmed to be open before proceeding with the WordPress installation.

## 6. Healthchecks and Service Dependencies

*   **Problem:** The initial `docker-compose.yml` lacked healthchecks and a defined startup order. This meant services could start in the wrong order (e.g., WordPress before MariaDB was healthy), leading to the connection failures described above.
*   **Solution:**
    1.  **MariaDB Healthcheck:** A `HEALTHCHECK` was added to the `srcs/requirements/mariadb/Dockerfile`. It uses `mysqladmin ping` to reliably check if the database server is responsive.
    2.  **WordPress Healthcheck:** A `healthcheck` was added to the `wordpress` service in `docker-compose.yml`. It uses `pgrep php-fpm7.4` to ensure the PHP-FPM process is running, which is a reliable indicator of the service's health.
    3.  **Nginx Healthcheck:** A basic `healthcheck` was added to the `nginx` service in `docker-compose.yml` to ensure the Nginx process is running.
    4.  **Startup Order (`depends_on`):** The `docker-compose.yml` was updated to use `depends_on` with `condition: service_healthy`. This ensures that MariaDB becomes fully healthy before the WordPress service starts, and WordPress is healthy before the Nginx service starts. This eliminates the race conditions and makes the stack startup reliable.

## 7. Handling Secrets for Evaluation

*   **Requirement:** Provide the project's secrets (the contents of the `.env` file) to evaluators securely, without committing them to the Git repository.
*   **Chosen Strategy:** Use a one-time secret sharing service.
*   **Action Plan:**
    1.  The full, working content of the `srcs/.env` file will be pasted into a secure secret sharing tool (e.g., onetimesecret.com).
    2.  Three separate, single-use links will be generated.
    3.  These links will be provided to the evaluators. Each link is destroyed automatically after being viewed once.
*   **Contingency:** This method serves as a convenient way to ensure the evaluator has the exact working configuration. The primary method, documented in the `README.md`, is for the evaluator to create their own `.env` file from the provided `.env.example`.

## Debugging Journey & Key Learnings (June 28, 2025)

Setting up a multi-container Docker environment via Makefiles and Compose files is a meticulous process where small details can lead to cascading failures. The final debugging session to get the stack fully operational was a perfect example of this.

Here's a summary of the issues we resolved and the key takeaways:

1.  **Nginx Restart Loop:**
    *   **Symptom:** `make status` showed Nginx in a `restarting` state.
    *   **Cause:** The Nginx entrypoint script was failing to substitute the `${DOMAIN_NAME}` variable correctly, leading to Nginx trying to load a certificate with a placeholder name (`yourlogin.42.fr.crt`) instead of the actual one.
    *   **Fix:** We corrected the `nginx.conf` to use the `${DOMAIN_NAME}` variable syntax properly and simplified the entrypoint script to perform a more robust substitution.

2.  **WordPress Database Connection Error:**
    *   **Symptom:** After fixing Nginx, the WordPress site loaded but showed "Error establishing a database connection."
    *   **Cause:** The MariaDB logs revealed the root problem: our custom `init_db.sh` script, which creates the WordPress database and user, was never being executed. The container was starting, but the database was empty.

3.  **The Stubborn MariaDB Initialization Failure (The Real Culprit):**
    *   **Attempt 1 (Missing Entrypoint):** We first discovered the `mariadb/Dockerfile` was missing the `ENTRYPOINT ["/usr/local/bin/init_db.sh"]` instruction. We added it.
    *   **Attempt 2 (Stale Volumes):** After adding the entrypoint, the script *still* didn't run. This was because a stale, persistent Docker volume from a previous failed run already existed. The entrypoint script is designed not to run if the database directory isn't empty. The `make fclean` and `docker volume rm srcs_db_data` commands were used to ensure a clean slate.
    *   **Attempt 3 (Ambiguous Image Names):** The final, most subtle issue was that our custom-built image was named `mariadb` in the `docker-compose.yml`. This is the same name as the official Docker Hub image. Docker was likely using a cached, official version of the image instead of our newly built one. Renaming our images to `inception-mariadb`, `inception-wordpress`, and `inception-nginx` in the `docker-compose.yml` file removed this ambiguity and was the final key to solving the problem.

**Final Lesson:** For complex Docker builds, always use **unique, specific image names** and have a **robust cleaning process** (`make fclean`) that removes not just containers but also volumes and images to guarantee a truly fresh start.

After applying these fixes and rebuilding the containers with `make all`, the `wordpress` container was able to successfully connect to the `mariadb` container, resolving the final major setup issue.
