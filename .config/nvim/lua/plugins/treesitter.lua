-- Treesitter highlight and indent are built into Neovim 0.11+.
-- nvim-treesitter plugin now only manages parser installation.
-- Use :TSInstall to add parsers, e.g. :TSInstall javascript typescript elixir python lua

vim.api.nvim_create_autocmd('FileType', {
  callback = function(args)
    if pcall(vim.treesitter.start, args.buf) then
      vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end
  end,
})
