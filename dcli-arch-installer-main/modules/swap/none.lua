-- No swap configuration
-- System runs without swap space

return {
    description = "No swap",
    
    packages = {},
    
    services = {
        enabled = {},
        disabled = {},
    },
}
