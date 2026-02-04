-- ly Display Manager
-- Minimal TUI display manager

return {
    description = "ly - Minimal TUI display manager",
    
    packages = {
        "ly",
    },
    
    services = {
        enabled = {
            "ly",
        },
        disabled = {},
    },
}
