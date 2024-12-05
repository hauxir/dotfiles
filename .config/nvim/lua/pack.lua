local cmd = vim.cmd

cmd 'packadd paq-nvim'
require('paq')({
  'airblade/vim-rooter';
  'elixir-lang/tree-sitter-elixir';

   -- Completion
  'hrsh7th/nvim-cmp';
  'hrsh7th/cmp-nvim-lsp';
  'hrsh7th/cmp-buffer';
  'hrsh7th/cmp-path';
  'hrsh7th/cmp-cmdline';
  'hrsh7th/cmp-calc';
  'hrsh7th/cmp-emoji';
  'onsails/lspkind-nvim';

  'mhartington/formatter.nvim';
  'neovim/nvim-lspconfig',
  'norcalli/nvim-base16.lua';
  'nvim-lua/plenary.nvim';
  'nvim-lua/popup.nvim';
  'nvim-telescope/telescope.nvim';
  'nvim-telescope/telescope-fzf-native.nvim';
  {'nvim-treesitter/nvim-treesitter', run = ':TSUpdate'};
  {'savq/paq-nvim', opt = true};
  'zbirenbaum/copilot.lua';
  'zbirenbaum/copilot-cmp';

  "jackMort/ChatGPT.nvim";
  "MunifTanjim/nui.nvim";
  "nvim-lua/plenary.nvim";
  'nvim-lualine/lualine.nvim', requires = { 'nvim-tree/nvim-web-devicons', opt = true };
})
