-- XFCE Desktop
-- Lightweight GTK-based desktop environment

return {
    description = "XFCE - Lightweight GTK desktop",
    
    packages = {
        -- Core XFCE
        "xfce4",
        "xfce4-goodies",
        
        -- Xorg
        "xorg-server",
        "xorg-xinit",
        
        -- File manager extras
        "gvfs",
        "gvfs-smb",
        "gvfs-mtp",
        
        -- Themes
        "arc-gtk-theme",
        "papirus-icon-theme",
        
        -- Polkit
        "polkit-gnome",
        
        -- Network manager applet
        "network-manager-applet",
        
        -- Portal
        "xdg-desktop-portal-gtk",
    },
    
    services = {
        enabled = {},
        disabled = {},
    },
}
