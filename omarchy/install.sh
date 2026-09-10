#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MENU_FILE="$HOME/.config/omarchy/extensions/omarchy-menu.jsonc"

mkdir -p "$HOME/.local/bin"
cp "$REPO_DIR/nimbus-feeder" "$HOME/.local/bin/nimbus-feeder"
chmod +x "$HOME/.local/bin/nimbus-feeder"
echo "installed ~/.local/bin/nimbus-feeder"

mkdir -p "$(dirname "$MENU_FILE")"
touch "$MENU_FILE"

python3 - "$MENU_FILE" "$REPO_DIR/omarchy/menu-entry.jsonc" <<'PYEOF'
import sys

menu_path, entry_path = sys.argv[1], sys.argv[2]

with open(entry_path, encoding="utf-8") as f:
    entry = f.read().rstrip("\n")

with open(menu_path, encoding="utf-8") as f:
    content = f.read()

if not content.strip():
    content = "{\n}\n"

if '"nimbus":' in content:
    print("menu entry already present, skipping")
else:
    idx = content.rstrip().rfind("}")
    content = content[:idx] + "\n" + entry + "\n" + content[idx:]
    with open(menu_path, "w", encoding="utf-8") as f:
        f.write(content)
    print(f"added Nimbus entry to {menu_path}")
PYEOF

echo "done. Find it in the Omarchy menu under 'Nimbus Gamepad'."
