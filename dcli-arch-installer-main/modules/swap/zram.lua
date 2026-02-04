-- ZRAM compressed swap
-- Compressed RAM-based swap using zram-generator

return {
    description = "ZRAM compressed swap",
    
    packages = {
        "zram-generator",
    },
    
    services = {
        enabled = {},
        disabled = {},
    },
}
