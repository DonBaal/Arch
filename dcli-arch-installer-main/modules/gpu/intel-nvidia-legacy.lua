-- Intel + NVIDIA Legacy hybrid (Optimus laptops)
-- For systems with Intel iGPU and NVIDIA dGPU (Legacy)

return {
    description = "Intel + NVIDIA Legacy (Optimus)",
    
    packages = {
        -- Intel
        "mesa",
        "lib32-mesa",
        "vulkan-intel",
        "lib32-vulkan-intel",
        "intel-media-driver",
        
        -- NVIDIA
        "nvidia-dkms",
        "nvidia-utils",
        "lib32-nvidia-utils",
        "nvidia-settings",
        "nvidia-prime",
        "egl-wayland",
    },
    
    services = {
        enabled = {
            "nvidia-suspend",
            "nvidia-resume",
            "nvidia-hibernate",
        },
        disabled = {},
    },
}
