-- i3 Window Manager
-- Tiling window manager for X11

return {
    description = "i3 - X11 tiling window manager",
    
    packages = {
        -- Core
        "i3-wm",
        "i3status",
        "i3lock",
        "i3blocks",
        
        -- Xorg
        "xorg-server",
        "xorg-xinit",
        "xorg-xrandr",
        "xorg-xsetroot",
        
        -- Launcher
        "dmenu",
        "rofi",
        
        -- Terminal
        "alacritty",
        "xterm",
        
        -- File manager
        "thunar",
        "thunar-volman",
        "gvfs",
        
        -- Compositor
        "picom",
        
        -- Notifications
        "dunst",
        "libnotify",
        
        -- Wallpaper
        "feh",
        "nitrogen",
        
        -- Screenshot
        "scrot",
        "xclip",
        
        -- Polkit
        "polkit-gnome",
        
        -- Network manager applet
        "network-manager-applet",
        
        -- Audio control
        "volumeicon",
    },
    
    services = {
        enabled = {},
        disabled = {},
    },
}
