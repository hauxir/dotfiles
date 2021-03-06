local actions = require('telescope.actions')

require('telescope').setup{
  defaults = {
        vimgrep_arguments = {
      'rg',
      '--color=never',
      '--no-heading',
      '--with-filename',
      '--line-number',
      '--column',
      '--smart-case'
    },
    layout_strategy = "vertical",
    mappings = {
      i = {
        ["<C-n>"] = false,
        ["<cr>"] = actions.select_tab,
        ["<C-j>"] = actions.move_selection_next,
        ["<C-k>"] = actions.move_selection_previous
      }
    }
  }
}

local set_keymap = require('../utils').set_keymap

set_keymap('n', '<leader>t', '<cmd>Telescope git_files<cr>')
set_keymap('n', '<leader>g', '<cmd>Telescope live_grep<cr>')
