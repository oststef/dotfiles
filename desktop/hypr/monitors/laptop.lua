-- Notebook: internal panel plus whatever gets plugged in.
-- The empty-output rule is the catch-all so an unknown external is configured
-- rather than falling through to Hyprland's implicit default.
-- 1.5 instead of "auto" (which picks 2 on the 2880x1800 panel, only 1440x900
-- of usable space). 2880/1.5 and 1800/1.5 are both whole, so Hyprland won't
-- reject it; 1.6 (1800x1125) is the next step down if 1920x1200 still crowds.
hl.monitor({
	output = "eDP-1",
	mode = "preferred",
	position = "auto",
	scale = "1.5",
})

-- "auto" places externals to the right but top-aligned, so a 1440-tall
-- ultrawide next to a 1080-tall laptop panel leaves the bottoms misaligned and
-- the pointer catching on the step. auto-center-right lines them up by centre.
-- Swap for auto-center-left / auto-up / auto-down to match how they physically
-- sit on the desk.
hl.monitor({
	output = "",
	mode = "preferred",
	position = "auto-center-right",
	scale = "1",
})

-- Per-monitor workspace blocks, same as the desktop: eDP-1 owns 1-10, a docked
-- external gets 11-20, so SUPER+1..0 never drags a workspace off the other
-- screen. The priority list is what pins the internal panel to 1-10; unlisted
-- monitors are auto-assigned after it, so any external lands on 11-20.
local hs = require("hyprsplit")
hs.config({ num_workspaces = 10 })
hs.monitor_priority({ "eDP-1" })

-- Undocking strands windows on 11-20, which SUPER+1..0 can no longer reach.
-- grab_rogue_windows pulls them back onto the active workspace.
-- ponytail: fires blind; if the leaving monitor is still in hl.get_monitors()
-- at this point its block still counts as valid and this is a no-op. SUPER+G
-- runs the same thing by hand.
hl.on("monitor.removed", hs.dsp.grab_rogue_windows())

-- Lid. logind already suspends on a bare lid close and ignores a docked one
-- (HandleLidSwitchDocked defaults to ignore), but nothing turns the internal
-- panel off inside a shut lid while docked — so it sits there lit. These do.
-- Verified form: hl.bind("switch:on:Lid Switch", ...) registers as a bindl.
local internal_disabled = nil

hl.bind("switch:on:Lid Switch", function()
	local internal, externals = nil, 0
	for _, m in ipairs(hl.get_monitors()) do
		if m.name:match("^eDP") then
			internal = m.name
		elseif not m.is_mirror then
			externals = externals + 1
		end
	end
	-- Undocked: leave it alone and let logind suspend.
	if internal and externals > 0 then
		internal_disabled = internal
		hl.monitor({ output = internal, disabled = true })
	end
end, { locked = true })

hl.bind("switch:off:Lid Switch", function()
	if internal_disabled then
		hl.monitor({ output = internal_disabled, disabled = false })
		internal_disabled = nil
	end
end, { locked = true })
