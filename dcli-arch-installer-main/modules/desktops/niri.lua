-- Niri
-- Scrollable-tiling Wayland compositor

return {
    description = "Niri - Scrolling Wayland compositor",

    packages = {
        -- Core
        "niri",

        -- XDG portals
        "xdg-desktop-portal-gtk",
        "xdg-desktop-portal-gnome",

        -- Status bar
        "waybar",

        -- Launcher
        "fuzzel",

        -- Notifications
        "mako",
        "libnotify",

        -- Terminal
        "alacritty",
        "foot",
        "kitty",

        -- File manager
        "thunar",
        "thunar-volman",
        "gvfs",
        "udiskie",

        -- Screenshot/recording
        "grim",
        "slurp",
        "wl-clipboard",
        "satty",

        -- Wallpaper
        "swaybg",

        -- Screen lock
        "swaylock",
        "swayidle",

        -- Polkit
        "polkit-gnome",

        -- Network manager applet
        "network-manager-applet",
        
        -- Brightness control
        "brightnessctl",
        
        -- Clipboard management
        "cliphist",

        -- X11 support
        "xwayland-satellite",

        -- Qt Wayland
        "qt5-wayland",
        "qt6-wayland",
    },
    
    aur_packages = {
        "wl-clip-persist",
        "sway-audio-idle-inhibit-git",
    },

    services = {
        enabled = {},
        disabled = {},
    },
}
