# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an Ubuntu AutoInstall ISO creation toolkit that automates the process of building custom Ubuntu installation ISOs with unattended configuration. The project supports Ubuntu 22.04+ server installations.

## Key Commands

### Main Workflow
```bash
# Initial setup (run once)
make download     # Download and verify Ubuntu ISO
make init         # Extract ISO contents and prepare workspace

# ISO generation (run each time)
make setup        # Copy configuration files to ISO workspace
make geniso       # Generate custom autoinstall ISO
```

### Alternative Commands
```bash
# Proxy support (for restricted networks)
make set-proxy PROXY=http://127.0.0.1:7890    # Configure proxy
make unset-proxy                               # Remove proxy
make proxy-status                              # Show proxy status

# File verification and troubleshooting
make get-official-sha256 # Get official SHA256 checksum
make check-download      # Check download file integrity
make verify-only         # Verify existing ISO file
make status             # Show all file statuses
make clean-all          # Clean everything
```

### RAID Setup Script
```bash
# Automatic RAID setup (requires root)
sudo ./scripts/setup_raid.sh                    # Auto-detect disks, create RAID 6
sudo ./scripts/setup_raid.sh -l 5               # Create RAID 5
sudo ./scripts/setup_raid.sh -h                 # Show help and available disks

# Manual disk specification
sudo ./scripts/setup_raid.sh /dev/nvme0n1 /dev/nvme0n2 /dev/nvme0n3 /dev/nvme0n4
```

## Architecture and Key Files

### Configuration Files
- `config/user-data.efi` - UEFI boot configuration with ESP partition
- `config/user-data.mbr` - Legacy BIOS/MBR boot configuration
- `config/meta-data` - Cloud-init metadata configuration
- `config/boot/grub/grub.cfg` - GRUB bootloader configuration
- `config/extras/acap.sudoers` - Sudoers configuration for passwordless sudo

### Build Process
1. **Download Phase**: Fetches Ubuntu ISO with SHA256 verification and proxy support
2. **Init Phase**: Mounts ISO and extracts contents to `iso_root/` directory
3. **Setup Phase**: Copies custom configurations over extracted ISO contents
4. **Generation Phase**: Uses `xorriso` to create bootable hybrid ISO with both UEFI and BIOS support

### Key Directories
- `iso_root/` - Extracted and modified ISO contents (working directory)
- `config/` - All customization files and configurations
- `scripts/` - Automation scripts (RAID setup, disk management)
- `docs/` - Documentation including RAID setup guides
- Base ISO file: `ubuntu-24.04.2-live-server-amd64.iso`

## Default Settings

### User Account
- Username: `acap` (configurable in user-data)
- Password: `secret` (hashed, configurable in user-data)
- SSH key authentication: Supported
- Passwordless sudo: Enabled via sudoers file

### System Configuration
- Locale: `en_US.UTF-8`
- Keyboard: US layout
- Timezone: Configurable in user-data
- Auto-reboot after installation

### Storage
- Default: Single disk with UEFI boot (ESP + boot + root partitions)
- RAID support: Available via post-install scripts (RAID 1/5/6/10)
- File system: ext4 for system partitions

## Hardware Support

### Primary Targets
- Modern UEFI systems with NVMe storage
- Legacy BIOS systems (with isolinux variant)
- Target Ubuntu version: 24.04.2 LTS Server

## Customization Points

### Network Configuration
- Proxy support for restricted environments
- Mirror selection (commented examples for Chinese mirrors)
- Package installation from offline/online sources

### Storage Configuration
- Automatic disk detection and system disk protection
- RAID setup with comprehensive disk validation
- Multiple storage layouts supported (simple, LVM, RAID)

## Development Notes

- The Makefile uses shell functions and extensive error handling
- ISO generation requires specific sector calculations for hybrid boot
- RAID scripts include rollback functionality and comprehensive validation
- All scripts use centralized logging via `scripts/common.sh`
- Chinese language support and fonts are included in package selection