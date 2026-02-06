#!/bin/bash
#
# Baal´s Arch Installer - Main Installer Script
#
# A beautiful, fast, streamlined Arch Linux installer that generates
#
# License: GPL-3.0
#

set -Eeuo pipefail

# ════════════════════════════════════════════════════════════════════════════════
# CONFIGURATION
# ════════════════════════════════════════════════════════════════════════════════

VERSION="1.0"
SCRIPT_NAME="Baal´s Arch Installer"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MOUNTPOINT="/mnt"

# Colors (fallback if gum not available)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Installation configuration (associative array)
declare -A CONFIG
CONFIG[installer_lang]="English"
CONFIG[locale]="en_US.UTF-8"
CONFIG[keyboard]="us"
CONFIG[timezone]="Europe/Berlin"
CONFIG[hostname]="donbaal"
CONFIG[username]="baal"
CONFIG[user_password]=""
CONFIG[root_password]=""
CONFIG[disk]="/dev/sda"
CONFIG[filesystem]="btrfs"
CONFIG[swap]="zram"
CONFIG[swap_size]="4G"
CONFIG[gfx_driver]="intel"
CONFIG[desktop]="none"
CONFIG[display_manager]="greetd"
CONFIG[config_format]="lua"
CONFIG[git_repo]=""
CONFIG[aur_helper]="paru"
CONFIG[backup_tool]="timeshift"
CONFIG[bootloader]="grub"
CONFIG[uefi]="no"
CONFIG[boot_part]=""
CONFIG[root_part]=""

# ════════════════════════════════════════════════════════════════════════════════
# ERROR HANDLING
# ════════════════════════════════════════════════════════════════════════════════

have_gum() { command -v gum &>/dev/null; }

on_err() {
    local exit_code=$?
    local line_no=${1:-?}
    local cmd=${2:-?}

    if have_gum; then
        gum style --foreground 196 --bold --margin "1 2" \
            "ERROR (exit=$exit_code) at line $line_no" \
            "$cmd"
        echo ""
        gum input --placeholder "Press Enter to exit..."
    else
        echo -e "${RED}ERROR (exit=$exit_code) at line $line_no${NC}"
        echo -e "${RED}$cmd${NC}"
    fi

    exit "$exit_code"
}

trap 'on_err "$LINENO" "$BASH_COMMAND"' ERR

# ════════════════════════════════════════════════════════════════════════════════
# UTILITY FUNCTIONS
# ════════════════════════════════════════════════════════════════════════════════

check_root() {
    if [[ ${EUID:-0} -ne 0 ]]; then
        echo -e "${RED}Error: This script must be run as root${NC}"
        exit 1
    fi
}

check_uefi() {
    if [[ -d /sys/firmware/efi/efivars ]]; then
        CONFIG[uefi]="yes"
    else
        CONFIG[uefi]="no"
    fi
}

cleanup_disk() {
    local disk="$1"
    
    [[ -z "$disk" ]] && return 0
    [[ ! -b "$disk" ]] && return 0
    
    echo "Cleaning up disk $disk..."
    
    # Unmount all partitions on this disk (including /mnt and subdirs)
    for mount_point in $(mount | grep "^${disk}" | awk '{print $3}' | sort -r); do
        echo "  Unmounting: $mount_point"
        umount -R "$mount_point" 2>/dev/null || umount -l "$mount_point" 2>/dev/null || true
    done
    
    # Also check /mnt specifically
    if mount | grep -q " $MOUNTPOINT "; then
        echo "  Unmounting: $MOUNTPOINT"
        umount -R "$MOUNTPOINT" 2>/dev/null || umount -l "$MOUNTPOINT" 2>/dev/null || true
    fi
    
    # Disable all swap
    swapoff -a 2>/dev/null || true
    
    # Close any cryptsetup/LVM on this disk
    for mapper in /dev/mapper/*; do
        [[ -b "$mapper" ]] && cryptsetup close "$mapper" 2>/dev/null || true
    done
    
    # Remove device mapper entries for this disk
    dmsetup remove_all 2>/dev/null || true
    
    # Kill any processes using the disk
    fuser -km "$disk" 2>/dev/null || true
    
    # Wait for everything to settle
    sleep 2
    sync
    
    # Final cleanup
    wipefs -af "$disk" 2>/dev/null || true
    dd if=/dev/zero of="$disk" bs=1M count=10 conv=notrunc 2>/dev/null || true
    
    # Inform kernel
    blockdev --rereadpt "$disk" 2>/dev/null || true
    partprobe "$disk" 2>/dev/null || true
    udevadm settle
    
    echo "Disk cleanup complete"
    sleep 1
}

# ════════════════════════════════════════════════════════════════════════════════
# GUM UI HELPERS
# ════════════════════════════════════════════════════════════════════════════════

show_header() {
    clear
    gum style \
        --foreground 212 --border-foreground 212 --border double \
        --align center --width 70 --margin "1 2" --padding "1 2" \
        "$SCRIPT_NAME v$VERSION" \
        "" \
        "Baal´s Declarative Arch Linux installation"
}

show_submenu_header() {
    local title="$1"
    gum style \
        --foreground 212 --bold --margin "1 2" \
        "$title"
}

show_info() {
    gum style --foreground 81 --margin "0 2" "$1"
}

show_success() {
    gum style --foreground 82 "  $1"
}

show_error() {
    gum style --foreground 196 "  $1"
}

show_warning() {
    gum style --foreground 214 "  $1"
}

confirm_action() {
    gum confirm --affirmative "Yes" --negative "No" "$1"
}

run_step() {
    local title="$1"
    shift
    show_info "$title"
    "$@"
    show_success "${title%...} - Done"
}

# ════════════════════════════════════════════════════════════════════════════════
# 1. INSTALLER LANGUAGE
# ════════════════════════════════════════════════════════════════════════════════

select_installer_language() {
    show_header
    show_submenu_header "1. Installer Language"
    echo ""
    show_info "Select the language for this installer interface"
    echo ""

    local languages=(
        "English"
        "Deutsch (German)"
    )

    local selection=""
    selection=$(printf '%s\n' "${languages[@]}" | gum choose --height 12 --header "Choose language:") || true

    if [[ -n "$selection" ]]; then
        CONFIG[installer_lang]="$selection"
        show_success "Language set to: $selection"
    fi

    sleep 0.5
}

# ════════════════════════════════════════════════════════════════════════════════
# 2. LOCALES
# ════════════════════════════════════════════════════════════════════════════════

select_locales() {
    show_header
    show_submenu_header "2. System Locales"
    echo ""

    show_info "Select your system locale (language & encoding)"
    echo ""

    local locales=(
        "en_US.UTF-8"
        "en_GB.UTF-8"
        "de_DE.UTF-8"
    )

    local locale_selection=""
    locale_selection=$(printf '%s\n' "${locales[@]}" | gum filter --placeholder "Search locale..." --height 12) || true

    if [[ -n "$locale_selection" ]]; then
        CONFIG[locale]="$locale_selection"
        show_success "System locale: $locale_selection"
    fi

    echo ""
    show_info "Select your keyboard layout"
    echo ""

    local keyboards=(
        "us"
        "de"
    )

    local kb_selection=""
    kb_selection=$(printf '%s\n' "${keyboards[@]}" | gum filter --placeholder "Search keyboard layout..." --height 12) || true

    if [[ -n "$kb_selection" ]]; then
        CONFIG[keyboard]="$kb_selection"
        loadkeys "$kb_selection" 2>/dev/null || true
        show_success "Keyboard layout: $kb_selection"
    fi

    sleep 0.5
}

# ════════════════════════════════════════════════════════════════════════════════
# 3. DISK CONFIGURATION
# ════════════════════════════════════════════════════════════════════════════════

select_disk() {
    show_header
    show_submenu_header "3. Disk Configuration"
    echo ""

    gum style --foreground 196 --bold --margin "0 2" \
        "WARNING: The selected disk will be COMPLETELY ERASED!"
    echo ""

    show_info "Select the target disk for installation"
    echo ""

    local disks=()
    while IFS= read -r line; do
        [[ -n "$line" ]] && disks+=("$line")
    done < <(lsblk -dpno NAME,SIZE,MODEL 2>/dev/null | grep -E '^/dev/(sd|nvme|vd|mmcblk)' | sed 's/  */ /g')

    if [[ ${#disks[@]} -eq 0 ]]; then
        show_error "No suitable disks found!"
        gum input --placeholder "Press Enter to continue..."
        return
    fi

    local disk_selection=""
    disk_selection=$(printf '%s\n' "${disks[@]}" | gum choose --height 10 --header "Available disks:") || true

    if [[ -n "$disk_selection" ]]; then
        CONFIG[disk]=$(echo "$disk_selection" | awk '{print $1}')
        show_success "Selected disk: ${CONFIG[disk]}"

        echo ""
        gum style --foreground 245 --margin "0 2" \
            "$(lsblk "${CONFIG[disk]}" 2>/dev/null)"
    fi

    echo ""
    show_info "Select filesystem type"
    echo ""

    local filesystems=(
        "btrfs    | Btrfs with snapshot support (recommended)"
        "zfs      | ZFS (manual support only)"
    )

    local fs_selection=""
    fs_selection=$(printf '%s\n' "${filesystems[@]}" | gum choose --height 5 --header "Filesystem:") || true

    if [[ -n "$fs_selection" ]]; then
        CONFIG[filesystem]=$(echo "$fs_selection" | awk '{print $1}')
        show_success "Filesystem: ${CONFIG[filesystem]}"

        if [[ "${CONFIG[filesystem]}" == "zfs" ]]; then
            show_warning "ZFS automation is not enabled; you will need to provision ZFS manually."
        fi
    fi

    sleep 0.5
}

# ════════════════════════════════════════════════════════════════════════════════
# 4. SWAP CONFIGURATION
# ════════════════════════════════════════════════════════════════════════════════

configure_swap() {
    show_header
    show_submenu_header "4. Swap Configuration"
    echo ""

    show_info "Select swap type for your system"
    echo ""

    local swap_options=(
        "zram     | Compressed RAM swap (Recommended)"
        "file     | Traditional swap file on disk"
        "none     | No swap"
    )

    local swap_selection=""
    swap_selection=$(printf '%s\n' "${swap_options[@]}" | gum choose --height 5 --header "Swap type:") || true

    if [[ -n "$swap_selection" ]]; then
        CONFIG[swap]=$(echo "$swap_selection" | awk '{print $1}')
        show_success "Swap type: ${CONFIG[swap]}"

        if [[ "${CONFIG[swap]}" == "file" ]]; then
            echo ""
            show_info "Enter swap file size (e.g., 4G, 8G)"
            local swap_size=""
            swap_size=$(gum input --placeholder "4G" --value "${CONFIG[swap_size]}" --width 20) || true
            if [[ -n "$swap_size" ]]; then
                CONFIG[swap_size]="$swap_size"
                show_success "Swap size: ${CONFIG[swap_size]}"
            fi
        fi
    fi

    sleep 0.5
}

# ════════════════════════════════════════════════════════════════════════════════
# 5. HOSTNAME
# ════════════════════════════════════════════════════════════════════════════════

configure_hostname() {
    show_header
    show_submenu_header "5. Hostname"
    echo ""

    show_info "Enter a hostname for your system"
    show_info "(lowercase letters, numbers, and hyphens only)"
    echo ""

    local hostname=""
    hostname=$(gum input --placeholder "donbaal" --value "${CONFIG[hostname]}" --width 40 --header "Hostname:") || true

    if [[ "$hostname" =~ ^[a-z][a-z0-9-]*$ && ${#hostname} -le 63 ]]; then
        CONFIG[hostname]="$hostname"
        show_success "Hostname: ${CONFIG[hostname]}"
    elif [[ -n "$hostname" ]]; then
        show_warning "Invalid hostname, using default: donbaal"
        CONFIG[hostname]="donbaal"
    fi

    sleep 0.5
}

# ════════════════════════════════════════════════════════════════════════════════
# 6. GRAPHICS DRIVER
# ════════════════════════════════════════════════════════════════════════════════

select_graphics_driver() {
    show_header
    show_submenu_header "6. Graphics Driver"
    echo ""

    local is_vm="no"
    if systemd-detect-virt -q 2>/dev/null; then
        is_vm="yes"
        gum style --foreground 82 --margin "0 2" "Virtual Machine detected"
        echo ""
    fi

    show_info "Select the graphics driver for your system"
    echo ""

    local drivers=()
    if [[ "$is_vm" == "yes" ]]; then
        drivers+=("vm                   | Virtual Machine (recommended)")
    fi
    drivers+=(
        "mesa-all             | All open-source drivers (safe default)"
        "intel                | Intel Graphics"
        "amd                  | AMD Graphics"
        "nvidia-turing        | NVIDIA Turing+ (RTX 20/30/40, GTX 1650+)"
        "nvidia-legacy        | NVIDIA Legacy (GTX 900/1000 series)"
        "intel-nvidia-turing  | Intel + NVIDIA Turing+ (Optimus)"
        "intel-nvidia-legacy  | Intel + NVIDIA Legacy (Optimus)"
        "amd-nvidia-turing    | AMD + NVIDIA Turing+ (Hybrid)"
        "amd-nvidia-legacy    | AMD + NVIDIA Legacy (Hybrid)"
    )
    if [[ "$is_vm" != "yes" ]]; then
        drivers+=("vm                   | Virtual Machine")
    fi

    local driver_selection=""
    driver_selection=$(printf '%s\n' "${drivers[@]}" | gum choose --height 12 --header "Graphics driver:") || true

    if [[ -n "$driver_selection" ]]; then
        CONFIG[gfx_driver]=$(echo "$driver_selection" | awk '{print $1}')
        show_success "Graphics driver: ${CONFIG[gfx_driver]}"
    fi

    sleep 0.5
}

# ════════════════════════════════════════════════════════════════════════════════
# 7. AUTHENTICATION
# ════════════════════════════════════════════════════════════════════════════════

configure_authentication() {
    show_header
    show_submenu_header "7. User Account Setup"
    echo ""

    show_info "Create your user account"
    echo ""

    local username=""
    username=$(gum input --placeholder "baal" --value "${CONFIG[username]}" --width 40 --header "Username (lowercase):") || true

    if [[ ! "$username" =~ ^[a-z_][a-z0-9_-]*$ || ${#username} -gt 32 || -z "$username" ]]; then
        show_warning "Invalid username. Using 'user'"
        username="user"
    fi
    CONFIG[username]="$username"
    show_success "Username: ${CONFIG[username]}"

    echo ""

    local user_pass1="" user_pass2=""
    user_pass1=$(gum input --password --placeholder "Password for $username" --width 50) || true
    user_pass2=$(gum input --password --placeholder "Confirm password" --width 50) || true

    if [[ "$user_pass1" == "$user_pass2" && ${#user_pass1} -ge 1 ]]; then
        CONFIG[user_password]="$user_pass1"
        show_success "User password set"
    else
        show_error "Passwords don't match. Please reconfigure."
        sleep 1
        configure_authentication
        return
    fi

    echo ""
    show_submenu_header "Root Password"
    echo ""

    if confirm_action "Use same password for root?"; then
        CONFIG[root_password]="${CONFIG[user_password]}"
        show_success "Root password set (same as user)"
    else
        local root_pass1="" root_pass2=""
        root_pass1=$(gum input --password --placeholder "Root password" --width 50) || true
        root_pass2=$(gum input --password --placeholder "Confirm root password" --width 50) || true

        if [[ "$root_pass1" == "$root_pass2" && -n "$root_pass1" ]]; then
            CONFIG[root_password]="$root_pass1"
            show_success "Root password set"
        else
            show_warning "Passwords don't match. Using user password for root."
            CONFIG[root_password]="${CONFIG[user_password]}"
        fi
    fi

    sleep 0.5
}

# ════════════════════════════════════════════════════════════════════════════════
# 8. TIMEZONE
# ════════════════════════════════════════════════════════════════════════════════

select_timezone() {
    show_header
    show_submenu_header "8. Timezone"
    echo ""

    show_info "Select your timezone"
    echo ""

    local regions=""
    regions=$(find /usr/share/zoneinfo -maxdepth 1 -type d -printf '%f\n' 2>/dev/null | \
              grep -vE '^(\+|posix|right|zoneinfo)$' | sort) || true

    local region=""
    region=$(echo "$regions" | gum filter --placeholder "Search region..." --height 12 --header "Select region:") || true

    if [[ -n "$region" ]]; then
        local cities=""
        cities=$(find "/usr/share/zoneinfo/$region" -type f -printf '%f\n' 2>/dev/null | sort) || true

        if [[ -n "$cities" ]]; then
            echo ""
            local city=""
            city=$(echo "$cities" | gum filter --placeholder "Search city..." --height 12 --header "Select city:") || true

            if [[ -n "$city" ]]; then
                CONFIG[timezone]="$region/$city"
            else
                CONFIG[timezone]="$region"
            fi
        else
            CONFIG[timezone]="$region"
        fi

        show_success "Timezone: ${CONFIG[timezone]}"
    fi

    sleep 0.5
}

# ════════════════════════════════════════════════════════════════════════════════
# 9. DESKTOP ENVIRONMENT
# ════════════════════════════════════════════════════════════════════════════════

select_desktop() {
    show_header
    show_submenu_header "9. Desktop Environment"
    echo ""

    show_info "Select your desktop environment(s) - Use SPACE to select multiple, ENTER to confirm"
    echo ""

    local desktops=(
        "kde-plasma   | KDE Plasma - Full-featured desktop"
        "gnome        | GNOME - Modern GTK desktop"
        "hyprland     | Hyprland - Wayland tiling compositor"
        "niri         | Niri - Scrolling Wayland compositor"
        "i3           | i3 - X11 tiling window manager"
        "xfce         | XFCE - Lightweight GTK desktop"
        "none         | None - TTY only (no desktop)"
    )

    local desktop_selection=""
    desktop_selection=$(printf '%s\n' "${desktops[@]}" | gum choose --no-limit --height 9 --header "Desktop(s):") || true

    if [[ -n "$desktop_selection" ]]; then
        # Convert multi-line selection to comma-separated list
        CONFIG[desktop]=$(echo "$desktop_selection" | awk '{print $1}' | tr '\n' ',' | sed 's/,$//')
        show_success "Desktop(s): ${CONFIG[desktop]}"

        # If no desktop selected or "none" selected, set display manager to none
        if [[ "${CONFIG[desktop]}" == "none" || -z "${CONFIG[desktop]}" ]]; then
            CONFIG[display_manager]="none"
            show_info "Display manager set to: none (TTY only)"
        fi
    fi

    sleep 0.5
}

# ════════════════════════════════════════════════════════════════════════════════
# 10. DISPLAY MANAGER
# ════════════════════════════════════════════════════════════════════════════════

select_display_manager() {
    # Skip if no desktop selected
    if [[ "${CONFIG[desktop]}" == "none" ]]; then
        return
    fi

    show_header
    show_submenu_header "10. Display Manager"
    echo ""

    show_info "Select your display manager (login screen)"
    echo ""

    # Set smart defaults based on desktop(s)
    local recommended=""
    if [[ "${CONFIG[desktop]}" == *"hyprland"* || "${CONFIG[desktop]}" == *"niri"* ]]; then
        recommended="greetd"
    elif [[ "${CONFIG[desktop]}" == *"kde-plasma"* ]]; then
        recommended="sddm"
    elif [[ "${CONFIG[desktop]}" == *"gnome"* ]]; then
        recommended="gdm"
    else
        recommended="ly"
    fi

    local display_managers=(
        "ly           | Minimal TUI greeter (works with all)"
        "sddm         | KDE's display manager"
        "gdm          | GNOME's display manager"
        "lightdm      | Lightweight display manager"
        "greetd       | Wayland-native greeter"
        "none         | No display manager (manual login)"
    )

    # Add recommendation marker
    local dm_with_rec=()
    for dm in "${display_managers[@]}"; do
        local dm_name=$(echo "$dm" | awk '{print $1}')
        if [[ "$dm_name" == "$recommended" ]]; then
            dm_with_rec+=("$dm (Recommended)")
        else
            dm_with_rec+=("$dm")
        fi
    done

    local dm_selection=""
    dm_selection=$(printf '%s\n' "${dm_with_rec[@]}" | gum choose --height 8 --header "Display Manager:") || true

    if [[ -n "$dm_selection" ]]; then
        CONFIG[display_manager]=$(echo "$dm_selection" | awk '{print $1}')
        show_success "Display Manager: ${CONFIG[display_manager]}"
    fi

    sleep 0.5
}

# ════════════════════════════════════════════════════════════════════════════════
# 9. PackageManagement CONFIG FORMAT
# ════════════════════════════════════════════════════════════════════════════════

select_config_format() {
    show_header
    show_submenu_header "9. PackageManagement Configuration"
    echo ""

    show_info "How would you like to configure PackageManagement?"
    echo ""

    local config_options=(
        "generate  | Generate new configuration"
        "clone     | Clone existing configuration from git"
    )

    local config_choice=""
    config_choice=$(printf '%s\n' "${config_options[@]}" | gum choose --height 4 --header "Configuration:") || true

    if [[ -z "$config_choice" ]]; then
        return
    fi

    local choice=$(echo "$config_choice" | awk '{print $1}')

    if [[ "$choice" == "generate" ]]; then
        echo ""
        show_info "Select configuration file format"
        echo ""

        local formats=(
            "lua   | (Advanced) Dynamic configuration with conditionals"
            "yaml  | Simple static configuration"
        )

        local format_selection=""
        format_selection=$(printf '%s\n' "${formats[@]}" | gum choose --height 4 --header "Format:") || true

        if [[ -n "$format_selection" ]]; then
            CONFIG[config_format]=$(echo "$format_selection" | awk '{print $1}')
            show_success "Config format: ${CONFIG[config_format]}"
        fi

        CONFIG[git_repo]=""

    elif [[ "$choice" == "clone" ]]; then
        echo ""
        show_info "Enter the git repository URL for your PackageManagement config"
        echo ""

        local repo_url=""
        repo_url=$(gum input --placeholder "https://github.com/username/arch-config" --width 60) || true

        if [[ -n "$repo_url" ]]; then
            CONFIG[git_repo]="$repo_url"
            show_success "Git repo: ${CONFIG[git_repo]}"
        else
            show_warning "No repo specified, will generate new config"
            CONFIG[git_repo]=""
        fi
    fi

    echo ""
    show_info "Select AUR helper"
    echo ""

    local aur_helpers=(
        "yay   | Yet Another Yogurt - AUR helper (Recommended)"
        "paru  | Feature-rich AUR helper"
    )

    local aur_selection=""
    aur_selection=$(printf '%s\n' "${aur_helpers[@]}" | gum choose --height 4 --header "AUR Helper:") || true

    if [[ -n "$aur_selection" ]]; then
        CONFIG[aur_helper]=$(echo "$aur_selection" | awk '{print $1}')
        show_success "AUR helper: ${CONFIG[aur_helper]}"
    fi

    echo ""
    show_info "Select snapshot/backup tool"
    echo ""

    local backup_tools=(
        "timeshift | Timeshift snapshots"
        "snapper   | Snapper snapshots"
    )

    local backup_selection=""
    backup_selection=$(printf '%s\n' "${backup_tools[@]}" | gum choose --height 4 --header "Backup tool:") || true

    if [[ -n "$backup_selection" ]]; then
        CONFIG[backup_tool]=$(echo "$backup_selection" | awk '{print $1}')
        show_success "Backup tool: ${CONFIG[backup_tool]}"
    fi

    sleep 0.5
}

# ════════════════════════════════════════════════════════════════════════════════
# MAIN MENU
# ════════════════════════════════════════════════════════════════════════════════

show_main_menu() {
    while true; do
        show_header

        local boot_mode="BIOS"
        [[ "${CONFIG[uefi]}" == "yes" ]] && boot_mode="UEFI"

        gum style --foreground 245 --margin "0 2" \
            "Boot Mode: $boot_mode"
        echo ""

        # Build config format string
        local config_display="${CONFIG[config_format]}"
        if [[ -n "${CONFIG[git_repo]}" ]]; then
            config_display="clone from git"
        fi

        local menu_items=(
            ""
            " 1. Installer Language    | ${CONFIG[installer_lang]}"
            " 2. Locales               | ${CONFIG[locale]} / ${CONFIG[keyboard]}"
            " 3. Disk Configuration    | ${CONFIG[disk]:-Not configured}$( [[ -n "${CONFIG[disk]}" ]] && echo " (${CONFIG[filesystem]})" )"
            " 4. Swap                  | ${CONFIG[swap]}"
            " 5. Hostname              | ${CONFIG[hostname]}"
            " 6. Graphics Driver       | ${CONFIG[gfx_driver]}"
            " 7. Authentication        | ${CONFIG[username]:-Not configured}"
            " 8. Timezone              | ${CONFIG[timezone]}"
            " 9. Desktop Environment   | ${CONFIG[desktop]//,/, }"
            "10. Display Manager       | ${CONFIG[display_manager]}"
            "11. PaMa Config Format    | $config_display"
            "-------------------------------------------"
            "12. Start Installation"
            " 0. Exit"
        )

        local selection=""
        selection=$(printf '%s\n' "${menu_items[@]}" | gum choose --height 18 --header $'Configure your installation:\n') || true

        case "$selection" in
            *" 1."*) select_installer_language ;;
            *" 2."*) select_locales ;;
            *" 3."*) select_disk ;;
            *" 4."*) configure_swap ;;
            *" 5."*) configure_hostname ;;
            *" 6."*) select_graphics_driver ;;
            *" 7."*) configure_authentication ;;
            *" 8."*) select_timezone ;;
            *" 9."*) select_desktop_environment ;;
            *"10."*) select_display_manager ;;
            *"11."*) select_config_format ;;
            *"12."*)
                if validate_config; then
                    show_summary
                    if confirm_action "Start installation? THIS WILL ERASE ${CONFIG[disk]}"; then
                        perform_installation
                        break
                    fi
                fi
                ;;
            *"0."*)
                if confirm_action "Exit installer?"; then
                    echo "Installation cancelled."
                    exit 0
                fi
                ;;
        esac
    done
}

# ════════════════════════════════════════════════════════════════════════════════
# VALIDATION
# ════════════════════════════════════════════════════════════════════════════════

validate_config() {
    local errors=()

    [[ -z "${CONFIG[disk]}" ]] && errors+=("Disk not configured")
    [[ -z "${CONFIG[username]}" ]] && errors+=("User account not configured")
    [[ -z "${CONFIG[user_password]}" ]] && errors+=("User password not set")
    [[ -z "${CONFIG[root_password]}" ]] && errors+=("Root password not set")
    [[ "${CONFIG[filesystem]}" == "zfs" ]] && errors+=("ZFS automation not enabled; please select Btrfs")

    if [[ ${#errors[@]} -gt 0 ]]; then
        show_header
        gum style --foreground 196 --bold --margin "1 2" \
            "Configuration Incomplete"
        echo ""
        for error in "${errors[@]}"; do
            show_error "$error"
        done
        echo ""
        gum input --placeholder "Press Enter to continue..."
        return 1
    fi

    return 0
}

# ════════════════════════════════════════════════════════════════════════════════
# SUMMARY
# ════════════════════════════════════════════════════════════════════════════════

show_summary() {
    show_header
    show_submenu_header "Installation Summary"
    echo ""

    local boot_mode="BIOS/Legacy"
    [[ "${CONFIG[uefi]}" == "yes" ]] && boot_mode="UEFI"

    local config_source="Generate new (${CONFIG[config_format]})"
    [[ -n "${CONFIG[git_repo]}" ]] && config_source="Clone from git"

    gum style --border rounded --border-foreground 212 --padding "1 2" --margin "0 2" \
        "Locale:           ${CONFIG[locale]}" \
        "Keyboard:         ${CONFIG[keyboard]}" \
        "Timezone:         ${CONFIG[timezone]}" \
        "Hostname:         ${CONFIG[hostname]}" \
        "" \
        "Username:         ${CONFIG[username]}" \
        "" \
        "Target Disk:      ${CONFIG[disk]}" \
        "Filesystem:       ${CONFIG[filesystem]}" \
        "Swap:             ${CONFIG[swap]}" \
        "" \
        "Graphics:         ${CONFIG[gfx_driver]}" \
        "" \
        "Boot Mode:        $boot_mode" \
        "Bootloader:       GRUB" \
        "" \
        "DCLI Config:      $config_source" \
        "Backups:          ${CONFIG[backup_tool]}" \
        "AUR Helper:       ${CONFIG[aur_helper]}"

    echo ""
    gum style --foreground 196 --bold --margin "0 2" \
        "ALL DATA ON ${CONFIG[disk]} WILL BE PERMANENTLY ERASED!"
    echo ""
}

# ════════════════════════════════════════════════════════════════════════════════
# INSTALLATION
# ════════════════════════════════════════════════════════════════════════════════

perform_installation() {
    show_header
    gum style --foreground 212 --bold --margin "1 2" \
        "Starting Installation..."
    echo ""

    run_step "Partitioning disk..." partition_disk
    run_step "Formatting partitions..." format_partitions
    run_step "Mounting filesystems..." mount_filesystems

    show_info "Installing base system (this may take a while)..."
    install_base_system
    show_success "Base system installed"

    run_step "Configuring system..." configure_system
    run_step "Creating user account..." create_user

    show_info "Installing critical packages..."
    install_critical_packages
    show_success "Critical packages installed"

    run_step "Installing bootloader..." install_bootloader

    show_info "Setting up DCLI..."
    setup_dcli
    show_success "DCLI configured"

    run_step "Creating first-boot service..." create_first_boot_service

    echo ""
    gum style --foreground 82 --bold --border double --border-foreground 82 \
        --align center --width 60 --margin "1 2" --padding "1 2" \
        "Installation Complete!" \
        "" \
        "Your system is ready to boot." \
        "" \
        "On first boot, DCLI will automatically run:" \
        "  - dcli sync" \
        "  - dcli merge --services" \
        "  - dcli merge --defaults" \
        "" \
        "Remove the installation media and reboot:" \
        "  umount -R /mnt && reboot"
    echo ""
}

# ════════════════════════════════════════════════════════════════════════════════
# DISK OPERATIONS
# ════════════════════════════════════════════════════════════════════════════════

partition_disk() {
    local disk="${CONFIG[disk]}"

    [[ -n "$disk" ]] || { echo "ERROR: CONFIG[disk] is empty"; exit 1; }

    # Comprehensive cleanup before partitioning
    cleanup_disk "$disk"

    if [[ "${CONFIG[uefi]}" == "yes" ]]; then
        parted -s "$disk" mklabel gpt
        parted -s "$disk" mkpart ESP fat32 1MiB 513MiB
        parted -s "$disk" set 1 esp on
        parted -s "$disk" mkpart primary 513MiB 100%
    else
        parted -s "$disk" mklabel msdos
        parted -s "$disk" mkpart primary ext4 1MiB 513MiB
        parted -s "$disk" set 1 boot on
        parted -s "$disk" mkpart primary 513MiB 100%
    fi

    partprobe "$disk" || true
    udevadm settle
    sleep 1

    if [[ "$disk" == *"nvme"* || "$disk" == *"mmcblk"* ]]; then
        CONFIG[boot_part]="${disk}p1"
        CONFIG[root_part]="${disk}p2"
    else
        CONFIG[boot_part]="${disk}1"
        CONFIG[root_part]="${disk}2"
    fi

    # Validate partitions exist
    if [[ ! -b "${CONFIG[boot_part]}" || ! -b "${CONFIG[root_part]}" ]]; then
        echo "ERROR: Partitions not ready after partitioning."
        lsblk -f "$disk" || true
        exit 1
    fi
}

format_partitions() {
    local root_device="${CONFIG[root_part]}"

    [[ -b "${CONFIG[boot_part]}" ]] || { echo "ERROR: boot_part not a block device"; exit 1; }
    [[ -b "$root_device" ]] || { echo "ERROR: root device not a block device"; exit 1; }

    # Format boot partition
    if [[ "${CONFIG[uefi]}" == "yes" ]]; then
        wipefs -af "${CONFIG[boot_part]}" &>/dev/null
        mkfs.fat -F32 "${CONFIG[boot_part]}"
    else
        wipefs -af "${CONFIG[boot_part]}" &>/dev/null
        mkfs.ext4 -F "${CONFIG[boot_part]}"
    fi

    # Format root partition
    wipefs -af "$root_device" &>/dev/null
    case "${CONFIG[filesystem]}" in
        btrfs)
            mkfs.btrfs -f "$root_device" ;;
        zfs)
            echo "ZFS filesystem automation not enabled; please provision ZFS manually after install." ;;
        *)
            echo "ERROR: Unknown filesystem"; exit 1 ;;
    esac
}

mount_filesystems() {
    local root_device="${CONFIG[root_part]}"

    if [[ "${CONFIG[filesystem]}" == "btrfs" ]]; then
        mount "$root_device" "$MOUNTPOINT"
        btrfs subvolume create "$MOUNTPOINT/@"
        btrfs subvolume create "$MOUNTPOINT/@home"
        btrfs subvolume create "$MOUNTPOINT/@var"
        btrfs subvolume create "$MOUNTPOINT/@tmp"
        btrfs subvolume create "$MOUNTPOINT/@snapshots"
        umount "$MOUNTPOINT"

        mount -o noatime,compress=zstd,subvol=@ "$root_device" "$MOUNTPOINT"
        mkdir -p "$MOUNTPOINT"/{home,var,tmp,.snapshots,boot}
        mount -o noatime,compress=zstd,subvol=@home "$root_device" "$MOUNTPOINT/home"
        mount -o noatime,compress=zstd,subvol=@var "$root_device" "$MOUNTPOINT/var"
        mount -o noatime,compress=zstd,subvol=@tmp "$root_device" "$MOUNTPOINT/tmp"
        mount -o noatime,compress=zstd,subvol=@snapshots "$root_device" "$MOUNTPOINT/.snapshots"
    else
        mount "$root_device" "$MOUNTPOINT"
        mkdir -p "$MOUNTPOINT/boot"
    fi

    if [[ "${CONFIG[uefi]}" == "yes" ]]; then
        mkdir -p "$MOUNTPOINT/boot/efi"
        mount "${CONFIG[boot_part]}" "$MOUNTPOINT/boot/efi"
    else
        mount "${CONFIG[boot_part]}" "$MOUNTPOINT/boot"
    fi
}

# ════════════════════════════════════════════════════════════════════════════════
# SYSTEM INSTALLATION
# ════════════════════════════════════════════════════════════════════════════════

install_base_system() {
    local packages="base linux linux-firmware sudo networkmanager git base-devel"

    # Add CPU microcode
    if grep -q "GenuineIntel" /proc/cpuinfo; then
        packages+=" intel-ucode"
    elif grep -q "AuthenticAMD" /proc/cpuinfo; then
        packages+=" amd-ucode"
    fi

    # Enable multilib repository in the TARGET system BEFORE pacstrap
    show_info "Enabling multilib repository for 32-bit support..."
    
    # Create pacman.conf with multilib enabled
    mkdir -p "$MOUNTPOINT/etc"
    cp /etc/pacman.conf "$MOUNTPOINT/etc/pacman.conf"
    
    # Uncomment [multilib] section
    sed -i '/^#\[multilib\]/s/^#//' "$MOUNTPOINT/etc/pacman.conf"
    sed -i '/^\[multilib\]/,/^Include/ s/^#//' "$MOUNTPOINT/etc/pacman.conf"
    
    show_success "Multilib repository enabled"

    pacstrap -K "$MOUNTPOINT" $packages
    genfstab -U "$MOUNTPOINT" >> "$MOUNTPOINT/etc/fstab"
}

configure_system() {
    # Timezone
    arch-chroot "$MOUNTPOINT" ln -sf "/usr/share/zoneinfo/${CONFIG[timezone]}" /etc/localtime
    arch-chroot "$MOUNTPOINT" hwclock --systohc

    # Locale
    echo "${CONFIG[locale]} UTF-8" >> "$MOUNTPOINT/etc/locale.gen"
    echo "en_US.UTF-8 UTF-8" >> "$MOUNTPOINT/etc/locale.gen"
    arch-chroot "$MOUNTPOINT" locale-gen
    echo "LANG=${CONFIG[locale]}" > "$MOUNTPOINT/etc/locale.conf"

    # Keyboard
    echo "KEYMAP=${CONFIG[keyboard]}" > "$MOUNTPOINT/etc/vconsole.conf"

    # Hostname
    echo "${CONFIG[hostname]}" > "$MOUNTPOINT/etc/hostname"
    cat > "$MOUNTPOINT/etc/hosts" << EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   ${CONFIG[hostname]}.localdomain ${CONFIG[hostname]}
EOF

    # Enable NetworkManager
    arch-chroot "$MOUNTPOINT" systemctl enable NetworkManager
}

create_user() {
    # Set root password
    echo "root:${CONFIG[root_password]}" | arch-chroot "$MOUNTPOINT" chpasswd

    # Create user
    arch-chroot "$MOUNTPOINT" useradd -m -G wheel,audio,video,storage,optical -s /bin/bash "${CONFIG[username]}"
    echo "${CONFIG[username]}:${CONFIG[user_password]}" | arch-chroot "$MOUNTPOINT" chpasswd

    # Enable sudo for wheel group
    sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' "$MOUNTPOINT/etc/sudoers"
}

# ════════════════════════════════════════════════════════════════════════════════
# CRITICAL PACKAGES (installed directly, not via dcli)
# ════════════════════════════════════════════════════════════════════════════════

install_critical_packages() {
    local packages=""

    # Base utilities
    packages+=" vim nano"

    # Bootloader
    packages+=" grub efibootmgr os-prober"

    # Filesystem tools
    case "${CONFIG[filesystem]}" in
        btrfs) packages+=" btrfs-progs grub-btrfs" ;;
        ext4)  packages+=" e2fsprogs" ;;
        xfs)   packages+=" xfsprogs" ;;
    esac

    # Audio (pipewire)
    packages+=" pipewire wireplumber pipewire-pulse pipewire-alsa pipewire-jack"

    # GPU drivers
    case "${CONFIG[gfx_driver]}" in
        intel)
            packages+=" mesa vulkan-intel intel-media-driver lib32-mesa lib32-vulkan-intel"
            ;;
        amd)
            packages+=" mesa vulkan-radeon libva-mesa-driver lib32-mesa lib32-vulkan-radeon"
            ;;
        nvidia-turing)
            packages+=" nvidia-open-dkms nvidia-utils nvidia-settings lib32-nvidia-utils"
            ;;
        nvidia-legacy)
            packages+=" nvidia-dkms nvidia-utils nvidia-settings lib32-nvidia-utils"
            ;;
        intel-nvidia-turing)
            packages+=" mesa vulkan-intel intel-media-driver nvidia-open-dkms nvidia-utils nvidia-settings lib32-nvidia-utils"
            ;;
        intel-nvidia-legacy)
            packages+=" mesa vulkan-intel intel-media-driver nvidia-dkms nvidia-utils nvidia-settings lib32-nvidia-utils"
            ;;
        amd-nvidia-turing)
            packages+=" mesa vulkan-radeon libva-mesa-driver nvidia-open-dkms nvidia-utils nvidia-settings lib32-nvidia-utils"
            ;;
        amd-nvidia-legacy)
            packages+=" mesa vulkan-radeon libva-mesa-driver nvidia-dkms nvidia-utils nvidia-settings lib32-nvidia-utils"
            ;;
        vm)
            packages+=" mesa xf86-video-qxl spice-vdagent"
            ;;
        mesa-all|*)
            packages+=" mesa vulkan-radeon vulkan-intel lib32-mesa"
            ;;
    esac

    # Desktop environment(s) - support multiple selections
    IFS=',' read -ra DESKTOPS <<< "${CONFIG[desktop]}"
    for desktop in "${DESKTOPS[@]}"; do
        case "$desktop" in
            kde-plasma)
                packages+=" plasma-meta kde-applications-meta konsole dolphin"
                ;;
            gnome)
                packages+=" gnome gnome-extra gnome-tweaks"
                ;;
            hyprland)
                packages+=" hyprland xdg-desktop-portal-hyprland waybar wofi dunst foot thunar"
                ;;
            niri)
                packages+=" niri xdg-desktop-portal-gtk xdg-desktop-portal-gnome waybar fuzzel rofi-wayland mako foot alacritty thunar udiskie xwayland-satellite"
                ;;
            i3)
                packages+=" i3-wm i3status i3lock dmenu xorg-server xorg-xinit alacritty thunar picom"
                ;;
            xfce)
                packages+=" xfce4 xfce4-goodies xorg-server xorg-xinit"
                ;;
            none)
                packages+=" tmux htop"
                ;;
        esac
    done

    # Display manager
    case "${CONFIG[display_manager]}" in
        ly)
            packages+=" ly"
            ;;
        sddm)
            packages+=" sddm"
            ;;
        gdm)
            packages+=" gdm"
            ;;
        lightdm)
            packages+=" lightdm lightdm-gtk-greeter"
            ;;
        greetd)
            packages+=" greetd greetd-tuigreet"
            ;;
    esac

    # Backup tool
    case "${CONFIG[backup_tool]}" in
        snapper)   packages+=" snapper" ;;
        timeshift) packages+=" timeshift" ;;
    esac

    # Swap
    if [[ "${CONFIG[swap]}" == "zram" ]]; then
        packages+=" zram-generator"
    fi

    # Multilib was already enabled during base system installation
    # Just update package database for lib32 packages
    if echo "$packages" | grep -q "lib32-"; then
        show_info "Updating package database for 32-bit packages..."
        arch-chroot "$MOUNTPOINT" pacman -Sy --noconfirm || {
            show_warning "Failed to update database, removing lib32 packages..."
            packages=$(echo "$packages" | sed 's/lib32-[^ ]*//g')
        }
    fi

    # Install packages
    show_info "Installing packages..."
    arch-chroot "$MOUNTPOINT" pacman -S --noconfirm $packages

    # Enable display manager (best effort)
    if [[ "${CONFIG[display_manager]}" != "none" ]]; then
        if ! arch-chroot "$MOUNTPOINT" systemctl enable "${CONFIG[display_manager]}"; then
            show_warning "Display manager enable failed: ${CONFIG[display_manager]} (continuing)"
        fi
    fi

    # Configure zram
    if [[ "${CONFIG[swap]}" == "zram" ]]; then
        cat > "$MOUNTPOINT/etc/systemd/zram-generator.conf" << EOF
[zram0]
zram-size = ram / 2
compression-algorithm = zstd
EOF
    fi

    # Create swapfile if selected
    if [[ "${CONFIG[swap]}" == "file" ]]; then
        local swap_size="${CONFIG[swap_size]}"
        arch-chroot "$MOUNTPOINT" dd if=/dev/zero of=/swapfile bs=1M count="${swap_size%G}000" status=progress
        arch-chroot "$MOUNTPOINT" chmod 600 /swapfile
        arch-chroot "$MOUNTPOINT" mkswap /swapfile
        echo "/swapfile none swap defaults 0 0" >> "$MOUNTPOINT/etc/fstab"
    fi
}

install_bootloader() {
    if [[ "${CONFIG[uefi]}" == "yes" ]]; then
        mkdir -p "$MOUNTPOINT/boot/efi"

        arch-chroot "$MOUNTPOINT" grub-install \
            --target=x86_64-efi \
            --efi-directory=/boot/efi \
            --bootloader-id=GRUB \
            --removable \
            --recheck
    else
        arch-chroot "$MOUNTPOINT" grub-install --target=i386-pc "${CONFIG[disk]}"
    fi

    # Configure GRUB
    sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT="quiet loglevel=3"/' \
        "$MOUNTPOINT/etc/default/grub"

    # Configure grub-btrfs for snapshot boot entries (btrfs only)
    if [[ "${CONFIG[filesystem]}" == "btrfs" ]]; then
        # Configure grub-btrfs for timeshift if using timeshift
        if [[ "${CONFIG[backup_tool]}" == "timeshift" ]]; then
            sed -i 's|^#GRUB_BTRFS_TIMESHIFT_AUTO=.*|GRUB_BTRFS_TIMESHIFT_AUTO="true"|' \
                "$MOUNTPOINT/etc/default/grub-btrfs/config"
        fi

        # Enable grub-btrfsd to auto-regenerate grub menu on snapshot changes
        arch-chroot "$MOUNTPOINT" systemctl enable grub-btrfsd.service || true
    fi

    arch-chroot "$MOUNTPOINT" grub-mkconfig -o /boot/grub/grub.cfg
}

# ════════════════════════════════════════════════════════════════════════════════
# DCLI SETUP
# ════════════════════════════════════════════════════════════════════════════════

setup_dcli() {
    local user_home="$MOUNTPOINT/home/${CONFIG[username]}"
    local config_dir="$user_home/.config/arch-config"
    local chroot_config_dir="/home/${CONFIG[username]}/.config/arch-config"

    # Install AUR helper
    install_aur_helper

    # Install dcli
    arch-chroot "$MOUNTPOINT" sudo -u "${CONFIG[username]}" "${CONFIG[aur_helper]}" -S --noconfirm dcli

    # Setup config directory
    if [[ -n "${CONFIG[git_repo]}" ]]; then
        # Clone existing config
        arch-chroot "$MOUNTPOINT" sudo -u "${CONFIG[username]}" mkdir -p "$(dirname "$chroot_config_dir")"
        arch-chroot "$MOUNTPOINT" sudo -u "${CONFIG[username]}" git config --global user.name "${CONFIG[username]}"
        arch-chroot "$MOUNTPOINT" sudo -u "${CONFIG[username]}" git config --global user.email "${CONFIG[username]}@localhost"
        arch-chroot "$MOUNTPOINT" sudo -u "${CONFIG[username]}" git clone "${CONFIG[git_repo]}" "$chroot_config_dir"
    else
        # Generate new config
        generate_dcli_config
    fi

}

install_aur_helper() {
    local helper="${CONFIG[aur_helper]}"
    local user_home="$MOUNTPOINT/home/${CONFIG[username]}"
    local build_dir="$user_home/aur-build/${helper}"

    # Prepare build dir owned by user
    arch-chroot "$MOUNTPOINT" mkdir -p "/home/${CONFIG[username]}/aur-build/${helper}"
    arch-chroot "$MOUNTPOINT" chown -R "${CONFIG[username]}:${CONFIG[username]}" "/home/${CONFIG[username]}/aur-build"

    # Clone AUR helper
    arch-chroot "$MOUNTPOINT" sudo -u "${CONFIG[username]}" git clone "https://aur.archlinux.org/${helper}.git" "/home/${CONFIG[username]}/aur-build/${helper}"

    # Build and install
    arch-chroot "$MOUNTPOINT" bash -c "cd /home/${CONFIG[username]}/aur-build/${helper} && sudo -u ${CONFIG[username]} makepkg -si --noconfirm"

    # Cleanup
    arch-chroot "$MOUNTPOINT" rm -rf "/home/${CONFIG[username]}/aur-build"
}

generate_dcli_config() {
    local user_home="$MOUNTPOINT/home/${CONFIG[username]}"
    local config_dir="$user_home/.config/arch-config"
    local format="${CONFIG[config_format]}"

    mkdir -p "$config_dir"/{hosts,modules}

    # Copy only the modules needed for this host to avoid duplicates/unused modules
    local modules_to_copy=(
        "modules/base-system.lua"
        "modules/filesystem/${CONFIG[filesystem]}.lua"
        "modules/bootloader/grub.lua"
        "modules/networking.lua"
        "modules/audio-pipewire.lua"
    )

    if [[ "${CONFIG[swap]}" != "none" ]]; then
        modules_to_copy+=("modules/swap/${CONFIG[swap]}.lua")
    fi

    modules_to_copy+=("modules/gpu/${CONFIG[gfx_driver]}.lua")

    # Copy all selected desktop modules
    if [[ "${CONFIG[desktop]}" != "none" ]]; then
        IFS=',' read -ra DESKTOPS <<< "${CONFIG[desktop]}"
        for desktop in "${DESKTOPS[@]}"; do
            modules_to_copy+=("modules/desktops/${desktop}.lua")
        done
    fi

    if [[ "${CONFIG[display_manager]}" != "none" ]]; then
        modules_to_copy+=("modules/display-managers/${CONFIG[display_manager]}.lua")
    fi

    for rel in "${modules_to_copy[@]}"; do
        local src="$SCRIPT_DIR/$rel"
        local dest="$config_dir/$rel"
        mkdir -p "$(dirname "$dest")"
        cp "$src" "$dest"
    done

    # Generate main config file
    if [[ "$format" == "lua" ]]; then
        generate_lua_config "$config_dir"
    else
        generate_yaml_config "$config_dir"
    fi

    # Set ownership
    arch-chroot "$MOUNTPOINT" chown -R "${CONFIG[username]}:${CONFIG[username]}" "/home/${CONFIG[username]}/.config/arch-config"
}

generate_lua_config() {
    local config_dir="$1"
    local hostname="${CONFIG[hostname]}"

    local enabled_modules=(
        "base-system"
        "filesystem/${CONFIG[filesystem]}"
        "bootloader/grub"
        "networking"
        "audio-pipewire"
        "gpu/${CONFIG[gfx_driver]}"
    )

    if [[ "${CONFIG[swap]}" != "none" ]]; then
        enabled_modules+=("swap/${CONFIG[swap]}")
    fi

    if [[ "${CONFIG[desktop]}" != "none" ]]; then
        enabled_modules+=("desktops/${CONFIG[desktop]}")
    fi

    if [[ "${CONFIG[display_manager]}" != "none" ]]; then
        enabled_modules+=("display-managers/${CONFIG[display_manager]}")
    fi

    local enabled_modules_block
    enabled_modules_block=$(printf '        "%s",\n' "${enabled_modules[@]}")

    local dm_service_block=""
    if [[ "${CONFIG[display_manager]}" != "none" ]]; then
        dm_service_block="            \"${CONFIG[display_manager]}\","$'\n'
    fi

    # Create config.lua
    cat > "$config_dir/config.lua" << EOF
return {
    host = "$hostname",
}
EOF

    # Create host file
    cat > "$config_dir/hosts/${hostname}.lua" << EOF
-- Generated by dcli-arch-installer
-- Host: $hostname

return {
    host = "$hostname",
    description = "Generated by dcli-arch-installer",

    enabled_modules = {
$enabled_modules_block
    },

    packages = {},
    exclude = {},

    services = {
        enabled = {
            "NetworkManager",
$dm_service_block        },
        disabled = {},
    },

    flatpak_scope = "user",
    aur_helper = "${CONFIG[aur_helper]}",

    config_backups = {
        enabled = true,
        max_backups = 5,
    },
}
EOF
}

generate_yaml_config() {
    local config_dir="$1"
    local hostname="${CONFIG[hostname]}"

    local enabled_modules=(
        "base-system"
        "filesystem/${CONFIG[filesystem]}"
        "bootloader/grub"
        "networking"
        "audio-pipewire"
        "gpu/${CONFIG[gfx_driver]}"
    )

    if [[ "${CONFIG[swap]}" != "none" ]]; then
        enabled_modules+=("swap/${CONFIG[swap]}")
    fi

    if [[ "${CONFIG[desktop]}" != "none" ]]; then
        enabled_modules+=("desktops/${CONFIG[desktop]}")
    fi

    if [[ "${CONFIG[display_manager]}" != "none" ]]; then
        enabled_modules+=("display-managers/${CONFIG[display_manager]}")
    fi

    local enabled_modules_block
    enabled_modules_block=$(printf '  - %s\n' "${enabled_modules[@]}")

    local dm_service_block=""
    if [[ "${CONFIG[display_manager]}" != "none" ]]; then
        dm_service_block="    - ${CONFIG[display_manager]}"$'\n'
    fi

    # Create config.yaml
    cat > "$config_dir/config.yaml" << EOF
host: $hostname
EOF

    # Create host file
    cat > "$config_dir/hosts/${hostname}.yaml" << EOF
# Generated by dcli-arch-installer
# Host: $hostname

host: $hostname
description: Generated by dcli-arch-installer

enabled_modules:
$enabled_modules_block

packages: []
exclude: []

services:
  enabled:
    - NetworkManager
$dm_service_block  disabled: []

flatpak_scope: user
aur_helper: ${CONFIG[aur_helper]}

config_backups:
  enabled: true
  max_backups: 5
EOF
}

# ════════════════════════════════════════════════════════════════════════════════
# FIRST BOOT SERVICE
# ════════════════════════════════════════════════════════════════════════════════

create_first_boot_service() {
    local username="${CONFIG[username]}"

    # Create the first-boot script
    cat > "$MOUNTPOINT/usr/local/bin/dcli-first-boot.sh" << 'SCRIPT'
#!/bin/bash
#
# DCLI First Boot Configuration
# This script runs once on first boot to complete DCLI setup
#

set -e

LOG_FILE="/var/log/dcli-first-boot.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "=========================================="
echo "DCLI First Boot Configuration"
echo "Started at: $(date)"
echo "=========================================="

# Wait for network
echo "Waiting for network..."
sleep 10

# Get the main user (first user in /home)
MAIN_USER=$(ls /home | head -n1)

if [[ -z "$MAIN_USER" ]]; then
    echo "ERROR: No user found in /home"
    exit 1
fi

echo "Running DCLI commands as user: $MAIN_USER"

CONFIG_DIR="/home/$MAIN_USER/.config/arch-config"
HOSTNAME=$(cat /etc/hostname 2>/dev/null || hostnamectl hostname 2>/dev/null || echo "localhost")

# Function to detect config format from hosts directory
detect_config_format() {
    if [[ -d "$CONFIG_DIR/hosts" ]]; then
        if ls "$CONFIG_DIR/hosts"/*.lua &>/dev/null; then
            echo "lua"
        elif ls "$CONFIG_DIR/hosts"/*.yaml &>/dev/null; then
            echo "yaml"
        else
            echo "lua"  # Default to lua
        fi
    else
        echo "lua"  # Default to lua
    fi
}

# Function to create config.lua pointing to a host
create_lua_config() {
    local host="$1"
    cat > "$CONFIG_DIR/config.lua" << EOF
return {
    host = "$host",
}
EOF
    chown "$MAIN_USER:$MAIN_USER" "$CONFIG_DIR/config.lua"
    echo "Created config.lua pointing to host: $host"
}

# Function to create config.yaml pointing to a host
create_yaml_config() {
    local host="$1"
    cat > "$CONFIG_DIR/config.yaml" << EOF
host: $host
EOF
    chown "$MAIN_USER:$MAIN_USER" "$CONFIG_DIR/config.yaml"
    echo "Created config.yaml pointing to host: $host"
}

# Function to create a minimal host.lua file
create_lua_host() {
    local host="$1"
    mkdir -p "$CONFIG_DIR/hosts"
    cat > "$CONFIG_DIR/hosts/${host}.lua" << EOF
-- Generated by dcli-first-boot for new host
-- Host: $host

return {
    host = "$host",
    description = "Auto-generated host configuration",

    enabled_modules = {},

    packages = {},
    exclude = {},

    services = {
        enabled = {
            "NetworkManager",
        },
        disabled = {},
    },

    flatpak_scope = "user",

    config_backups = {
        enabled = true,
        max_backups = 5,
    },
}
EOF
    chown "$MAIN_USER:$MAIN_USER" "$CONFIG_DIR/hosts/${host}.lua"
    echo "Created new host file: hosts/${host}.lua"
}

# Function to create a minimal host.yaml file
create_yaml_host() {
    local host="$1"
    mkdir -p "$CONFIG_DIR/hosts"
    cat > "$CONFIG_DIR/hosts/${host}.yaml" << EOF
# Generated by dcli-first-boot for new host
# Host: $host

host: $host
description: Auto-generated host configuration

enabled_modules: []

packages: []
exclude: []

services:
  enabled:
    - NetworkManager
  disabled: []

flatpak_scope: user

config_backups:
  enabled: true
  max_backups: 5
EOF
    chown "$MAIN_USER:$MAIN_USER" "$CONFIG_DIR/hosts/${host}.yaml"
    echo "Created new host file: hosts/${host}.yaml"
}

# Check if config.lua or config.yaml exists
echo ""
echo "Checking for DCLI configuration..."

if [[ -f "$CONFIG_DIR/config.lua" ]] || [[ -f "$CONFIG_DIR/config.yaml" ]]; then
    echo "Configuration file found, proceeding with sync..."
else
    echo "No config.lua or config.yaml found in cloned repository"
    echo "Hostname: $HOSTNAME"

    # Detect format from existing host files
    FORMAT=$(detect_config_format)
    echo "Detected config format: $FORMAT"

    # Check if a host file exists for this hostname
    if [[ "$FORMAT" == "lua" ]]; then
        if [[ -f "$CONFIG_DIR/hosts/${HOSTNAME}.lua" ]]; then
            echo "Found matching host file: hosts/${HOSTNAME}.lua"
            create_lua_config "$HOSTNAME"
        else
            echo "No matching host file found for hostname: $HOSTNAME"
            echo "Creating new host configuration..."
            create_lua_host "$HOSTNAME"
            create_lua_config "$HOSTNAME"
        fi
    else
        if [[ -f "$CONFIG_DIR/hosts/${HOSTNAME}.yaml" ]]; then
            echo "Found matching host file: hosts/${HOSTNAME}.yaml"
            create_yaml_config "$HOSTNAME"
        else
            echo "No matching host file found for hostname: $HOSTNAME"
            echo "Creating new host configuration..."
            create_yaml_host "$HOSTNAME"
            create_yaml_config "$HOSTNAME"
        fi
    fi

    # Ensure proper ownership
    chown -R "$MAIN_USER:$MAIN_USER" "$CONFIG_DIR"
fi

# Run dcli validate to verify config is correct
echo ""
echo "Running: dcli validate"
sudo -u "$MAIN_USER" dcli validate || {
    echo "WARNING: dcli validate had issues - check your configuration"
}

echo ""
echo "Configuration is ready. Run 'dcli sync' when you're ready to install packages."

echo ""
echo "=========================================="
echo "DCLI First Boot Configuration Complete"
echo "Finished at: $(date)"
echo "=========================================="

# Self-destruct
echo "Cleaning up first-boot service..."
systemctl disable dcli-first-boot.service
rm -f /etc/systemd/system/dcli-first-boot.service
rm -f /usr/local/bin/dcli-first-boot.sh

echo "First boot setup complete!"
SCRIPT

    chmod +x "$MOUNTPOINT/usr/local/bin/dcli-first-boot.sh"

    # Create the systemd service
    cat > "$MOUNTPOINT/etc/systemd/system/dcli-first-boot.service" << EOF
[Unit]
Description=DCLI First Boot Configuration
After=network-online.target
Wants=network-online.target
ConditionPathExists=/usr/local/bin/dcli-first-boot.sh

[Service]
Type=oneshot
ExecStart=/usr/local/bin/dcli-first-boot.sh
RemainAfterExit=yes
StandardOutput=journal+console
StandardError=journal+console

[Install]
WantedBy=multi-user.target
EOF

    # Enable the service
    arch-chroot "$MOUNTPOINT" systemctl enable dcli-first-boot.service
}

# ════════════════════════════════════════════════════════════════════════════════
# MAIN
# ════════════════════════════════════════════════════════════════════════════════

main() {
    check_root
    check_uefi
    show_main_menu
}

main "$@"
