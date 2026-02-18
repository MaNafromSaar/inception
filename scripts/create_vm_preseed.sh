#!/bin/bash

# Inception VM with Preseed - Automated Debian Installation
# This script creates a VM and configures it for automated installation using preseed

set -e

# --- Configuration ---
VM_NAME="inception-vm"
ISO_DIR="${HOME}/Downloads/inception-vm"
ISO_NAME="debian-11.11.0-amd64-netinst.iso"
ISO_PATH="${ISO_DIR}/${ISO_NAME}"
PRESEED_FILE="$(dirname "$0")/debian-preseed.cfg"

# VM Hardware
MEMORY_MB=4096
CPUS=2
DISK_SIZE_MB=25600
DISK_PATH="${HOME}/VirtualBox VMs/${VM_NAME}/${VM_NAME}.vdi"

# --- Colors ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }
print_step() { echo -e "${BLUE}[STEP]${NC} $1"; }

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║     Inception VM - Automated Installation with Preseed        ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Check VirtualBox
print_step "Checking VirtualBox..."
if ! command -v VBoxManage &> /dev/null; then
    print_error "VirtualBox not found. Install from: https://www.virtualbox.org/"
    exit 1
fi
print_info "VirtualBox: $(VBoxManage --version)"

# Check ISO
print_step "Checking Debian ISO..."
if [ ! -f "${ISO_PATH}" ]; then
    print_error "ISO not found: ${ISO_PATH}"
    print_warning "Run: ./scripts/prepare_vm.sh"
    exit 1
fi
print_info "ISO found."

# Check preseed file
print_step "Checking preseed configuration..."
if [ ! -f "${PRESEED_FILE}" ]; then
    print_error "Preseed file not found: ${PRESEED_FILE}"
    exit 1
fi
print_info "Preseed file: ${PRESEED_FILE}"

# Delete existing VM if present
if VBoxManage list vms | grep -q "\"${VM_NAME}\""; then
    print_warning "VM '${VM_NAME}' exists. Deleting..."
    VBoxManage controlvm "${VM_NAME}" poweroff 2>/dev/null || true
    sleep 2
    VBoxManage unregistervm "${VM_NAME}" --delete
fi

# Create VM
print_step "Creating VM..."
VBoxManage createvm --name "${VM_NAME}" --ostype "Debian_64" --register

# Configure hardware
print_step "Configuring hardware..."
VBoxManage modifyvm "${VM_NAME}" \
    --memory ${MEMORY_MB} \
    --cpus ${CPUS} \
    --vram 16 \
    --boot1 dvd \
    --boot2 disk \
    --acpi on \
    --ioapic on

# Create disk
print_step "Creating virtual disk..."
VBoxManage createhd --filename "${DISK_PATH}" --size ${DISK_SIZE_MB} --format VDI

# Add storage controllers
print_step "Configuring storage..."
VBoxManage storagectl "${VM_NAME}" --name "SATA" --add sata --controller IntelAhci
VBoxManage storageattach "${VM_NAME}" --storagectl "SATA" --port 0 --device 0 \
    --type hdd --medium "${DISK_PATH}"

VBoxManage storagectl "${VM_NAME}" --name "IDE" --add ide
VBoxManage storageattach "${VM_NAME}" --storagectl "IDE" --port 0 --device 0 \
    --type dvddrive --medium "${ISO_PATH}"

# Network: NAT with port forwarding
print_step "Configuring network..."
VBoxManage modifyvm "${VM_NAME}" --nic1 nat
VBoxManage modifyvm "${VM_NAME}" \
    --natpf1 "ssh,tcp,,2222,,22" \
    --natpf1 "https,tcp,,8443,,443" \
    --natpf1 "http,tcp,,8081,,8081"

print_info "Network: NAT mode with port forwarding"

# Configure for preseed
print_step "Configuring preseed boot..."

# Create initrd with preseed file
PRESEED_INITRD="/tmp/inception-preseed-initrd.gz"
mkdir -p /tmp/preseed-work
cp "${PRESEED_FILE}" /tmp/preseed-work/preseed.cfg
cd /tmp/preseed-work
echo "preseed.cfg" | cpio -o -H newc | gzip > "${PRESEED_INITRD}"
cd - > /dev/null

print_warning "Note: Automated installation requires manual boot parameter entry."
print_warning "When the installer boots, press ESC, then enter:"
print_warning ""
print_warning "  auto url=file:///preseed.cfg"
print_warning ""

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                  VM Creation Complete                          ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
print_info "VM Name: ${VM_NAME}"
print_info "Preseed file copied to initrd"
echo ""
echo "Next steps:"
echo "  1. Start VM: VBoxManage startvm \"${VM_NAME}\" --type gui"
echo ""
echo "  2. At boot menu, press ESC"
echo ""
echo "  3. Type: auto url=file:///preseed.cfg"
echo ""
echo "  4. Installation will proceed automatically!"
echo ""
echo "  Default credentials:"
echo "    User: inception / Password: inception123"
echo "    Root: root / Password: temproot123"
echo ""
echo "  5. After reboot, run setup_vm.sh inside the VM"
echo ""
print_info "Preseed initrd: ${PRESEED_INITRD}"
