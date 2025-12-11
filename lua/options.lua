-- default terminal
vim.o.shell = "zsh"

-- Hint: use `:h <option>` to figure out the meaning if needed
vim.g.clipboard = 'osc52' --use system clipboard
vim.opt.completeopt = { 'menu', 'menuone', 'noselect' }
vim.opt.mouse = 'a' -- allow the mouse to be used in Nvim

-- Tab
vim.opt.tabstop = 4 -- number of visual spaces per TAB
vim.opt.softtabstop = 4 -- number of speces in tab when editing
vim.opt.shiftwidth = 4 -- insert 4 space on a tab 
vim.opt.expandtab = true -- tabs are spaces, mainly because of pythn

-- UI config
vim.opt.number = true -- show absolute number
vim.opt.relativenumber = true -- add numbers to each line on the left side
vim.opt.cursorline = true -- highlight cursor line underneath the cursor horizontally
vim.opt.splitbelow = true -- open new vertical split bottom
vim.opt.splitright = true -- open new horizontal split right
-- vim.opt.termguicolors =  true -- enable 24-bit RGB color in the TUI
vim.opt.showmode = false -- turn of the "-- INSERT --" mode hint

-- Searching
vim.opt.incsearch = true -- search as characters are entered
vim.opt.hlsearch = true -- do highlight matches
vim.opt.ignorecase = true -- ignore case in searches by default
vim.opt.smartcase = true -- but make it case sensitive if an uppercase is entered

-- encoding
vim.opt.encoding = 'utf-8'
