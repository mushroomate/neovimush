-- define the colorscheme here
-- local colorscheme = "monokai_pro" -- <-- it's monokaipro of monokai theme.
local colorscheme = "monokai-pro" -- <-- it's Monokai Pro  plugin

local is_ok, _ = pcall(vim.cmd, "colorscheme " .. colorscheme)
if not is_ok then
    vim.notify('colorscheme ' .. colorscheme .. ' not found!')
    return
end
