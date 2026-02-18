# Developer Documentation - Inception Project

This document provides comprehensive technical information for developers working on the Inception infrastructure.

---

## Table of Contents

1. [Environment Setup](#environment-setup)
2. [Project Structure](#project-structure)
3. [Building and Launching](#building-and-launching)
4. [Container Management](#container-management)
5. [Volume Management](#volume-management)
6. [Network Configuration](#network-configuration)
7. [Service Details](#service-details)
8. [Development Workflow](#development-workflow)
9. [Testing and Debugging](#testing-and-debugging)
10. [Security Considerations](#security-considerations)

---

## Environment Setup

### Prerequisites

The following must be installed on your development VM:

- **Operating System**: Debian 11 (Bullseye) or later
- **Docker Engine**: 20.10.0+
- **Docker Compose**: 2.0.0+ (plugin version: `docker compose`)
- **Make**: GNU Make 4.0+
- **Git**: For version control

### Initial VM Setup

#### Option 1: Automated Setup (Recommended)

Use the provided setup script to configure a fresh Debian VM:

```bash
# On the VM, as root user
su -
git clone https://github.com/MaNafromSaar/inception.git
cd inception
chmod +x scripts/setup_vm.sh
./scripts/setup_vm.sh
```

The script will:
- Install `sudo`, `git`, and `build-essential`
- Install Docker Engine and Docker Compose plugin
- Add your user to the `docker` and `sudo` groups
- Configure firewall rules (UFW)

After running the script, **log out and log back in** for group changes to take effect.

#### Option 2: Manual Setup

Follow the detailed instructions in [VM_SETUP_GUIDE.md](./VM_SETUP_GUIDE.md).

### Preparing VM on Host Machine

To download the Debian ISO before VM creation:

```bash
# On your host machine
./scripts/prepare_vm.sh
```

This downloads Debian 11.11.0 (penultimate stable) and verifies checksums.

### Configuration Files

#### Required: `.env` File

Create `srcs/.env` with your configuration:

```bash
# Domain Configuration
DOMAIN_NAME=mnaumann.42.fr

# MariaDB Configuration
MYSQL_ROOT_PASSWORD=your_root_password_here
MYSQL_DATABASE=wordpress
MYSQL_USER=wp_user
MYSQL_PASSWORD=your_db_password_here

# WordPress Admin User
WP_ADMIN_USER=wpadmin
WP_ADMIN_PASSWORD=your_admin_password_here
WP_ADMIN_EMAIL=admin@mnaumann.42.fr

# WordPress Regular User
WP_USER=wpuser
WP_USER_PASSWORD=your_user_password_here
WP_USER_EMAIL=user@mnaumann.42.fr

# WordPress Configuration
WP_TITLE=Inception WordPress
WP_URL=https://mnaumann.42.fr

# FTP Configuration
FTP_USER=ftpuser
FTP_PASSWORD=your_ftp_password_here

# Redis Configuration
REDIS_HOST=redis
REDIS_PORT=6379

# Adminer Configuration (optional)
ADMINER_DESIGN=pepa-linha
```

**Security**: Never commit this file to Git. It's included in `.gitignore`.

#### Docker Compose Files

Two compose files are provided:

1. **`srcs/docker-compose.yml`**: Uses Docker-managed volumes (development)
2. **`srcs/docker-compose.host.yml`**: Uses bind mounts to `/home/mnaumann/data` (production/evaluation)

The Makefile automatically selects the appropriate file.

### Secrets Management

For production deployments, consider using Docker Secrets instead of environment variables:

```yaml
# Example docker-compose.yml snippet
secrets:
  db_root_password:
    file: ./secrets/db_root_password.txt
  db_password:
    file: ./secrets/db_password.txt

services:
  mariadb:
    secrets:
      - db_root_password
      - db_password
```

---

## Project Structure

```
inception/
├── Makefile                      # Build and orchestration commands
├── README.md                     # Project overview and quick start
├── USER_DOC.md                   # User documentation
├── DEV_DOC.md                    # This file (developer documentation)
├── VM_SETUP_GUIDE.md            # Virtual machine setup instructions
│
├── documentation/               # Extended project documentation
│   ├── PROJECT_ROADMAP.md       # Development phases and roadmap
│   ├── project_notes.md         # Debugging notes and solutions
│   ├── CRITERIA_IMPLEMENTATION.md # Requirements mapping
│   ├── bonus_implementation.md  # Bonus features attestation
│   ├── modules.md               # Service explanations
│   └── subject.md               # Original project subject
│
├── scripts/                     # Helper scripts
│   ├── prepare_vm.sh            # Downloads Debian ISO for VM creation
│   └── setup_vm.sh              # Automated VM setup (run as root)
│
├── secrets/                     # Credentials (gitignored)
│   ├── credentials.txt          # Main credentials file
│   └── PASSWORD_HINT.txt        # Password recovery hint
│
├── html/                        # Static website content (bonus)
│   └── index.html               # Static site homepage
│
└── srcs/                        # Main project source
    ├── .env                     # Environment variables (gitignored)
    ├── .env.example             # Template for .env
    ├── docker-compose.yml       # Dev compose file (Docker volumes)
    ├── docker-compose.host.yml  # Production compose file (bind mounts)
    │
    └── requirements/            # Service definitions
        ├── nginx/
        │   ├── Dockerfile       # NGINX container definition
        │   ├── conf/
        │   │   ├── nginx.conf   # Static NGINX config
        │   │   └── nginx.conf.template # Template with env vars
        │   └── tools/
        │       ├── generate_ssl.sh      # SSL certificate generator
        │       └── nginx_entrypoint.sh  # Container startup script
        │
        ├── wordpress/
        │   ├── Dockerfile       # WordPress + PHP-FPM container
        │   └── tools/
        │       ├── configure_wp.sh      # WordPress installation script
        │       ├── custom_entrypoint.sh # Custom entrypoint
        │       └── healthcheck.sh       # Health check script
        │
        ├── mariadb/
        │   ├── Dockerfile       # MariaDB container
        │   ├── conf/
        │   │   └── my.cnf       # MariaDB configuration
        │   └── tools/
        │       ├── init_db.sh   # Database initialization
        │       └── healthcheck.sh
        │
        ├── redis/               # Bonus: Redis cache
        │   ├── Dockerfile
        │   ├── conf/redis.conf
        │   └── tools/
        │       ├── redis_entrypoint.sh
        │       └── healthcheck.sh
        │
        └── ftp/                 # Bonus: FTP server
            ├── Dockerfile
            └── tools/
                └── vsftpd_entrypoint.sh
```

---

## Building and Launching

### Makefile Targets

The Makefile provides several targets for managing the infrastructure:

#### Primary Targets

```bash
make               # Default: builds images and starts all services
make up            # Alias for default target
make down          # Stops and removes containers and networks
make clean         # Down + remove data volumes
make fclean        # Clean + remove Docker images
make re            # Clean + rebuild everything
```

#### Utility Targets

```bash
make status        # Show container status
make logs          # Tail logs from all services
make help          # Display available targets
```

### Build Process

When you run `make`, the following happens:

1. **Prerequisite checks**: Verifies Docker and Docker Compose are installed
2. **Directory creation**: Creates `/home/mnaumann/data/{mariadb,wordpress}` if using host mode
3. **Image building**: Builds Docker images from Dockerfiles
4. **Service startup**: Launches containers with `docker compose up -d`
5. **Health validation**: Waits for services to become healthy

### Manual Build Commands

For finer control, use Docker Compose directly:

```bash
# Build all images
docker compose -f srcs/docker-compose.yml build

# Build specific service
docker compose -f srcs/docker-compose.yml build nginx

# Build without cache (clean rebuild)
docker compose -f srcs/docker-compose.yml build --no-cache

# Start services
docker compose -f srcs/docker-compose.yml up -d

# Stop services
docker compose -f srcs/docker-compose.yml down
```

### Build Arguments and Customization

Some Dockerfiles accept build arguments:

```dockerfile
# Example: WordPress Dockerfile
ARG PHP_VERSION=8.1
ARG DEBIAN_VERSION=bullseye
```

To override during build:

```bash
docker compose -f srcs/docker-compose.yml build \
  --build-arg PHP_VERSION=8.2 wordpress
```

---

## Container Management

### Listing Containers

```bash
# All containers (including stopped)
docker ps -a

# Only running containers
docker ps

# Project containers only
docker compose -f srcs/docker-compose.yml ps
```

### Inspecting Containers

```bash
# Detailed container information
docker inspect <container_name>

# Container logs
docker logs <container_name>
docker logs -f <container_name>  # Follow mode

# Container resource usage
docker stats

# Processes inside container
docker top <container_name>
```

### Executing Commands in Containers

```bash
# Interactive shell
docker compose -f srcs/docker-compose.yml exec <service_name> /bin/bash

# Single command
docker compose -f srcs/docker-compose.yml exec <service_name> <command>

# Examples:
docker compose -f srcs/docker-compose.yml exec mariadb mysql -uroot -p
docker compose -f srcs/docker-compose.yml exec wordpress wp --info
docker compose -f srcs/docker-compose.yml exec nginx nginx -t
```

### Restarting Services

```bash
# Restart all services
docker compose -f srcs/docker-compose.yml restart

# Restart specific service
docker compose -f srcs/docker-compose.yml restart nginx

# Force recreate (rebuild + restart)
docker compose -f srcs/docker-compose.yml up -d --force-recreate nginx
```

---

## Volume Management

### Volume Types

The project uses two volume configurations:

#### Development Mode (Docker Volumes)

Defined in `docker-compose.yml`:

```yaml
volumes:
  mariadb_data:
    driver: local
  wordpress_data:
    driver: local
```

**Location**: `/var/lib/docker/volumes/`

**Pros**: Portable, managed by Docker, better performance on Docker Desktop  
**Cons**: Less control, harder to access from host

#### Production Mode (Bind Mounts)

Defined in `docker-compose.host.yml`:

```yaml
volumes:
  mariadb_data:
    driver: local
    driver_opts:
      type: none
      device: /home/mnaumann/data/mariadb
      o: bind
```

**Location**: `/home/mnaumann/data/`

**Pros**: Full control, easy backup, required by project subject  
**Cons**: Permissions issues, path dependencies

### Volume Commands

```bash
# List volumes
docker volume ls

# Inspect volume
docker volume inspect <volume_name>

# Remove unused volumes
docker volume prune

# Remove specific volume
docker volume rm <volume_name>
```

### Data Persistence

Data persists in:

```bash
/home/mnaumann/data/
├── mariadb/          # Database files (.ibd, .frm, etc.)
│   └── mysql/
│       └── wordpress/
└── wordpress/        # WordPress core files and uploads
    ├── wp-content/
    │   ├── uploads/  # User-uploaded media
    │   ├── themes/
    │   └── plugins/
    └── wp-config.php
```

### Backup and Restore

#### Manual Backup

```bash
# Stop services first
make down

# Create backup
sudo tar -czf inception-backup-$(date +%Y%m%d-%H%M%S).tar.gz \
  /home/mnaumann/data/

# Restart services
make
```

#### Restore from Backup

```bash
make down
sudo rm -rf /home/mnaumann/data/*
sudo tar -xzf inception-backup-TIMESTAMP.tar.gz -C /
sudo chown -R $(whoami):$(whoami) /home/mnaumann/data/
make
```

---

## Network Configuration

### Custom Bridge Network

The project uses a custom Docker bridge network defined in `docker-compose.yml`:

```yaml
networks:
  inception_network:
    driver: bridge
```

**Purpose**: Isolates containers from other Docker networks, enables service name resolution.

### Service Communication

Services communicate via service names (DNS resolution):

- WordPress → MariaDB: `mariadb:3306`
- WordPress → Redis: `redis:6379`
- NGINX → WordPress: `wordpress:9000` (PHP-FPM)

**Example**: WordPress connection in PHP:

```php
define('DB_HOST', 'mariadb:3306');  // Not 'localhost'
```

### Port Mappings

```yaml
services:
  nginx:
    ports:
      - "443:443"     # HTTPS
      - "8081:8081"   # Static site
  
  ftp:
    ports:
      - "21:21"                # FTP control
      - "21100-21110:21100-21110"  # Passive data
```

**Internal ports** (not exposed to host):
- MariaDB: 3306
- Redis: 6379
- WordPress PHP-FPM: 9000

### Network Inspection

```bash
# List networks
docker network ls

# Inspect network
docker network inspect inception_network

# See which containers are connected
docker network inspect inception_network | jq '.[].Containers'
```

---

## Service Details

### NGINX

**Base Image**: `debian:bullseye` or `alpine:3.18`  
**Purpose**: Reverse proxy, SSL/TLS termination, static file serving

**Key Files**:
- `Dockerfile`: Installs NGINX, OpenSSL
- `nginx.conf.template`: Configuration template with env var substitution
- `generate_ssl.sh`: Generates self-signed SSL certificates
- `nginx_entrypoint.sh`: Substitutes env vars and starts NGINX

**Build Process**:
1. Install NGINX and OpenSSL
2. Copy configuration templates
3. Copy entrypoint and SSL generation scripts
4. Expose ports 443 and 8081

**Runtime Process**:
1. Generate SSL certificates if not present
2. Substitute environment variables in config
3. Test configuration (`nginx -t`)
4. Start NGINX in foreground

**Health Check**: HTTP request to localhost

### WordPress

**Base Image**: `debian:bullseye` with PHP-FPM  
**Purpose**: Content Management System

**Key Files**:
- `Dockerfile`: Installs PHP, PHP-FPM, WP-CLI, dependencies
- `configure_wp.sh`: Downloads WordPress, configures database, creates users
- `custom_entrypoint.sh`: Launches config script in background, starts PHP-FPM
- `healthcheck.sh`: Checks PHP-FPM socket

**Build Process**:
1. Install PHP 8.1+ and extensions (mysqli, redis, curl, gd, etc.)
2. Install WP-CLI for automation
3. Create WordPress directory and set permissions
4. Copy configuration scripts

**Runtime Process**:
1. Wait for `wp-load.php` to exist (WordPress core files)
2. Wait for MariaDB to be ready
3. Configure `wp-config.php` with database credentials
4. Install WordPress (if not already installed)
5. Create admin and regular users
6. Install and configure Redis Object Cache plugin
7. Start PHP-FPM in foreground

**Health Check**: PHP-FPM socket availability check

### MariaDB

**Base Image**: `debian:bullseye` or `alpine:3.18`  
**Purpose**: Relational database for WordPress

**Key Files**:
- `Dockerfile`: Installs MariaDB server
- `my.cnf`: MariaDB configuration (bind address, buffer sizes)
- `init_db.sh`: Creates database and users
- `healthcheck.sh`: Verifies MySQL daemon is accepting connections

**Build Process**:
1. Install MariaDB server and client
2. Copy custom configuration
3. Copy initialization scripts

**Runtime Process**:
1. Initialize data directory (first run only)
2. Start MariaDB in safe mode for configuration
3. Create database and users from environment variables
4. Set root password
5. Flush privileges
6. Stop safe mode and start MariaDB daemon

**Health Check**: `mysqladmin ping`

### Redis (Bonus)

**Base Image**: `alpine:3.18`  
**Purpose**: Caching layer for WordPress

**Key Files**:
- `Dockerfile`: Installs Redis
- `redis.conf`: Redis configuration (persistence, max memory, eviction policy)
- `redis_entrypoint.sh`: Starts Redis server
- `healthcheck.sh`: Redis PING command

**Configuration**:
```conf
maxmemory 256mb
maxmemory-policy allkeys-lru
save 900 1
save 300 10
```

**Health Check**: `redis-cli PING`

### FTP Server (Bonus)

**Base Image**: `alpine:3.18`  
**Purpose**: File transfer to WordPress volume

**Key Files**:
- `Dockerfile`: Installs vsftpd
- `vsftpd_entrypoint.sh`: Creates FTP user, configures vsftpd, starts daemon

**Configuration**:
- Passive mode: ports 21100-21110
- chroot jail: /var/www/html
- Write permissions enabled

**Health Check**: Process check for vsftpd

---

## Development Workflow

### Making Changes

1. **Modify source files** (Dockerfiles, configs, scripts)
2. **Rebuild affected service**:
   ```bash
   docker compose -f srcs/docker-compose.yml build <service_name>
   ```
3. **Recreate container**:
   ```bash
   docker compose -f srcs/docker-compose.yml up -d --force-recreate <service_name>
   ```
4. **Test changes**
5. **Commit to Git**

### Adding a New Service

1. Create service directory: `srcs/requirements/<service_name>/`
2. Write `Dockerfile`
3. Add configuration files to `conf/`
4. Add scripts to `tools/`
5. Update `docker-compose.yml`:
   ```yaml
   services:
     new_service:
       build: ./requirements/new_service
       container_name: inception-new_service
       networks:
         - inception_network
       restart: always
   ```
6. Test and document

### Environment Variable Updates

1. Edit `srcs/.env`
2. Restart affected services:
   ```bash
   docker compose -f srcs/docker-compose.yml up -d --force-recreate
   ```

---

## Testing and Debugging

### Service Health Checks

Each service implements a health check:

```yaml
healthcheck:
  test: ["CMD", "<health_check_command>"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 40s
```

Check health status:

```bash
docker ps  # Look for "(healthy)" or "(unhealthy)"
```

### Common Issues and Solutions

#### 1. Container Restart Loop

**Symptoms**: Container continuously restarts

**Debug**:
```bash
docker logs <container_name>
docker compose -f srcs/docker-compose.yml logs <service_name>
```

**Common causes**:
- Entrypoint script error
- Missing dependencies
- Port already in use
- Configuration syntax error

#### 2. Service Dependency Issues

**Symptoms**: WordPress can't connect to MariaDB

**Debug**:
```bash
# Check if MariaDB is healthy
docker ps | grep mariadb

# Test connection from WordPress container
docker compose -f srcs/docker-compose.yml exec wordpress \
  nc -zv mariadb 3306
```

**Solution**: Ensure `depends_on` with `condition: service_healthy` is set

#### 3. Permission Issues

**Symptoms**: "Permission denied" errors in logs

**Debug**:
```bash
# Check file ownership
ls -la /home/mnaumann/data/

# Check container user
docker compose -f srcs/docker-compose.yml exec wordpress whoami
```

**Solution**: Adjust file ownership or Dockerfile USER directive

#### 4. SSL Certificate Issues

**Symptoms**: NGINX fails to start with SSL errors

**Debug**:
```bash
docker compose -f srcs/docker-compose.yml exec nginx nginx -t
```

**Solution**: Regenerate certificates or check file paths

### Performance Profiling

```bash
# Monitor resource usage
docker stats

# Check disk I/O
docker compose -f srcs/docker-compose.yml exec mariadb iostat

# Check WordPress query times
docker compose -f srcs/docker-compose.yml exec wordpress \
  wp db query "SHOW PROCESSLIST;" --allow-root
```

---

## Security Considerations

### Secret Management

**Current Implementation**:
- Secrets in `.env` file (development)
- File excluded from Git via `.gitignore`

**Production Recommendation**:
- Use Docker Secrets
- Encrypt secrets at rest
- Rotate credentials regularly

### Container Security

1. **Non-root users**: Run processes as non-root inside containers where possible
2. **Read-only filesystems**: Mount volumes as read-only when appropriate
3. **Resource limits**: Set memory and CPU limits
4. **Network isolation**: Only expose necessary ports
5. **Image scanning**: Use tools like Trivy or Snyk to scan for vulnerabilities

### SSL/TLS Configuration

**Current**: Self-signed certificates (development)

**Production**:
- Use Let's Encrypt for valid certificates
- Configure strong cipher suites
- Enable HSTS headers
- Implement certificate renewal automation

### Firewall Configuration

On the VM, use UFW:

```bash
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 443/tcp   # HTTPS
sudo ufw allow 8081/tcp  # Static site
sudo ufw allow 21/tcp    # FTP
sudo ufw allow 21100:21110/tcp  # FTP passive
sudo ufw enable
```

---

## Contributing

### Code Style

- **Shell scripts**: Follow Google Shell Style Guide
- **Dockerfiles**: Use official best practices
- **YAML**: 2-space indentation
- **Comments**: Explain complex logic

### Git Workflow

1. Create feature branch: `git checkout -b feature/my-feature`
2. Make changes and test
3. Commit with clear messages: `git commit -m "feat: add Redis cache support"`
4. Push to repository
5. Open pull request (if collaborative)

### Documentation

- Update relevant `.md` files when adding features
- Document environment variables in `.env.example`
- Add debugging notes to `documentation/project_notes.md`

---

## Additional Resources

- [VM_SETUP_GUIDE.md](./VM_SETUP_GUIDE.md): Complete VM setup
- [documentation/PROJECT_ROADMAP.md](./documentation/PROJECT_ROADMAP.md): Project phases
- [documentation/project_notes.md](./documentation/project_notes.md): Debugging journey
- [documentation/CRITERIA_IMPLEMENTATION.md](./documentation/CRITERIA_IMPLEMENTATION.md): Requirements mapping

---

**Last Updated**: February 2026  
**Project**: Inception (42 School)  
**Author**: mnaumann
