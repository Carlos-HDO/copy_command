#!/usr/bin/env bash
# Removes the copy command (c) symlinks created by install.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="$HOME/.local/bin"

removed=0
for name in c copy-clip; do
    link="$TARGET_DIR/$name"
    if [ -L "$link" ] && [ "$(readlink -- "$link")" = "$SCRIPT_DIR/copy.sh" ]; then
        rm -f -- "$link"
        echo "🗑️  Removed $link"
        removed=$((removed+1))
    elif [ -e "$link" ] || [ -L "$link" ]; then
        echo "⚠️  Skipped $link: it does not point to $SCRIPT_DIR/copy.sh"
    fi
done

if [ $removed -eq 0 ]; then
    echo "Nothing to remove."
else
    echo "✅ Uninstalled successfully!"
fi
