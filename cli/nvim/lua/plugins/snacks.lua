return {
  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        hidden = true,
        ignored = true,
        sources = {
          explorer = {
            auto_close = true,
            layout = {
              preset = "vscode",
              preview = "main",
            },
          },
        },
      },
    },
  },
}
