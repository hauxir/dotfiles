local function eslint_config_exists()
  local eslintrc = vim.fn.glob(".eslintrc*", 0, 1)

  if not vim.tbl_isempty(eslintrc) then
    return true
  end

  if vim.fn.filereadable("package.json") == 1 then
    local package_content = vim.fn.readfile("package.json")
    if #package_content > 0 then
      local package_data = vim.fn.json_decode(table.concat(package_content, "\n"))
      if package_data and package_data["eslintConfig"] then
        return true
      end
    end
  end

  return false
end

local eslint = {
  lintCommand = "eslint_d -f unix --stdin --stdin-filename ${INPUT}",
  lintStdin = true,
  lintFormats = {"%f:%l:%c: %m"},
  lintIgnoreExitCode = true,
  formatCommand = "eslint_d --fix-to-stdout --stdin --stdin-filename=${INPUT}",
  formatStdin = true
}

-- Configure servers with overrides (defaults come from nvim-lspconfig lsp/ files)
vim.lsp.config('elixirls', {
  cmd = { 'elixir-ls' },
})

vim.lsp.config('efm', {
  root_dir = function(bufnr, on_dir)
    if not eslint_config_exists() then
      return
    end
    on_dir(vim.fn.getcwd())
  end,
  settings = {
    languages = {
      javascript = {eslint},
      javascriptreact = {eslint},
      ["javascript.jsx"] = {eslint},
      typescript = {eslint},
      ["typescript.tsx"] = {eslint},
      typescriptreact = {eslint}
    }
  },
  filetypes = {
    "javascript",
    "javascriptreact",
    "javascript.jsx",
    "typescript",
    "typescript.tsx",
    "typescriptreact"
  },
})

-- Enable all servers
vim.lsp.enable({
  'bashls',
  'cssls',
  'html',
  'jsonls',
  'elixirls',
  'ruff',
  'basedpyright',
  'ts_ls',
  'efm',
})

-- Server-specific on_attach logic via LspAttach autocmd
vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if not client then return end

    if client.name == 'ts_ls' then
      client.server_capabilities.documentFormattingProvider = false
      client.server_capabilities.documentRangeFormattingProvider = false
    end

    if client.name == 'efm' then
      client.server_capabilities.documentFormattingProvider = true
      client.server_capabilities.gotoDefinitionProvider = false

      if client:supports_method("textDocument/formatting") then
        vim.api.nvim_create_autocmd("BufWritePre", {
          buffer = args.buf,
          callback = function()
            vim.lsp.buf.format({ bufnr = args.buf })
          end,
        })
      end
    end
  end,
})

-- Diagnostic keymaps
local set_keymap = require('../utils').set_keymap
set_keymap('n', '<leader>z', '<cmd> lua vim.diagnostic.open_float(0, {scope="line"})<cr>')
set_keymap('n', '<leader>n', '<cmd>lua vim.diagnostic.goto_next()<cr>')
set_keymap('n', '<leader>p', '<cmd>lua vim.diagnostic.goto_prev()<cr>')

-- Show diagnostics automatically when cursor holds on a line
vim.api.nvim_create_autocmd("CursorHold", {
  callback = function()
    local opts = {
      focusable = false,
      close_events = { "BufLeave", "CursorMoved", "InsertEnter", "FocusLost" },
      border = 'rounded',
      source = 'always',
      prefix = ' ',
      scope = 'cursor',
    }
    vim.diagnostic.open_float(nil, opts)
  end
})

local function goto_definition_in_tab()
  local params = vim.lsp.util.make_position_params(0, 'utf-8')
  vim.lsp.buf_request(0, 'textDocument/definition', params, function(err, result, ctx, _)
    if err or not result then return end
    local function jump_to_location(location)
      local uri = location.uri or location.targetUri
      local bufnr = vim.uri_to_bufnr(uri)
      local current_buf = vim.api.nvim_get_current_buf()

      if bufnr == current_buf then
        -- Same file: just jump
        vim.lsp.util.jump_to_location(location, 'utf-8')
      else
        -- Different file: open in new tab
        vim.cmd('tabnew')
        vim.lsp.util.jump_to_location(location, 'utf-8')
      end
    end

    if vim.islist(result) then
      jump_to_location(result[1])
    else
      jump_to_location(result)
    end
  end)
end
vim.keymap.set('n', 'gd', goto_definition_in_tab, { noremap = true, silent = true })
