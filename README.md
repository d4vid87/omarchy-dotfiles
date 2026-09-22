# Omarchy setup

Private backup of my Omarchy configuration, custom plugins, theme, and package list.

## Restore on a fresh Omarchy install

```bash
git clone git@github.com:d4vid87/omarchy-setup.git
cd omarchy-setup
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

Run `./update.sh` on the original computer to refresh this backup before pushing.

## Snapshot: 2026-09-22

Includes current Hyprland, terminal and shell settings, custom plugins, six
third-party plugin revisions, Noir and Deep Space themes, active generated theme
and wallpaper selections, and installed package lists. The installer restores
`state/current` as well as configuration. Accounts, credentials, clipboard history,
notifications, and other application data are excluded.

External dependencies are not bundled: the lock-screen avatar on `/run/media`,
`~/AppImages/stormdesk.appimage`, `~/AppImages/hookecho.appimage`, and system-installed
fonts/icons. Restore those separately. This is a desktop configuration export,
not a full operating-system backup. Plugin-specific state outside the current
theme directory is not included.
