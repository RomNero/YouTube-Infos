#!/usr/bin/env bash
set -euo pipefail

# ------------------------------------------------------------------------------
# Proxmox Ubuntu 24.04 Cloud-Init Template Creator
#
# Behavior:
#  - If started with no arguments -> interactive menu
#  - Option 1 -> run with default values
#  - Option 2 -> interactive configuration
#  - Option --default -> run with defaults directly
#
# Author: RomNero
# ------------------------------------------------------------------------------

# -----------------------------
# Default values
# -----------------------------
VMID=9998
VM_NAME="ubuntu-2404-ci"

MEMORY_MB=4096
CORES=2

BRIDGE="vmbr0"
NET_MODEL="virtio"

STORAGE="local-lvm"

ISO_DIR="/var/lib/vz/template/iso"

UBUNTU_IMG_URL="https://cloud-images.ubuntu.com/releases/noble/release/ubuntu-24.04-server-cloudimg-amd64.img"
UBUNTU_IMG_FILE="ubuntu-24.04-server-cloudimg-amd64.img"

CI_USER="ubuntu"
IPCONFIG0="ip=dhcp"

DISK_RESIZE="+10G"

# -----------------------------
# Helper: ask question with default
# -----------------------------
ask() {
    local prompt=$1
    local default=$2
    read -p "$prompt [$default]: " value
    echo "${value:-$default}"
}

# -----------------------------
# Interactive configuration
# -----------------------------
interactive_config() {

    echo ""
    echo "Configure VM parameters (press ENTER to use default value)"
    echo ""

    VMID=$(ask "VM ID" "$VMID")
    VM_NAME=$(ask "VM Name" "$VM_NAME")
    MEMORY_MB=$(ask "RAM (MB)" "$MEMORY_MB")
    CORES=$(ask "CPU Cores" "$CORES")
    BRIDGE=$(ask "Network Bridge" "$BRIDGE")
    STORAGE=$(ask "Storage" "$STORAGE")
    CI_USER=$(ask "Cloud-init User" "$CI_USER")
    IPCONFIG0=$(ask "IP Config (e.g. ip=dhcp or ip=192.168.1.10/24,gw=192.168.1.1)" "$IPCONFIG0")
    DISK_RESIZE=$(ask "Disk Resize" "$DISK_RESIZE")
}

# -----------------------------
# Help / Menu
# -----------------------------
menu() {

    echo ""
    echo "Proxmox Ubuntu 24.04 Cloud-Init Template Script"
    echo "-----------------------------------------------"
    echo ""
    echo "1) Install with default settings"
    echo "2) Customize parameters"
    echo "3) Exit"
    echo ""

    read -p "Select option: " choice

    case $choice in
        1)
            echo "Running with default settings..."
            ;;
        2)
            interactive_config
            ;;
        *)
            echo "Exit."
            exit 0
            ;;
    esac
}

# -----------------------------
# Parameter handling
# -----------------------------
if [[ $# -eq 0 ]]; then
    menu
fi

if [[ "${1:-}" == "--default" ]]; then
    echo "Running with default configuration..."
fi

# -----------------------------
# Preflight checks
# -----------------------------
if [[ $EUID -ne 0 ]]; then
  echo "ERROR: Run this script as root."
  exit 1
fi

command -v qm >/dev/null || { echo "qm command not found"; exit 1; }
command -v wget >/dev/null || { echo "wget not found"; exit 1; }

UBUNTU_IMG_PATH="$ISO_DIR/$UBUNTU_IMG_FILE"

mkdir -p "$ISO_DIR"

# -----------------------------
# Download cloud image
# -----------------------------
if [[ ! -f "$UBUNTU_IMG_PATH" ]]; then
    echo "Downloading Ubuntu Cloud Image..."
    wget -O "$UBUNTU_IMG_PATH" "$UBUNTU_IMG_URL"
else
    echo "Cloud image already exists."
fi

# -----------------------------
# Create VM
# -----------------------------
echo "Creating VM $VMID..."

qm create "$VMID" \
  --name "$VM_NAME" \
  --memory "$MEMORY_MB" \
  --cores "$CORES" \
  --net0 "${NET_MODEL},bridge=${BRIDGE}"

# -----------------------------
# Import disk
# -----------------------------
echo "Importing disk..."

qm importdisk "$VMID" "$UBUNTU_IMG_PATH" "$STORAGE"

IMPORTED_VOL="${STORAGE}:vm-${VMID}-disk-0"

# -----------------------------
# Configure disk
# -----------------------------
qm set "$VMID" \
  --scsihw virtio-scsi-single \
  --scsi0 "${IMPORTED_VOL},discard=on"

# -----------------------------
# Add cloud-init drive
# -----------------------------
qm set "$VMID" --ide2 "${STORAGE}:cloudinit"

# -----------------------------
# Boot configuration
# -----------------------------
qm set "$VMID" --boot c --bootdisk scsi0

# Enable QEMU agent
qm set "$VMID" --agent enabled=1

# -----------------------------
# Resize disk
# -----------------------------
qm resize "$VMID" scsi0 "$DISK_RESIZE"

# -----------------------------
# Cloud-init defaults
# -----------------------------
qm set "$VMID" --ciuser "$CI_USER"
qm set "$VMID" --ipconfig0 "$IPCONFIG0"

# -----------------------------
# Convert to template
# -----------------------------
echo "Converting VM to template..."

qm template "$VMID"

echo ""
echo "Template successfully created!"
echo "VMID: $VMID"
echo "Name: $VM_NAME"
