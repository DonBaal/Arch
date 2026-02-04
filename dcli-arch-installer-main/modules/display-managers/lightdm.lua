-- LightDM Display Manager
-- Lightweight display manager

return {
    description = "LightDM - Lightweight display manager",
    
    packages = {
        "lightdm",
        "lightdm-gtk-greeter",
        "lightdm-gtk-greeter-settings",
    },
    
    services = {
        enabled = {
            "lightdm",
        },
        disabled = {},
    },
}
