-- GRUB bootloader
-- GNU GRand Unified Bootloader

return {
    description = "GRUB bootloader",
    
    packages = {
        "grub",
        "efibootmgr",
        "os-prober",
    },
    
    services = {
        enabled = {},
        disabled = {},
    },
}
