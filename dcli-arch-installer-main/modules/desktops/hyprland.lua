-- Hyprland
-- Dynamic tiling Wayland compositor

return {
    description = "Hyprland - Wayland tiling compositor",
    
    packages = {
        -- Core
        "hyprland",
        "xdg-desktop-portal-hyprland",
        
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
        
        -- Qt Wayland
        "qt5-wayland",
        "qt6-wayland",
    },
    
    services = {
        enabled = {},
        disabled = {},
    },
}
