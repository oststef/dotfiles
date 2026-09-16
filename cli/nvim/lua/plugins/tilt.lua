return {
  {
    "neovim/nvim-lspconfig",
    -- Neovim doesn't detect the Tiltfile filetype on its own, so tilt_ls
    -- won't attach without this.
    init = function()
      vim.filetype.add({
        filename = { ["Tiltfile"] = "tiltfile" },
        pattern = { [".*%.tiltfile"] = "tiltfile" },
      })
      -- Tiltfiles are Starlark; reuse the starlark treesitter parser.
      vim.treesitter.language.register("starlark", "tiltfile")
    end,
    opts = {
      servers = {
        -- LSP ships inside the `tilt` binary (cmd: tilt lsp start).
        -- mason = false: the binary is installed separately, and
        -- mason-lspconfig doesn't reliably auto-enable tilt_ls.
        tilt_ls = {
          mason = false,
        },
      },
    },
  },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = { ensure_installed = { "starlark" } },
  },
}
