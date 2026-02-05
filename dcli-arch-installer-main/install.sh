#!/bin/bash
#
# dcli-arch-installer - Quick Launch Script
#
# Usage:
#   curl -L https://gitlab.com/theblackdon/dcli-arch-installer/-/raw/main/install.sh | bash
# Or:
#   curl -L https://gitlab.com/theblackdon/dcli-arch-installer/-/raw/main/install.sh -o install.sh
#   bash install.sh

set -e

# Configuration
REPO_URL=" https://raw.githubusercontent.com/DonBaal/Arch/main/dcli-arch-installer-main"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'

print_banner() {
    echo -e "${PURPLE}"
    clear
    cat << 'EOF'
    ____  ________    ____
   / __ \/ ____/ /   /  _/
  / / / / /   / /    / /  
 / /_/ / /___/ /____/ /   
/_____/\____/_____/___/   
                          
 Arch Linux Installer
EOF
    echo -e "${NC}"
    echo -e "${CYAN}Declarative Arch Linux installation powered by dcli${NC}"
    echo "=================================================="
    echo ""
}

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root"
        echo ""
        echo "Please run:"
        echo -e "  ${CYAN}sudo bash <(curl -fsSL $REPO_URL/install.sh)${NC}"
        exit 1
    fi
}

# Check for internet connection
check_internet() {
    log_info "Checking internet connection..."
    if ! ping -c 1 -W 5 archlinux.org &>/dev/null; then
        log_error "No internet connection detected"
        echo "Please ensure you have network connectivity"
        echo ""
        echo "For WiFi, use: iwctl"
        echo "For Ethernet, try: dhcpcd"
        exit 1
    fi
    log_info "Internet connection confirmed"
}

# Check if we're on Arch Linux ISO
check_arch_iso() {
    if [[ ! -f /etc/arch-release ]]; then
        log_error "This script must be run from an Arch Linux live environment"
        exit 1
    fi
    
    if [[ -d /run/archiso ]]; then
        log_info "Arch Linux live environment detected"
    else
        log_warn "This doesn't appear to be an Arch ISO live environment"
        log_warn "Proceeding anyway, but some features may not work correctly"
    fi
}

# Install dependencies
install_dependencies() {
    log_info "Installing dependencies..."
    
    local deps_needed=()
    
    command -v gum &>/dev/null || deps_needed+=("gum")
    command -v parted &>/dev/null || deps_needed+=("parted")
    command -v arch-chroot &>/dev/null || deps_needed+=("arch-install-scripts")
    command -v sgdisk &>/dev/null || deps_needed+=("gptfdisk")
    command -v mkfs.btrfs &>/dev/null || deps_needed+=("btrfs-progs")
    command -v mkfs.fat &>/dev/null || deps_needed+=("dosfstools")
    command -v mkfs.ext4 &>/dev/null || deps_needed+=("e2fsprogs")
    command -v mkfs.xfs &>/dev/null || deps_needed+=("xfsprogs")
    command -v git &>/dev/null || deps_needed+=("git")
    
    if [[ ${#deps_needed[@]} -gt 0 ]]; then
        pacman -Sy --noconfirm "${deps_needed[@]}" &>/dev/null
        log_info "Dependencies installed: ${deps_needed[*]}"
    else
        log_info "All dependencies already available"
    fi
}

# Download and run installer
download_and_run() {
    log_info "Downloading dcli-arch-installer..."
    
    # Create temp directory
    INSTALL_DIR=$(mktemp -d)
    cd "$INSTALL_DIR"
    
    # Download main installer script
    if curl -fsSL "$REPO_URL/dcli-install.sh" -o dcli-install.sh 2>/dev/null; then
        chmod +x dcli-install.sh
        log_info "Installer downloaded"
    else
        log_error "Failed to download installer"
        log_info "Attempting to clone full repository..."
        
        # Fallback: clone the repo
        if git clone --depth 1 https://gitlab.com/theblackdon/dcli-arch-installer.git "$INSTALL_DIR/repo" 2>/dev/null; then
            cp "$INSTALL_DIR/repo/dcli-install.sh" ./dcli-install.sh
            cp -r "$INSTALL_DIR/repo/modules" ./modules
            chmod +x dcli-install.sh
            log_info "Repository cloned"
        else
            log_error "Failed to download installer. Please check your internet connection."
            exit 1
        fi
    fi
    
    # Download modules directory
    log_info "Downloading module files..."
    mkdir -p modules/{filesystem,bootloader,swap,gpu,desktops,display-managers}
    
    # Module files to download
    local module_files=(
        "base-system.lua"
        "networking.lua"
        "audio-pipewire.lua"
        "filesystem/btrfs.lua"
        "filesystem/ext4.lua"
        "filesystem/xfs.lua"
        "bootloader/grub.lua"
        "swap/zram.lua"
        "swap/file.lua"
        "swap/none.lua"
        "gpu/intel.lua"
        "gpu/amd.lua"
        "gpu/nvidia-turing.lua"
        "gpu/nvidia-legacy.lua"
        "gpu/intel-nvidia-turing.lua"
        "gpu/intel-nvidia-legacy.lua"
        "gpu/amd-nvidia-turing.lua"
        "gpu/amd-nvidia-legacy.lua"
        "gpu/vm.lua"
        "gpu/mesa-all.lua"
        "desktops/kde-plasma.lua"
        "desktops/gnome.lua"
        "desktops/hyprland.lua"
        "desktops/niri.lua"
        "desktops/i3.lua"
        "desktops/xfce.lua"
        "desktops/none.lua"
        "display-managers/ly.lua"
        "display-managers/sddm.lua"
        "display-managers/gdm.lua"
        "display-managers/lightdm.lua"
        "display-managers/greetd.lua"
        "display-managers/none.lua"
    )
    
    for file in "${module_files[@]}"; do
        curl -fsSL "$REPO_URL/modules/$file" -o "modules/$file" 2>/dev/null || true
    done
    
    log_info "Module files downloaded"
    
    echo ""
    log_info "Starting installer in 3 seconds..."
    sleep 3
    
    # Run the installer
    exec bash dcli-install.sh
}

main() {
    print_banner
    
    log_info "Running pre-flight checks..."
    echo ""
    
    check_root
    check_arch_iso
    check_internet
    install_dependencies
    
    echo ""
    log_info "All pre-flight checks passed"
    echo ""
    
    download_and_run
}

# Run main function
main "$@"
