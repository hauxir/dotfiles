require('nvim-treesitter.configs').setup({
  highlight = {
    enable = true,
  },
  ensure_installed = 'maintained',
  indent = {
    enable = true,
  },
  incremental_selection = {
    enable = true,
    keymaps = {
      init_selection = 'gnn',
      node_incremental = 'grn',
      scope_incremental = 'grc',
      node_decremental = 'grm',
    },
  },
  playground = {
    enable = true,
    disable = {},
    updatetime = 25,
    persist_queries = false,
  },
  textobjects = {
    select = {
      enable = true,
      keymaps = {
        ['af'] = '@function.outer',
        ['if'] = '@function.inner',
        ['ac'] = '@class.outer',
        ['ic'] = '@class.inner',
        ['aP'] = '@parameter.outer',
        ['iP'] = '@parameter.inner',
      },
    },
  },
})

require("nvim-treesitter.parsers").elixir = {
  install_info = {
    url = "$HOME/tree-sitter-elixir/",
    files = "grammar.js"
  },
  used_by = {'elixir'}
}
