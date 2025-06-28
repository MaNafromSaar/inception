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

# --- Final Instructions ---
echo "\n-------------------------------------------------"
echo "✅ VM Setup is Complete!"
echo "-------------------------------------------------"
echo "Next steps for the user '$regular_user':"
echo "1. Log out and log back in to apply sudo permissions."
echo "2. Clone the project repository."
echo "3. Run 'make' inside the project directory."
