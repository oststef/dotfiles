-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local map = vim.keymap.set

-- Inside herdr there is no $TMUX, so at the edge of nvim hand off to herdr instead.
-- herdr TUI sets HERDR_PANE_ID; the herdr desktop app's terminals set HC_TERMINAL_ID.
local function navigate(wincmd, direction, tmux_cmd)
  local handoff
  if vim.env.HERDR_PANE_ID then
    handoff = { "herdr", "pane", "focus", "--pane", vim.env.HERDR_PANE_ID, "--direction", direction }
  elseif vim.env.HC_TERMINAL_ID then
    handoff = { "herdr-app", "do", "pane.go", "--direction", direction }
  else
    return "<cmd> " .. tmux_cmd .. "<CR>"
  end
  return function()
    local win = vim.api.nvim_get_current_win()
    vim.cmd.wincmd(wincmd)
    if vim.api.nvim_get_current_win() == win then
      vim.system(handoff)
    end
  end
end

map("n", "<C-h>", navigate("h", "left", "TmuxNavigateLeft"), { desc = "Go to left pane" })
map("n", "<C-l>", navigate("l", "right", "TmuxNavigateRight"), { desc = "Go to right pane" })
map("n", "<C-j>", navigate("j", "down", "TmuxNavigateDown"), { desc = "Go to down pane" })
map("n", "<C-k>", navigate("k", "up", "TmuxNavigateUp"), { desc = "Go to up pane" })

map("n", "<leader>h", vim.lsp.buf.hover, { desc = "LSP Hover" })
