# Inception Project Roadmap

## 0. Project Overview

This project involves setting up a multi-container Docker application using Docker Compose. The services include Nginx (as a reverse proxy with TLS), WordPress, and MariaDB. Each service must run in its own container, built from custom Dockerfiles using Alpine or Debian base images. Specific attention must be paid to security, environment variable management, and Docker best practices.

**Key Document:** `inceptionsubject.txt`

## I. Phase 1: Environment Setup & Basic Structure

**Goal:** Prepare the foundational directory structure, configuration files, and ensure the development environment is ready.

**Steps:**

1.  **Virtual Machine (VM) Setup (User Task):**
    *   **Requirement:** The project must be completed on a Virtual Machine.
    *   Ensure Docker and Docker Compose are installed on your VM.
    *   **Note:** While Docker Desktop is useful, the final project submission requires it to run on a VM.

2.  **Project Directory Structure:**
    *   Create the root project directory (e.g., `inception`).
    *   Inside the root, create:
        *   `Makefile`
        *   `srcs/`
        *   `srcs/docker-compose.yml`
        *   `srcs/.env`
        *   `srcs/requirements/`
        *   `srcs/requirements/mariadb/`
        *   `srcs/requirements/mariadb/Dockerfile`
        *   `srcs/requirements/mariadb/tools/`
        *   `srcs/requirements/wordpress/`
        *   `srcs/requirements/wordpress/Dockerfile`
        *   `srcs/requirements/wordpress/tools/`
        *   `srcs/requirements/nginx/`
        *   `srcs/requirements/nginx/Dockerfile`
        *   `srcs/requirements/nginx/conf/`
        *   `secrets/` (For storing sensitive data if using Docker secrets or other secure methods. The subject mentions `.env` for variables and implies other files for credentials to be gitignored).

3.  **Initial `Makefile`:**
    *   Define basic targets like `all`, `clean`, `fclean`, `re`.

4.  **Initial `srcs/docker-compose.yml`:**
    *   Define the version.
    *   Define the main services: `nginx`, `wordpress`, `mariadb`.
    *   Define the network.
    *   Define the volumes.

5.  **Initial `srcs/.env`:**
    *   Define placeholders for required environment variables (e.g., `DOMAIN_NAME`, database credentials).

**Checking Questions & Milestones:**

*   [ ] Is your Virtual Machine set up with Docker and Docker Compose?
*   [ ] Is the complete directory structure created as listed above?
*   [ ] Does `Makefile` exist?
*   [ ] Does `srcs/docker-compose.yml` exist?
*   [ ] Does `srcs/.env` exist with placeholder variables?
*   [ ] Are all specified `Dockerfile` paths created (empty files for now)?

---

## II. Phase 2: MariaDB Service

**Goal:** Create a working MariaDB container that initializes a database and users based on environment variables.

**Steps:**

1.  **Write `srcs/requirements/mariadb/Dockerfile`:**
    *   Use penultimate stable Alpine or Debian.
    *   Install MariaDB server.
    *   Copy entrypoint/initialization scripts from `tools/`.
    *   Set up a user, expose port 3306 (though it won\'t be exposed to host).
    *   Define `CMD` or `ENTRYPOINT` to start MariaDB and run init scripts.

2.  **Create Initialization Scripts (`srcs/requirements/mariadb/tools/init_db.sh` or similar):**
    *   Script to:
        *   Start MariaDB temporarily if needed for setup.
        *   Create the database (e.g., `${MYSQL_DATABASE}`).
        *   Create a user (e.g., `${MYSQL_USER}`) with password (`${MYSQL_PASSWORD}`).
        *   Grant privileges to the user on the database.
        *   Set/change root password (`${MYSQL_ROOT_PASSWORD}`).
        *   Ensure it handles existing setup gracefully if the container restarts.

3.  **Update `srcs/docker-compose.yml` for MariaDB:**
    *   `build`: context `./requirements/mariadb`
    *   `container_name`: `mariadb` (or your chosen name, must match service name)
    *   `image`: `mariadb` (must match service name)
    *   `env_file`: `./.env`
    *   `volumes`: Define a volume for `/var/lib/mysql` (e.g., `db_data:/var/lib/mysql`).
    *   `networks`: Connect to the custom Docker network.
    *   `restart: always` (or `unless-stopped`).

4.  **Update `srcs/.env`:**
    *   Fill in actual values for:
        *   `MYSQL_DATABASE`
        *   `MYSQL_USER`
        *   `MYSQL_PASSWORD`
        *   `MYSQL_ROOT_PASSWORD`

5.  **Update `Makefile`:**
    *   Add commands to build and run only the MariaDB service for testing.
    *   Target in `Makefile`: `docker-compose -f srcs/docker-compose.yml up --build -d mariadb`

**Connecting & Testing MariaDB:**

*   **Build & Run:** Use `make` target or `docker-compose up --build -d mariadb`.
*   **Check Container:** `docker ps` (is `mariadb` running?).
*   **Check Logs:** `docker logs mariadb` (look for MariaDB startup messages, errors, script execution).
*   **Verify Data Persistence:** Stop and start the container. Data should persist.
*   **Connect (for testing, from another container or host if port mapped temporarily):**
    *   `docker exec -it mariadb mysql -u${MYSQL_USER} -p${MYSQL_PASSWORD} ${MYSQL_DATABASE}`
    *   Check if database and user exist.
*   **Check Volumes:** Inspect the volume location on the host (VM): `/home/yourlogin/data/db_data` (or similar, based on your volume definition in `docker-compose.yml` and the project requirement for `/home/login/data`).

**Checking Questions & Milestones:**

*   [ ] Is the MariaDB Dockerfile complete and building successfully?
*   [ ] Does the initialization script correctly set up the database and users using environment variables?
*   [ ] Is the MariaDB service correctly defined in `docker-compose.yml`?
*   [ ] Are environment variables for MariaDB set in `.env`?
*   [ ] Can the MariaDB container start without errors?
*   [ ] Is data persisting in the volume after container restarts?
*   [ ] Can you successfully connect to the database with the created user?

---

## III. Phase 3: WordPress Service

**Goal:** Create a working WordPress container that connects to MariaDB and serves WordPress files via php-fpm.

**Steps:**

1.  **Write `srcs/requirements/wordpress/Dockerfile`:**
    *   Use penultimate stable Alpine or Debian.
    *   Install PHP, php-fpm, and required PHP extensions for WordPress (e.g., `mysqli`, `gd`, `curl`).
    *   Download WordPress (specific version, not latest) using `curl` or `wget` and extract it.
    *   Copy WordPress files to the appropriate location (e.g., `/var/www/html`).
    *   Configure php-fpm to listen on a port (e.g., 9000).
    *   Copy entrypoint/configuration scripts from `tools/`.
    *   Set correct permissions for WordPress files.

2.  **Create Configuration Scripts (`srcs/requirements/wordpress/tools/configure_wp.sh` or similar):**
    *   Script to:
        *   Wait for MariaDB to be available (e.g., using `nc` or a custom script).
        *   Create `wp-config.php` from `wp-config-sample.php` or use `wp-cli`.
        *   Populate `wp-config.php` with database details from environment variables (`DB_NAME`, `DB_USER`, `DB_PASSWORD`, `DB_HOST`).
        *   Set WordPress salts (can be generated or static, but should be from env vars or secrets).
        *   `ENTRYPOINT` or `CMD` should start php-fpm in the foreground.

3.  **Update `srcs/docker-compose.yml` for WordPress:**
    *   `build`: context `./requirements/wordpress`
    *   `container_name`: `wordpress`
    *   `image`: `wordpress`
    *   `env_file`: `./.env`
    *   `depends_on`: `mariadb`
    *   `volumes`: Define a volume for WordPress files (`/var/www/html`) (e.g., `wp_files:/var/www/html`).
    *   `networks`: Connect to the custom Docker network.
    *   `restart: always`.

4.  **Update `srcs/.env`:**
    *   Add/verify WordPress related variables if any (e.g., `WP_DB_HOST=mariadb`).
    *   `DB_NAME` should be `${MYSQL_DATABASE}`.
    *   `DB_USER` should be `${MYSQL_USER}`.
    *   `DB_PASSWORD` should be `${MYSQL_PASSWORD}`.

5.  **Update `Makefile`:**
    *   Ensure `all` target builds WordPress.

**Connecting & Testing WordPress:**

*   **Build & Run:** `docker-compose -f srcs/docker-compose.yml up --build -d wordpress` (will also start MariaDB).
*   **Check Containers:** `docker ps` (are `wordpress` and `mariadb` running?).
*   **Check WordPress Logs:** `docker logs wordpress` (look for php-fpm startup, connection to DB, any errors).
*   **Check MariaDB Logs:** `docker logs mariadb` (see if WordPress is making connections).
*   **Verify `wp-config.php`:** `docker exec -it wordpress cat /var/www/html/wp-config.php` (check if DB details are correct).
*   **Check php-fpm:** `docker exec -it wordpress ps aux | grep php-fpm` (is it running?).

**Checking Questions & Milestones:**

*   [ ] Is the WordPress Dockerfile complete and building successfully?
*   [ ] Does the configuration script correctly set up `wp-config.php` and wait for MariaDB?
*   [ ] Is the WordPress service correctly defined in `docker-compose.yml` with dependency on MariaDB?
*   [ ] Can the WordPress container start without errors?
*   [ ] Does WordPress successfully connect to the MariaDB container? (Check logs).
*   [ ] Are WordPress files persisting in the volume?

---

## IV. Phase 4: Nginx Service

**Goal:** Set up Nginx as a reverse proxy to serve WordPress over HTTPS (TLSv1.2/1.3 only) on your custom domain.

**Steps:**

1.  **Write `srcs/requirements/nginx/Dockerfile`:**
    *   Use penultimate stable Alpine or Debian.
    *   Install Nginx.
    *   Remove default Nginx configuration.
    *   Copy your custom Nginx configuration from `conf/`.
    *   Copy SSL certificate and key into the image (generate these next).
    *   Expose port 443.
    *   `CMD` to start Nginx in the foreground (`nginx -g \'daemon off;\'`).

2.  **Generate SSL Certificate:**
    *   Create self-signed SSL certificate and private key for `yourlogin.42.fr`.
    *   Use OpenSSL. Store these in a secure location (e.g., `secrets/` or `srcs/requirements/nginx/conf/ssl/`) and ensure they are copied into the Nginx image.
    *   **Example (OpenSSL):**
        ```bash
        # In your VM or a temp location
        openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout yourlogin.42.fr.key -out yourlogin.42.fr.crt \
        -subj "/C=FR/ST=Paris/L=Paris/O=42/OU=student/CN=yourlogin.42.fr"
        ```
    *   Place these files where the Nginx Dockerfile can copy them.

3.  **Create Nginx Configuration (`srcs/requirements/nginx/conf/nginx.conf` or `default.conf`):**
    *   Listen on port 443 ssl.
    *   Specify `ssl_certificate` and `ssl_certificate_key` paths (inside the container).
    *   Configure `ssl_protocols TLSv1.2 TLSv1.3;`.
    *   Configure `ssl_ciphers` (use strong ciphers).
    *   Server name: `yourlogin.42.fr`.
    *   Location block `/` to proxy requests to WordPress:
        *   `proxy_pass http://wordpress:9000;` (or the port php-fpm is listening on in the WordPress container).
        *   Set necessary proxy headers (`Host`, `X-Real-IP`, `X-Forwarded-For`, `X-Forwarded-Proto`).
    *   Handle static files if needed (though WordPress usually handles its own).

4.  **Update `srcs/docker-compose.yml` for Nginx:**
    *   `build`: context `./requirements/nginx`
    *   `container_name`: `nginx`
    *   `image`: `nginx`
    *   `env_file`: `./.env` (if `DOMAIN_NAME` is used in Nginx conf via envsubst, or for cert generation)
    *   `depends_on`: `wordpress`
    *   `ports`: `443:443`
    *   `networks`: Connect to the custom Docker network.
    *   `restart: always`.

5.  **Update `srcs/.env`:**
    *   `DOMAIN_NAME=yourlogin.42.fr` (replace `yourlogin`).

6.  **Update `Makefile`:**
    *   Ensure `all` target builds Nginx.

**Connecting & Testing Nginx:**

*   **Build & Run All:** `make all` or `docker-compose -f srcs/docker-compose.yml up --build -d`.
*   **Check Containers:** `docker ps` (are `nginx`, `wordpress`, `mariadb` running?).
*   **Check Nginx Logs:** `docker logs nginx` (look for startup, SSL errors, request logs).
*   **Domain Setup (Host VM):** Edit `/etc/hosts` on your VM: `127.0.0.1 yourlogin.42.fr`.
*   **Access in Browser:** Open `https://yourlogin.42.fr`.
    *   Accept self-signed certificate warning.
    *   You should see the WordPress setup page or your site.
*   **Check TLS Version:** Use browser developer tools (Security tab) or `openssl s_client -connect yourlogin.42.fr:443 -tls1_2` (and for 1.3).

**Checking Questions & Milestones:**

*   [ ] Is the Nginx Dockerfile complete and building successfully?
*   [ ] Are SSL certificate and key generated and correctly copied/used by Nginx?
*   [ ] Is the Nginx configuration correctly proxying to WordPress and enforcing TLSv1.2/1.3?
*   [ ] Is the Nginx service defined in `docker-compose.yml` with port mapping and dependency?
*   [ ] Is `DOMAIN_NAME` set in `.env` and `/etc/hosts` configured on the VM?
*   [ ] Can you access the WordPress site via `https://yourlogin.42.fr`?
*   [ ] Is TLSv1.2 or TLSv1.3 being used?

---

## V. Phase 5: Integration, Domain, Security & Final Checks

**Goal:** Ensure all components work together seamlessly, meet all project requirements, and security best practices are followed.

**Steps:**

1.  **Complete `Makefile`:**
    *   `all`: `docker-compose -f srcs/docker-compose.yml up --build -d`
    *   `down`: `docker-compose -f srcs/docker-compose.yml down`
    *   `clean`: `docker-compose -f srcs/docker-compose.yml down -v --rmi local --remove-orphans` (removes volumes, images built locally for the project)
    *   `fclean`: `$(MAKE) clean && docker system prune -af --volumes && docker network rm $(shell docker network ls -q -f name=YOUR_NETWORK_NAME)` (more aggressive, be careful. Get network name from `docker-compose.yml`).
    *   `re`: `$(MAKE) fclean && $(MAKE) all`

2.  **WordPress Installation & User Setup:**
    *   Complete the WordPress installation via the browser at `https://yourlogin.42.fr`.
    *   Create two users in WordPress: one administrator (username must NOT be admin, Admin, administrator, etc.) and one regular user.

3.  **Volume Mapping Verification:**
    *   Ensure WordPress database volume (`db_data`) and WordPress website files volume (`wp_files`) are correctly mapped to `/home/yourlogin/data/` on the host VM.
    *   **In `docker-compose.yml`:**
        ```yaml
        volumes:
          db_data:
            driver_opts:
              type: none
              o: bind
              device: /home/YOUR_LOGIN/data/mariadb # Or whatever you name the subfolder
          wp_files:
            driver_opts:
              type: none
              o: bind
              device: /home/YOUR_LOGIN/data/wordpress # Or whatever you name the subfolder
        ```
    *   **Important:** Replace `YOUR_LOGIN` with your actual login. Create these directories on your VM first (`mkdir -p /home/YOUR_LOGIN/data/mariadb /home/YOUR_LOGIN/data/wordpress`).

4.  **Security & Best Practices Review:**
    *   **No Passwords in Dockerfiles:** Double-check.
    *   **Environment Variables:** All sensitive data (passwords, API keys, domain names) from `.env`.
    *   **Docker Secrets (Recommended):** If implemented, verify.
    *   **PID 1 & Daemons:** Ensure services run correctly as main process. No `tail -f /dev/null` or `sleep infinity`.
    *   **Restart Policy:** `restart: always` or `unless-stopped` for all services.
    *   **Network:** Custom network used. No `network: host` or `links:`.
    *   **Image Tags:** No `latest` tag for base images. Use specific penultimate stable versions.
    *   **Container Names:** Match service names.
    *   **.gitignore:** Ensure `srcs/.env`, `secrets/` (if containing actual secrets), and host volume data paths are gitignored.

**Final Checking Questions & Milestones:**

*   [ ] Is the `Makefile` complete with all required targets?
*   [ ] Can you successfully install WordPress and create the required users?
*   [ ] Are volumes correctly mapped to `/home/yourlogin/data/...` on the VM and persisting data?
*   [ ] Are all security requirements from `inceptionsubject.txt` met?
    *   [ ] Nginx is sole entry point on port 443.
    *   [ ] TLSv1.2/TLSv1.3 only.
    *   [ ] Passwords not in Dockerfiles.
    *   [ ] Environment variables used for configuration.
*   [ ] Do containers restart automatically on crash?
*   [ ] Are all Dockerfile best practices followed (PID 1, no hacky loops)?
*   [ ] Is the entire application stack stable and functional?

---

## VI. Phase 6: Bonus Part (Optional)

**Goal:** Implement additional services as per the bonus list, each in its own Docker container with its own Dockerfile.

*   **Redis Cache for WordPress:**
    *   Dockerfile for Redis.
    *   Configure WordPress (plugin like "Redis Object Cache") to use it.
    *   Add to `docker-compose.yml`.
*   **FTP Server:**
    *   Dockerfile for FTP server (e.g., vsftpd).
    *   Point to WordPress files volume.
    *   Add to `docker-compose.yml`.
*   **Simple Static Website (Not PHP):**
    *   Create site (HTML, CSS, JS).
    *   Dockerfile for a web server (e.g., another Nginx, Caddy) to serve it.
    *   Configure main Nginx to route to it (e.g., on a subpath or different port if allowed for bonus).
    *   Add to `docker-compose.yml`.
*   **Adminer:**
    *   Dockerfile for Adminer.
    *   Configure to connect to MariaDB.
    *   Add to `docker-compose.yml`.
*   **Service of Choice:**
    *   Implement and justify.

**Checking Questions for Bonus:**
*   [ ] Is each bonus service in its own container with its own Dockerfile?
*   [ ] Does each bonus service function correctly?
*   [ ] Is the mandatory part still perfect?

---
This roadmap provides a detailed plan. We will tackle each phase step-by-step.
Remember to replace `yourlogin` or `YOUR_LOGIN` with your actual 42 login throughout the project.
