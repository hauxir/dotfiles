require("chatgpt").setup({})
local set_keymap = require('../utils').set_keymap
set_keymap('n', '<leader>a', '<cmd> ChatGPTEditWithInstructions<cr>')
