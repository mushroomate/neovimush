-- default terminal
local default_shell
if vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1 then
    default_shell = "pwsh"
else
    default_shell = "zsh"
end
vim.o.shell = default_shell

-- Hint: use `:h <option>` to figure out the meaning if needed
vim.g.clipboard = 'osc52' --use system clipboard
vim.opt.completeopt = { 'menu', 'menuone', 'noselect' }
vim.opt.mouse = 'a'       -- allow the mouse to be used in Nvim

-- Tab
vim.opt.tabstop = 4      -- number of visual spaces per TAB
vim.opt.softtabstop = 4  -- number of speces in tab when editing
vim.opt.shiftwidth = 4   -- insert 4 space on a tab
vim.opt.expandtab = true -- tabs are spaces, mainly because of pythn

-- UI config
vim.opt.number = true         -- show absolute number
vim.opt.relativenumber = true -- add numbers to each line on the left side
vim.opt.cursorline = true     -- highlight cursor line underneath the cursor horizontally
vim.opt.splitbelow = true     -- open new vertical split bottom
vim.opt.splitright = true     -- open new horizontal split right
-- vim.opt.termguicolors =  true -- enable 24-bit RGB color in the TUI
vim.opt.showmode = false      -- turn of the "-- INSERT --" mode hint

-- Searching
vim.opt.incsearch = true  -- search as characters are entered
vim.opt.hlsearch = true   -- do highlight matches
vim.opt.ignorecase = true -- ignore case in searches by default
vim.opt.smartcase = true  -- but make it case sensitive if an uppercase is entered

-- encoding
vim.opt.encoding = 'utf-8'

-- GUI setting
if vim.g.neovide then
    -- clipboard
    vim.g.neovide_no_terminal_clipboard = true
    if vim.fn.executable('wl-copy') == 1 then
        -- wayland
        vim.g.clipboard = {
            name = 'wl-clipboard',
            copy = {
                ['+'] = { 'wl-copy', '--type', 'text/plain' },
                ['*'] = { 'wl-copy', '--type', 'text/plain' },
            },
            paste = {
                ['+'] = { 'wl-paste', '--no-newline' },
                ['*'] = { 'wl-paste', '--no-newline' },
            },
        }
    elseif vim.fn.executable('xclip') == 1 then
        -- X11
        vim.g.clipboard = {
            name = 'xclip',
            copy = {
                ['+'] = { 'xclip', '-selection', 'clipboard' },
                ['*'] = { 'xclip', '-selection', 'clipboard' },
            },
            paste = {
                ['+'] = { 'xclip', '-selection', 'clipboard', '-o' },
                ['*'] = { 'xclip', '-selection', 'clipboard', '-o' },
            },
        }
    else
        vim.g.clipboard = "unnamedplus"
    end

    -- enable multigrid mode
    vim.g.neovide_multigrid = true

    -- font setting
    -- vim.opt.guifont = "Inconsolata Nerd Font Mono:h16"
    vim.opt.guifont = "DepartureMono Nerd Font Propo,Inconsolata Nerd Font Mono:h12"

    -- opacity & blur
    vim.g.neovide_opacity = 0.92
    vim.g.neovide_floating_blur_amount_x = 2.0
    vim.g.neovide_floating_blur_amount_y = 2.0

    -- cursor
    vim.g.neovide_cursor_vfx_mode = "pixiedust"
    vim.g.neovide_cursor_animation_length = 0.13
    vim.g.neovide_cursor_trail_size = 0.8
    vim.g.neovide_hide_mouse_when_typing = true

    -- refresh rate
    vim.g.neovide_refresh_rate = 144
    vim.g.neovide_refresh_rate_idle = 5

    -- AA
    vim.g.neovide_font_antialias = true
    vim.g.neovide_font_subpixel = true

    -- IME optmize (I don't know the feature of this option now)
    -- vim.g.neovide_input_ime = true

    -- shortcut
    vim.keymap.set('n', '<F11>', function()
        vim.g.neovide_fullscreen = not vim.g.neovide_fullscreen
    end)
end
