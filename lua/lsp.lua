require('mason').setup({
    ui = {
        icons = {
            package_installed = "√",
            package_pending = "→",
            package_uninstalled = "×"
        }
    }
})

--- todo: add Linter & Formatter modules
---       including: 'prettier'
local ensure_installed_lsp = { 'ruff', 'lua_ls', 'rust_analyzer', 'marksman', 'omnisharp', 'nil_ls', 'biome' }

-- Discard LSPs which do not supported by Windows
if vim.fn.has("win32") == 1 then
    local windows_exclude = { 'nil_ls' }

    for i = #ensure_installed_lsp, 1, -1 do
        local current_tool = ensure_installed_lsp[i]

        for _, exlude_name in ipairs(windows_exclude) do
            if current_tool == exlude_name then
                table.remove(ensure_installed_lsp, i)
            end
        end
    end
end

require('mason-lspconfig').setup({
    -- A list of servers to automatically install if they're not already installed
    ensure_installed = ensure_installed_lsp,
    automatic_installation = true,
})

-- rest of the configuration
-- Set different settings for different languages' LSP
-- LSP list: https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md
-- How to use setup({}): https://github.com/neovim/nvim-lspconfig/wiki/Understanding-setup-%7B%7D
--     - the settings table is sent to the LSP
--     - on_attach: a lua callback function to run after LSP attaches to a given buffer

-- Customized on_attach function
-- See `:help vim.diagnostic.*` for documentation on any of the below functions
local opts = { noremap = true, silent = true }
vim.keymap.set('n', '<space>e', vim.diagnostic.open_float, opts)
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, opts)
vim.keymap.set('n', ']d', vim.diagnostic.goto_next, opts)
vim.keymap.set('n', '<space>q', vim.diagnostic.setloclist, opts)

-- Use an on_attach function to only map the following keys
-- after the language server attaches to the current buffer
local on_attach = function(bufnr)
    -- Enable completion triggered by <c-x><c-o>
    vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')

    -- See `:help vim.lsp.*` for documentation on any of the below functions
    local bufopts = { noremap = true, silent = true, buffer = bufnr }
    vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, bufopts)
    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, bufopts)
    vim.keymap.set('n', 'K', vim.lsp.buf.hover, bufopts)
    vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, bufopts)
    vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, bufopts)
    vim.keymap.set('n', '<space>wa', vim.lsp.buf.add_workspace_folder, bufopts)
    vim.keymap.set('n', '<space>wr', vim.lsp.buf.remove_workspace_folder, bufopts)
    vim.keymap.set('n', '<space>wl', function()
        print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
    end, bufopts)
    vim.keymap.set('n', '<space>D', vim.lsp.buf.type_definition, bufopts)
    vim.keymap.set('n', '<space>rn', vim.lsp.buf.rename, bufopts)
    vim.keymap.set('n', '<space>ca', vim.lsp.buf.code_action, bufopts)
    vim.keymap.set('n', 'gr', vim.lsp.buf.references, bufopts)
    vim.keymap.set("n", "<space>f", function()
        vim.lsp.buf.format({ async = true })
    end, bufopts)
end

local cmp_nvim_lsp = require('cmp_nvim_lsp')
local cmp = require('cmp')
local lsp_capabilities = cmp_nvim_lsp.default_capabilities()

cmp.setup({
    snippet = { ... },
    window = {
        completion = cmp.config.window.bordered(),
        documentation = cmp.config.window.bordered(),
    },
    mapping = cmp.mapping.preset.insert({
        ['<C-b>'] = cmp.mapping.scroll_docs(-4),
        ['<C-f>'] = cmp.mapping.scroll_docs(4),
        ['<C-Space>'] = cmp.mapping.complete(),
        ['<C-e>'] = cmp.mapping.abort(),
        ['<CR>'] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
    }),
    sources = cmp.config.sources({
        { name = 'lazydev' },
        { name = 'nvim_lsp' },
        -- { name = 'vsnip' }, -- For vsnip users.
        { name = 'luasnip' }, -- For luasnip users.
        -- { name = 'ultisnips' }, -- For ultisnips users.
        -- { name = 'snippy' }, -- For snippy users.
    }, {
        { name = 'buffer' },
        { name = 'path' },
    })
})

local common_config = {
    on_attach = on_attach,
    -- 可以在这里添加其他通用设置，例如 capabilities
    capabilities = lsp_capabilities,
}


local util = require("lspconfig.util")
local lspconfig = require("lspconfig")
local servers = {}

servers.ruff = {}
servers.rust_analyzer = {}
servers.marksman = {}
servers.omnisharp = {}
servers.nil_ls = {}

servers.lua_ls = {
    settings = {
        Lua = {
            runtime = { version = 'LuaJIT' },
            diagnostics = { globals = { 'vim' } },
            workspace = { library = vim.api.nvim_get_runtime_file("", true) },
            telemetry = { enable = false },
        }
    }
}

servers.biome = {
    filetypes = {
        "javascript", "javascriptreact", "typescript", "typescript.tsx",
        "json", "jsonc", "css", "svelte", "vue", "astro"
    },
    single_file_support = true,
    root_dir = function(fname)
        -- fname 是文件路径(string)
        local root_file = util.root_pattern("biome.json", "biome.jsonc")(fname)
        if root_file then
            return root_file
        end

        local git_root = util.root_pattern(".git")(fname)
        if git_root then
            return git_root
        end

        return util.path.dirname(fname)
    end,
}


for name, config in pairs(servers) do
    local final_config = vim.tbl_deep_extend("force", common_config, config)
    lspconfig[name].setup(final_config)
end
