#!/usr/bin/env bash
# Enable Ly display manager

set -euo pipefail

if [ "$EUID" -ne 0 ]; then
  echo "Error: this script must be run as root (sudo)." >&2
  exit 1
fi

echo "Enabling Ly display manager..."

# Disable other common display managers if enabled
for dm in gdm sddm lightdm; do
  if systemctl is-enabled "${dm}.service" &>/dev/null; then
    echo "Disabling ${dm}.service"
    systemctl disable "${dm}.service"
  fi
done

# Enable Ly
if systemctl is-enabled ly.service &>/dev/null; then
  echo "Ly is already enabled"
else
  systemctl enable --now ly.service
  echo "Ly enabled"
fi

echo "Ly setup complete."
