#!/usr/bin/env bash
set -euo pipefail

repo=$(cd -- "$(dirname -- "$0")" && pwd)
backup="$HOME/.local/state/omarchy-setup/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$backup"

for name in hypr omarchy alacritty ghostty kitty starship.toml; do
  [[ -e "$HOME/.config/$name" ]] && cp -a -- "$HOME/.config/$name" "$backup/"
done
[[ -d "$HOME/.local/state/omarchy/current" ]] && cp -a "$HOME/.local/state/omarchy/current" "$backup/current"
mkdir -p "$HOME/.local/state/omarchy/current"
rsync -a "$repo/state/current/" "$HOME/.local/state/omarchy/current/"
for link in "$HOME/.local/state/omarchy/current/"background*; do
  [[ -L "$link" ]] || continue
  target=$(readlink "$link")
  ln -sfn "${target/#\/home\/dwm/$HOME}" "$link"
done
rsync -a "$repo/config/.config/" "$HOME/.config/"

rg -l -0 '/home/dwm' "$HOME/.config/hypr" "$HOME/.config/omarchy" 2>/dev/null |
  xargs -0r sed -i "s|/home/dwm|$HOME|g"

while read -r url name commit; do
  destination="$HOME/.config/omarchy/plugins/$name"
  [[ -d "$destination/.git" ]] || git clone "$url" "$destination"
  git -C "$destination" fetch --quiet origin "$commit"
  git -C "$destination" checkout --quiet "$commit"
done < "$repo/plugins.lock"

hyprctl reload
hyprctl configerrors
omarchy restart shell
printf 'Restored. Previous files: %s\n' "$backup"
