# DonArch Configurations - Integriert

## ✅ Was wurde gemacht

Die DonArch Konfigurationen sind jetzt **direkt im dcli-arch-installer** integriert!

### Struktur:

```
dcli-arch-installer-main/
├── configs/                          ← NEU!
│   ├── assets/                       ← Von donarch-master
│   ├── hyprland/
│   │   ├── hypr/                     ← Hyprland configs
│   │   └── DankMaterialShell/
│   ├── niri/
│   │   ├── niri/                     ← Niri configs
│   │   └── DankMaterialShell/
│   └── shared/                       ← Gemeinsame configs
│       ├── kitty/
│       ├── fish/
│       ├── gtk-3.0/
│       ├── gtk-4.0/
│       ├── fastfetch/
│       ├── noctalia/
│       ├── qt5ct/
│       ├── qt6ct/
│       └── DankMaterialShell/
├── dcli-install.sh                   ← Angepasst
├── copy-configs.ps1                  ← Hilfsskript
└── ...
```

## 🔄 Configs aktualisieren

Wenn du die Configs aus donarch-master aktualisieren möchtest:

```powershell
# In PowerShell (Windows):
cd c:\Code\Arch\dcli-arch-installer-main
.\copy-configs.ps1
```

```bash
# In Bash (Linux/Arch ISO):
cd /path/to/dcli-arch-installer-main
# Manuell kopieren oder copy-configs.ps1 zu bash konvertieren
```

## 📦 Installation

### Auf USB vorbereiten:

Jetzt musst du **NUR** den `dcli-arch-installer-main` Ordner auf dein Installationsmedium kopieren - donarch-master wird nicht mehr benötigt!

```
USB:\
└── dcli-arch-installer-main\    ← Alles drin!
    ├── configs\                 ← Configs bereits dabei
    ├── modules\
    └── dcli-install.sh
```

### Im Arch ISO:

```bash
mount /dev/sdX1 /mnt/usb
cd /mnt/usb/dcli-arch-installer-main
sudo bash dcli-install.sh
```

Die Configs werden automatisch nach:
- `/home/username/.config/hypr/`
- `/home/username/.config/niri/`
- `/home/username/.config/DankMaterialShell/`
- und weitere shared configs...

kopiert!

## ✨ Vorteile

1. ✅ **Keine externe Abhängigkeit** mehr zu donarch-master während Installation
2. ✅ **Alle Configs direkt dabei** - funktioniert auch ohne Internet
3. ✅ **Template-Variablen werden automatisch ersetzt**
4. ✅ **Fehlerhafte Pfade werden automatisch gefixt**
5. ✅ **Einfacher zu distribuieren** - nur ein Verzeichnis benötigt

## 🔧 Was das Installerskript macht

Das `deploy_donarch_configs()` im dcli-install.sh:

1. Liest Configs aus `$SCRIPT_DIR/configs` (lokal!)
2. Kopiert sie nach `/mnt/home/username/.config/`
3. Ersetzt Template-Variablen:
   - `{{SHELL_NAME}}` → `DankMaterialShell`
   - `{{LAUNCH_CMD}}` → `ags`
   - `{{LAUNCHER_CMD}}` → `wofi --show drun`
4. Kommentiert fehlerhafte Pfade aus (z.B. Ax-Shell Referenzen)
5. Setzt korrekte Berechtigungen

## 🎯 Nächste Schritte

Die Installation sollte jetzt vollständig funktionieren mit allen Hyprland/Niri Configs! 🎉
