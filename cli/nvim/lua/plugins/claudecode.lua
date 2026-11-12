-- Claude runs in its own herdr pane and connects via /ide, so don't spawn a terminal inside nvim.
return {
  "coder/claudecode.nvim",
  opts = { terminal = { provider = "none" } },
}
