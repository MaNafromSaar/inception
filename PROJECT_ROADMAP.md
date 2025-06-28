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
*   [ ] Does the MariaDB container build and run without errors?
*   [ ] Can you connect to the database from another container (e.g., a temporary admin tool)?
*   [ ] Does the database persist data after a container restart (`docker-compose down` and `docker-compose up`)?

---

## III. Phase 3: WordPress Service

**Goal:** Create a working WordPress container that connects to the MariaDB service.

**Steps:**

1.  **Write `srcs/requirements/wordpress/Dockerfile`:**
    *   Use a stable PHP-FPM base image (e.g., `php:fpm-alpine`).
    *   Install necessary PHP extensions for WordPress (e.g., `mysqli`, `gd`, `curl`).
    *   Install `wp-cli` for command-line management.
    *   Copy configuration scripts from `tools/`.
    *   Set up a user and working directory.
    *   Define `CMD` or `ENTRYPOINT` to start PHP-FPM and run configuration scripts.

2.  **Create Configuration Scripts (`srcs/requirements/wordpress/tools/configure_wp.sh`):**
    *   Script to:
        *   Wait for the MariaDB service to be available.
        *   Download and configure `wp-config.php` using `wp-cli` or `sed` commands, populating it with database details from environment variables.
        *   Handle initial WordPress installation if desired (e.g., `wp core install`).

3.  **Update `srcs/docker-compose.yml` for WordPress:**
    *   `build`: context `./requirements/wordpress`
    *   `container_name`: `wordpress`
    *   `image`: `wordpress`
    *   `env_file`: `./.env`
    *   `volumes`: Define a volume for `/var/www/html` (e.g., `wp_files:/var/www/html`).
    *   `networks`: Connect to the custom Docker network.
    *   `depends_on`: `mariadb`.
    *   `restart: always`.

4.  **Update `srcs/.env`:**
    *   Add WordPress-specific variables if needed (e.g., `WP_ADMIN_USER`, `WP_ADMIN_PASSWORD`).

**Checking Questions & Milestones:**

*   [ ] Does the WordPress container build and run?
*   [ ] Does it successfully connect to the MariaDB container?
*   [ ] Can you access the WordPress installation screen through a browser (via Nginx later)?
*   [ ] Do WordPress files persist after a container restart?

---

## IV. Phase 4: Nginx Service

**Goal:** Set up Nginx as a reverse proxy to serve the WordPress site over HTTPS.

**Steps:**

1.  **Write `srcs/requirements/nginx/Dockerfile`:**
    *   Use a stable Nginx base image (e.g., `nginx:alpine`).
    *   Copy the Nginx configuration file from `conf/`.
    *   Copy SSL certificate and key generation scripts from `tools/`.
    *   Expose port 443.

2.  **Create Nginx Configuration (`srcs/requirements/nginx/conf/nginx.conf`):**
    *   Define a server block for your domain (`${DOMAIN_NAME}`).
    *   Listen on port 443 for SSL.
    *   Configure SSL with your generated certificate and key.
    *   Set up a `location` block to pass PHP requests to the WordPress container (e.g., `fastcgi_pass wordpress:9000`).
    *   Include standard security headers and performance optimizations.

3.  **Create SSL Generation Script (`srcs/requirements/nginx/tools/generate_ssl.sh`):**
    *   Use `openssl` to generate a self-signed SSL certificate and private key.
    *   The script should place the certificate and key in a location that the Nginx configuration expects.

4.  **Update `srcs/docker-compose.yml` for Nginx:**
    *   `build`: context `./requirements/nginx`
    *   `container_name`: `nginx`
    *   `image`: `nginx`
    *   `env_file`: `./.env`
    *   `ports`: Map host port 443 to container port 443 (`443:443`).
    *   `networks`: Connect to the custom Docker network.
    *   `depends_on`: `wordpress`.
    *   `restart: always`.

**Checking Questions & Milestones:**

*   [ ] Does the Nginx container build and run?
*   [ ] Can you access `https://your.domain.name` in a browser and see the WordPress site?
*   [ ] Is the connection secure (using your self-signed certificate)?

---

## V. Phase 5: Finalization & Documentation

**Goal:** Ensure the project is robust, well-documented, and meets all subject requirements.

**Steps:**

1.  **Healthchecks:**
    *   Add `HEALTHCHECK` instructions to the Dockerfiles (e.g., `mysqladmin ping` for MariaDB) or `healthcheck` blocks in `docker-compose.yml`.
    *   Update `depends_on` to use `condition: service_healthy` to ensure proper startup order.

2.  **Makefile Polish:**
    *   Ensure `clean` and `fclean` correctly remove all containers, networks, and volumes.
    *   Add helper targets like `logs`, `status`, etc.

3.  **Documentation:**
    *   Write a comprehensive `README.md` explaining the project, how to set it up, and how to use the `Makefile`.
    *   Ensure all environment variables are documented in a `.env.example` file.

4.  **Security & Evaluation:**
    *   **Requirement:** Plan how to securely transmit secrets (the `.env` file) to evaluators.
    *   **Strategy:** Use a one-time secret sharing service (e.g., onetimesecret.com) to generate single-use links for the `.env` content. This avoids committing secrets to Git while ensuring evaluators have the exact configuration.

5.  **Final Review:**
    *   Read through the project subject (`inceptionsubject.txt`) one last time.
    *   Check all requirements: container names, image names must match service names, use of `restart: always`, volume paths, etc.
    *   Ensure no secrets are hardcoded or committed to Git.

**Checking Questions & Milestones:**

*   [ ] Are all services healthy and starting in the correct order?
*   [ ] Is the `Makefile` complete and working as expected?
*   [ ] Is the `README.md` clear and comprehensive?
*   [ ] Is there a `.env.example` file?
*   [ ] Is the plan for handling secrets during evaluation documented and ready?
*   [ ] Does the project meet every single requirement from the subject PDF?

---

## VI. Bonus Features (Optional)

*   **Redis:** Add a Redis container for caching.
*   **FTP Server:** Add an FTP server container for file transfers.
*   **Adminer/phpMyAdmin:** Add a database administration tool.
*   **Static Website:** Add a container for a simple static website.
*   **Portainer:** Add a container for Docker management.
