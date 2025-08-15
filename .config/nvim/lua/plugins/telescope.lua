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
    },
    -- Close empty buffer when opening a file from Telescope
    attach_mappings = function(_, map)
      actions.select_default:replace(function(prompt_bufnr)
        local state = require("telescope.actions.state")
        local selected = state.get_selected_entry()
        local current_buf = vim.api.nvim_get_current_buf()
        
        -- Close telescope
        actions.close(prompt_bufnr)
        
        -- Check if current buffer is empty and unnamed
        if vim.fn.buflisted(current_buf) == 1 and 
           vim.api.nvim_buf_get_name(current_buf) == "" and 
           vim.api.nvim_buf_line_count(current_buf) == 1 and
           vim.api.nvim_buf_get_lines(current_buf, 0, -1, false)[1] == "" then
          vim.api.nvim_buf_delete(current_buf, {force = true})
        end
        
        -- Open the selected file
        if selected then
          vim.cmd("edit " .. selected.path or selected.value)
        end
      end)
      return true
    end
  }
}

require('telescope').load_extension('fzf')

local set_keymap = require('../utils').set_keymap

set_keymap('n', '<leader>t', '<cmd>Telescope git_files<cr>')
set_keymap('n', '<leader>g', '<cmd>Telescope live_grep<cr>')
