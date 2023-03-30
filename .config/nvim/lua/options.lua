local opt = vim.opt
local g = vim.g
local cmd = vim.cmd

g.mapleader = ','

cmd 'filetype plugin indent on'

opt.completeopt = {'menuone', 'noselect'}

opt.number = true

opt.backspace = {'indent','eol','start'}  -- Make backspace work as expected
opt.sidescroll = 1                -- Scroll one char horizontally instead of half page
opt.sidescrolloff = 20            -- How many chars away from the edge should start scroll
opt.linebreak = true

opt.expandtab = true
opt.autoindent = true
opt.tabstop = 2
opt.softtabstop = 2
opt.shiftwidth = 2

opt.hlsearch = true               -- Highlight when searching
opt.ignorecase = true             -- Ignore casing while searching
opt.incsearch = true              -- Incremental search while typing

opt.hidden = true
opt.cursorline = true
opt.termguicolors = true
opt.mouse = "a"


-- Theme
cmd 'syntax enable'

-- IndentLine
g.indent_blankline_use_treesitter = true
g.indent_blankline_show_current_context = true
g.indent_blankline_buftype_exclude = {'terminal'}

-- Rooter
g.rooter_patterns = {'.git'}
