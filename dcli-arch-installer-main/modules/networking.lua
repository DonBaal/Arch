-- Networking packages and services
-- Network management, WiFi, Bluetooth, and related tools

return {
    description = "Network management and connectivity",
    
    packages = {
        -- Network management
        "networkmanager",
        "network-manager-applet",
        
        -- WiFi tools
        "iwd",
        "wpa_supplicant",
        "wireless_tools",
        "wireless-regdb",
        
        -- DHCP
        "dhcpcd",
        
        -- DNS utilities
        "bind",
        "ldns",
        
        -- SSH
        "openssh",
        
        -- Bluetooth
        "bluez",
        "bluez-utils",
        "bluez-tools",
        
        -- Misc networking
        "nmap",
        "traceroute",
        "net-tools",
    },
    
    services = {
        enabled = {
            "NetworkManager",
            "bluetooth",
        },
        disabled = {},
    },
}
