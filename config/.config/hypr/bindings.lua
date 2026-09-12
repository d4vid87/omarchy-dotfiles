-- Keep only your personal keybinding overrides here. Add new bindings or
-- unbind defaults before replacing them.

-- See current bindings and descriptions:
--   omarchy menu keybindings --print

-- To disable every Omarchy default binding, set this in
-- ~/.config/hypr/hyprland.lua before require("default.hypr.omarchy"), then add
-- only the bindings you want below:
--   omarchy_default_bindings = false

-- To disable all preinstalled app/webapp bindings, set:
--   omarchy_preinstalled_bindings = false

-- Add a new binding.
-- o.bind("SUPER + SHIFT + R", "SSH", "alacritty -e ssh your-server")

-- Change an existing binding by unbinding it first, then binding the key again.
-- This example changes SUPER+SPACE from the launcher to the Omarchy root menu.
-- hl.unbind("SUPER + SPACE")
-- o.bind("SUPER + SPACE", "Omarchy menu", "omarchy-menu toggle root")

-- Disable a default binding without replacing it.
-- hl.unbind("SUPER + SHIFT + B")

-- Logitech MX Keys examples:
-- o.bind("SUPER + SHIFT + S", nil, "omarchy-capture-screenshot")
-- o.bind("SUPER + H", nil, "voxtype record toggle")
-- o.bind("SUPER + PERIOD", nil, "omarchy-shell shell toggle omarchy.emojis")

-- Voxtype push-to-talk: move from F9 to Scroll Lock
hl.unbind("F9")
o.bind("Scroll_Lock", "Start dictation (push-to-talk)", "voxtype record start")
o.bind("Scroll_Lock", "Stop dictation (push-to-talk)", "voxtype record stop", { release = true })

-- >>> dwm.alttab >>>
-- Windows-style Alt-Tab switcher (dwm.alttab shell plugin). Managed by install.sh.
-- Defaults were: cycle_next + bring_to_top on ALT+TAB, reverse pair on ALT+SHIFT+TAB.
hl.unbind("ALT + TAB")
hl.unbind("ALT + SHIFT + TAB")
o.bind("ALT + TAB", "Window switcher", hl.dsp.global("dwm.alttab:next"), { repeating = true })
o.bind("ALT + SHIFT + TAB", "Window switcher (reverse)", hl.dsp.global("dwm.alttab:prev"), { repeating = true })
o.bind("CTRL + ALT + TAB", "Window switcher (sticky)", hl.dsp.global("dwm.alttab:sticky"))
-- Uncomment to add a switcher limited to the current workspace:
-- o.bind("ALT + GRAVE", "Window switcher (this workspace)", hl.dsp.global("dwm.alttab:next-workspace"), { repeating = true })

-- Releasing Alt commits the selection.
hl.bind("ALT + Alt_L", hl.dsp.global("dwm.alttab:alt"), { release = true })
hl.bind("ALT + Alt_R", hl.dsp.global("dwm.alttab:alt"), { release = true })

-- The overlay animates itself, so keep the compositor out of it, and frost
-- whatever is behind it. Delete these two lines if you do not want blur.
hl.layer_rule({ match = { namespace = "^dwm-alttab$" }, no_anim = true, blur = true })
hl.config({ decoration = { blur = { enabled = true, passes = 3 } } })
-- <<< dwm.alttab <<<

-- Super + Left/Right moves the focused window to the next monitor in that
-- direction (was: focus left/right window).
hl.unbind("SUPER + LEFT")
hl.unbind("SUPER + RIGHT")
o.bind("SUPER + LEFT", "Move window to left monitor", hl.dsp.window.move({ monitor = "l" }))
o.bind("SUPER + RIGHT", "Move window to right monitor", hl.dsp.window.move({ monitor = "r" }))

-- Ctrl + Alt + T opens the terminal (alongside the default SUPER + RETURN).
o.bind("CTRL + ALT + T", "Terminal", { omarchy = "terminal" })

-- Alt + F4 closes the focused window (alongside the default SUPER + W).
o.bind("ALT + F4", "Close window", hl.dsp.window.close())

-- Super + Return opens the browser (terminal stays on CTRL + ALT + T).
hl.unbind("SUPER + RETURN")
o.bind("SUPER + RETURN", "Browser", { omarchy = "browser" })

-- Super + Up/Down snaps the focused window to the top or bottom half of its
-- monitor (Windows-style), floating it first (was: focus above/below window).
-- ponytail: ignores gaps_out, the halves sit flush against the work area.
local function snap_half(edge)
  return function()
    local win = hl.get_active_window()
    local mon = win and win.monitor or hl.get_active_monitor()
    if not win or not mon then return end

    if not win.floating then hl.dispatch(hl.dsp.window.float()) end

    local r = mon.reserved or {}
    local x = mon.x + (r.left or 0)
    local y = mon.y + (r.top or 0)
    local w = mon.width / mon.scale - (r.left or 0) - (r.right or 0)
    local h = (mon.height / mon.scale - (r.top or 0) - (r.bottom or 0)) / 2

    hl.dispatch(hl.dsp.window.resize({ x = w, y = h, relative = false }))
    hl.dispatch(hl.dsp.window.move({ x = x, y = edge == "u" and y or y + h, relative = false }))
  end
end

hl.unbind("SUPER + UP")
hl.unbind("SUPER + DOWN")
o.bind("SUPER + UP", "Snap window to top half", snap_half("u"))
o.bind("SUPER + DOWN", "Snap window to bottom half", snap_half("d"))

-- Super + D turns off all monitors (any key/mouse input wakes them; omarchy
-- defaults set key_press/mouse_move_enables_dpms).
o.bind("SUPER + D", "Screens off", hl.dsp.dpms("off"))
