#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PLUGIN_DIR="$HOME/.config/omarchy/plugins/reloadedhead.nimbus"
UDEV_RULE="/etc/udev/rules.d/99-nimbus.rules"

mkdir -p "$HOME/.local/bin"
cp "$REPO_DIR/bin/nimbus-feeder" "$HOME/.local/bin/nimbus-feeder"
chmod +x "$HOME/.local/bin/nimbus-feeder"
echo "installed ~/.local/bin/nimbus-feeder"

mkdir -p "$PLUGIN_DIR"
cp "$REPO_DIR/manifest.json" "$REPO_DIR/Panel.qml" "$PLUGIN_DIR/"
echo "installed bar-widget plugin to $PLUGIN_DIR"

if [ ! -f "$UDEV_RULE" ] || ! diff -q "$REPO_DIR/udev/99-nimbus.rules" "$UDEV_RULE" >/dev/null 2>&1; then
    sudo install -m 0644 "$REPO_DIR/udev/99-nimbus.rules" "$UDEV_RULE"
    sudo udevadm control --reload-rules
    sudo usermod -aG input "$USER"
    echo "installed $UDEV_RULE and added $USER to the input group"
    echo "log out and back in for the group change to take effect"
else
    echo "udev rule already up to date"
fi

echo "done. Add 'Nimbus Gamepad' to the bar with: omarchy bar put reloadedhead.nimbus"
