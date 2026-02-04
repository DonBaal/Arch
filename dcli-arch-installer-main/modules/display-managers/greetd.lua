-- greetd Display Manager
-- Wayland-native login manager

return {
    description = "greetd - Wayland-native greeter",
    
    packages = {
        "greetd",
        "greetd-tuigreet",
    },
    
    services = {
        enabled = {
            "greetd",
        },
        disabled = {},
    },
}
