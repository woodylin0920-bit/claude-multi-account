#!/usr/bin/env bash
set -e

DEST="$HOME/.config/claude-multi-account"
ZSHRC="$HOME/.zshrc"
LINE="source \"$DEST/claude-multi-account.zsh\""

echo "Installing claude-multi-account..."

# 複製 .zsh 到 ~/.config/claude-multi-account/
mkdir -p "$DEST"
cp claude-multi-account.zsh "$DEST/"
echo "  ✅ Copied to $DEST/claude-multi-account.zsh"

# 在 ~/.zshrc 加 source 行（避免重複加）
if grep -qF "$LINE" "$ZSHRC" 2>/dev/null; then
  echo "  ℹ️  Already sourced in $ZSHRC"
else
  echo "" >> "$ZSHRC"
  echo "$LINE" >> "$ZSHRC"
  echo "  ✅ Added source line to $ZSHRC"
fi

echo ""
echo "Done! Next steps:"
echo "  1. Edit $DEST/claude-multi-account.zsh"
echo "     → Uncomment the alias lines for your accounts"
echo "  2. Run: source ~/.zshrc"
echo "  3. Run: claude-help  (to verify)"
