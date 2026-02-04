-- Audio stack using PipeWire
-- Modern audio server replacing PulseAudio/JACK

return {
    description = "PipeWire audio stack",
    
    packages = {
        -- Core PipeWire
        "pipewire",
        "wireplumber",
        
        -- Compatibility layers
        "pipewire-pulse",
        "pipewire-alsa",
        "pipewire-jack",
        
        -- ALSA utilities
        "alsa-utils",
        "alsa-plugins",
        "alsa-firmware",
        
        -- Audio control
        "pavucontrol",
        
        -- Codecs
        "gst-plugins-base",
        "gst-plugins-good",
        "gst-plugins-bad",
        "gst-plugins-ugly",
        "gst-libav",
    },
    
    services = {
        enabled = {},
        disabled = {},
    },
}
