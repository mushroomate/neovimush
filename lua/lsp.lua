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
local ensure_installed_lsp = { 'pyright', 'ruff', 'lua_ls', 'rust_analyzer', 'marksman', 'omnisharp', 'nil_ls', 'ts_ls',
    'biome' }

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

-- 创建一个全局的格式化自动命令组
local lsp_fmt_group = vim.api.nvim_create_augroup('LspFormattingGroup', {})
-- Use an on_attach function to only map the following keys
-- after the language server attaches to the current buffer
local on_attach = function(client, bufnr)
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
    vim.keymap.set('n', '<leader>th', function()
        vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr }))
    end, { desc = 'Toggle Inlay Hints', buffer = bufnr })


    -- 1. Inlay Hints (手动开启逻辑)
    if client.server_capabilities.inlayHintProvider then
        vim.keymap.set('n', '<leader>th', function()
            local is_enabled = vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr })
            vim.lsp.inlay_hint.enable(not is_enabled, { bufnr = bufnr })
            print("Inlay Hints: " .. (is_enabled and "OFF" or "ON"))
        end, { desc = 'Toggle Inlay Hints', buffer = bufnr })
    end

    -- 2. 解决多 Formatter 冲突：明确分工
    -- 严禁 pyright 和 ts_ls 参与格式化，把舞台留给 ruff 和 biome
    if client.name == "pyright" or client.name == "ts_ls" then
        client.server_capabilities.documentFormattingProvider = false
        client.server_capabilities.documentRangeFormattingProvider = false
    end

    -- 3. 配置保存时自动格式化 (Format on Save)
    -- 如果当前接入的 LSP 支持格式化，则绑定保存事件
    if client.server_capabilities.documentFormattingProvider then
        -- 每次附加时，先清除旧的自动命令，防止多次触发
        vim.api.nvim_clear_autocmds({ group = lsp_fmt_group, buffer = bufnr })

        -- 创建在保存前 (BufWritePre) 触发的自动命令
        vim.api.nvim_create_autocmd("BufWritePre", {
            group = lsp_fmt_group,
            buffer = bufnr,
            callback = function()
                -- 注意：保存时的格式化必须是同步的 (async = false)
                -- 否则可能在格式化完成前文件就保存了
                vim.lsp.buf.format({
                    async = false,
                    bufnr = bufnr
                })
            end,
        })
    end
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

servers.rust_analyzer = {
    settings = {
        ["rust-analyzer"] = {
            inlayHints = {
                -- 1. 类型提示：告诉插件是否显示变量、闭包的推导类型
                typeHints = {
                    -- 核心开关：显示 let x = 5; 这里的 i32
                    enable = true,
                    -- 是否隐藏闭包初始化时的类型
                    hideClosureInitialization = false,
                    -- 如果构造函数名已知（如 Vec::new()），是否隐藏类型提示
                    hideNamedConstructor = false,
                },

                -- 2. 参数名提示：在调用函数时，显示形参的名字
                parameterHints = {
                    -- 核心开关：显示 test_func(a: 1, b: 2) 中的 a: 和 b:
                    enable = true
                },

                -- 3. 链式调用提示：在使用迭代器或长链式调用时，显示每一步返回的类型
                chainingHints = {
                    -- 非常有用！能看到 .map().filter() 每一层的返回类型
                    enable = true
                },

                -- 4. 结尾括号提示：在函数或循环的大括号结尾显示它是属于谁的
                closingBraceHints = {
                    enable = true,
                    -- 只有当代码块超过 25 行时才显示（避免短代码太乱）
                    minLines = 25
                },

                -- 5. 生命周期提示：通常建议关闭，除非你在深度优化引用逻辑
                lifetimeElisionHints = {
                    -- 设置为 "never" 因为这会让代码看起来非常臃肿
                    enable = "never",
                    useParameterNames = false
                },

                -- 6. 其他视觉控制
                -- 在提示文字前是否渲染冒号 (例如显示 ": i32" 还是 "i32")
                renderColons = true,
                -- 提示信息的最大字符长度，超过会截断
                maxLength = 25,
            },
        },
    },
}
servers.marksman = {}
servers.omnisharp = {
    settings = {
        RoslynExtensionsOptions = {
            EnableInlayHintsForParameters = true,
            EnableInlayHintsForLiteralParameters = true,
            EnableInlayHintsForTypes = true,
            EnableInlayHintsForImplicitVariableTypes = true,
            EnableInlayHintsForLambdaParameterTypes = true,
            EnableInlayHintsForImplicitObjectCreation = true,
        }
    }
}

servers.ruff = {}

servers.pyright = {
    settings = {
        python = {
            analysis = {
                typeCheckingMode = "basic", -- 推荐 basic，strict 可能会报太多类型警告
                -- 开启 Pyright 的内联提示
                inlayHints = {
                    variableTypes = true,       -- 显示变量的推导类型
                    functionReturnTypes = true, -- 显示函数的推导返回值类型
                    callArgumentNames = true,   -- 显示函数调用的参数名
                    pytestParameters = true,    -- pytest fixture 提示
                },
            },
        },
    },
}

-- 提取一个通用的 hint 配置表，给 js 和 ts 复用
local ts_inlay_hints = {
    includeInlayEnumMemberValueHints = true,
    includeInlayFunctionLikeReturnTypeHints = true,
    includeInlayFunctionParameterTypeHints = true,
    includeInlayParameterNameHints = "all",                        -- 可选 "none" | "literals" | "all"
    includeInlayParameterNameHintsWhenArgumentMatchesName = false, -- 如果参数名和传入的变量名一样，则隐藏（智能降噪）
    includeInlayPropertyDeclarationTypeHints = true,
    includeInlayVariableTypeHints = true,
}

servers.ts_ls = {
    settings = {
        -- TypeScript 的提示配置
        typescript = {
            inlayHints = ts_inlay_hints,
        },
        -- JavaScript 的提示配置
        javascript = {
            inlayHints = ts_inlay_hints,
        },
    }
}
servers.nil_ls = {}

servers.lua_ls = {
    settings = {
        Lua = {
            runtime = { version = 'LuaJIT' },
            telemetry = { enable = false },
            hint = {
                enable = true,
                setType = true,
                paramName = "All",
                paramType = true,
                await = true,
                arrayIndex = "Disable",
            },
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
