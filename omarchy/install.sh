#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PLUGIN_DIR="$HOME/.config/omarchy/plugins/reloadedhead.nimbus"
UDEV_RULE="/etc/udev/rules.d/99-nimbus.rules"

mkdir -p "$HOME/.local/bin"
cp "$REPO_DIR/bin/nimbus-feeder" "$HOME/.local/bin/nimbus-feeder"
chmod +x "$HOME/.local/bin/nimbus-feeder"
echo "installed ~/.local/bin/nimbus-feeder"

# Mirror the whole repo into the plugin dir (minus git internals) so it
# matches exactly what the Omarchy marketplace's `git clone` produces —
# the bar-widget's "Fix permissions" button expects bin/ and udev/
# alongside manifest.json regardless of which install path was used.
mkdir -p "$PLUGIN_DIR"
tar -C "$REPO_DIR" --exclude=.git -cf - . | tar -C "$PLUGIN_DIR" -xf -
echo "installed bar-widget plugin to $PLUGIN_DIR"

if [ ! -f "$UDEV_RULE" ] || ! diff -q "$REPO_DIR/udev/99-nimbus.rules" "$UDEV_RULE" >/dev/null 2>&1; then
    sudo "$REPO_DIR/bin/nimbus-setup-udev" "$REPO_DIR/udev/99-nimbus.rules" "$USER"
    echo "installed $UDEV_RULE and added $USER to the input group"
    echo "log out and back in for the group change to take effect"
else
    echo "udev rule already up to date"
fi

echo "done. Add 'Nimbus Gamepad' to the bar with: omarchy bar put reloadedhead.nimbus"
