#!/bin/bash

# Inception VM Creation Script for VirtualBox
# This script automates the creation of a VirtualBox VM for the Inception project.
# Run this script on your HOST machine (not inside a VM).

set -e  # Exit on error

# --- Configuration ---
VM_NAME="inception-vm"
ISO_DIR="${HOME}/Downloads/inception-vm"
ISO_NAME="debian-11.11.0-amd64-netinst.iso"
ISO_PATH="${ISO_DIR}/${ISO_NAME}"

# VM Hardware Settings
MEMORY_MB=4096          # 4 GB RAM
CPUS=2                  # 2 CPU cores
DISK_SIZE_MB=25600      # 25 GB disk
VRAM_MB=16              # Video RAM (minimal, headless)
DISK_PATH="${HOME}/VirtualBox VMs/${VM_NAME}/${VM_NAME}.vdi"

# Network Settings
NETWORK_TYPE="nat"      # Options: "bridged" or "nat"
                        # NAT is more reliable and doesn't require kernel modules
# If using bridged, specify adapter (e.g., "en0", "eth0", "wlan0")
HOST_ADAPTER=""         # Leave empty for auto-detection

# --- Colors for output ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# --- Functions ---
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# --- Main Script ---
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║       Inception VM Creation - VirtualBox Automation           ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# --- Check if VirtualBox is installed ---
print_step "Checking for VirtualBox installation..."
if ! command -v VBoxManage &> /dev/null; then
    print_error "VirtualBox (VBoxManage) is not installed or not in PATH."
    print_error "Please install VirtualBox from: https://www.virtualbox.org/wiki/Downloads"
    exit 1
fi

VBOX_VERSION=$(VBoxManage --version)
print_info "VirtualBox detected: ${VBOX_VERSION}"

# --- Check if ISO exists ---
print_step "Checking for Debian ISO..."
if [ ! -f "${ISO_PATH}" ]; then
    print_error "Debian ISO not found at: ${ISO_PATH}"
    print_warning "Please run './scripts/prepare_vm.sh' first to download the ISO."
    exit 1
fi
print_info "ISO found: ${ISO_PATH}"

# --- Check if VM already exists ---
print_step "Checking if VM '${VM_NAME}' already exists..."
if VBoxManage list vms | grep -q "\"${VM_NAME}\""; then
    print_warning "VM '${VM_NAME}' already exists!"
    read -p "Do you want to delete it and recreate? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_info "Powering off and deleting existing VM..."
        VBoxManage controlvm "${VM_NAME}" poweroff 2>/dev/null || true
        sleep 2
        VBoxManage unregistervm "${VM_NAME}" --delete
        print_info "Existing VM deleted."
    else
        print_info "Keeping existing VM. Exiting."
        exit 0
    fi
fi

# --- Create the VM ---
print_step "Creating new VM: ${VM_NAME}..."
VBoxManage createvm \
    --name "${VM_NAME}" \
    --ostype "Debian_64" \
    --register

print_info "VM created and registered."

# --- Configure VM settings ---
print_step "Configuring VM hardware..."

# System settings
VBoxManage modifyvm "${VM_NAME}" \
    --memory ${MEMORY_MB} \
    --cpus ${CPUS} \
    --vram ${VRAM_MB} \
    --boot1 dvd \
    --boot2 disk \
    --boot3 none \
    --boot4 none \
    --acpi on \
    --ioapic on \
    --rtcuseutc on

print_info "System settings configured (RAM: ${MEMORY_MB}MB, CPUs: ${CPUS})."

# --- Create and attach storage ---
print_step "Creating virtual hard disk..."
VBoxManage createhd \
    --filename "${DISK_PATH}" \
    --size ${DISK_SIZE_MB} \
    --format VDI

print_info "Virtual disk created: ${DISK_SIZE_MB}MB"

# Add SATA controller
print_step "Adding storage controllers..."
VBoxManage storagectl "${VM_NAME}" \
    --name "SATA Controller" \
    --add sata \
    --controller IntelAhci \
    --portcount 2 \
    --bootable on

# Attach hard disk
VBoxManage storageattach "${VM_NAME}" \
    --storagectl "SATA Controller" \
    --port 0 \
    --device 0 \
    --type hdd \
    --medium "${DISK_PATH}"

# Add IDE controller for DVD
VBoxManage storagectl "${VM_NAME}" \
    --name "IDE Controller" \
    --add ide \
    --controller PIIX4

# Attach ISO
VBoxManage storageattach "${VM_NAME}" \
    --storagectl "IDE Controller" \
    --port 0 \
    --device 0 \
    --type dvddrive \
    --medium "${ISO_PATH}"

print_info "Storage configured and Debian ISO attached."

# --- Network configuration ---
print_step "Configuring network..."

if [ "${NETWORK_TYPE}" = "bridged" ]; then
    # Auto-detect host network adapter if not specified
    if [ -z "${HOST_ADAPTER}" ]; then
        # Try to find active network adapter
        if command -v ip &> /dev/null; then
            HOST_ADAPTER=$(ip route | grep default | awk '{print $5}' | head -n1)
        elif command -v ifconfig &> /dev/null; then
            HOST_ADAPTER=$(ifconfig | grep -E '^[a-z]' | grep -v lo | head -n1 | cut -d: -f1)
        fi
    fi
    
    if [ -n "${HOST_ADAPTER}" ]; then
        VBoxManage modifyvm "${VM_NAME}" \
            --nic1 bridged \
            --bridgeadapter1 "${HOST_ADAPTER}"
        print_info "Network: Bridged mode on adapter '${HOST_ADAPTER}'"
        print_warning "The VM will get an IP from your router (DHCP)."
    else
        VBoxManage modifyvm "${VM_NAME}" --nic1 bridged
        print_info "Network: Bridged mode (adapter auto-detect)"
    fi
elif [ "${NETWORK_TYPE}" = "nat" ]; then
    VBoxManage modifyvm "${VM_NAME}" --nic1 nat
    
    # Add port forwarding rules for NAT
    VBoxManage modifyvm "${VM_NAME}" \
        --natpf1 "ssh,tcp,,2222,,22" \
        --natpf1 "https,tcp,,8443,,443" \
        --natpf1 "http,tcp,,8081,,8081" \
        --natpf1 "ftp,tcp,,2121,,21"
    
    print_info "Network: NAT mode with port forwarding"
    print_info "  SSH:   localhost:2222  -> VM:22"
    print_info "  HTTPS: localhost:8443  -> VM:443"
    print_info "  HTTP:  localhost:8081  -> VM:8081"
    print_info "  FTP:   localhost:2121  -> VM:21"
else
    print_error "Invalid NETWORK_TYPE: ${NETWORK_TYPE}"
    exit 1
fi

# --- Final summary ---
echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                   VM Creation Complete!                        ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
print_info "VM Name: ${VM_NAME}"
print_info "Memory: ${MEMORY_MB}MB ($(echo "scale=1; ${MEMORY_MB}/1024" | bc)GB)"
print_info "CPUs: ${CPUS}"
print_info "Disk: ${DISK_SIZE_MB}MB ($(echo "scale=1; ${DISK_SIZE_MB}/1024" | bc)GB)"
print_info "Network: ${NETWORK_TYPE}"
echo ""
echo "Next steps:"
echo "  1. Start the VM: VBoxManage startvm \"${VM_NAME}\" --type gui"
echo "     (Or use VirtualBox GUI and click 'Start')"
echo ""
echo "  2. Install Debian 11 (follow the installer):"
echo "     - avoid using GUI installation: select 'Install' rather than 'Graphical Install'"
echo "     - Hostname: inception"
echo "     - Domain: (leave blank)"
echo "     - Set root password"
echo "     - Create a regular user"
echo "     - Partitioning: Guided - use entire disk"
echo "     - Software selection: DESELECT desktop, SELECT 'SSH server' and 'standard system utilities'"
echo "     - Install GRUB to /dev/sda"
echo ""
echo "  3. After installation, eject the ISO:"
echo "     VBoxManage storageattach \"${VM_NAME}\" \\"
echo "       --storagectl \"IDE Controller\" \\"
echo "       --port 0 --device 0 --type dvddrive --medium none"
echo ""
echo "  4. Inside the VM (as root), clone the project and run setup:"
echo "     apt-get update && apt-get install -y git"
echo "     git clone https://github.com/MaNafromSaar/inception.git"
echo "     cd inception"
echo "     chmod +x scripts/setup_vm.sh"
echo "     ./scripts/setup_vm.sh"
echo ""
print_info "Happy hacking! 🚀"
