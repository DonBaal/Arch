-- No Desktop (TTY only)
-- Minimal system with terminal utilities

return {
    description = "No desktop - TTY only",

    packages = {
        -- Terminal utilities
        "tmux",
        "htop",
        "fastfetch",

        -- Text editors
        "nano",
        "vim",

        -- File management
        "mc",
        "yazi",
        "tree",

        -- System monitoring
        "iotop",
        "iftop",
    },

    services = {
        enabled = {},
        disabled = {},
    },
}
