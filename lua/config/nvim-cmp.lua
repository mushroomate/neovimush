local has_words_before = function()
    local line, col = vim.api.nvim_win_get_cursor(0)
    return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
end

local luasnip = require("luasnip")
local cmp = require("cmp")

local cmp_sources = {
    { name = 'lazydev' }, -- For lazydev users (Lua LSP hints)
    { name = 'nvim_lsp' }, -- For nvim-lsp
    { name = 'luasnip' },  -- For luasnip user
}

if vim.fn.environ()["DEEPSEEK_API_KEY"] ~= nil then
    table.insert(cmp_sources, { name = 'minuet' })
end

cmp.setup({
    snippet = {
        -- REQUIRED - you must specify a snippet engine
        expand = function(args)
            require('luasnip').lsp_expand(args.body) -- For `luasnip` users.
        end,
    },
    window = {
        completion = cmp.config.window.bordered(),
        documentation = cmp.config.window.bordered(),
    },
    mapping = cmp.mapping.preset.insert({
        -- Use <C-b/f> to scroll the docs
        ['<C-b>'] = cmp.mapping.scroll_docs(-4),
        ['<C-f>'] = cmp.mapping.scroll_docs(4),
        -- Use <C-Space> to trigger completion manually
        ['<C-Space>'] = cmp.mapping.complete(),
        -- Use <C-e> to abort completion
        ['<C-e>'] = cmp.mapping.abort(),
        -- Use <C-k/j> to switch items
        ['<C-k>'] = cmp.mapping.select_prev_item(),
        ['<C-j>'] = cmp.mapping.select_next_item(),
        -- Use <CR>(Enter) to confirm selection
        -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
        ['<CR>'] = cmp.mapping.confirm({ select = true }),

        -- A super tab
        -- source: https://github.com/hrsh7th/nvim-cmp/wiki/Example-mappings#luasnip
        ["<Tab>"] = cmp.mapping(function(fallback)
            -- Hint: if the completion menu is visible select next one
            if cmp.visible() then
                cmp.select_next_item()
            elseif has_words_before() then
                cmp.complete()
            else
                fallback()
            end
        end, { "i", "s" }), -- i - insert mode; s - select mode
        ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
                cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
                luasnip.jump(-1)
            else
                fallback()
            end
        end, { "i", "s" }),
    }),
    performance = {
        fetching_timeout = 2000,
    },

    -- Let's configure the item's appearance
    -- source: https://github.com/hrsh7th/nvim-cmp/wiki/Menu-Appearance
    formatting = {
        -- Set order from left to right
        -- kind: single letter indicating the type of completion
        -- abbr: abbreviation of "word"; when not empty it is used in the menu instead of "word"
        -- menu: extra text for the popup menu, displayed after "word" or "abbr"
        fields = { 'abbr', 'menu' },

        -- customize the appearance of the completion menu
        format = function(entry, vim_item)
            vim_item.menu = ({
                nvim_lsp = '[Lsp]',
                luasnip = '[Luasnip]',
                buffer = '[File]',
                path = '[Path]',
            })[entry.source.name]
            return vim_item
        end,
    },

    -- Set source precedence
    sources = cmp.config.sources(cmp_sources, {
        { name = 'buffer' }, -- For buffer word completion
        { name = 'path' },   -- For path completion
    }),
})
