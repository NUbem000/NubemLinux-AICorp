# Installation Guide

This guide will walk you through installing NubemLinux-AICorp on your system.

## Prerequisites

Before installation, ensure your system meets these requirements:

### Hardware Requirements

**Minimum:**
- 4GB RAM
- 50GB free disk space
- x86_64 processor with virtualization support
- Internet connection (for AI model downloads)

**Recommended:**
- 8GB+ RAM
- 100GB+ free disk space
- NVIDIA GPU with CUDA support
- Gigabit Ethernet connection

### BIOS/UEFI Settings

1. Enable virtualization (Intel VT-x/AMD-V)
2. Disable Secure Boot (temporarily)
3. Set boot mode to UEFI (recommended) or Legacy BIOS

## Creating Bootable Media

### USB Drive (Recommended)

1. Download the ISO:
   ```bash
   wget https://github.com/NUbem000/NubemLinux-AICorp/releases/download/v1.0.0/nubemlinux-aicorp-1.0.0.iso
   ```

2. Verify the download:
   ```bash
   sha256sum nubemlinux-aicorp-1.0.0.iso
   ```

3. Create bootable USB:
   
   **Linux:**
   ```bash
   sudo dd if=nubemlinux-aicorp-1.0.0.iso of=/dev/sdX bs=4M status=progress
   sync
   ```
   
   **Windows:**
   - Use [Rufus](https://rufus.ie/) or [Etcher](https://www.balena.io/etcher/)
   
   **macOS:**
   ```bash
   sudo dd if=nubemlinux-aicorp-1.0.0.iso of=/dev/diskX bs=4m
   ```

### Virtual Machine

For testing or development:

1. Create a new VM with:
   - Type: Linux
   - Version: Ubuntu 64-bit
   - RAM: 4GB minimum
   - Storage: 50GB minimum
   - Enable virtualization features

2. Mount the ISO as boot device

## Installation Process

### 1. Boot from Installation Media

1. Insert USB drive or mount ISO
2. Restart computer
3. Access boot menu (usually F12, F8, or ESC)
4. Select USB drive or virtual CD

### 2. Installation Options

At the boot menu, choose:

- **Try NubemLinux-AICorp**: Test without installing
- **Install NubemLinux-AICorp**: Direct installation
- **Install (Safe Graphics)**: For systems with graphics issues

### 3. Installation Wizard

Follow the on-screen wizard:

1. **Language Selection**
   - Choose your preferred language
   - Click Continue

2. **Keyboard Layout**
   - Select keyboard layout
   - Test in the input field
   - Click Continue

3. **Network Configuration**
   - Connect to WiFi if needed
   - Configure proxy if required
   - Click Continue

4. **Installation Type**
   - **Erase disk**: Clean installation (recommended)
   - **Manual partitioning**: Advanced users only
   - **Dual boot**: Alongside existing OS

5. **User Account**
   - Enter your name
   - Choose username
   - Set strong password
   - Enable automatic login (optional)

6. **AI Configuration**
   - Select default AI model (Llama 3.1 or Llama 2)
   - Enable cloud fallback (recommended)
   - Configure voice/image processing

7. **Review Settings**
   - Verify all settings
   - Click Install

### 4. Post-Installation

After installation completes:

1. Remove installation media
2. Reboot system
3. First boot configuration will start automatically

## First Boot Configuration

On first boot, NubemLinux-AICorp will:

1. **Initialize AI Components**
   - Download selected AI models
   - Configure Ollama service
   - Set up NubemCopilot

2. **Configure Security**
   - Enable firewall
   - Apply security policies
   - Set up automatic updates

3. **Customize Environment**
   - Apply corporate branding
   - Configure desktop environment
   - Set up user preferences

## Troubleshooting

### Boot Issues

If system won't boot:

1. Check BIOS/UEFI settings
2. Verify installation media integrity
3. Try safe graphics mode
4. Disable Secure Boot

### Network Issues

If no internet connection:

1. Check cable/WiFi connection
2. Verify network settings
3. Configure proxy if needed
4. Check firewall rules

### AI Model Download Fails

If AI models won't download:

1. Check internet connection
2. Verify proxy settings
3. Try different mirror
4. Download manually later

## Advanced Installation

### Custom Partitioning

For advanced users:

```
/boot/efi - 512MB (EFI System Partition)
/boot     - 1GB (ext4)
/         - 30GB minimum (ext4)
/home     - Remaining space (ext4)
swap      - Equal to RAM (swap)
```

### Automated Installation

Create a preseed file for unattended installation:

```bash
# Example preseed configuration
d-i debian-installer/locale string en_US
d-i keyboard-configuration/xkb-keymap select us
d-i netcfg/choose_interface select auto
d-i mirror/country string manual
d-i mirror/http/hostname string archive.ubuntu.com
d-i mirror/http/directory string /ubuntu
```

### Network Boot (PXE)

Set up PXE server:

1. Configure DHCP/TFTP server
2. Extract kernel and initrd from ISO
3. Create PXE menu configuration
4. Boot clients from network

## Next Steps

After successful installation:

1. [Configure your system](user-manual.md)
2. [Set up AI assistant](ai-assistant.md)
3. [Review security settings](security.md)
4. [Customize your environment](customization.md)

## Getting Help

If you encounter issues:

- Check our [FAQ](faq.md)
- Visit [troubleshooting guide](troubleshooting.md)
- Open an [issue on GitHub](https://github.com/NUbem000/NubemLinux-AICorp/issues)
- Contact support@nubemlinux.com