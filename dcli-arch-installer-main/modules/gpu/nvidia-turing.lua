-- NVIDIA Turing+ drivers (RTX 20/30/40 series, GTX 1650+)
-- Open kernel module for modern NVIDIA GPUs

return {
    description = "NVIDIA drivers (Turing+: RTX 20/30/40, GTX 1650+)",
    
    packages = {
        "nvidia-open-dkms",
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
