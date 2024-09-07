#!/bin/bash

# Version 3.5 - Proxmox VM Setup Script for Manual Windows Install

# Constants for download URLs
VIRTIO_ISO_URL="https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso"
WIN2022_ISO_URL="https://software-download.microsoft.com/download/pr/Windows_Server_2022_Datacenter_Eval.iso"

# Default VM settings
DEFAULT_DISK_SIZE="40G"
DEFAULT_CPU_CORES=4
DEFAULT_RAM_SIZE=8192  # 8GB RAM
DEFAULT_OS_TYPE="win11"
DEFAULT_STORAGE="local-lvm"
DEFAULT_WIN_ISO="/var/lib/vz/template/iso/server2022.iso"
VIRTIO_ISO_PATH="/var/lib/vz/template/iso/virtio-win.iso"

# Colors for output formatting
YELLOW='\033[1;33m'
GREEN='\033[1;32m'
RED='\033[1;31m'
NC='\033[0m' # No Color

# Function to print step headers
log_step() {
  echo -e "${YELLOW}\n====== $1 ======\n${NC}"
}

# Function to handle errors and rollback the VM
rollback() {
  echo -e "${RED}An error occurred during '$1'. Rolling back and cleaning up...${NC}"
  qm destroy $VMID --purge 2>/dev/null
  echo -e "${RED}VM $VMID has been destroyed.${NC}"
  exit 1
}

# Step 0: Create /opt/scripts folder and script file
log_step "Step 0: Preparing the environment"
echo -e "${GREEN}Creating /opt/scripts directory and preparing the script...${NC}"

# Create the /opt/scripts directory if it doesn't exist
if [ ! -d "/opt/scripts" ]; then
  mkdir -p /opt/scripts
  if [ $? -ne 0 ]; then
    echo -e "${RED}ERROR: Failed to create /opt/scripts directory.${NC}"
    exit 1
  else
    echo -e "${GREEN}Directory /opt/scripts created successfully.${NC}"
  fi
else
  echo -e "${GREEN}Directory /opt/scripts already exists.${NC}"
fi

# File path for the server script
SCRIPT_PATH="/opt/scripts/server2022.sh"

# Step 1: Prompt for VM Details
log_step "Step 1: Gathering user input"
read -p "Enter the VM name (default: dc0): " VM_NAME
VM_NAME=${VM_NAME:-dc0}

read -p "Enter the VM ID (default: 20220): " VMID
VMID=${VMID:-20220}

read -p "Enter the disk size (default: $DEFAULT_DISK_SIZE): " VM_DISK_SIZE
VM_DISK_SIZE=${VM_DISK_SIZE:-$DEFAULT_DISK_SIZE}

read -p "Enter the number of CPU cores (default: $DEFAULT_CPU_CORES): " VM_CPU_CORES
VM_CPU_CORES=${VM_CPU_CORES:-$DEFAULT_CPU_CORES}

read -p "Enter the amount of RAM in MB (default: $DEFAULT_RAM_SIZE): " VM_RAM_SIZE
VM_RAM_SIZE=${VM_RAM_SIZE:-$DEFAULT_RAM_SIZE}

read -p "Enter the path to the Windows Server ISO (default: $DEFAULT_WIN_ISO): " WIN_ISO
WIN_ISO=${WIN_ISO:-$DEFAULT_WIN_ISO}

# Step 2: Verify or Download Windows Server 2022 ISO
log_step "Step 2: Verifying Windows Server 2022 ISO"
if [ ! -f "$WIN_ISO" ]; then
  echo -e "${YELLOW}Windows Server 2022 ISO not found. Downloading...${NC}"
  wget -O "$WIN_ISO" "$WIN2022_ISO_URL"
  if [ $? -ne 0 ]; then
    echo -e "${RED}ERROR: Failed to download Windows Server 2022 ISO.${NC}"
    rollback "Windows ISO Download"
  else
    echo -e "${GREEN}Windows Server 2022 ISO downloaded successfully.${NC}"
  fi
else
  echo -e "${GREEN}Windows Server 2022 ISO found at $WIN_ISO.${NC}"
fi

# Step 3: Verify or Download VirtIO Drivers ISO
log_step "Step 3: Verifying VirtIO Drivers ISO"
if [ ! -f "$VIRTIO_ISO_PATH" ]; then
  echo -e "${YELLOW}VirtIO drivers ISO not found. Downloading...${NC}"
  wget -O "$VIRTIO_ISO_PATH" "$VIRTIO_ISO_URL"
  if [ $? -ne 0 ]; then
    echo -e "${RED}ERROR: Failed to download VirtIO drivers ISO.${NC}"
    rollback "VirtIO ISO Download"
  else
    echo -e "${GREEN}VirtIO drivers ISO downloaded successfully.${NC}"
  fi
else
  echo -e "${GREEN}VirtIO drivers ISO found at $VIRTIO_ISO_PATH.${NC}"
fi

# Step 4: Creating and allocating the hard disk using pvesm alloc
log_step "Step 4: Creating and allocating a $VM_DISK_SIZE disk for VM $VMID on storage $DEFAULT_STORAGE"
pvesm alloc $DEFAULT_STORAGE $VMID vm-$VMID-disk-0 $VM_DISK_SIZE
if [ $? -ne 0 ]; then
  echo -e "${RED}ERROR: Failed to allocate disk space for VM $VMID on storage $DEFAULT_STORAGE.${NC}"
  rollback "Manual Disk Allocation"
else
  echo -e "${GREEN}Disk space successfully allocated for VM $VMID.${NC}"
fi

# Step 5: Creating the VM
log_step "Step 5: Creating the VM with ID $VMID"
qm create $VMID --name $VM_NAME --memory $VM_RAM_SIZE --cores $VM_CPU_CORES --bios seabios --machine pc-i440fx-5.1 \
  --net0 virtio,bridge=vmbr0,firewall=1 \
  --scsihw virtio-scsi-pci --scsi0 $DEFAULT_STORAGE:vm-$VMID-disk-0 --ide2 $DEFAULT_STORAGE:cloudinit
if [ $? -ne 0 ]; then
  echo -e "${RED}ERROR: Failed to create VM $VMID.${NC}"
  rollback "VM Creation"
else
  echo -e "${GREEN}VM $VM_NAME with VMID $VMID has been successfully created.${NC}"
fi

# Step 6: Attach Windows Server ISO and VirtIO Drivers
log_step "Step 6: Attaching Windows Server ISO and VirtIO Drivers"
qm set $VMID --cdrom "$WIN_ISO" --ide3 "$VIRTIO_ISO_PATH",media=cdrom
if [ $? -ne 0 ]; then
  echo -e "${RED}ERROR: Failed to attach ISOs to VM $VMID.${NC}"
  rollback "ISO Attachment"
else
  echo -e "${GREEN}Windows Server and VirtIO Drivers ISOs attached successfully.${NC}"
fi

# Step 7: Starting the VM
log_step "Step 7: Starting VM $VM_NAME with VMID $VMID"
qm start $VMID
if [ $? -ne 0 ]; then
  echo -e "${RED}ERROR: Failed to start VM $VMID.${NC}"
  rollback "VM Start"
else
  echo -e "${GREEN}VM $VM_NAME with VMID $VMID has been successfully started!${NC}"
fi

# Step 8: Completion
log_step "Step 8: VM Creation and Configuration Complete"
echo -e "${GREEN}VM $VM_NAME with VMID $VMID has been successfully created, configured, and started.${NC}"
echo -e "${GREEN}You can now access the VM through Proxmox.${NC}"
