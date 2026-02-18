*This project has been created as part of the 42 curriculum by mnaumann.*

# Inception

![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![Nginx](https://img.shields.io/badge/Nginx-009639?style=for-the-badge&logo=nginx&logoColor=white)
![WordPress](https://img.shields.io/badge/WordPress-21759B?style=for-the-badge&logo=wordpress&logoColor=white)
![MariaDB](https://img.shields.io/badge/MariaDB-003545?style=for-the-badge&logo=mariadb&logoColor=white)

## Description

The Inception project is a system administration exercise that demonstrates proficiency in containerization using Docker. It involves setting up a complete web infrastructure with multiple interconnected services, each running in isolated containers orchestrated by Docker Compose.

The project creates a robust, portable, and secure WordPress hosting environment with:
- **NGINX** as a reverse proxy with TLS/SSL encryption
- **WordPress** with PHP-FPM for dynamic content management
- **MariaDB** as the database backend
- **Bonus services**: Redis caching, FTP server, Adminer database management, and a static website

All services are containerized from custom Dockerfiles, emphasizing security best practices, proper service isolation, and data persistence through Docker volumes. The entire stack is designed to run on a virtual machine and meets strict 42 school requirements for network configuration, secret management, and service orchestration.

## Core Stack

*   **Nginx:** Serves as the web server and reverse proxy, handling SSL/TLS termination.
*   **WordPress:** The content management system, running on a PHP-FPM backend.
*   **MariaDB:** Provides the database for WordPress.
*   **Docker & Docker Compose:** For containerization and service orchestration.

## Getting Started

### VM Setup Options

This project provides **multiple ways** to set up your development VM. See [VM_SETUP_GUIDE.md](./VM_SETUP_GUIDE.md) for complete details.

**Quick overview:**
1. **Fully Automated** - Preseed file, zero interaction (~10 min)
2. **Semi-Automated** - Script creates VM, manual Debian install with step-by-step guide (~15 min)
3. **Manual** - Complete control over every step
4. **Pre-built Template** - Import ready-made VM for evaluations (2 min)

**Recommended for first-time setup:** Method 2 (Semi-Automated)

### Quick Start (Assuming VM Ready)

Once you have a Debian VM with Docker installed (using any method above):

1.  **Clone the Repository**
    ```bash
    git clone https://github.com/MaNafromSaar/inception.git
    cd inception
    ```

2.  **Configure Environment**
    ```bash
    # Copy credentials file (provided separately)
    cp /path/to/credentials.txt srcs/.env
    ```
   
3.  **Build and Run**
    ```bash
    make
    ```
   
4.  **Access Services**
    - WordPress: `https://mnaumann.42.fr` (or `https://localhost:8443` if using NAT)
    - Admin panel: `https://mnaumann.42.fr/wp-admin`

For detailed VM setup, see [VM_SETUP_GUIDE.md](./VM_SETUP_GUIDE.md).

---

## Makefile Commands

*   `make` or `make up`: The default command to build and start all services.
*   `make down`: Stops and removes the containers and network.
*   `make clean`: Performs a `down` and also removes the data volumes from the host.
*   `make re`: A convenient shortcut for `make clean` followed by `make`.
*   `make logs`: Tails the logs of all running services.
*   `make status`: Shows the status of the Docker containers.

## Instructions

### Quick Start
1. Ensure you have Docker and Docker Compose installed on your VM
2. Clone this repository
3. Configure your `.env` file in the `srcs/` directory
4. Run `make` from the project root
5. Access the services via the configured domain name

For detailed setup instructions, see [DEV_DOC.md](./DEV_DOC.md).
For user-facing documentation, see [USER_DOC.md](./USER_DOC.md).

## Project Description

### Docker Architecture

This project leverages Docker containerization to create an isolated, reproducible infrastructure. Each service runs in its own container, built from custom Dockerfiles based on either Alpine Linux or Debian (penultimate stable version as per project requirements).

**Key Design Choices:**

1. **Service Isolation**: Each component (NGINX, WordPress, MariaDB, etc.) runs in a dedicated container, following microservices principles
2. **Custom Images**: All Dockerfiles are written from scratch (except base OS images), ensuring full control and understanding of each service
3. **Automated Configuration**: Initialization scripts handle database setup, WordPress installation, and SSL certificate generation
4. **Health Checks**: All services implement health checks to ensure proper startup sequencing and reliability
5. **Data Persistence**: Named volumes ensure data survives container recreation

### Technical Comparisons

#### Virtual Machines vs Docker

**Virtual Machines:**
- Full OS virtualization with hypervisor
- Heavier resource usage (each VM runs complete OS)
- Stronger isolation (hardware-level)
- Slower startup times
- Better for running different OS types

**Docker Containers:**
- OS-level virtualization sharing host kernel
- Lightweight and efficient (shared kernel, isolated processes)
- Fast startup (seconds vs minutes)
- Easier to version and distribute (Dockerfiles, images)
- Better for microservices and DevOps workflows
- **Used in this project** for portability and efficient resource usage

#### Secrets vs Environment Variables

**Environment Variables:**
- Stored in `.env` file
- Passed to containers at runtime
- Visible in container inspection and process lists
- Simpler to implement
- **Used in this project** for non-critical configuration

**Docker Secrets:**
- Encrypted during transit and at rest
- Only available to services that need them
- Not visible in container inspection
- Stored in tmpfs (memory), not disk
- **Recommended for production** (passwords, API keys, certificates)
- Can be implemented in this project by modifying docker-compose.yml

#### Docker Network vs Host Network

**Docker Network (bridge):**
- Isolated network for containers
- Container-to-container communication via service names
- Controllable port mapping to host
- Better security through isolation
- **Used in this project** (custom bridge network)

**Host Network:**
- Container shares host's network stack
- No network isolation
- Better performance (no NAT overhead)
- Less portable and less secure
- **Not used** per project requirements

#### Docker Volumes vs Bind Mounts

**Docker Volumes:**
- Managed by Docker (created, stored, deleted via Docker)
- Stored in Docker-controlled directory (`/var/lib/docker/volumes/`)
- Better performance on Docker Desktop
- Easier to backup and migrate
- **Used in development/testing mode** in this project

**Bind Mounts:**
- Direct mapping to host filesystem path
- Full control over exact location
- Host processes can modify files
- **Used in production mode** (`/home/login/data`) per project requirements
- Configured via `docker-compose.host.yml`

### Sources and Components

The project includes the following source components:
- **Dockerfiles**: Custom container definitions for each service
- **Configuration files**: NGINX conf, MariaDB settings, Redis config, etc.
- **Initialization scripts**: Automated setup for databases and WordPress
- **Docker Compose files**: Service orchestration and networking
- **Makefile**: Build automation and management commands
- **Documentation**: Comprehensive guides for users and developers

## Resources

### Classic References

**Docker Documentation:**
- [Docker Official Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Dockerfile Best Practices](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)

**Service-Specific Documentation:**
- [NGINX Documentation](https://nginx.org/en/docs/)
- [WordPress Codex](https://wordpress.org/documentation/)
- [MariaDB Knowledge Base](https://mariadb.com/kb/en/)
- [Redis Documentation](https://redis.io/documentation)
- [vsftpd Documentation](https://security.appspot.com/vsftpd.html)

**System Administration:**
- [Linux Container Security](https://www.redhat.com/en/topics/security/container-security)
- [Docker Security Best Practices](https://snyk.io/blog/10-docker-image-security-best-practices/)

**Tutorials and Guides:**
- [Docker for Beginners](https://docker-curriculum.com/)
- [WordPress with Docker](https://www.digitalocean.com/community/tutorials/how-to-install-wordpress-with-docker-compose)
- [SSL/TLS Configuration](https://ssl-config.mozilla.org/)

### AI Usage

AI tools (primarily GitHub Copilot and Claude AI) were used throughout this project to enhance productivity and learning:

**Tasks Where AI Was Used:**

1. **Documentation Writing**: AI assisted in creating comprehensive, well-structured documentation (this README, USER_DOC, DEV_DOC)
2. **Script Generation**: Initial drafts of bash scripts for VM setup, container initialization, and configuration
3. **Debugging Assistance**: Troubleshooting Docker networking issues, service health checks, and startup race conditions
4. **Configuration Templates**: Generating baseline NGINX configs, Docker Compose structures
5. **Code Review**: Identifying potential security issues and best practice violations

**Validation Process:**
- All AI-generated code was thoroughly reviewed and tested
- Complex logic was explained to peers for verification
- Critical security components were manually verified against official documentation
- Every script and configuration was tested in multiple scenarios
- The author can explain and justify all implementation decisions

**Parts NOT Generated by AI:**
- Core architecture decisions and design choices
- Custom solutions to project-specific challenges
- Integration logic between services
- Troubleshooting of complex multi-container issues
- Final debugging and optimization

The AI served as a productivity multiplier and learning aid, but all content was validated, understood, and can be defended during evaluation.

## Project Documentation

For additional technical documentation, see:

*   **[USER_DOC.md](./USER_DOC.md)**: User and administrator guide
*   **[DEV_DOC.md](./DEV_DOC.md)**: Developer setup and implementation guide
*   **[VM_SETUP_GUIDE.md](./VM_SETUP_GUIDE.md)**: Virtual machine setup instructions
*   **[documentation/PROJECT_ROADMAP.md](./documentation/PROJECT_ROADMAP.md)**: Development roadmap and project phases
*   **[documentation/project_notes.md](./documentation/project_notes.md)**: Detailed debugging notes and solutions
*   **[documentation/CRITERIA_IMPLEMENTATION.md](./documentation/CRITERIA_IMPLEMENTATION.md)**: Mapping of project requirements to implementation

## License

This is an educational project created for the 42 school curriculum. Use and modification are permitted for learning purposes.
