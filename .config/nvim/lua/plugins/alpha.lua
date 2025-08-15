local alpha = require('alpha')
local dashboard = require('alpha.themes.dashboard')

-- Set header
dashboard.section.header.val = {
  '                                                     ',
  '  ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗',
  '  ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║',
  '  ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║',
  '  ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║',
  '  ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║',
  '  ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝',
  '                                                     ',
}

-- Set menu
dashboard.section.buttons.val = {
  dashboard.button('f', '  Find file', ':Telescope git_files<CR>'),
  dashboard.button('e', '  New file', ':ene <BAR> startinsert<CR>'),
  dashboard.button('r', '  Recent files', ':Telescope oldfiles<CR>'),
  dashboard.button('g', '  Find text', ':Telescope live_grep<CR>'),
  dashboard.button('c', '  Configuration', ':e ~/.config/nvim/init.lua<CR>'),
  dashboard.button('q', '  Quit Neovim', ':qa<CR>'),
}

-- Set footer
local function footer()
  local version = vim.version()
  local nvim_version = '  v' .. version.major .. '.' .. version.minor .. '.' .. version.patch
  
  -- Get current git branch
  local git_branch = vim.fn.system("git branch --show-current 2>/dev/null | tr -d '\n'")
  local branch_info = ''
  if git_branch ~= '' then
    branch_info = '  ' .. git_branch
  end
  
  return nvim_version .. branch_info
end

dashboard.section.footer.val = footer()

-- Set colors
dashboard.section.header.opts.hl = 'Include'
dashboard.section.buttons.opts.hl = 'Keyword'
dashboard.section.footer.opts.hl = 'Type'

-- Configure layout
dashboard.opts.layout = {
  { type = 'padding', val = 2 },
  dashboard.section.header,
  { type = 'padding', val = 2 },
  dashboard.section.buttons,
  { type = 'padding', val = 1 },
  dashboard.section.footer,
}

-- Setup alpha
alpha.setup(dashboard.opts)

-- Configure Alpha buffer
vim.cmd([[
  autocmd FileType alpha setlocal nofoldenable
]])

-- Hide tabline when Alpha is the only buffer
vim.api.nvim_create_autocmd('User', {
  pattern = 'AlphaReady',
  callback = function()
    vim.opt.showtabline = 0
    vim.api.nvim_create_autocmd('BufUnload', {
      buffer = 0,
      callback = function()
        vim.opt.showtabline = 2
      end
    })
  end
})