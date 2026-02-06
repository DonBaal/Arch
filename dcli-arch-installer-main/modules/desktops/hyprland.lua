-- Hyprland
-- Dynamic tiling Wayland compositor

return {
    description = "Hyprland - Wayland tiling compositor",
    
    packages = {
        -- Core
        "hyprland",
        "hypridle",
        "xdg-desktop-portal-hyprland",
        "xdg-desktop-portal-gtk",
        
        -- Status bar
        "waybar",
        
        -- Launcher
        "wofi",
        "rofi-wayland",
        
        -- Notifications
        "dunst",
        "libnotify",
        
        -- Terminal
        "foot",
        "kitty",
        
        -- File manager
        "thunar",
        "thunar-volman",
        "gvfs",
        
        -- Screenshot/recording
        "grim",
        "slurp",
        "wl-clipboard",
        
        -- Wallpaper
        "swww",
        "swaybg",
        
        -- Screen lock
        "swaylock",
        "swayidle",
        
        -- Polkit
        "polkit-gnome",
        
        -- Network manager applet
        "network-manager-applet",
        
        -- Display management
        "nwg-displays",
        
        -- Brightness & Audio control
        "brightnessctl",
        "pavucontrol",
        
        -- Qt Wayland
        "qt5-wayland",
        "qt6-wayland",
    },
    
    aur_packages = {
        "grimblast-git",
    },
    
    services = {
        enabled = {},
        disabled = {},
    },
}
