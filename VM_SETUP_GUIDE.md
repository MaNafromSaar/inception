# Virtual Machine Setup Guide for Inception Project

This guide covers VM setup for the Inception project. **Automated scripts are provided** for a streamlined experience.

**Recommended**: Use the automated scripts (see [Quick Setup](#quick-automated-setup) below).

---

## Quick Automated Setup

For the fastest setup, use the provided automation scripts on your **host machine**:

### Step 1: Download Debian ISO

```bash
./scripts/prepare_vm.sh
```

This downloads Debian 11.11.0 (Bullseye) netinst ISO and verifies its integrity.

### Step 2: Create the VM

```bash
./scripts/create_inception_vm.sh
```

This creates and configures a VirtualBox VM with optimal settings automatically.

### Step 3: Install Debian

Start the VM (via VirtualBox GUI or `VBoxManage startvm "inception-vm" --type gui`) and follow the Debian installer:

- **Hostname**: `inception`
- **Domain**: (leave blank)
- **Root password**: Set a strong password
- **User account**: Create a non-root user
- **Partitioning**: `Guided - use entire disk`
- **Software**: **DESELECT** desktop environments, **SELECT** `SSH server` and `standard system utilities`
- **GRUB**: Install to `/dev/sda`

### Step 4: Setup Inside VM

After Debian installation, boot into the VM and run (as root):

```bash
su -
apt-get update && apt-get install -y git
git clone https://github.com/MaNafromSaar/inception.git
cd inception
chmod +x scripts/setup_vm.sh
./scripts/setup_vm.sh
```

**Done!** Your VM is ready to run the Inception project.

---

## Manual Setup (Alternative)

If you prefer manual setup or don't have VirtualBox, follow these detailed instructions.

## 1. Prerequisites

*   **VirtualBox** (or VMware, or your preferred hypervisor)
*   **Debian 11 (Bullseye) ISO**: `netinst` image for `amd64`
    *   Download manually or use `scripts/prepare_vm.sh`

## 2. VM Creation (VirtualBox)

## 2. VM Creation (VirtualBox)

**Note**: The `scripts/create_inception_vm.sh` script automates all of this.

### Manual VM Configuration:

1.  **Create a New VM:**
    *   Name: `inception-vm`
    *   Type: `Linux`
    *   Version: `Debian (64-bit)`
2.  **Memory:** 4 GB (4096 MB)
3.  **Hard Disk:**
    *   Create a virtual hard disk (VDI format)
    *   Dynamically allocated
    *   Size: 25 GB
4.  **Settings:**
    *   **System > Processor:** 2 CPUs
    *   **Storage:** Attach the Debian ISO to the optical drive
    *   **Network:** Bridged Adapter (recommended) or NAT with port forwarding

## 3. Debian Installation

Boot the VM from the ISO and follow the installer.

**Key Configuration:**
**Key Configuration:**
- **Hostname:** `inception`
- **Domain name:** (leave blank)
- **Root password:** Set a strong password
- **User account:** Create a non-root user
- **Partitioning:** `Guided - use entire disk`
- **Software Selection:**
  - **RECOMMENDED**: Headless setup - **DESELECT** all desktop environments
  - **SELECT**: `SSH server` and `standard system utilities`
- **GRUB:** Install to `/dev/sda`

**Why headless?** Lighter resources, faster performance, more realistic server environment.

## 4. Post-Installation Setup

**Option A: Automated (Recommended)**

Run the provided setup script as root:

```bash
su -
apt-get update && apt-get install -y git
git clone https://github.com/MaNafromSaar/inception.git
cd inception
./scripts/setup_vm.sh
```

The script installs Docker, adds your user to necessary groups, and configures the firewall.

**Option B: Manual Setup**

1.  **Update the system:**
    ```bash
    sudo sed -i '/^deb cdrom:/s/^/#/' /etc/apt/sources.list
    sudo apt update && sudo apt full-upgrade -y
    ```

2.  **Install Git and build tools** (REQUIRED - not included in base Debian):
    ```bash
    sudo apt install -y git build-essential curl wget ca-certificates
    ```

3.  **Install Docker** (follow official docs or see script for commands)

4.  **Configure firewall, add user to docker group, etc.**

See the automated script for the complete setup sequence.

---

## Network Configuration
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
