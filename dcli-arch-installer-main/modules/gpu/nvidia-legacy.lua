-- NVIDIA Legacy drivers (GTX 900/1000 series)
-- Proprietary drivers for older NVIDIA GPUs

return {
    description = "NVIDIA drivers (Legacy: GTX 900/1000 series)",
    
    packages = {
        "nvidia-dkms",
        "nvidia-utils",
        "lib32-nvidia-utils",
        "nvidia-settings",
        "opencl-nvidia",
        "lib32-opencl-nvidia",
        "libvdpau",
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
