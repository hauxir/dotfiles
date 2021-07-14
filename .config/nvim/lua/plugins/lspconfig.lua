require('lspconfig').bashls.setup({})
require('lspconfig').cssls.setup({})
require('lspconfig').html.setup({})
require('lspconfig').jsonls.setup({})
require('lspconfig').tsserver.setup({})
require('lspconfig').elixirls.setup({
  cmd = {'/root/.local/share/elixir-ls/language_server.sh'};
})
