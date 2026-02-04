-- BTRFS filesystem support
-- Modern copy-on-write filesystem with snapshots

return {
    description = "BTRFS filesystem tools and utilities",
    
    packages = {
        "btrfs-progs",
        "snapper",
        "snap-pac",
        "grub-btrfs",
    },
    
    services = {
        enabled = {
            "snapper-timeline.timer",
            "snapper-cleanup.timer",
        },
        disabled = {},
    },
}
