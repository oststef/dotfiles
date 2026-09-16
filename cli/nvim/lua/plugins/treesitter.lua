return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.highlight = opts.highlight or {}
      opts.highlight.enable = true
      opts.highlight.disable = opts.highlight.disable or {}

      -- disable TS for Snacks dashboard pseudo-language
      table.insert(opts.highlight.disable, "snacks_dashboard")
    end,
  },
}
