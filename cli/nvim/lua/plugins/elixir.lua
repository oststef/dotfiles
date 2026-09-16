return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        -- Disable elixir-ls (configured by lazyvim.plugins.extras.lang.elixir);
        -- this also stops mason-lspconfig from auto-installing/reinstalling it.
        elixirls = { enabled = false },

        -- Dexter: fast, full-featured Elixir LSP (https://github.com/remoteoss/dexter).
        -- Not available via Mason — install the `dexter` binary separately
        -- (e.g. `mise use -g aqua:remoteoss/dexter@latest`, asdf, or `brew install dexter-lsp`).
        dexter = {
          mason = false,
          cmd = { "dexter", "lsp" },
          filetypes = { "elixir", "eelixir", "heex" },
          root_markers = { ".dexter/dexter.db", ".dexter.db", "mix.exs", ".git" },
          init_options = {
            followDelegates = true,
          },
        },
      },
    },
  },
}
