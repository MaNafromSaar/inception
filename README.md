_This project has been created as part of the 42 curriculum by mnaumann_

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

Make sure you have received the credentials for the project. The `.env` file is essential for configuring the services and should not be committed to version control. Ask evaluee in case of any question on how to obtain the credentials.

### Method 1: Automated VM Setup (Recommended)

This project includes a script to automate the entire setup of a fresh Debian VM. This is the fastest and most reliable way to get started.

1.  **On the new VM, log in as `root`** (`su -`).
2.  **Get the setup script onto the VM.** You can either clone the whole repository as root, or just copy the content of `setup_vm.sh` into a new file.
    ```bash
    # Option A: Clone the repo (you might need to install git first: apt-get update && apt-get install git)
    git clone https://github.com/MaNafromSaar/inception.git
    cd inception
    chmod +x setup_vm.sh
    ./setup_vm.sh
    ```
3.  **Follow the script prompts.** It will ask for the regular username to grant `sudo` privileges to.
4.  **Log out from `root` and log back in as your regular user.** The VM is now fully prepared. You can proceed to clone the repo (if you haven't already) and run `make`.

### Method 2: Manual Installation

Follow these steps if you prefer to set up the environment manually.

#### Prerequisites

*   A user with `sudo` privileges.
*   `git`
*   `make` (from the `build-essential` package)
*   Docker
*   Docker Compose

#### Installation & Usage

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
    > **Note:** The `.env.example` file is the only template provided for secrets. The original subject file is not included in this repository.
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
