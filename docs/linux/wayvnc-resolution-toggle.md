# wayvnc Resolution Toggle Guide

## Problem
When connecting from a MacBook (e.g., 2560x1600) to Omarchy with an ultrawide monitor (e.g., 2560x1080 or 5120x1440), the remote desktop appears tiny and unusable.

## Solution: Resolution Toggle Script

Run these commands on Omarchy to create the script:

```bash
# Create the toggle script
cat > ~/toggle-resolution.sh << 'SCRIPT'
#!/bin/bash
MONITOR="DP-3"  # Change this to match your monitor name (run 'hyprctl monitors')
CURRENT=$(hyprctl monitors | awk -v mon="$MONITOR" '
    $2 == mon {getline; print $1}')

if [[ "$CURRENT" == *"5120x1440"* ]] || [[ "$CURRENT" == *"2560x1080"* ]]; then
    echo "Switching to MacBook-friendly resolution (1920x1080@60)..."
    hyprctl keyword monitor "$MONITOR,1920x1080@60,0x0,1"
elif [[ "$CURRENT" == *"1920x1080"* ]]; then
    echo "Switching back to original resolution..."
    hyprctl keyword monitor "$MONITOR,original,0x0,1"
else
    echo "Unknown current mode: $CURRENT"
fi
SCRIPT

# Make it executable
chmod +x ~/toggle-resolution.sh

# Add Hyprland keybinding (optional)
echo 'bindd = SUPER SHIFT, R, exec, ~/toggle-resolution.sh' >> ~/.config/hypr/bindings.conf

# Reload Hyprland config
hyprctl reload
```

## Usage

Before connecting from your Mac:
```bash
./toggle-resolution.sh
```

Or use the hotkey: **Super+Shift+R**

After connecting and finishing, switch back:
```bash
./toggle-resolution.sh
```

## Find Your Monitor Name

Run on Omarchy:
```bash
hyprctl monitors
```

Look for the monitor name (e.g., `DP-3`, `HDMI-A-1`, `eDP-1` for laptops) and update the script.
