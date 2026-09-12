-- Extra autostart processes.
-- o.launch_on_start("my-service")

-- Weather wall on the Acer: HookEcho left, StormDesk right, regardless of launch order.
local acer = "desc:Acer Technologies Acer XR341CK T3MAA0014200"

hl.workspace_rule({ workspace = "1", monitor = acer, default = true, persistent = true })

-- Match the current layout, including the 45px bar and window gaps.
o.window("hookecho", {
  workspace = "1 silent", monitor = acer, float = true,
  size = { "(monitor_w/2-21)", "(monitor_h-71)" }, move = { 13, 58 },
})
o.window("Stormdesk", {
  workspace = "1 silent", monitor = acer, float = true,
  size = { "(monitor_w/2-21)", "(monitor_h-71)" }, move = { "(monitor_w/2+8)", 58 },
})

-- ponytail: plain launches, no sole/focus wrapper -- these only run at start.
o.launch_on_start("/home/dwm/AppImages/stormdesk.appimage")
o.launch_on_start("/home/dwm/AppImages/hookecho.appimage")
