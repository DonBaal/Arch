-- Virtual Machine graphics
-- Drivers for VirtualBox, VMware, QEMU/KVM

return {
    description = "Virtual Machine graphics drivers",
    
    packages = {
        "mesa",
        "lib32-mesa",
        "xf86-video-qxl",
        "xf86-video-vmware",
        "spice-vdagent",
        "open-vm-tools",
    },
    
    services = {
        enabled = {
            "spice-vdagentd",
        },
        disabled = {},
    },
}
