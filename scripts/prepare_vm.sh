#!/bin/bash

# Inception VM Preparation Script
# This script downloads the Debian Boot ISO (netinst) for the Inception project.
# Run this script on your HOST machine before creating the VM.

set -e  # Exit on error

# --- Configuration ---
# Using Debian 11 (Bullseye) - the penultimate stable release as per project requirements
DEBIAN_VERSION="11.11.0"
ARCH="amd64"
ISO_NAME="debian-${DEBIAN_VERSION}-${ARCH}-netinst.iso"
ISO_URL="https://cdimage.debian.org/cdimage/archive/${DEBIAN_VERSION}/${ARCH}/iso-cd/${ISO_NAME}"
CHECKSUM_URL="https://cdimage.debian.org/cdimage/archive/${DEBIAN_VERSION}/${ARCH}/iso-cd/SHA256SUMS"
DOWNLOAD_DIR="${HOME}/Downloads/inception-vm"

# --- Colors for output ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
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

# --- Main Script ---
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║         Inception VM Preparation - Debian ISO Download        ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# --- Create download directory ---
print_info "Creating download directory: ${DOWNLOAD_DIR}"
mkdir -p "${DOWNLOAD_DIR}"
cd "${DOWNLOAD_DIR}"

# --- Check if ISO already exists ---
if [ -f "${ISO_NAME}" ]; then
    print_warning "ISO file already exists: ${ISO_NAME}"
    read -p "Do you want to re-download it? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Using existing ISO file."
        ISO_EXISTS=true
    else
        print_info "Removing existing ISO and re-downloading..."
        rm -f "${ISO_NAME}"
        ISO_EXISTS=false
    fi
else
    ISO_EXISTS=false
fi

# --- Download the ISO ---
if [ "${ISO_EXISTS}" = false ]; then
    print_info "Downloading Debian ${DEBIAN_VERSION} netinst ISO..."
    print_info "URL: ${ISO_URL}"
    echo ""
    
    if command -v wget &> /dev/null; then
        wget --continue --show-progress "${ISO_URL}" -O "${ISO_NAME}"
    elif command -v curl &> /dev/null; then
        curl -L --progress-bar "${ISO_URL}" -o "${ISO_NAME}"
    else
        print_error "Neither wget nor curl is installed. Please install one of them."
        exit 1
    fi
    
    if [ $? -eq 0 ]; then
        print_info "Download completed successfully!"
    else
        print_error "Download failed. Please check your internet connection and try again."
        exit 1
    fi
fi

# --- Download and verify checksum ---
print_info "Downloading SHA256 checksums..."
if command -v wget &> /dev/null; then
    wget -q "${CHECKSUM_URL}" -O SHA256SUMS
elif command -v curl &> /dev/null; then
    curl -sL "${CHECKSUM_URL}" -o SHA256SUMS
fi

if [ -f SHA256SUMS ]; then
    print_info "Verifying ISO checksum..."
    
    # Extract the checksum for our specific ISO
    EXPECTED_CHECKSUM=$(grep "${ISO_NAME}" SHA256SUMS | awk '{print $1}')
    
    if [ -z "${EXPECTED_CHECKSUM}" ]; then
        print_warning "Could not find checksum for ${ISO_NAME} in SHA256SUMS file."
        print_warning "Skipping checksum verification."
    else
        # Calculate actual checksum
        if command -v sha256sum &> /dev/null; then
            ACTUAL_CHECKSUM=$(sha256sum "${ISO_NAME}" | awk '{print $1}')
        elif command -v shasum &> /dev/null; then
            ACTUAL_CHECKSUM=$(shasum -a 256 "${ISO_NAME}" | awk '{print $1}')
        else
            print_warning "No checksum tool found (sha256sum or shasum). Skipping verification."
            ACTUAL_CHECKSUM=""
        fi
        
        if [ -n "${ACTUAL_CHECKSUM}" ]; then
            if [ "${EXPECTED_CHECKSUM}" = "${ACTUAL_CHECKSUM}" ]; then
                print_info "✓ Checksum verification PASSED!"
            else
                print_error "✗ Checksum verification FAILED!"
                print_error "Expected: ${EXPECTED_CHECKSUM}"
                print_error "Got:      ${ACTUAL_CHECKSUM}"
                print_error "The downloaded ISO may be corrupted. Please re-download."
                exit 1
            fi
        fi
    fi
else
    print_warning "Could not download SHA256SUMS file. Skipping checksum verification."
fi

# --- Summary ---
echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                      Preparation Complete!                     ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
print_info "ISO Location: ${DOWNLOAD_DIR}/${ISO_NAME}"
print_info "ISO Size: $(du -h "${ISO_NAME}" | cut -f1)"
echo ""
echo "Next steps:"
echo "  1. Create a new VM in VirtualBox/VMware"
echo "  2. Attach this ISO as the boot medium"
echo "  3. Install Debian following the VM_SETUP_GUIDE.md"
echo "  4. After installation, run setup_vm.sh (as root) inside the VM"
echo ""
