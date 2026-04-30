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
    end, 2000) -- 将这个值改成500ms 或 1000
end


-- lspsaga 配置  确保在 plugins.lua 中有对应的插件声明
local saga_ok, saga = pcall(require, 'lspsaga')
if saga_ok then
    saga.setup({
        -- -------------------------------
        -- 悬停文档 (Hover)
        -- -------------------------------
        hover = {
            max_width = 0.6,  -- 窗口宽度占编辑器比例
            max_height = 0.6, -- 窗口高度比例
            -- 边框与标题
            border = 'rounded',
            title = ' Documentation ',
        },

        -- -------------------------------
        -- 代码动作 (Code Action)
        -- 增强：支持数字快捷键、预览 diff
        -- -------------------------------
        code_action = {
            num_shortcut = true,      -- 按数字快速选择动作
            show_server_name = false, -- 不显示 LSP 服务器名
            keys = {
                exec = '<CR>',        -- 执行当前动作
                quit = { 'q', '<Esc>' },
            },
            lightbulb = { -- 当有可用动作时，行号边显示灯泡
                enable = true,
                sign = true,
                virtual_text = false,
            },
        },

        -- -------------------------------
        -- 重命名 (Rename)
        -- -------------------------------
        rename = {
            in_select = true, -- 启动时自动高亮选中
            auto_save = false,
            keys = {
                exec = '<CR>',
                quit = { '<C-c>', '<Esc>' },
            },
        },

        -- -------------------------------
        -- 查找器 (Finder) — 引用/实现/定义预览
        -- 快捷键 gr, gi 将调用此模块
        -- -------------------------------
        finder = {
            max_height = 0.5,
            left_width = 0.4, -- 左侧预览窗口宽度
            methods = {       -- 可搜索的方法
                'textDocument/references',
                'textDocument/implementations',
                'textDocument/definitions',
            },
            default = 'ref+imp', -- 默认同时查引用和实现
            keys = {
                vsplit = 'v',    -- 垂直分屏打开
                split = 's',     -- 水平分屏打开
                quit = { 'q', '<Esc>' },
            },
        },

        -- -------------------------------
        -- 符号大纲 (Outline)
        -- -------------------------------
        outline = {
            layout = 'normal',      -- 使用分屏窗口，而不是浮动窗口
            win_position = 'right', -- 放在右侧
            win_width = 40,
            auto_preview = true,    -- 光标移动时自动预览符号位置
            keys = {
                jump = '<CR>',
                quit = { 'q', '<Esc>' },
            },
        },

        -- -------------------------------
        -- 诊断增强 (Diagnostic)
        -- 提供漂亮的浮动窗口和跳转列表
        -- -------------------------------
        diagnostic = {
            show_layout = 'float', -- 浮动窗口显示
            max_show_width = 0.7,
            wrap_long_lines = true,
            auto_preview = true,      -- 跳转时自动预览
            jump_num_shortcut = true, -- 数字跳转
            keys = {
                exec = 'o',
                quit = { 'q', '<Esc>' },
            },
        },

        -- -------------------------------
        -- 面包屑导航 (Winbar)
        -- 在顶部显示当前上下文，如 `struct Foo > fn bar`
        -- -------------------------------
        symbol_in_winbar = {
            enable = true,
            folder_level = 2,
            separator = ' > ',
            color_mode = true,
        },
    })

    -- 额外设置：诊断跳转快捷键（默认已配置 [[ 和 ]] 跳转到上一个/下一个诊断）
    -- 也可以在 on_attach 中不设置，直接使用 lspsaga 自带的映射
end


-- 快捷键映射
local opts = { noremap = true, silent = true }

-- 仅保留原生诊断相关的一个备用映射（发送到位置列表）
vim.keymap.set('n', '<space>q', vim.diagnostic.setloclist, vim.tbl_extend("force", opts, { desc = "Diagnostics List" }))

-- 格式化自动命令组
local lsp_fmt_group = vim.api.nvim_create_augroup('LspFormattingGroup', {})

local on_attach = function(client, buf_nr)
    local map = function(mode, keys, func, desc)
        vim.keymap.set(mode, keys, func, { buffer = buf_nr, desc = "LSP: " .. desc })
    end

    -- -------------------------------
    -- 导航：保留原生跳转（简洁可靠）
    -- -------------------------------
    map('n', 'gD', vim.lsp.buf.declaration, "Goto Declaration")
    map('n', '<Space>D', vim.lsp.buf.type_definition, "Type Definition")

    -- -------------------------------
    -- lspsaga 接管的功能
    -- -------------------------------
    -- 悬停文档 (K)
    map('n', 'K', '<Cmd>Lspsaga hover_doc<CR>', "Saga Hover")

    -- 定义预览 (gd)
    -- 使用 peek_definition 在浮动窗口中预览，按 Enter 可跳转
    map('n', 'gd', '<Cmd>Lspsaga peek_definition<CR>', "Saga Peek Definition")

    -- 查找引用/实现 (gr, gi)
    map('n', 'gr', '<Cmd>Lspsaga finder<CR>', "Saga Finder (refs+impls)")
    map('n', 'gi', '<Cmd>Lspsaga finder impl<CR>', "Saga Finder (impls only)")

    -- 代码动作 (<Space>ca)
    map('n', '<Space>ca', '<Cmd>Lspsaga code_action<CR>', "Saga Code Action")

    -- 重命名 (<Space>rn)
    map('n', '<Space>rn', '<Cmd>Lspsaga rename<CR>', "Saga Rename")

    -- 当前行诊断浮动窗口 (<Space>e)
    map('n', '<Space>e', '<Cmd>Lspsaga show_line_diagnostics<CR>', "Saga Line Diagnostics")

    -- 签名帮助 (保留原生，lspsaga 未提供更好的 UI)
    map('n', '<C-k>', vim.lsp.buf.signature_help, "Signature Help")

    -- 格式化
    map('n', '<Space>f', function() vim.lsp.buf.format({ async = true }) end, "Format Document")

    -- Inlay Hints 切换
    map('n', '<leader>th', function()
        vim.lsp.inlay_hint.enable(
            not vim.lsp.inlay_hint.is_enabled({ bufnr = buf_nr }),
            { bufnr = buf_nr }
        )
    end, 'Toggle Inlay Hints')

    -- Winbar 面包屑导航开关（如果你想临时关闭）
    map('n', '<leader>tw', '<Cmd>Lspsaga winbar_toggle<CR>', 'Toggle Winbar')

    -- 大纲侧边栏
    map('n', '<leader>o', '<Cmd>Lspsaga outline<CR>', "Saga Outline")

    -- 工作区管理
    map('n', '<Space>wa', vim.lsp.buf.add_workspace_folder, "Add Workspace Folder")
    map('n', '<Space>wr', vim.lsp.buf.remove_workspace_folder, "Remove Workspace Folder")
    map('n', '<Space>wl', function()
        print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
    end, "List Workspace Folders")

    -- 多 Formatter 冲突处理
    if client.name == "pyright" or client.name == "ts_ls" then
        client.server_capabilities.documentFormattingProvider = false
        client.server_capabilities.documentRangeFormattingProvider = false
    end

    -- 保存时自动格式化
    if client.server_capabilities.documentFormattingProvider then
        vim.api.nvim_clear_autocmds({ group = lsp_fmt_group, buffer = buf_nr })
        vim.api.nvim_create_autocmd("BufWritePre", {
            group = lsp_fmt_group,
            buffer = buf_nr,
            callback = function()
                vim.lsp.buf.format({ async = false, bufnr = buf_nr })
            end,
        })
    end
end

-- Which-Key 分组
local wk_status, wk = pcall(require, "which-key")
if wk_status then
    wk.add({
        { "<space>w",   group = "Workspace" },
        { "<space>r",   group = "Rename/Symbol" },
        { "<space>c",   group = "Code Action" },
        { "<leader>a",  group = "Avante" },
        { "<leader>l",  group = "LSP Tools" }, -- 可用来存放 leader 下的 LSP 功能
        { "<leader>t",  group = "Toggle" },
        -- 可以进一步细化
        { "<leader>o",  desc = "Outline" },
        { "<leader>th", desc = "Toggle Inlay Hints" },
        { "<leader>tw", desc = "Toggle Winbar" },
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

                -- 5. 生命周期提示：通常建议关闭，除非在深度优化引用逻辑
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
        "javascript", "javascriptreact", "typescript", "typescriptreact",
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
    vim.lsp.config(name, final_config)
    vim.lsp.enable(name)
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
