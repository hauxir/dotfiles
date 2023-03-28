local cmd = vim.cmd

cmd 'packadd paq-nvim'
require('paq')({
  'airblade/vim-rooter';
  'ananthakumaran/tree-sitter-elixir';
  'hrsh7th/nvim-compe';
  'jose-elias-alvarez/nvim-lsp-ts-utils',
  'kabouzeid/nvim-lspinstall',
  'mhartington/formatter.nvim';
  'neovim/nvim-lspconfig',
  'norcalli/nvim-base16.lua';
  'nvim-lua/plenary.nvim';
  'nvim-lua/popup.nvim';
  'nvim-telescope/telescope.nvim';
  'nvim-telescope/telescope-fzf-native.nvim';
  'nvim-treesitter/highlight.lua';
  {'nvim-treesitter/nvim-treesitter', run = ':TSUpdate'};
  {'savq/paq-nvim', opt = true};
})
