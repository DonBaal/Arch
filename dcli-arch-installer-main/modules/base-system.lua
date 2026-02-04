-- Base system packages and services
-- Core packages required for any Arch Linux installation

return {
    description = "Base system packages and core utilities",

    packages = {
        -- Core system
        "base",
        "base-devel",
        "linux",
        "linux-firmware",
        "linux-headers",

        -- System utilities
        "sudo",
        "git",
        "wget",
        "curl",
        "nano",
        "helix",
        "vim",
        "htop",
        "gum",

        -- Filesystem utilities
        "dosfstools",
        "gptfdisk",
        "parted",

        -- Archive utilities
        "unzip",
        "zip",
        "p7zip",
        "unrar",

        -- Man pages
        "man-db",
        "man-pages",
        "texinfo",
    },

    services = {
        enabled = {},
        disabled = {},
    },
}
