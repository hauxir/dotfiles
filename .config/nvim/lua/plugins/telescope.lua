local actions = require('telescope.actions')
local action_state = require('telescope.actions.state')

local function smart_file_opener(prompt_bufnr)
  -- Get the buffer that was active before Telescope opened
  local pre_telescope_buf = vim.fn.bufnr('#')
  local pre_telescope_filetype = vim.api.nvim_buf_get_option(pre_telescope_buf, 'filetype')
  
  if pre_telescope_filetype == 'alpha' then
    -- Replace the Alpha dashboard - use select_default to stay in same window
    actions.select_default(prompt_bufnr)
  else
    -- For all other buffers, open in new tab
    actions.select_tab(prompt_bufnr)
  end
end

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
        ["<cr>"] = smart_file_opener,
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

-- Remove the auto-open Telescope autocmd since Alpha will handle the startup screen
