local cmd = vim.cmd

cmd 'packadd paq-nvim'
require('paq-nvim')({
  {'savq/paq-nvim', opt = true};
  'nvim-lua/plenary.nvim';
  'nvim-lua/popup.nvim';
  'neovim/nvim-lspconfig',
  'kabouzeid/nvim-lspinstall',
  'ananthakumaran/tree-sitter-elixir';
  {'nvim-treesitter/nvim-treesitter', run = ':TSUpdate'};
  'nvim-telescope/telescope.nvim';
  'hrsh7th/nvim-compe';
  'nvim-treesitter/highlight.lua';
  'neovim/nvim-lspconfig';
  'norcalli/nvim-base16.lua';
  'lewis6991/gitsigns.nvim';
  'airblade/vim-rooter';
  'mhartington/formatter.nvim';
})
