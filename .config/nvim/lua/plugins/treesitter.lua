-- Treesitter highlight and indent are built into Neovim 0.11+.
-- nvim-treesitter plugin now only manages parser installation.

-- Auto-install missing parsers when opening a file
vim.api.nvim_create_autocmd('FileType', {
  callback = function(args)
    local ft = vim.bo[args.buf].filetype
    if ft == '' then return end

    if pcall(vim.treesitter.start, args.buf) then
      vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    else
      -- Parser not installed yet — try to install it automatically
      local lang = vim.treesitter.language.get_lang(ft) or ft
      local ok = pcall(vim.treesitter.language.add, lang)
      if not ok then
        -- Silently attempt TSInstall; parser may not exist for this filetype
        vim.cmd('silent! TSInstall ' .. lang)
      end
    end
  end,
})
