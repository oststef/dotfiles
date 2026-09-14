-- hyprsplit is loaded by monitors/desktop.lua and nowhere else, so this is nil
-- on the laptop. There, plain hl.dsp gives Hyprland's global workspaces, which
-- survive a monitor being unplugged; see monitors/laptop.lua for why.
local hs = package.loaded["hyprsplit"]
local ws = hs and hs.dsp or hl.dsp

local SUPER_SHIFT = "SUPER + SHIFT"
local mainMod = "SUPER"

hl.bind(mainMod .. " + return", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + C", hl.dsp.window.close())
hl.bind(mainMod .. " + M", hl.dsp.exit())
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + space", hl.dsp.global("quickshell:launcher"))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + T", hl.dsp.layout("togglesplit"))
-- only meaningful with per-monitor blocks, i.e. only on the desktop
if hs then
	hl.bind(mainMod .. " + G", hs.dsp.grab_rogue_windows())
end

hl.bind(mainMod .. " + TAB", function()
	hl.plugin.overview.toggle()
end, { description = "Toggle overview" })
hl.bind(SUPER_SHIFT .. " + TAB", function()
	hl.plugin.overview.toggle("all")
end, { description = "Toggle overview on all monitors" })

hl.bind("PRINT", hl.dsp.exec_cmd("hyprshot -m window"))
hl.bind("SHIFT + PRINT", hl.dsp.exec_cmd("hyprshot -m region"))
hl.bind(SUPER_SHIFT .. " + l", hl.dsp.exec_cmd("hyprlock"))

hl.bind(mainMod .. " + h", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + l", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + j", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + k", hl.dsp.focus({ direction = "down" }))

hl.bind(mainMod .. " + ALT + h", ws.focus({ workspace = "-1" }))
hl.bind(mainMod .. " + ALT + l", ws.focus({ workspace = "+1" }))

for i = 1, 10 do
	local key = i % 10 -- workspace 10 sits on key 0
	hl.bind(mainMod .. " + " .. key, ws.focus({ workspace = i }))
	hl.bind(SUPER_SHIFT .. " + " .. key, ws.window.move({ workspace = i }))
end

hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- Three-finger swipe. The built-in action = "workspace" animates continuously
-- but doesn't know about hyprsplit's per-monitor blocks, so it would swipe from
-- 10 straight into 11. With blocks, dispatch through hyprsplit and lose the
-- animation; without them (the laptop), take the built-in.
if hs then
	hl.gesture({ fingers = 3, direction = "left", action = hs.dsp.focus({ workspace = "+1" }) })
	hl.gesture({ fingers = 3, direction = "right", action = hs.dsp.focus({ workspace = "-1" }) })
else
	hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
end

hl.bind(mainMod .. " + mouse_down", ws.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", ws.focus({ workspace = "e-1" }))

hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag())
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize())

hl.bind(
	"XF86AudioRaiseVolume",
	hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86AudioLowerVolume",
	hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86AudioMute",
	hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86AudioMicMute",
	hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),
	{ locked = true, repeating = true }
)
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"), { locked = true, repeating = true })

hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
