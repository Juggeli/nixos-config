return {
  "jose-elias-alvarez/null-ls.nvim",
  opts = function(_, config)
    local null_ls = require "null-ls"

    config.sources = {
      null_ls.builtins.formatting.stylua,
    }
    return config
  end,
}
