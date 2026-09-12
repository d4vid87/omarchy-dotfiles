-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
-- List current monitors and supported resolutions with: hyprctl monitors all

local omarchy_monitor_scale = 1

-- ponytail: GDK_SCALE dropped; per-monitor scale handles GTK sizing.
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = omarchy_monitor_scale })

-- Pinned positions. "auto" assigns by connection order, so monitors swapped sides
-- depending on which came up first -- worst with the two identical LG ULTRAFINEs.
-- Matched by desc: (serial) instead of DP-N port names, which are not stable.
--
-- Physical layout, left to right:
--   Acer 2560 | LG 2560 | Sceptre 3440 | LG 2560   = 11120 wide (logical)
-- The LGs run 3840x2160 at scale 1.5, so each occupies 2560 logical px.
-- Acer runs 2560x1080@60: its HDMI link has no bandwidth for 3440x1440 above 29.97Hz.
hl.monitor({ output = "desc:Acer Technologies Acer XR341CK T3MAA0014200", mode = "2560x1080@60", position = "0x0", scale = omarchy_monitor_scale })
hl.monitor({ output = "desc:LG Electronics LG ULTRAFINE 508RMMDCD643", mode = "preferred", position = "8560x0", scale = 1.5 })
hl.monitor({ output = "desc:Sceptre Tech Inc Sceptre O34", mode = "3440x1440@180", position = "5120x0", scale = omarchy_monitor_scale })
hl.monitor({ output = "desc:LG Electronics LG ULTRAFINE 508RMGCCD663", mode = "preferred", position = "2560x0", scale = 1.5 })

-- Configure a specific monitor.
-- hl.monitor({ output = "DP-2", mode = "2560x1440@144", position = "0x0", scale = 1 })

-- Portrait/rotated secondary monitor (transform: 1 = 90°, 3 = 270°).
-- hl.monitor({ output = "DP-2", mode = "preferred", position = "auto", scale = 1, transform = 1 })
