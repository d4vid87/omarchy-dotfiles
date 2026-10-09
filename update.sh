#!/usr/bin/env bash
set -euo pipefail

repo=$(cd -- "$(dirname -- "$0")" && pwd)
rsync -a --exclude='*.bak*' --exclude='*backup*' --exclude='.git' "$HOME/.config/hypr" "$HOME/.config/alacritty" "$HOME/.config/ghostty" "$HOME/.config/kitty" "$HOME/.config/voxtype" "$repo/config/.config/"
mkdir -p "$repo/config/.config/systemd/user"
rsync -a "$HOME/.config/systemd/user/voxtype.service" "$repo/config/.config/systemd/user/"
rsync -a --delete --delete-excluded --exclude='.claude' --exclude='*.bak*' --exclude='*backup*' --exclude='.git' "$HOME/.config/omarchy/" "$repo/config/.config/omarchy/"
mkdir -p "$repo/state/current"
rsync -a --delete "$HOME/.local/state/omarchy/current/" "$repo/state/current/"
for link in "$repo/config/.config/omarchy/lock-videos/"*.mp4; do
  [[ -L "$link" ]] && ln -sfn "../plugins/io.github.sirjul1337.lock-explorer/videos/$(basename "$link")" "$link"
done
cp "$HOME/.config/starship.toml" "$repo/config/.config/starship.toml"
mkdir -p "$repo/assets/cursors" "$repo/wallpapers"
if [[ -d "$HOME/.local/share/icons/Bibata-Modern-Ice-Right" ]]; then
  rsync -a --delete "$HOME/.local/share/icons/Bibata-Modern-Ice-Right/" "$repo/assets/cursors/Bibata-Modern-Ice-Right/"
fi
if [[ -d "$HOME/Wallpapers" ]]; then
  rsync -a --delete "$HOME/Wallpapers/" "$repo/wallpapers/"
fi
pacman -Qqen > "$repo/packages/official.txt"
pacman -Qqem > "$repo/packages/foreign.txt"
printf 'Backup refreshed; review with: git -C %q diff\n' "$repo"
