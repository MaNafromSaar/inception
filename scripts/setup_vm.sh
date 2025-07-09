# ...existing code from setup_vm.sh...

#!/bin/bash

# Inception VM Setup Script
# This script prepares a clean Debian VM for the Inception project.
# It installs all necessary dependencies: sudo, git, make, and Docker.
# RUN THIS SCRIPT AS THE ROOT USER.

# --- Check if running as root ---
echo "Step 1: Checking for root privileges..."
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root. Please use 'su -' and run it again." >&2
    exit 1
fi
echo "Root check passed."

# --- Configure APT to use online repositories ---
echo "\nStep 2: Configuring APT to use online sources instead of CD-ROM..."
# Comment out the CD-ROM line in the sources.list file
sed -i '/^deb cdrom:/s/^/#/' /etc/apt/sources.list
echo "APT configured."

# --- Update package lists and install core dependencies ---
echo "\nStep 3: Installing sudo, git, and build-essential..."
apt-get update
apt-get install -y sudo git build-essential
echo "Core dependencies installed."

# --- Add your user to the sudo group ---
# Replace 'inception' with the actual username if it's different
read -p "Please enter the username to add to the sudo group (e.g., inception): " regular_user
if id "$regular_user" &>/dev/null; then
    echo "Adding user '$regular_user' to the sudo group..."
    usermod -aG sudo $regular_user
    echo "User '$regular_user' added to sudo group. They will need to log out and log back in for it to take effect."
else
    echo "Warning: User '$regular_user' not found. Skipping sudo group addition."
fi

# --- Install Docker Engine ---
echo "\nStep 4: Installing Docker Engine..."
apt-get install -y ca-certificates curl
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
echo "Docker Engine installation complete."

# --- Add user to the docker group ---
echo "
Step 5: Adding user '$regular_user' to the docker group..."
if id "$regular_user" &>/dev/null; then
    usermod -aG docker $regular_user
    echo "User '$regular_user' added to the docker group. They will need to log out and log back in for it to take effect."
else
    echo "Warning: User '$regular_user' not found. Skipping docker group addition."
fi

echo ""
echo "Adding project domains to /etc/hosts for local resolution..."

# Check if the domain entry already exists to prevent duplicates.
if ! grep -q "127.0.0.1 mnaumann.42.fr" /etc/hosts; then
    # Append the line to the hosts file.
    # This script is expected to be run with sudo, so direct redirection is fine.
    echo "127.0.0.1 mnaumann.42.fr static.mnaumann.42.fr" >> /etc/hosts
    echo "Domains successfully added to /etc/hosts."
else
    echo "Domains already present in /etc/hosts. No changes made."
fi

# --- Final Instructions ---
echo "
-------------------------------------------------"
echo "✅ VM Setup is Complete!"
echo "-------------------------------------------------"
echo "Next steps for the user '$regular_user':"
echo "1. IMPORTANT: Log out of your session and log back in to apply group permissions (sudo and docker)."
echo "2. Clone your project repository into your user's home directory."
echo "3. Navigate into your project directory: cd <project_folder>"
echo "4. Create your .env file from the example: cp srcs/.env.example srcs/.env"
echo "5. Edit the 'srcs/.env' file and fill in your secrets."
echo "6. Run 'make' to build and start the services. If you have issues with old containers, run 'make down && make'."




