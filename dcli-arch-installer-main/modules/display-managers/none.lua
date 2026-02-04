-- No Display Manager
-- Manual login via TTY

return {
    description = "No display manager - manual TTY login",
    
    packages = {},
    
    services = {
        enabled = {},
        disabled = {},
    },
}
