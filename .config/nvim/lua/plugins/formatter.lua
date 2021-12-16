local prettier = function()
    return {
        exe = "npm run --silent prettier --",
        args = {"--stdin-filepath", vim.api.nvim_buf_get_name(0)},
        stdin = true
    }
end

local eslint = function()
  return {
      exe = "npm run --silent eslint --",
      args = { '--stdin', '--stdin-filename', vim.api.nvim_buf_get_name(0), '--fix-dry-run' },
      stdin = true
    }
end

local mixformat = function()
  return {
      exe = "mix format",
      args = { vim.api.nvim_buf_get_name(0) },
      stdin = false
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
