local util = require "formatter.util"

local prettier = function()
    return {
        exe = "prettier",
        args = {
             "--stdin-filepath",
             util.escape_path(util.get_current_buffer_file_path()),
        },
        stdin = true,
        try_node_modules = true
    }
end

local eslint = function()
  return {
      exe = "eslint",
      args = {
          "--stdin",
          "--stdin-filename",
          util.escape_path(util.get_current_buffer_file_path()),
          "--fix-to-stdout",
      },
      stdin = true,
      try_node_modules = true
    }
end

local mixformat = function()
  return {
      exe = "mix format",
      args = { "-" },
      stdin = true
    }
end

require('formatter').setup({
  logging = false,
  filetype = {
    javascript = {prettier,eslint},
    typescript = {prettier,eslint},
    typescriptreact = {prettier,eslint},
    json = {prettier},
    elixir = {mixformat}
  }
})

vim.api.nvim_exec([[
augroup FormatAutogroup
  autocmd!
  autocmd BufWritePost *.ts,*.js,*.ts,*.tsx,*.json,*.ex,*.exs FormatWrite
augroup END
]], true)
