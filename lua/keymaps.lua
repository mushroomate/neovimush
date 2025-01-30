-- magic setting
-- local map = vim.api.nvim_set_keymap
-- vim.g.mapleader=' '

-- define common options
local opts = {
    noremap = true,
    silent = true,
}

-----------------
-- Normal mode --
-----------------

-- Hint: see `:h vim.map.set()`
-- Better window navigation
vim.keymap.set('n', '<C-h>', '<C-w>h', opts)
vim.keymap.set('n', '<C-j>', '<C-w>j', opts)
vim.keymap.set('n', '<C-k>', '<C-w>k', opts)
vim.keymap.set('n', '<C-l>', '<C-w>l', opts)

-- Resize iwth arrows
-- delta: 2 lines
vim.keymap.set('n', '<C-Up>', ':resize -2<CR>', opts)
vim.keymap.set('n', '<C-Down>', ':resize +2<CR>', opts)
vim.keymap.set('n', '<C-Left>', ':vertical resize -2<CR>', opts)
vim.keymap.set('n', '<C-Right>', ':vertical resize +2<CR>', opts)


-----------------
-- Visual mode --
-----------------

-- Hint: start visual mode with the same area as the previous area as the previous area and the same mode
vim.keymap.set('v', '<', '<gv', opts)
vim.keymap.set('v', '>', '>gv', opts)


------------
-- Plugin --
------------
-- vim-translator
-- Echo translation in the cmdline    
vim.keymap.set('n', '<Leader>t', '<Plug>Translate', { silent = true })
vim.keymap.set('v', '<Leader>t', '<Plug>TranslateV', { silent = true })
-- Display translation in a window    
vim.keymap.set('n', '<Leader>w', '<Plug>TranslateW', { silent = true })
vim.keymap.set('v', '<Leader>w', '<Plug>TranslateWV', { silent = true })
-- Replace the text with translation    
vim.keymap.set('n', '<Leader>r', '<Plug>TranslateR', { silent = true })
vim.keymap.set('v', '<Leader>r', '<Plug>TranslateRV', { silent = true })
-- Translate the text in clipboard    
vim.keymap.set('n', '<Leader>x', '<Plug>TranslateX', { silent = true })
