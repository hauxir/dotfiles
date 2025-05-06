local lspconfig = require"lspconfig"

local function eslint_config_exists()
  local eslintrc = vim.fn.glob(".eslintrc*", 0, 1)

  if not vim.tbl_isempty(eslintrc) then
    return true
  end

  if vim.fn.filereadable("package.json") then
    if vim.fn.json_decode(vim.fn.readfile("package.json"))["eslintConfig"] then
      return true
    end
  end

  return false
end

require('lspconfig').bashls.setup({})
require('lspconfig').cssls.setup({})
require('lspconfig').html.setup({})
require('lspconfig').jsonls.setup({})
require('lspconfig').ts_ls.setup({})
require('lspconfig').elixirls.setup({})
require('lspconfig').elixirls.setup({
  cmd = {'elixir-ls'};
})

local eslint = {
  lintCommand = "eslint_d -f unix --stdin --stdin-filename ${INPUT}",
  lintStdin = true,
  lintFormats = {"%f:%l:%c: %m"},
  lintIgnoreExitCode = true,
  formatCommand = "eslint_d --fix-to-stdout --stdin --stdin-filename=${INPUT}",
  formatStdin = true

}
local buf_map = function(bufnr, mode, lhs, rhs, opts)
    vim.api.nvim_buf_set_keymap(bufnr, mode, lhs, rhs, opts or {
        silent = true,
    })
end

lspconfig.ts_ls.setup({
    on_attach = function(client, bufnr)
        client.server_capabilities.documentFormattingProvider = false
        client.server_capabilities.documentRangeFormattingProvider = false
        local ts_utils = require("nvim-lsp-ts-utils")
        ts_utils.setup({
            eslint_bin = "eslint_d",
            eslint_enable_diagnostics = true,
            eslint_enable_code_actions = true,
            enable_formatting = true,
            formatter = "prettier",
        })
        ts_utils.setup_client(client)
        buf_map(bufnr, "n", "gs", ":TSLspOrganize<CR>")
        buf_map(bufnr, "n", "gi", ":TSLspRenameFile<CR>")
        buf_map(bufnr, "n", "go", ":TSLspImportAll<CR>")
    end,
})

require('lspconfig').efm.setup {
  on_attach = function(client)
    client.server_capabilities.documentFormattingProvider = true
    client.server_capabilities.gotoDefinitionProvider = false
  end,
  root_dir = function()
    if not eslint_config_exists() then
      return nil
    end
    return vim.fn.getcwd()
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
}

local set_keymap = require('../utils').set_keymap
set_keymap('n', '<leader>z', '<cmd> lua vim.diagnostic.open_float(0, {scope="line"})<cr>')

local function goto_definition_in_tab()
  local params = vim.lsp.util.make_position_params()
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

    if vim.tbl_islist(result) then
      jump_to_location(result[1])
    else
      jump_to_location(result)
    end
  end)
end
vim.keymap.set('n', 'gd', goto_definition_in_tab, { noremap = true, silent = true })
