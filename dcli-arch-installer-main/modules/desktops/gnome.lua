-- GNOME Desktop
-- Modern GTK-based desktop environment

return {
    description = "GNOME Desktop",
    
    packages = {
        -- Core GNOME
        "gnome",
        "gnome-extra",
        
        -- Tweaks and extensions
        "gnome-tweaks",
        "gnome-shell-extensions",
        "dconf-editor",
        
        -- GTK themes
        "adwaita-icon-theme",
        
        -- Portal
        "xdg-desktop-portal-gnome",
        
        -- Xorg (for X11 fallback)
        "xorg-server",
        "xorg-xinit",
    },
    
    services = {
        enabled = {},
        disabled = {},
    },
}
