-- SDDM Display Manager
-- KDE's display manager

return {
    description = "SDDM - KDE display manager",
    
    packages = {
        "sddm",
        "sddm-kcm",
    },
    
    services = {
        enabled = {
            "sddm",
        },
        disabled = {},
    },
}
