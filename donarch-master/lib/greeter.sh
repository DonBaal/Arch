#!/usr/bin/env bash
# DMS-greeter (greetd) setup functions for donarch installer
# Adapted from enable-dms-greeter.sh

# Source utils for logging
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

# Disable conflicting display managers
disable_other_display_managers() {
    log_info "Checking for conflicting display managers..."

    local disabled_any=false
    for dm in gdm sddm lightdm lxdm; do
        if systemctl is-enabled "${dm}.service" &>/dev/null; then
            log_warn "Disabling ${dm} display manager..."
            sudo systemctl disable "${dm}.service"
            disabled_any=true
        fi
    done

    if [ "$disabled_any" = false ]; then
        log_info "No conflicting display managers found"
    else
        log_success "Conflicting display managers disabled"
    fi
}

# Enable greetd service
enable_greetd() {
    log_info "Enabling greetd service..."

    if systemctl is-enabled greetd.service &>/dev/null; then
        log_info "greetd is already enabled"
    else
        sudo systemctl enable greetd.service
        log_success "greetd service enabled"
    fi
}

# Configure greetd to use DMS-greeter
configure_greetd() {
    local install_hyprland="$1"
    local install_niri="$2"

    log_info "Configuring greetd to use DMS-greeter..."

    sudo mkdir -p /etc/greetd

    # Determine default session command based on what's installed
    local default_command=""
    if [ "$install_hyprland" = "true" ]; then
        default_command="hyprland"
    elif [ "$install_niri" = "true" ]; then
        default_command="niri-session"
    fi

    # Create greetd config with dms-greeter
    sudo tee /etc/greetd/config.toml > /dev/null << EOFGREETD
[terminal]
vt = 1

[default_session]
command = "dms-greeter --command ${default_command}"
user = "greeter"
EOFGREETD

    log_success "greetd configuration created"
}

# Create Wayland session desktop files
create_session_files() {
    local install_hyprland="$1"
    local install_niri="$2"

    log_info "Creating Wayland session files..."

    sudo mkdir -p /usr/share/wayland-sessions

    # Create Hyprland session file
    if [ "$install_hyprland" = "true" ]; then
        sudo tee /usr/share/wayland-sessions/hyprland-dms.desktop > /dev/null << 'EOFHYPR'
[Desktop Entry]
Name=Hyprland (DMS)
Comment=Hyprland with DankMaterialShell
Exec=Hyprland
Type=Application
EOFHYPR
        log_success "Hyprland session file created"
    fi

    # Create Niri session file
    if [ "$install_niri" = "true" ]; then
        sudo tee /usr/share/wayland-sessions/niri-dms.desktop > /dev/null << 'EOFNIRI'
[Desktop Entry]
Name=Niri (DMS)
Comment=Niri with DankMaterialShell
Exec=niri-session
Type=Application
EOFNIRI
        log_success "Niri session file created"
    fi
}

# Main greeter setup function
setup_greeter() {
    local install_hyprland="$1"
    local install_niri="$2"

    log_step "Setting Up DMS-Greeter Display Manager"

    log_info "This step requires sudo privileges to configure the display manager"
    echo ""

    disable_other_display_managers
    enable_greetd
    configure_greetd "$install_hyprland" "$install_niri"
    create_session_files "$install_hyprland" "$install_niri"

    echo ""
    log_success "DMS-Greeter setup complete!"
    echo ""
    log_info "Session selection:"
    [ "$install_hyprland" = "true" ] && echo "  • Hyprland (DMS) - Available at login"
    [ "$install_niri" = "true" ] && echo "  • Niri (DMS) - Available at login"
    echo ""
    log_warn "You will need to reboot to use the new display manager"
}
