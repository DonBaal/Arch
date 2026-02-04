-- Mesa all open-source drivers
-- Safe default with all open-source GPU drivers

return {
    description = "All open-source GPU drivers (Mesa)",
    
    packages = {
        "mesa",
        "lib32-mesa",
        "vulkan-radeon",
        "lib32-vulkan-radeon",
        "vulkan-intel",
        "lib32-vulkan-intel",
        "libva-mesa-driver",
        "lib32-libva-mesa-driver",
        "mesa-vdpau",
        "lib32-mesa-vdpau",
    },
    
    services = {
        enabled = {},
        disabled = {},
    },
}
