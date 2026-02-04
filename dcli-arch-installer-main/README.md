# DCLI Declaritive Arch Installer

A New, streamlined Arch Linux installer with a modern TUI that generates declarative dcli configuration files so your entire system is declared through dcli. 

## Features

- Beautiful gum-based TUI interface
- 9 configuration options with visual menu navigation
- Generates declarative dcli configuration (Lua or YAML)
- Comprehensive GPU driver selection including hybrid setups
- BTRFS with subvolumes, ext4, or XFS filesystem support
- ZRAM or swapfile configuration
- First-boot service for automatic dcli configuration setup

## Quick Start (from Arch ISO)

Boot into the Arch Linux live ISO and run:

```bash
curl -L https://gitlab.com/theblackdon/dcli-arch-installer/-/raw/main/install.sh | bash
```

Or step by step:

```bash
curl -L https://gitlab.com/theblackdon/dcli-arch-installer/-/raw/main/install.sh -o install.sh
bash install.sh
```

## Configuration Options

| # | Option | Description |
|---|--------|-------------|
| 1 | Installer Language | Interface language |
| 2 | Locales | System locale + keyboard layout |
| 3 | Disk Configuration | Target disk + filesystem |
| 4 | Swap | zram / swapfile / none |
| 5 | Hostname | System hostname |
| 6 | Graphics Driver | Intel, AMD, NVIDIA, hybrid, or VM |
| 7 | Authentication | Username + passwords |
| 8 | Timezone | Region/city |
| 9 | dcli Config Format | Generate Lua/YAML or clone from git |

## Graphics Driver Options

| Option | Description |
|--------|-------------|
| mesa-all | All open-source drivers (safe default) |
| intel | Intel integrated graphics |
| amd | AMD/ATI graphics |
| nvidia-turing | NVIDIA RTX 20/30/40, GTX 1650+ |
| nvidia-legacy | NVIDIA GTX 900/1000 series |
| intel-nvidia-turing | Intel + NVIDIA Turing+ (Optimus) |
| intel-nvidia-legacy | Intel + NVIDIA Legacy (Optimus) |
| amd-nvidia-turing | AMD + NVIDIA Turing+ |
| amd-nvidia-legacy | AMD + NVIDIA Legacy |
| vm | Virtual machine drivers |

## How It Works

### Installation Phase (Chroot)

1. Partitions and formats the disk
2. Installs base system via pacstrap
3. Installs critical packages (GPU drivers)
4. Generates dcli configuration files
5. Installs AUR helper and dcli
6. Creates first-boot service
7. Installs GRUB bootloader

### First Boot Phase (Automatic)

On first boot, the dcli-first-boot service automatically:

1. Checks if `config.lua` or `config.yaml` exists
2. Creates the config file if missing (detects hostname and matches to existing host file, or creates a new one)
3. Runs `dcli validate` to verify the configuration

The service then removes itself. Run `dcli sync` when you're ready to install your declared packages.

## File Structure

```
dcli-arch-installer/
├── install.sh              # Curl launcher script
├── dcli-install.sh         # Main installer script
├── modules/
│   ├── base-system.lua
│   ├── networking.lua
│   ├── audio-pipewire.lua
│   ├── filesystem/
│   │   ├── btrfs.lua
│   │   ├── ext4.lua
│   │   └── xfs.lua
│   ├── bootloader/
│   │   └── grub.lua
│   ├── swap/
│   │   ├── zram.lua
│   │   ├── file.lua
│   │   └── none.lua
│   └── gpu/
│       ├── intel.lua
│       ├── amd.lua
│       ├── nvidia-turing.lua
│       ├── nvidia-legacy.lua
│       ├── intel-nvidia-turing.lua
│       ├── intel-nvidia-legacy.lua
│       ├── amd-nvidia-turing.lua
│       ├── amd-nvidia-legacy.lua
│       ├── vm.lua
│       └── mesa-all.lua
└── README.md
```

## Generated dcli Configuration

After installation, your system will have:

```
~/.config/arch-config/
├── config.lua              # Points to your host
├── hosts/
│   └── {hostname}.lua      # Your host configuration
└── modules/                # All module files
```

## Requirements

- Arch Linux live ISO (latest recommended)
- Internet connection
- UEFI or BIOS system
- At least 20GB disk space

## WiFi from the Arch ISO

```bash
# Enter the iwd shell
iwctl

# List devices
device list

# Scan and list networks
station wlan0 scan
station wlan0 get-networks

# Connect (will prompt for passphrase)
station wlan0 connect "SSID_NAME"

# Exit iwctl
exit
```

## Troubleshooting

### No internet connection

```bash
# For WiFi
iwctl

# For Ethernet
dhcpcd
```

### Installer won't start

```bash
# Install gum manually
pacman -Sy gum

# Run installer directly
bash dcli-install.sh
```

## Post-Installation

After rebooting, you can manage your system with dcli:

```bash
# Check system status
dcli status

# Sync packages with configuration
dcli sync

# Enable a new module
dcli module enable gaming

# Update system
dcli update
```

## License

GPL-3.0 License
