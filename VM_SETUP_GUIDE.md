# Virtual Machine Setup Guide for Inception Project

This guide provides **three methods** to set up your VM, from fully automated to detailed manual steps.

**Choose your approach:**
- 🚀 [Method 1: Fully Automated (Preseed)](#method-1-fully-automated-preseed) - Zero interaction, fastest
- ⚡ [Method 2: Semi-Automated](#method-2-semi-automated-recommended) - Script creates VM, manual Debian install
- 🔧 [Method 3: Completely Manual](#method-3-completely-manual) - Full control, step-by-step
- 📦 [Method 4: Pre-built Template](#method-4-pre-built-vm-template-for-evaluations) - For evaluations/testing

---

## Method 1: Fully Automated (Preseed)

**Zero-interaction installation using Debian preseed automation.**

### Step 1: Download ISO
```bash
./scripts/prepare_vm.sh
```

### Step 2: Create VM with Preseed
```bash
./scripts/create_vm_preseed.sh
```

### Step 3: Boot and Auto-Install
The VM will boot automatically. Debian installation proceeds without any prompts.

**Default credentials** (change after first login):
- User: `inception` / Password: `inception123`
- Root: `root` / Password: `temproot123`

### Step 4: Run Setup Script
After installation and reboot, login and run:
```bash
su -
cd /home/inception
git clone https://github.com/MaNafromSaar/inception.git
cd inception
./scripts/setup_vm.sh
```

**Total time**: ~10 minutes (unattended)

---

## Method 2: Semi-Automated (Recommended)

**Script creates the VM, you complete Debian installation manually with detailed guidance.**

### Step 1: Download Debian ISO

```bash
./scripts/prepare_vm.sh
```

### Step 2: Create the VM

```bash
./scripts/create_inception_vm.sh
```

This creates a VirtualBox VM with optimal settings (4GB RAM, 2 CPUs, 25GB disk, NAT network).

### Step 3: Install Debian (Manual with Detailed Steps)

Start the VM:
```bash
VBoxManage startvm "inception-vm" --type gui
```

**Debian Installer - Every Step:**

#### Boot Screen
- Select: **Install** (not Graphical Install)
- Press Enter

#### 1. Select a Language
- Choose: **English**
- Press Enter

#### 2. Select Your Location
- Choose: **United States** (or your location)
- Press Enter

#### 3. Configure the Keyboard
- Choose: **American English**
- Press Enter

#### 4. Configure the Network
- **Hostname**: Type `inception` and press Enter
- **Domain name**: Leave **blank** (just press Enter)
  - ⚠️ **Important**: Domain blank! Project domain (`mnaumann.42.fr`) is set later in `.env`

#### 5. Set Up Users and Passwords
- **Root password**: Enter a strong password (e.g., `Inception42!`)
- **Re-enter root password**: Same password
- **Full name for new user**: Type your name (e.g., `Inception User`)
- **Username**: Type `inception` (or your preferred username)
- **Password for new user**: Enter a password (e.g., `inception123`)
- **Re-enter password**: Same password

#### 6. Configure the Clock
- **Time zone**: Choose your timezone (e.g., `Eastern`, `Pacific`, `Europe/Berlin`)
- Press Enter

#### 7. Partition Disks
- **Partitioning method**: Select **Guided - use entire disk**
- **Select disk**: Choose `/dev/sda` (should be only option)
- **Partitioning scheme**: Select **All files in one partition**
  - ℹ️ Note: Docker doesn't require special partitioning. Simple is fine.
- **Finish partitioning**: Select **Finish partitioning and write changes to disk**
- **Write changes to disks?**: Select **Yes**
- Installation begins (takes 2-5 minutes)

#### 8. Configure the Package Manager
- **Scan extra installation media?**: Select **No**
- **Debian archive mirror country**: Choose your country
- **Debian archive mirror**: Choose `deb.debian.org` (or closest mirror)
- **HTTP proxy**: Leave **blank** (press Enter)

#### 9. Configuring popularity-contest
- **Participate in package usage survey?**: Select **No**

#### 10. Software Selection
- **⚠️ IMPORTANT - Choose Desktop for Evaluation**
- Use **Space** to select/deselect, **Enter** to continue

**For Evaluation/Demonstration (Recommended):**
- **SELECT** (check):
  - [x] **LXQt** (ultra-lightweight desktop)
  - [x] SSH server
  - [x] standard system utilities
- **DESELECT** (uncheck):
  - [ ] Debian desktop environment
  - [ ] GNOME
  - [ ] KDE
  - [ ] Cinnamon
  - [ ] MATE
  - [ ] LXDE
  - [ ] Xfce

**Why LXQt?** 
- Ultra-lightweight (~350 MB RAM, smallest Qt-based desktop)
- Minimal footprint for OVA template
- **Firefox pre-installed** for demonstrations (WordPress, Adminer, static site)

**For Production/Server-Only:**
- If you don't need browser on VM (accessing from host via ports):
  - [x] SSH server
  - [x] standard system utilities only
  - [ ] (all desktops deselected)

- Press **Enter** to continue
- Installation continues (takes 5-15 minutes with LXQt)

#### 11. Install the GRUB Boot Loader
- **Install GRUB to master boot record?**: Select **Yes**
- **Device for boot loader**: Select `/dev/sda`
- Press Enter

#### 12. Finish the Installation
- **Installation complete**: Press **Continue**
- VM will reboot

**Debian installation complete!**

### Step 4: Setup Inside VM

**⚠️ GUI Login Note**: Desktop environments don't allow direct root login.

After reboot:
1. **Log in with your regular user** (e.g., `mana`, `inception`, pass *abc*)
2. **Open terminal** (LXQt Menu → System Tools → QTerminal)
3. **Switch to root**: `su -` (enter root password *abc*)

Then run:

```bash
# Update package lists and remove CD-ROM source
sed -i '/^deb cdrom:/s/^/#/' /etc/apt/sources.list
apt-get update

# Install git
apt-get install -y git

# Clone project
git clone https://github.com/MaNafromSaar/inception.git
cd inception

# Run automated setup
chmod +x scripts/setup_vm.sh
./scripts/setup_vm.sh
```

The setup script will:
- Install Docker and Docker Compose
- Add your user to necessary groups
- Configure firewall

**Done!** Your VM is ready.

**Total time**: ~15-20 minutes

---

## Method 3: Completely Manual

For complete control without any scripts (e.g., using VMware or other hypervisors).

### 1. Prerequisites

*   **VirtualBox** (or VMware, or your preferred hypervisor)
*   **Debian 11 (Bullseye) ISO**: `netinst` image for `amd64`
    *   Download manually or use `scripts/prepare_vm.sh`

### 2. VM Creation (VirtualBox)

**Note**: The `scripts/create_inception_vm.sh` script automates all of this.

**Manual VM Configuration:**

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
    *   **Network:** NAT with port forwarding

### 3. Debian Installation

Boot the VM from the ISO. Follow the installer steps as detailed in [Method 2](#method-2-semi-automated-recommended) above.

### 4. Post-Installation
### 4. Post-Installation Setup

**Option A: Automated (Recommended)**

Run the provided setup script as root:

```bash
su -
apt-get update && apt-get install -y git
git clone https://github.com/MaNafromSaar/inception.git
cd inception
./scripts/setup_vm.sh
```

**Option B: Manual Docker Installation**

Follow official Docker documentation for Debian 11, then manually configure firewall and user permissions.

---
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

---

## Method 4: Pre-built VM Template (For Evaluations)

**Use a pre-configured VM template to skip OS installation entirely.**

This method is perfect for:
- Project evaluations
- Quick testing
- Sharing with evaluators

### Creating the Template (One-Time Setup)

After completing VM setup using any of the methods above:

```bash
# Power off the VM
VBoxManage controlvm "inception-vm" poweroff

# Export as OVA template
VBoxManage export inception-vm -o inception-base-template.ova
```

This creates a portable VM template file (~1-2 GB).

### Using the Template

**For evaluators or quick testing:**

```bash
# Import the template
VBoxManage import inception-base-template.ova --vsys 0 --vmname inception-eval

# Start the VM
VBoxManage startvm "inception-eval" --type gui

# Login and run the project
cd /path/to/inception
make
```

**Advantages:**
- ✅ Skip 15-20 minutes of OS installation
- ✅ Docker already installed and configured
- ✅ User already in docker group
- ✅ Focus on project evaluation, not setup
- ✅ Compliant with subject (still on a VM, Docker setup is "from scratch")

**Sharing the Template:**

See [documentation/VM_TEMPLATE_GUIDE.md](./documentation/VM_TEMPLATE_GUIDE.md) for detailed instructions on:
- Creating and exporting templates
- Sharing via USB, vServer, or file sharing services
- Import and usage instructions

---

## Network Access Configuration

### NAT Mode (Default from Scripts)

If using NAT network (default), access services via port forwarding:

**Add to your host's `/etc/hosts`:**
```
127.0.0.1  mnaumann.42.fr
127.0.0.1  adminer.mnaumann.42.fr  
127.0.0.1  static.mnaumann.42.fr
```

**Port mapping:**
- HTTPS (WordPress): `https://localhost:8443` → `https://mnaumann.42.fr`
- Static site: `http://localhost:8081`
- SSH: `ssh -p 2222 inception@localhost`

### Bridged Mode (Direct Network Access)

If you manually configured bridged networking:

1. Find VM IP inside VM:
   ```bash
   hostname -I
   ```

2. Add to host's `/etc/hosts`:
   ```
   <VM_IP>  mnaumann.42.fr
   <VM_IP>  adminer.mnaumann.42.fr
   <VM_IP>  static.mnaumann.42.fr
   ```

3. Access directly:
   - `https://mnaumann.42.fr`
   - `ssh inception@<VM_IP>`

---

## Security Best Practices

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
