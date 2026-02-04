-- GDM Display Manager
-- GNOME's display manager

return {
    description = "GDM - GNOME display manager",
    
    packages = {
        "gdm",
    },
    
    services = {
        enabled = {
            "gdm",
        },
        disabled = {},
    },
}
