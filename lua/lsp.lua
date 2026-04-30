require('mason').setup({
    ui = {
        icons = {
            package_installed = "√",
            package_pending = "→",
            package_uninstalled = "×"
        }
    }
})


-- None LSP tools
local non_lsp_tools = {
    'bacon',
    'cspell',
}

local registry = require("mason-registry")
vim.defer_fn(function()
    for _, tool in ipairs(non_lsp_tools) do
        if registry.has_package(tool) then
            local pkg = registry.get_package(tool)
            if not pkg:is_installed() then
                print("Mason installing: " .. tool)
                pkg:install()
            end
        else
            print("Mason tool cannot found: " .. tool)
        end
    end
end, 1000)

--- including: 'prettier'
local desired_lsps = {
    'lua_ls',
    'marksman',
    'pyright', 'ruff',
    'ts_ls', 'biome',
    'rust_analyzer',
    'omnisharp',
    'nil_ls',
    'slint_lsp'
}

local lsp_allowed_users = {
    slint_lsp = { "mein" }, -- 只有用户名是 mein 的机器才会装 slint
    omnisharp = { "mein" },
    rust_analyzer = { "mein" },
    nil_ls = { "mein" },
}

local lsp_dependencies = {
    omnisharp     = { "unzip" }, -- omnisharp 需要 unzip 才能解压
    nil_ls        = { "nix" },   -- nil_ls 只有在有 nix 的环境下才有意义
    biome         = { "npm" },   -- biome 需要 npm
    ts_ls         = { "npm" },
    rust_analyzer = { "cargo" }, -- rust 依赖 cargo
    pyright       = { "npm" },
}

local ensure_installed_lsp = {}
local missing_deps_msgs = {} -- 存警告信息
local skip_logs = {}         -- 存普通日志信息
local current_user = os.getenv("USER") or os.getenv("USERNAME") or "unknown_user"

for _, lsp in ipairs(desired_lsps) do
    local can_install = true
    -- 检查用户白名单
    if lsp_allowed_users[lsp] then
        local user_matched = false
        for _, allowed_user in ipairs(lsp_allowed_users[lsp]) do
            if current_user == allowed_user then
                user_matched = true
                break
            end
        end

        -- 如果当前用户不在白名单里，静默跳过
        if not user_matched then
            can_install = false
            table.insert(skip_logs, string.format("Skipped '%s' (User '%s' ignored)", lsp, current_user))
        end
    end
    -- 检查前置依赖
    if can_install and lsp_dependencies[lsp] then
        for _, cmd in ipairs(lsp_dependencies[lsp]) do
            if vim.fn.executable(cmd) == 0 then
                can_install = false
                table.insert(missing_deps_msgs, string.format("Skipped '%s' (Missing system cmd: %s)", lsp, cmd))
                break
            end
        end
    end

    -- 如果条件都满足，才加入 Mason 的安装列表
    if can_install then
        table.insert(ensure_installed_lsp, lsp)
    end
end
require('mason-lspconfig').setup({
    -- A list of servers to automatically install if they're not already installed
    ensure_installed = ensure_installed_lsp,
    automatic_installation = true,
})

-- 如果有因为缺少依赖而被跳过的 LSP，在启动时给出黄字警告
if #missing_deps_msgs > 0 then
    -- 延迟一小会儿显示，避免被启动画面盖住
    vim.defer_fn(function()
        vim.notify(
            "LSP Setup Warnings:\n" .. table.concat(missing_deps_msgs, "\n"),
            vim.log.levels.WARN,
            { title = "LSP Dependencies" }
        )
    end, 2000)
end

-- rest of the configuration
-- Set different settings for different languages' LSP
-- LSP list: https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md
-- How to use setup({}): https://github.com/neovim/nvim-lspconfig/wiki/Understanding-setup-%7B%7D
--     - the settings table is sent to the LSP
--     - on_attach: a lua callback function to run after LSP attaches to a given buffer

-- Customized on_attach function
-- See `:help vim.diagnostic.*` for documentation on any of the below functions
local opts = { noremap = true, silent = true }
vim.keymap.set('n', '<space>e', vim.diagnostic.open_float, vim.tbl_extend("force", opts, { desc = "Show Diagnostics" }))
vim.keymap.set('n', '<space>q', vim.diagnostic.setloclist, vim.tbl_extend("force", opts, { desc = "Diagnostics List" }))

-- 创建一个全局的格式化自动命令组
local lsp_fmt_group = vim.api.nvim_create_augroup('LspFormattingGroup', {})
-- Use an on_attach function to only map the following keys
-- after the language server attaches to the current buffer
local on_attach = function(client, buf_nr)
    -- Enable completion triggered by <c-x><c-o>
    -- See `:help vim.lsp.*` for documentation on any of the below functions
    local map = function(mode, keys, func, desc)
        vim.keymap.set(mode, keys, func, { buffer = buf_nr, desc = "LSP: " .. desc })
    end
    map('n', 'gD', vim.lsp.buf.declaration, "Goto Declaration")
    map('n', 'gd', vim.lsp.buf.definition, "Goto Definition")
    map('n', 'K', vim.lsp.buf.hover, "Hover Documentation")
    map('n', 'gi', vim.lsp.buf.implementation, "Goto Implementation")
    map('n', '<C-k>', vim.lsp.buf.signature_help, "Signature Help")

    map('n', '<Space>D', vim.lsp.buf.type_definition, "Type Definition")
    map('n', '<Space>rn', vim.lsp.buf.rename, "Rename Symbol")
    map('n', '<Space>ca', vim.lsp.buf.code_action, "Code Action")
    map('n', 'gr', vim.lsp.buf.references, "Goto References")
    map('n', '<Space>f', function() vim.lsp.buf.format({ async = true }) end, "Format Document")
    map('n', '<leader>th', function()
        vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = buf_nr }))
    end, 'Toggle Inlay Hints')

    -- 工作区相关
    map('n', '<Space>wa', vim.lsp.buf.add_workspace_folder, "Add Workspace Folder")
    map('n', '<Space>wr', vim.lsp.buf.remove_workspace_folder, "Remove Workspace Folder")
    map('n', '<Space>wl', function()
        print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
    end, "List Workspace Folders")


    -- 1. Inlay Hints (手动开启逻辑)
    if client.server_capabilities.inlayHintProvider then
        vim.keymap.set('n', '<leader>th', function()
            local is_enabled = vim.lsp.inlay_hint.is_enabled({ bufnr = buf_nr })
            vim.lsp.inlay_hint.enable(not is_enabled, { bufnr = buf_nr })
            print("Inlay Hints: " .. (is_enabled and "OFF" or "ON"))
        end, { desc = 'Toggle Inlay Hints', buffer = buf_nr })
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
        vim.api.nvim_clear_autocmds({ group = lsp_fmt_group, buffer = buf_nr })

        -- 创建在保存前 (BufWritePre) 触发的自动命令
        vim.api.nvim_create_autocmd("BufWritePre", {
            group = lsp_fmt_group,
            buffer = buf_nr,
            callback = function()
                -- 注意：保存时的格式化必须是同步的 (async = false)
                -- 否则可能在格式化完成前文件就保存了
                vim.lsp.buf.format({
                    async = false,
                    bufnr = buf_nr
                })
            end,
        })
    end
end

-- which-key group setting
local wk_status, wk = pcall(require, "which-key")
if wk_status then
    wk.add({
        { "<space>w",  group = "Workspace" },
        { "<space>r",  group = "Rename" },
        { "<space>c",  group = "Code Action" },
        { "<leader>a", group = "Avante" },
    })
end


local cmp_nvim_lsp = require('cmp_nvim_lsp')
local cmp = require('cmp')
local lsp_capabilities = cmp_nvim_lsp.default_capabilities()

cmp.setup({
    snippet = {
        expand = function(args)
            require('luasnip').lsp_expand(args.body)
        end,
    },
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

        return vim.fs.dirname(fname)
    end,
}


for name, config in pairs(servers) do
    local final_config = vim.tbl_deep_extend("force", common_config, config)
    lspconfig[name].setup(final_config)
end


--- none lsp tools
local null_ls_status, null_ls = pcall(require, "null-ls")
local cspell_status, cspell = pcall(require, "cspell")

if null_ls_status and cspell_status then
    -- 自定义 cspell 的行为
    local cspell_config = {
        config = {
            -- 告诉插件：当我要添加白名单单词时，写到哪个文件里
            -- 如果当前目录下没有，它会自动在 ~/.config/nvim/ (或你的家目录) 找全局配置
            find_json = function(_)
                return vim.fn.expand("cspell.json")
            end,
        },
    }

    null_ls.setup({
        sources = {
            -- 1. 注入拼写检查的红波浪线
            cspell.diagnostics.with({
                config = cspell_config,
                -- 诊断信息的级别，设为 HINT 或 WARN 避免满屏爆红太刺眼
                diagnostics_postprocess = function(diagnostic)
                    diagnostic.severity = vim.diagnostic.severity.HINT
                end,
            }),
            -- 2. 注入“添加到字典”的快捷修复动作
            cspell.code_actions.with({ config = cspell_config }),
        },
    })
end
