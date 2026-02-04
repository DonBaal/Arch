-- Intel Graphics drivers
-- Open-source drivers for Intel integrated GPUs

return {
    description = "Intel Graphics drivers",
    
    packages = {
        "mesa",
        "lib32-mesa",
        "vulkan-intel",
        "lib32-vulkan-intel",
        "intel-media-driver",
        "libva-intel-driver",
        "intel-gpu-tools",
    },
    
    services = {
        enabled = {},
        disabled = {},
    },
}
