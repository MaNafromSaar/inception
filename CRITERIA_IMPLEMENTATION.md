# Inception Project: Criteria Implementation Mapping

This document maps each project requirement to its implementation in the codebase.

---

**1. VM & Docker Compose**
- All orchestration via Docker Compose (`srcs/docker-compose.yml`, `Makefile`).
- Designed for VM deployment (`VM_SETUP_GUIDE.md`).

**2. Image Naming**
- Dockerfiles named after their service (e.g., `nginx`, `wordpress`, `mariadb` in `srcs/requirements/`).
- Service names match image names in Compose files.

**3. Dedicated Containers**
- Each service runs in its own container (`docker-compose.yml`).

**4. Alpine/Debian Base**
- Dockerfiles use Alpine or Debian (`srcs/requirements/*/Dockerfile`).

**5. Custom Dockerfiles**
- All Dockerfiles are written from scratch (no pre-built images except Alpine/Debian).

**6. No DockerHub/Ready-Made Images**
- Only Alpine/Debian images are pulled; all other images built locally (`Makefile`, `docker-compose.yml`).

**7. NGINX with TLSv1.2/1.3**
- NGINX container (`srcs/requirements/nginx/Dockerfile`) with TLS config (`nginx.conf`, `generate_ssl.sh`).

**8. WordPress with php-fpm**
- WordPress container (`srcs/requirements/wordpress/Dockerfile`) installs/configures php-fpm (`configure_wp.sh`).

**9. MariaDB Container**
- MariaDB container (`srcs/requirements/mariadb/Dockerfile`), no nginx present.

**10. Volumes for DB & WP Files**
- Volumes defined in Compose files and handled in host mode via `/home/login/data`.

**11. Docker Network**
- Custom network defined in `docker-compose.yml`.

**12. Auto-Restart**
- `restart: always` set for all services in `docker-compose.yml`.

**13. No hacky patches/infinite loops**
- Entrypoint scripts use proper daemon handling (`nginx_entrypoint.sh`, `custom_entrypoint.sh`).
- No `tail -f`, `sleep infinity`, or infinite loops.

**14. No host network or links**
- `network: host`, `--link`, and `links:` are not used; only custom Docker network.

**15. Proper PID 1 handling**
- Entrypoint scripts and Dockerfiles follow best practices for PID 1.

**16. WP DB Users**
- Two users created in MariaDB init scripts (`init_db.sh`); admin username avoids forbidden patterns.

**17. Host Volumes**
- Host mode volumes mapped to `/home/login/data` (`Makefile`, `docker-compose.host.yml`).

**18. Domain Name**
- Domain set via `.env` and used in NGINX config; instructions in `VM_SETUP_GUIDE.md`.

**19. No latest tag**
- No service uses the `latest` tag in Compose files.

**20. No passwords in Dockerfiles**
- Passwords set via environment variables and `.env` file, not hardcoded.

**21. Use of environment variables**
- All sensitive/config values set via `.env` and passed to containers.

**22. Use of .env and Docker secrets**
- `.env` file used for environment variables; secrets can be added via Docker secrets if needed.

**23. NGINX as sole entry point, port 443, TLSv1.2/1.3**
- Only NGINX exposes port 443; TLS enforced in config.

---

**References in code:**
- `srcs/docker-compose.yml`, `srcs/docker-compose.host.yml`
- `srcs/requirements/*/Dockerfile`
- `srcs/requirements/nginx/conf/nginx.conf`, `generate_ssl.sh`
- `srcs/requirements/wordpress/tools/configure_wp.sh`
- `srcs/requirements/mariadb/tools/init_db.sh`
- `.env`, `.gitignore`
- `Makefile`
- `VM_SETUP_GUIDE.md`
- Entry point scripts in `srcs/requirements/*/tools/`
