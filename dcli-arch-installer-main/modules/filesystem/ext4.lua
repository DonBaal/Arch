-- EXT4 filesystem support
-- Traditional reliable Linux filesystem

return {
    description = "EXT4 filesystem tools",
    
    packages = {
        "e2fsprogs",
    },
    
    services = {
        enabled = {},
        disabled = {},
    },
}
