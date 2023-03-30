local cmd = vim.cmd

cmd 'packadd paq-nvim'
require('paq')({
  'airblade/vim-rooter';
  'ananthakumaran/tree-sitter-elixir';

   -- Completion
  'hrsh7th/nvim-cmp';
  'hrsh7th/cmp-nvim-lsp';
  'hrsh7th/cmp-buffer';
  'hrsh7th/cmp-path';
  'hrsh7th/cmp-cmdline';
  'hrsh7th/cmp-calc';
  'hrsh7th/cmp-emoji';
  'onsails/lspkind-nvim';
  
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
  'zbirenbaum/copilot.lua';
  'zbirenbaum/copilot-cmp';
})
