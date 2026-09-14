-- Notebook: internal panel plus whatever gets plugged in.
-- The empty-output rule is the catch-all so an unknown external is configured
-- rather than falling through to Hyprland's implicit default.
hl.monitor({
	output = "eDP-1",
	mode = "preferred",
	position = "auto",
	scale = "auto",
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

-- Deliberately no hyprsplit here. Its per-monitor workspace blocks give the
-- external its own 11-20, and when you undock, those workspaces stay alive on
-- the internal panel but SUPER+1..0 (which only address the local block, 1-10)
-- can no longer reach them. Its monitor.added/config.reloaded handlers impose
-- the blocks whether or not its dispatchers are used, so the module has to stay
-- unloaded, not merely unused. Plain Hyprland workspaces are global: a
-- workspace follows you between screens and nothing can be stranded.

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
