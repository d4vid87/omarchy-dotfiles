-- Extra autostart processes.
-- o.launch_on_start("my-service")

-- Restore the two dashboard apps to their selected monitors.
local acer = "desc:Acer Technologies Acer XR341CK T3MAA0014200"
local lg = "desc:LG Electronics LG ULTRAFINE 508RMMDCD643"
local chatgpt_lg = "desc:LG Electronics LG ULTRAFINE 508RMGCCD663"
local sceptre = "desc:Sceptre Tech Inc Sceptre O34"

hl.workspace_rule({ workspace = "10", monitor = acer, default = true, persistent = true })

o.window("hookecho", { workspace = "10 silent", monitor = acer, fullscreen = true })
o.window("stormdesk", { workspace = "4 silent", monitor = lg, fullscreen = true })
o.window("firefox", { workspace = "1 silent", monitor = sceptre, fullscreen = true })
o.window("chatgpt", { workspace = "7 silent", monitor = chatgpt_lg })

o.exec_on_start("/home/dwm/.local/bin/acer-weather-workspace")
o.exec_on_start("/home/dwm/.local/bin/firefox-sceptre-start")
o.exec_on_start("/home/dwm/.local/bin/chatgpt-lg-start")
