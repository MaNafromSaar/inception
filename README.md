# Inception Project (42 School)

![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![Nginx](https://img.shields.io/badge/Nginx-009639?style=for-the-badge&logo=nginx&logoColor=white)
![WordPress](https://img.shields.io/badge/WordPress-21759B?style=for-the-badge&logo=wordpress&logoColor=white)
![MariaDB](https://img.shields.io/badge/MariaDB-003545?style=for-the-badge&logo=mariadb&logoColor=white)

A robust and portable Docker-based infrastructure for running a WordPress website. This project uses Docker Compose to orchestrate Nginx, WordPress, and MariaDB containers, fulfilling the requirements of the 42 school's "Inception" project.

The entire stack is designed to be self-contained and easy to deploy on a virtual machine for testing and evaluation.

## Core Stack

*   **Nginx:** Serves as the web server and reverse proxy, handling SSL/TLS termination.
*   **WordPress:** The content management system, running on a PHP-FPM backend.
*   **MariaDB:** Provides the database for WordPress.
*   **Docker & Docker Compose:** For containerization and service orchestration.

## Getting Started

### Prerequisites

*   Docker
*   Docker Compose

### Installation & Usage

1.  **Clone the Repository**
    ```bash
    # If you haven't already, clone the project repository
    git clone https://github.com/MaNafromSaar/inception.git/
    cd inception
    ```

2.  **Configuration**
    -   Navigate to the `srcs/` directory.
    -   Create a `.env` file by copying the example: `cp .env.example .env`
    -   Edit `srcs/.env` to set your `DOMAIN_NAME`, secure database credentials, and unique WordPress salts.
    > **Warning:** The `.env` file contains sensitive information. It is included in `.gitignore` and should never be committed to version control.

3.  **Build and Run**
    From the project's root directory, simply run the main `make` rule:
    ```bash
    make
    ```
    This command will:
    - Check for Docker and Docker Compose.
    - Create the necessary data directories (`/home/yourlogin/data/...`).
    - Build the container images.
    - Launch all services in detached mode.

4.  **Access Your WordPress Site**
    -   On your host machine (not the VM), edit your `/etc/hosts` file to map your domain to the VM's IP address. If running locally, use `127.0.0.1`.
        ```
        127.0.0.1 mnaumann.42.fr
        ```
    -   Open your browser and navigate to `https://mnaumann.42.fr`. You should be greeted by the WordPress installation screen.

## Makefile Commands

*   `make` or `make up`: The default command to build and start all services.
*   `make down`: Stops and removes the containers and network.
*   `make clean`: Performs a `down` and also removes the data volumes from the host.
*   `make re`: A convenient shortcut for `make clean` followed by `make`.
*   `make logs`: Tails the logs of all running services.
*   `make status`: Shows the status of the Docker containers.

## Project Documentation

For a deeper dive into the project's architecture, setup decisions, and development history, please see:

*   **[PROJECT_ROADMAP.md](./PROJECT_ROADMAP.md)**: Outlines the project goals, features, and overall strategy.
*   **[project_notes.md](./project_notes.md)**: Contains detailed notes, troubleshooting steps, and solutions discovered during development.
