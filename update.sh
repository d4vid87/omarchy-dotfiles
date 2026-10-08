#!/usr/bin/env bash
set -euo pipefail

repo=$(cd -- "$(dirname -- "$0")" && pwd)
rsync -a --exclude='*.bak*' --exclude='*backup*' --exclude='.git' "$HOME/.config/hypr" "$HOME/.config/alacritty" "$HOME/.config/ghostty" "$HOME/.config/kitty" "$repo/config/.config/"
rsync -a --delete --delete-excluded --exclude='.claude' --exclude='*.bak*' --exclude='*backup*' --exclude='.git' --exclude='plugins/akitaonrails.ai-usagebar' --exclude='plugins/io.github.sirjul1337.lock-explorer' --exclude='plugins/bobbynicholas.omaland' --exclude='plugins/com.omastorm.radar' --exclude='plugins/io.github.deunnis.lacquer' --exclude='plugins/omaplug' "$HOME/.config/omarchy/" "$repo/config/.config/omarchy/"
mkdir -p "$repo/state/current"
rsync -a --delete "$HOME/.local/state/omarchy/current/" "$repo/state/current/"
for link in "$repo/config/.config/omarchy/lock-videos/"*.mp4; do
  [[ -L "$link" ]] && ln -sfn "../plugins/io.github.sirjul1337.lock-explorer/videos/$(basename "$link")" "$link"
done
cp "$HOME/.config/starship.toml" "$repo/config/.config/starship.toml"
pacman -Qqen > "$repo/packages/official.txt"
pacman -Qqem > "$repo/packages/foreign.txt"
printf 'Backup refreshed; review with: git -C %q diff\n' "$repo"
