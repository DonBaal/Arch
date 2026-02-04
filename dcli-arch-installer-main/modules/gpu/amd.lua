-- AMD Graphics drivers
-- Open-source drivers for AMD/ATI GPUs

return {
    description = "AMD Graphics drivers",
    
    packages = {
        "mesa",
        "lib32-mesa",
        "vulkan-radeon",
        "lib32-vulkan-radeon",
        "libva-mesa-driver",
        "lib32-libva-mesa-driver",
        "mesa-vdpau",
        "lib32-mesa-vdpau",
        "xf86-video-amdgpu",
    },
    
    services = {
        enabled = {},
        disabled = {},
    },
}
