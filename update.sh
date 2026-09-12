#!/usr/bin/env bash
set -euo pipefail

repo=$(cd -- "$(dirname -- "$0")" && pwd)
rsync -a --exclude='*.bak*' "$HOME/.config/hypr" "$HOME/.config/alacritty" "$HOME/.config/ghostty" "$HOME/.config/kitty" "$repo/config/.config/"
rsync -a --delete --exclude='*.bak*' --exclude='plugins/akitaonrails.ai-usagebar' --exclude='plugins/io.github.sirjul1337.lock-explorer' "$HOME/.config/omarchy/" "$repo/config/.config/omarchy/"
cp "$HOME/.config/starship.toml" "$repo/config/.config/starship.toml"
pacman -Qqen > "$repo/packages/official.txt"
pacman -Qqem > "$repo/packages/foreign.txt"
printf 'Backup refreshed; review with: git -C %q diff\n' "$repo"
