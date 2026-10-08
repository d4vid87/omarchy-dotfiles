-- Extra autostart processes.
-- o.launch_on_start("my-service")

-- Tile HookEcho and StormDesk on the Acer weather workspace.
local acer = "desc:Acer Technologies Acer XR341CK T3MAA0014200"

hl.workspace_rule({ workspace = "10", monitor = acer, default = true, persistent = true })

o.window("hookecho", { workspace = "10 silent", monitor = acer, tile = true })
o.window("stormdesk", { workspace = "10 silent", monitor = acer, tile = true })

o.exec_on_start("/home/dwm/.local/bin/acer-weather-workspace")
