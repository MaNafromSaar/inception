# Virtual Machine Setup Guide for Inception Project

This guide provides step-by-step instructions to set up a Debian 11 (Bullseye) Virtual Machine for the Inception project. It covers both GUI and headless (server-only) setups, networking, and firewall configuration.

## 1. Prerequisites

*   **VirtualBox** (or VMware, or your preferred hypervisor)
*   **Debian 11 (Bullseye) ISO:** Use the `netinst` image for `amd64`.

## 2. VM Creation (VirtualBox Example)

1.  **Create a New VM:**
    *   **Name:** `inception-vm`
    *   **Type:** `Linux`
    *   **Version:** `Debian (64-bit)`
2.  **Memory:** At least **2 GB** (4 GB recommended for GUI).
3.  **Hard Disk:**
    *   `Create a virtual hard disk now`
    *   `VDI (VirtualBox Disk Image)`
    *   `Dynamically allocated`
    *   **20-25 GB** size.
4.  **Settings:**
    *   **System > Processor:** **2 CPUs** (or more).
    *   **Storage:** Mount the Debian 11 ISO to the virtual optical drive.
    *   **Network:**
        *   **Adapter 1:** `Bridged Adapter` (recommended for easy host access), or `NAT` with port forwarding.

## 3. Debian 11 Installation

1.  **Start the VM** and begin the installation from the ISO.
2.  **Follow the installer prompts:**
    *   **Hostname:** `inception`
    *   **Domain name:** (leave blank)
    *   **Set a strong root password.**
    *   **Create a non-root user** for daily use (remember the username and password).
    *   **Partitioning:** `Guided - use entire disk`.
    *   **Software Selection:**
        *   For GUI: Select `XFCE` or `GNOME` desktop environment, `SSH server`, and `standard system utilities`.
        *   For headless: **DESELECT** desktop environment, **SELECT** `SSH server` and `standard system utilities`.
    *   **GRUB:** Install to the primary drive (e.g., `/dev/sda`).

## 4. Post-Installation Hardening and Setup

1.  **Log in** as your non-root user or root.
2.  **Update the system:**
    ```bash
    # IMPORTANT: Remove the CD-ROM source from APT to avoid install errors
    sudo sed -i '/^deb cdrom:/s/^/#/' /etc/apt/sources.list
    sudo apt update && sudo apt full-upgrade -y && sudo apt autoremove -y
    ```
3.  **Install Essential Packages:**
    ```bash
    sudo apt install -y curl wget git vim ca-certificates build-essential cmake
    ```
    (If using the setup script, this will be handled automatically.)
4.  **Install Docker and Docker Compose (Official Repository):**
    > **Tip:** If you are using a desktop environment (GNOME/XFCE), you may find it easier to visit the official Docker website in your browser and follow the latest instructions for Debian: [https://docs.docker.com/engine/install/debian/](https://docs.docker.com/engine/install/debian/)
    >
    > This ensures you always get the most up-to-date and accurate steps for your system, with troubleshooting tips and copy-paste commands.
    
    ```bash
    sudo apt install -y ca-certificates curl gnupg
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
      $(. /etc/os-release && echo \"$VERSION_CODENAME\") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    ```
    Test with:
    ```bash
    docker compose version
    ```
    
    > **Note:** If your Makefile or scripts use `docker-compose` (with a hyphen) but only `docker compose` (with a space) is available, you can add a compatibility alias:
    >
    > ```bash
    > echo 'alias docker-compose="docker compose"' >> ~/.bashrc
    > source ~/.bashrc
    > ```
    >
    > This will allow `docker-compose` commands to work as expected.
5.  **Configure Firewall (UFW):**
    ```bash
    sudo apt install -y ufw
    sudo ufw allow ssh
    sudo ufw allow http
    sudo ufw allow https
    sudo ufw allow 8081
    sudo ufw enable
    ```
6.  **Add your user to the `docker` group:**
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
    *   the real .env will be made available via a 1-time secure link.
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
    *   You should see `nginx`, `wordpress`, `mariadb`, etc. with a status of `Up (healthy)`.

2.  **Access WordPress and Static Site:**
    *   From your host, open a browser and go to `https://<VM_IP>` or your configured domain.
    *   If using NAT, set up port forwarding for 80/443/8081.
    *   Accept the self-signed certificate warning.

## 7. Security Best Practices

*   **Principle of Least Privilege:** Use your non-root user for daily tasks. Only use root when necessary.
*   **Regular Updates:** Periodically run `sudo apt update && sudo apt full-upgrade -y` on the VM. Rebuild Docker images (`make re`) to get the latest patches.
*   **Firewall:** UFW is configured to only allow necessary traffic (SSH, HTTP/S, 8081). Keep it enabled.
*   **Strong Credentials:** Use strong, unique passwords and secrets in your `.env` file. Never use defaults.

## 8. Troubleshooting

*   **Container not starting/healthy:**
    *   Use `docker logs <container_name>` to view errors.
*   **Network Issues:**
    *   Ensure your VM's network is set to `Bridged Adapter` and that it has an IP address on your local network.
    *   Check `ufw status` to ensure the firewall is not blocking required ports.
*   **Permission Errors:**
    *   Ensure your user is in the `docker` group and has logged out/in after being added.
    *   Check file permissions on the project files if you encounter build issues.

---

> **Note:** The project no longer includes the original subject file. All required secrets and credentials are managed via the `.env.example` template in `srcs/`. Copy this to `.env` and fill in your own values.
