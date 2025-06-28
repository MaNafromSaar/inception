# Virtual Machine Setup Guide for Inception Project

This guide provides step-by-step instructions to set up a Debian 11 (Bullseye) Virtual Machine for the Inception project.

## 1. Prerequisites

*   **VirtualBox:** Latest version.
*   **Debian 11 (Bullseye) ISO:** `netinst` image for `amd64`.

## 2. VM Creation (VirtualBox)

1.  **New VM:**
    *   **Name:** `inception-vm`
    *   **Type:** `Linux`
    *   **Version:** `Debian (64-bit)`
2.  **Memory:** At least **2 GB**.
3.  **Hard Disk:**
    *   `Create a virtual hard disk now`
    *   `VDI (VirtualBox Disk Image)`
    *   `Dynamically allocated`
    *   **20-25 GB** size.
4.  **Settings:**
    *   **System > Processor:** **2 CPUs**.
    *   **Storage:** Mount the Debian 11 ISO to the virtual optical drive.
    *   **Network:**
        *   **Adapter 1:** `Bridged Adapter`, attached to your host's active network interface. This gives the VM its own IP address.

## 3. Debian 11 Installation

1.  **Start the VM** and begin the installation from the ISO.
2.  **Follow the installer prompts:**
    *   **Hostname:** `inception`
    *   **Domain name:** (leave blank)
    *   **Set a strong root password.**
    *   **Create a non-root user** for daily use.
    *   **Partitioning:** `Guided - use entire disk`.
    *   **Software Selection:**
        *   **DESELECT** any desktop environment (e.g., GNOME).
        *   **SELECT** `SSH server` and `standard system utilities`.
    *   **GRUB:** Install to the primary drive (e.g., `/dev/sda`).

## 4. Post-Installation Hardening and Setup

1.  **Log in** as your non-root user.
2.  **Update the system:**
    ```bash
    sudo apt update && sudo apt full-upgrade -y && sudo apt autoremove -y
    ```
3.  **Install Essential Packages:**
    ```bash
    sudo apt install -y curl wget git vim ufw docker.io docker-compose
    ```
4.  **Configure Firewall (UFW):**
    ```bash
    # Allow SSH, HTTP, and HTTPS
    sudo ufw allow ssh
    sudo ufw allow http
    sudo ufw allow https
    # Enable the firewall
    sudo ufw enable
    ```
5.  **Add your user to the `docker` group:**
    ```bash
    sudo usermod -aG docker ${USER}
    ```
    **IMPORTANT:** Log out and log back in for this to take effect. Verify with `docker ps`.

## 5. Project Deployment

1.  **Clone the Project:**
    ```bash
    git clone <your_project_repository_url> ~/inception
    cd ~/inception
    ```
2.  **Configure Secrets:**
    *   Your project requires sensitive information (database passwords, API keys, etc.). These are managed in a `.env` file within the `srcs` directory.
    *   **NEVER commit the `.env` file to version control.**
    *   Create the `.env` file by copying the example and then edit it:
        ```bash
        cp srcs/.env.example srcs/.env
        vim srcs/.env
        ```
    *   Fill in all required values with strong, unique credentials.

3.  **Build and Run the Services:**
    *   Use the provided `Makefile` to build and launch all services in the correct order.
    ```bash
    make all
    ```

## 6. Verification and Access

1.  **Check Container Status:**
    *   After running `make all`, verify that all containers are running and healthy.
    ```bash
    docker ps -a
    ```
    *   You should see `nginx`, `wordpress`, and `mariadb` with a status of `Up (healthy)`.

2.  **Access WordPress:**
    *   Find your VM's IP address using `ip a`.
    *   Open a web browser on your host machine and navigate to `https://<VM_IP_ADDRESS>`.
    *   You will see a browser warning for the self-signed SSL certificate. This is expected. Proceed to the site.

## 7. Security Best Practices

*   **Principle of Least Privilege:** The non-root user has `sudo` access but should be used for administrative tasks only when necessary. The Docker containers run with minimal privileges.
*   **Regular Updates:** Periodically run `sudo apt update && sudo apt full-upgrade -y` on the VM to keep the host OS secure. Rebuild your Docker images (`make re`) to incorporate the latest security patches for the base images and packages.
*   **Firewall:** The `ufw` firewall is configured to only allow necessary traffic (SSH, HTTP/S). Keep it enabled.
*   **Strong Credentials:** Use strong, unique passwords and secrets in your `.env` file. Do not use default credentials.

## 8. Troubleshooting

*   **Container not starting/healthy:**
    *   Use `docker logs <container_name>` (e.g., `docker logs wordpress`) to view the output and identify errors.
*   **Network Issues:**
    *   Ensure your VM's network is set to `Bridged Adapter` and that it has an IP address on your local network.
    *   Check `ufw status` to ensure the firewall is not blocking required ports.
*   **Permission Errors:**
    *   Ensure your user is in the `docker` group and that you have logged out/in after adding it.
    *   Check file permissions on the project files if you encounter issues during the build.
