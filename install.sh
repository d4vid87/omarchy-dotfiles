#!/usr/bin/env bash
set -euo pipefail

repo=$(cd -- "$(dirname -- "$0")" && pwd)
backup="$HOME/.local/state/omarchy-setup/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$backup"

for name in hypr omarchy alacritty ghostty kitty voxtype starship.toml; do
  [[ -e "$HOME/.config/$name" ]] && cp -a -- "$HOME/.config/$name" "$backup/"
done
if [[ -f "$HOME/.config/systemd/user/voxtype.service" ]]; then
  mkdir -p "$backup/systemd/user"
  cp -a -- "$HOME/.config/systemd/user/voxtype.service" "$backup/systemd/user/"
fi
[[ -d "$HOME/Wallpapers" ]] && cp -a -- "$HOME/Wallpapers" "$backup/"
if [[ -d "$HOME/.local/share/icons/Bibata-Modern-Ice-Right" ]]; then
  mkdir -p "$backup/.local/share/icons"
  cp -a -- "$HOME/.local/share/icons/Bibata-Modern-Ice-Right" "$backup/.local/share/icons/"
fi
[[ -d "$HOME/.local/state/omarchy/current" ]] && cp -a "$HOME/.local/state/omarchy/current" "$backup/current"
mkdir -p "$HOME/.local/state/omarchy/current"
rsync -a "$repo/state/current/" "$HOME/.local/state/omarchy/current/"
for link in "$HOME/.local/state/omarchy/current/"background*; do
  [[ -L "$link" ]] || continue
  target=$(readlink "$link")
  ln -sfn "${target/#\/home\/dwm/$HOME}" "$link"
done
rsync -a "$repo/config/.config/" "$HOME/.config/"
mkdir -p "$HOME/.local/share/icons" "$HOME/Wallpapers"
rsync -a "$repo/assets/cursors/" "$HOME/.local/share/icons/"
rsync -a "$repo/wallpapers/" "$HOME/Wallpapers/"

rg -l -0 '/home/dwm' "$HOME/.config/hypr" "$HOME/.config/omarchy" 2>/dev/null |
  xargs -0r sed -i "s|/home/dwm|$HOME|g"

if command -v voxtype >/dev/null 2>&1 && systemctl --user cat voxtype.service >/dev/null 2>&1; then
  systemctl --user daemon-reload
  systemctl --user enable --now voxtype.service
fi

while read -r url name commit; do
  destination="$HOME/.config/omarchy/plugins/$name"
  if [[ ! -d "$destination/.git" ]]; then
    [[ -d "$destination" ]] && continue
    git clone "$url" "$destination"
  fi
  git -C "$destination" fetch --quiet origin "$commit"
  git -C "$destination" checkout --quiet "$commit"
done < "$repo/plugins.lock"

hyprctl reload
hyprctl configerrors
omarchy restart shell
printf 'Restored. Previous files: %s\n' "$backup"
