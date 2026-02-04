-- AMD + NVIDIA Turing+ hybrid
-- For systems with AMD iGPU and NVIDIA dGPU (Turing+)

return {
    description = "AMD + NVIDIA Turing+ (Hybrid)",
    
    packages = {
        -- AMD
        "mesa",
        "lib32-mesa",
        "vulkan-radeon",
        "lib32-vulkan-radeon",
        "libva-mesa-driver",
        
        -- NVIDIA
        "nvidia-open-dkms",
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
