#!/usr/bin/env bash
# Installs the copy command (c) into ~/.local/bin

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="$HOME/.local/bin"
BIN_NAME="c"

mkdir -p "$TARGET_DIR"

for name in "$BIN_NAME" copy-clip; do
    link="$TARGET_DIR/$name"
    if [ -e "$link" ] || [ -L "$link" ]; then
        if [ ! -L "$link" ] || [ "$(readlink -- "$link")" != "$SCRIPT_DIR/copy.sh" ]; then
            echo "[!] Cannot install: $link already exists and is not this project's link." >&2
            exit 1
        fi
    fi
done

chmod +x "$SCRIPT_DIR/copy.sh"

for name in "$BIN_NAME" copy-clip; do
    link="$TARGET_DIR/$name"
    if [ ! -L "$link" ]; then
        ln -s "$SCRIPT_DIR/copy.sh" "$link"
    fi
done

echo "✅ Installed successfully!"
echo "Commands available in $TARGET_DIR:"
echo "  • $BIN_NAME"
echo "  • copy-clip"

if ! command -v wl-copy >/dev/null 2>&1 &&
   ! command -v xsel >/dev/null 2>&1 &&
   ! command -v xclip >/dev/null 2>&1 &&
   ! command -v pbcopy >/dev/null 2>&1; then
    echo ""
    echo "⚠️  No clipboard tool found. Install wl-clipboard (Wayland), xsel or xclip (X11)."
fi

case ":$PATH:" in
    *":$TARGET_DIR:"*) ;;
    *)
        echo ""
        echo "⚠️  '$TARGET_DIR' is not in your PATH. Add this to your ~/.bashrc or ~/.zshrc:"
        echo "    export PATH=\"\$HOME/.local/bin:\$PATH\""
        ;;
esac
