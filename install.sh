#!/usr/bin/env bash
# Script de instalação do comando copy (c) em ~/.local/bin

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="$HOME/.local/bin"
BIN_NAME="c"

mkdir -p "$TARGET_DIR"

chmod +x "$SCRIPT_DIR/copy.sh"

ln -sf "$SCRIPT_DIR/copy.sh" "$TARGET_DIR/$BIN_NAME"
ln -sf "$SCRIPT_DIR/copy.sh" "$TARGET_DIR/copy-clip"

echo "✅ Instalado com sucesso!"
echo "Comandos disponíveis em $TARGET_DIR:"
echo "  • $BIN_NAME"
echo "  • copy-clip"
echo ""
echo "Certifique-se de que '$TARGET_DIR' esteja no seu PATH."
