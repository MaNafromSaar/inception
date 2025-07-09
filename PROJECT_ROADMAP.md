# Inception Project Roadmap

## 0. Project Overview

This project sets up a multi-container Docker application using Docker Compose. Services include Nginx (reverse proxy with TLS), WordPress, MariaDB, Redis, FTP, and Adminer. Each service runs in its own container, built from custom Dockerfiles (Alpine or Debian base). Security, environment variable management, and Docker best practices are emphasized.

<!-- The original subject file is not included in this repository. All requirements are now reflected in the documentation and .env.example. -->

---

## I. Phase 1: Environment Setup & Basic Structure

**Goal:** Prepare the foundational directory structure, configuration files, and ensure the development environment is ready.

**Checklist:**
- [x] Virtual Machine (VM) set up with Docker and Docker Compose
- [x] Complete directory structure created:
    - `Makefile`
    - `srcs/`
    - `srcs/docker-compose.yml`
    - `srcs/.env` (from `.env.example`)
    - `srcs/requirements/` (with subfolders for each service)
- [x] All specified Dockerfiles and tools/scripts created

**Tricky Situation:**
> _Docker Desktop is useful for development, but the final project must run on a VM. This required careful attention to file paths, permissions, and network settings._

---

## II. Phase 2: MariaDB Service

**Goal:** Create a working MariaDB container that initializes a database and users from environment variables.

**Checklist:**
- [x] Write `srcs/requirements/mariadb/Dockerfile` (Alpine/Debian, install MariaDB, copy init scripts)
- [x] Create `init_db.sh` to:
    - Start MariaDB for setup
    - Create database/user from env vars
    - Grant privileges
    - Set root password
    - Be idempotent (safe on restart)
- [x] Update `docker-compose.yml` for MariaDB (build, env_file, volumes, healthcheck)
- [x] Add custom `my.cnf` to bind MariaDB to all interfaces

**Tricky Situation:**
> _MariaDB container was stuck in a restart loop due to incorrect initialization and network binding. Solution: rewrote `init_db.sh` for idempotency and added `bind-address = 0.0.0.0` to `my.cnf`._

---

## III. Phase 3: WordPress Service

**Goal:** Create a WordPress container that connects to MariaDB and is fully automated.

**Checklist:**
- [x] Write `srcs/requirements/wordpress/Dockerfile` (PHP-FPM base, install extensions, wp-cli)
- [x] Create `configure_wp.sh` to:
    - Wait for MariaDB to be ready (with `netcat`)
    - Configure `wp-config.php` from env vars
    - Install WordPress and create admin/user
- [x] Update `docker-compose.yml` for WordPress (build, env_file, volumes, healthcheck, depends_on)

**Tricky Situation:**
> _Race condition: WordPress tried to connect before MariaDB was ready. Solution: improved wait logic in `configure_wp.sh` and added healthchecks with `depends_on: condition: service_healthy`._

---

## IV. Phase 4: Nginx Service

**Goal:** Set up Nginx as a reverse proxy for WordPress, with HTTPS and static site support.

**Checklist:**
- [x] Write `srcs/requirements/nginx/Dockerfile` (Nginx base, copy config, SSL tools)
- [x] Create `nginx.conf` and `nginx.conf.template` (server blocks for WordPress and static site)
- [x] Create `generate_ssl.sh` for self-signed certs
- [x] Update `docker-compose.yml` for Nginx (build, env_file, ports, depends_on)

**Tricky Situation:**
> _Nginx restart loop due to bad variable substitution in config and entrypoint. Solution: fixed variable syntax and simplified entrypoint script._

---

## V. Phase 5: Finalization & Documentation

**Goal:** Ensure the project is robust, well-documented, and meets all requirements.

**Checklist:**
- [x] Add healthchecks to all services
- [x] Polish Makefile (add `logs`, `status`, `clean`, `fclean`)
- [x] Write comprehensive `README.md` and update this roadmap
- [x] Ensure `.env.example` is complete and up to date
- [x] Plan for secure secret sharing (use onetimesecret.com, never commit secrets)
- [x] Remove all legacy/unused files and document the cleanup

**Tricky Situation:**
> _Stale Docker volumes and ambiguous image names caused persistent build/run errors. Solution: always use unique image names and robust `make fclean` to remove all containers, volumes, and images._

---

## VI. Bonus Features (Optional)
- [x] Redis: container for caching
- [x] FTP server: for file transfers
- [x] Adminer: for database management
- [x] Static website: served via Nginx

---

## Key Lessons & Debugging Journey
- Always use unique image names to avoid Docker cache confusion.
- Use healthchecks and `depends_on: condition: service_healthy` for reliable startup order.
- Make all scripts idempotent and robust against restarts.
- Clean up all legacy files and document your process for clarity.
- Document every tricky situation and how it was resolved—future you (and others) will thank you! (see `project_notes.md` for details).