-- KDE Plasma Desktop
-- Full-featured Qt-based desktop environment

return {
    description = "KDE Plasma Desktop",
    
    packages = {
        -- Core Plasma
        "plasma-meta",
        
        -- KDE Applications
        "kde-applications-meta",
        
        -- Essential apps
        "konsole",
        "dolphin",
        "ark",
        "spectacle",
        "kate",
        "gwenview",
        "okular",
        
        -- KDE integration
        "kde-gtk-config",
        "breeze-gtk",
        "xdg-desktop-portal-kde",
        
        -- Xorg (for X11 sessions)
        "xorg-server",
        "xorg-xinit",
        "xorg-xrandr",
    },
    
    services = {
        enabled = {},
        disabled = {},
    },
}
