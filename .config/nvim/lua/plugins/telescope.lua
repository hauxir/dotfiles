local actions = require('telescope.actions')

require('telescope').setup{
   extensions = {
    fzf = {
      fuzzy = true,
      override_generic_sorter = true,
      override_file_sorter = true,
      case_mode = "smart_case",
    }
  },
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
    file_ignore_patterns = {"node_modules", "dist", "public"},
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

require('telescope').load_extension('fzf')

local set_keymap = require('../utils').set_keymap

set_keymap('n', '<leader>t', '<cmd>Telescope git_files<cr>')
set_keymap('n', '<leader>g', '<cmd>Telescope live_grep<cr>')
