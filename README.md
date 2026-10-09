# Omarchy dotfiles

Backup of my Omarchy configuration, installed plugins, cursor theme, wallpapers, and package list.

## Restore on a fresh Omarchy install

```bash
git clone https://github.com/d4vid87/omarchy-dotfiles.git
cd omarchy-dotfiles
./install.sh
```

The installer backs up any replaced files under `~/.local/state/omarchy-setup/`,
rewrites old `/home/dwm` paths to the new user's home, restores third-party
plugins at the recorded commits, reloads Hyprland, and restarts Omarchy Shell.

Package lists are reference snapshots. Install only what the new computer needs:

```bash
sudo pacman -S --needed - < packages/official.txt
yay -S --needed - < packages/foreign.txt
```

The monitor rules describe the original four-monitor desk. Omarchy's generic
fallback remains first, so other displays still work; edit
`~/.config/hypr/monitors.lua` for the new hardware.

A user timer refreshes this snapshot and pushes changes to the public GitHub repo every 15 minutes. Run it immediately with `systemctl --user start omarchy-dotfiles-backup.service`; check recent runs with `journalctl --user -u omarchy-dotfiles-backup.service`. Disable automatic backups with `systemctl --user disable --now omarchy-dotfiles-backup.timer`.

## Snapshot contents

Includes Hyprland key bindings, terminal and shell settings, all installed Omarchy
plugins, the Bibata-Modern-Ice-Right cursor theme, wallpapers from `~/Wallpapers`,
Omarchy themes and active per-monitor wallpaper selections, and installed package
lists. The installer restores `state/current` as well as configuration. Accounts,
credentials, clipboard history, notifications, and other application data are excluded.

External dependencies are not bundled: the lock-screen avatar on `/run/media`,
`~/AppImages/stormdesk.appimage`, `~/AppImages/hookecho.appimage`, and system-installed
fonts. Restore those separately. This is a desktop configuration export, not a full
operating-system backup. Plugin-specific state outside each installed plugin folder
and the current theme directory is not included.
