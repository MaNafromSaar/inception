# User Documentation - Inception Project

This document provides clear instructions for end users and administrators to operate the Inception infrastructure.

---

## Table of Contents

1. [Services Overview](#services-overview)
2. [Starting and Stopping the Project](#starting-and-stopping-the-project)
3. [Accessing Services](#accessing-services)
4. [Credentials Management](#credentials-management)
5. [Service Health Monitoring](#service-health-monitoring)
6. [Common Tasks](#common-tasks)
7. [Troubleshooting](#troubleshooting)

---

## Services Overview

The Inception project provides the following services:

### Core Services (Mandatory)

| Service | Purpose | Access |
|---------|---------|--------|
| **NGINX** | Web server and reverse proxy with SSL/TLS | Port 443 (HTTPS) |
| **WordPress** | Content Management System (CMS) | Via NGINX at `https://mnaumann.42.fr` |
| **MariaDB** | Database backend for WordPress | Internal only (not exposed) |

### Bonus Services

| Service | Purpose | Access |
|---------|---------|--------|
| **Redis** | Cache server for WordPress performance | Internal only |
| **FTP Server** | File transfer for WordPress files | Port 21 (FTP), Passive ports 21100-21110 |
| **Adminer** | Web-based database management | Via NGINX at `https://adminer.mnaumann.42.fr` |
| **Static Site** | Static HTML showcase website | Port 8081 at `http://static.mnaumann.42.fr:8081` |

**Security Note**: Only NGINX (port 443) and the static site (port 8081) are exposed to the host. All other services communicate via an internal Docker network for enhanced security.

---

## Starting and Stopping the Project

### Prerequisites

- Virtual Machine running Debian 11 (Bullseye)
- Docker and Docker Compose installed
- User added to `docker` group
- Credentials file (`.env`) properly configured

### Starting the Infrastructure

From the project root directory:

```bash
make
```

Or explicitly:

```bash
make up
```

**What happens:**
1. Docker images are built from Dockerfiles
2. Data directories are created on the host (`/home/mnaumann/data/`)
3. All containers are started in the correct order
4. Health checks ensure services are ready

**Expected output:**
```
✓ Building docker images...
✓ Creating data directories...
✓ Starting services...
✓ All services are up and running!
```

**Startup time**: Approximately 30-60 seconds for all services to become healthy.

### Stopping the Infrastructure

To stop all services but keep data:

```bash
make down
```

**What happens:**
- All containers are stopped and removed
- Networks are removed
- Volumes and data persist

### Cleaning Up

To remove everything including data:

```bash
make clean
```

**⚠️ Warning**: This deletes all WordPress content, database entries, and uploaded files!

To rebuild from scratch:

```bash
make re
```

This is equivalent to `make clean` followed by `make`.

---

## Accessing Services

### Configuring DNS

Before accessing services, add these entries to your **host machine's** `/etc/hosts` file:

```bash
<VM_IP_ADDRESS>  mnaumann.42.fr
<VM_IP_ADDRESS>  adminer.mnaumann.42.fr
<VM_IP_ADDRESS>  static.mnaumann.42.fr
```

Replace `<VM_IP_ADDRESS>` with:
- Your VM's IP address (if running in VirtualBox/VMware)
- `127.0.0.1` (if running directly on the host)

To find your VM's IP:
```bash
hostname -I
```

### WordPress Website

**URL**: `https://mnaumann.42.fr`

**Initial Access:**
1. Open your browser and navigate to the URL above
2. Accept the self-signed SSL certificate warning
3. You'll see the WordPress homepage (already configured)

**Admin Panel:**
- URL: `https://mnaumann.42.fr/wp-admin`
- Username: See credentials section below
- Password: See credentials section below

### Adminer (Database Management)

**URL**: `https://adminer.mnaumann.42.fr`

**Login Information:**
- System: `MySQL`
- Server: `mariadb` (service name)
- Username: See credentials section
- Password: See credentials section
- Database: `wordpress`

### Static Website

**URL**: `http://static.mnaumann.42.fr:8081`

This is a simple static HTML site for demonstration purposes.

### FTP Access

**Connection Details:**
- Host: `<VM_IP_ADDRESS>`
- Port: `21`
- Username: `ftpuser`
- Password: See credentials section
- Protocol: FTP (passive mode recommended)

**Using FTP Client (FileZilla example):**
```bash
Host: ftp://<VM_IP_ADDRESS>
Username: ftpuser
Password: <FTP_PASSWORD>
Port: 21
```

**Using Command Line:**
```bash
ftp <VM_IP_ADDRESS>
# Enter username: ftpuser
# Enter password: <FTP_PASSWORD>
```

---

## Credentials Management

### Locating Credentials

All credentials are stored in the `srcs/.env` file. This file is **NOT** committed to version control for security reasons.

**Location**: `srcs/.env`

To view credentials (from project root):

```bash
cat srcs/.env
```

### Key Credentials

The `.env` file contains:

```bash
# Domain Configuration
DOMAIN_NAME=mnaumann.42.fr

# MariaDB Configuration
MYSQL_ROOT_PASSWORD=<root_password>
MYSQL_DATABASE=wordpress
MYSQL_USER=<db_user>
MYSQL_PASSWORD=<db_password>

# WordPress Admin User
WP_ADMIN_USER=<admin_username>
WP_ADMIN_PASSWORD=<admin_password>
WP_ADMIN_EMAIL=<admin_email>

# WordPress Regular User
WP_USER=<regular_username>
WP_USER_PASSWORD=<regular_password>
WP_USER_EMAIL=<user_email>

# FTP Configuration
FTP_USER=ftpuser
FTP_PASSWORD=<ftp_password>

# Redis (optional, auto-configured)
REDIS_HOST=redis
REDIS_PORT=6379
```

### Security Best Practices

1. **Never commit** the `.env` file to Git
2. **Change default passwords** before deployment
3. **Use strong passwords** (12+ characters, mixed case, numbers, symbols)
4. **Share credentials securely** (use encrypted channels or password managers)
5. **Rotate passwords periodically** in production environments

### Changing Credentials

To change passwords:

1. Stop the services: `make down`
2. Edit `srcs/.env` with new credentials
3. Clean old data: `make clean` (⚠️ deletes existing data)
4. Rebuild and start: `make`

**Note**: Changing passwords for an existing installation requires manual database updates or a full rebuild.

---

## Service Health Monitoring

### Checking Service Status

To view the status of all containers:

```bash
make status
```

Or using Docker directly:

```bash
docker compose -f srcs/docker-compose.yml ps
```

**Expected output:**
```
NAME                    STATUS                  PORTS
inception-nginx         Up (healthy)            0.0.0.0:443->443/tcp
inception-wordpress     Up (healthy)            
inception-mariadb       Up (healthy)            
inception-redis         Up (healthy)            
inception-ftp           Up (healthy)            0.0.0.0:21->21/tcp
```

### Service Health States

- **Up (healthy)**: Service is running and passed health checks ✓
- **Up (health: starting)**: Service is starting, health check not yet passed ⏳
- **Up (unhealthy)**: Service is running but health check is failing ⚠️
- **Exited**: Service has stopped or crashed ✗

### Viewing Service Logs

To monitor all service logs in real-time:

```bash
make logs
```

To view logs for a specific service:

```bash
docker compose -f srcs/docker-compose.yml logs -f <service_name>
```

Available service names:
- `nginx`
- `wordpress`
- `mariadb`
- `redis`
- `ftp`

**Example:**
```bash
docker compose -f srcs/docker-compose.yml logs -f wordpress
```

### Health Check Details

Each service has automated health checks:

| Service | Health Check Method | Interval |
|---------|-------------------|----------|
| NGINX | HTTP request to localhost | Every 30s |
| WordPress | PHP-FPM socket check | Every 30s |
| MariaDB | MySQL ping | Every 30s |
| Redis | Redis PING command | Every 30s |
| FTP | Process check | Every 30s |

---

## Common Tasks

### Restarting a Specific Service

```bash
docker compose -f srcs/docker-compose.yml restart <service_name>
```

**Example:**
```bash
docker compose -f srcs/docker-compose.yml restart nginx
```

### Accessing a Container Shell

To troubleshoot or inspect a container:

```bash
docker compose -f srcs/docker-compose.yml exec <service_name> /bin/sh
```

**Example (WordPress container):**
```bash
docker compose -f srcs/docker-compose.yml exec wordpress /bin/bash
```

### Backing Up Data

Data is stored on the host at `/home/mnaumann/data/`:

```bash
# Backup directory structure
/home/mnaumann/data/
├── mariadb/          # Database files
└── wordpress/        # WordPress files and uploads
```

**To create a backup:**
```bash
sudo tar -czf inception-backup-$(date +%Y%m%d).tar.gz /home/mnaumann/data/
```

**To restore a backup:**
```bash
make down
sudo rm -rf /home/mnaumann/data/*
sudo tar -xzf inception-backup-YYYYMMDD.tar.gz -C /
make
```

### Checking Disk Usage

To see how much space the data volumes are using:

```bash
du -sh /home/mnaumann/data/*
```

---

## Troubleshooting

### Services Won't Start

**Check 1: Docker is running**
```bash
systemctl status docker
```

**Check 2: Port conflicts**
```bash
sudo netstat -tulpn | grep -E '(443|21|8081)'
```

**Check 3: Disk space**
```bash
df -h
```

**Solution**: Ensure no other services are using ports 443, 21, or 8081.

### Cannot Access WordPress Site

**Check 1: Services are healthy**
```bash
make status
```

**Check 2: DNS configuration**
```bash
cat /etc/hosts | grep mnaumann.42.fr
```

**Check 3: Firewall rules (on VM)**
```bash
sudo ufw status
```

**Solution**: Ensure ports 443 and 8081 are allowed through the firewall.

### Database Connection Errors

**Check 1: MariaDB is healthy**
```bash
docker compose -f srcs/docker-compose.yml ps mariadb
```

**Check 2: Credentials match**
```bash
cat srcs/.env | grep MYSQL
```

**Solution**: Verify that WordPress credentials match MariaDB user credentials.

### SSL Certificate Warnings

**Cause**: The project uses self-signed SSL certificates.

**Solutions:**
1. Accept the browser warning (for testing)
2. Add the certificate to your system's trusted certificates
3. Use Let's Encrypt for production (requires domain and public IP)

### FTP Connection Refused

**Check 1: FTP service is running**
```bash
docker compose -f srcs/docker-compose.yml ps ftp
```

**Check 2: Passive mode ports**
```bash
sudo ufw status | grep 21100:21110
```

**Solution**: Ensure FTP passive ports (21100-21110) are open in the firewall.

### High Memory Usage

**Check resource usage:**
```bash
docker stats
```

**Solution**: Each container uses memory. For better performance, allocate at least 4GB RAM to the VM.

---

## Support

For technical issues or questions:
1. Check the [troubleshooting](#troubleshooting) section
2. Review [DEV_DOC.md](./DEV_DOC.md) for detailed technical information
3. Consult the [documentation/project_notes.md](./documentation/project_notes.md) for debugging notes

---

**Last Updated**: February 2026  
**Project**: Inception (42 School)  
**Author**: mnaumann
