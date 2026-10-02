local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable", -- latest stable release
        lazypath,
    })
end

vim.opt.rtp:prepend(lazypath)

local avante_build_cmd
-- if you want to build from source then do `make BUILD_FROM_SOURCE=true`
if vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1 then
    avante_build_cmd = "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false" -- for windows
else
    avante_build_cmd = "make"
end

-- nvim-treesitter 分支与 API 随实际运行的 Neovim 版本切换：
--   Neovim >= 0.12 -> main 分支（重写版 API）
--   Neovim <  0.12 -> master 分支（旧版 API）
local nvim_012 = vim.fn.has("nvim-0.12") == 1
local ts_branch = nvim_012 and "main" or "master"

-- 探测本机可用的 AI 后端，按优先级返回 { model, end_point, api_key, name }：
--   1) Crysta（llama-server，https://llm.sugarsource.club）—— 首选
--   2) ollama 的 qwen3.5（latest 优先，其次 9b）
-- 都不可用返回 nil，minuet 将回退到 DeepSeek。
-- 注意：minuet 的 api_key 字段是「环境变量名」，不是 key 值本身。
local function minuet_local_target()
    if vim.fn.executable("curl") == 0 then
        return nil
    end

    -- 1) Crysta（llama.cpp 服务）
    local health = vim.fn.system({
        "curl",
        "-s",
        "--max-time",
        "1",
        "https://llm.sugarsource.club/health",
    })
    if vim.v.shell_error == 0 and health:find('"ok"', 1, true) then
        return {
            model = "Crysta",
            end_point = "https://llm.sugarsource.club/v1/chat/completions",
            api_key = "SUGARSOURCE_API_KEY",
            name = "Crysta",
        }
    end

    -- 2) ollama：qwen3.5（latest 优先，其次 9b）
    local out = vim.fn.system({
        "curl",
        "-s",
        "--max-time",
        "2",
        "http://localhost:11434/api/tags",
    })
    if vim.v.shell_error ~= 0 or out == "" then
        return nil
    end
    for _, model in ipairs({ "qwen3.5:latest", "qwen3.5:9b" }) do
        if out:find('"' .. model .. '"', 1, true) then
            return {
                model = model,
                end_point = "http://localhost:11434/v1/chat/completions",
                api_key = "TERM",
                name = "Ollama",
            }
        end
    end
    return nil
end

-- require of the monokai
require("lazy").setup({
    -- translator
    "voldikss/vim-translator",

    -- toggle fcitx,
    {
        "h-hg/fcitx.nvim",
        cond = function()
            return vim.fn.has("linux") == 1
        end,
    },

    -- theme
    {
        "loctvl842/monokai-pro.nvim",
        opts = {
            day_night = {
                enable = true,             -- turn off by default
                day_filter = "spectrum",   -- classic | octagon | pro | machine | ristretto | spectrum
                night_filter = "spectrum", -- classic | octagon | pro | machine | ristretto | spectrum
            },
        },
    },

    {
        -- treesitter for minimap dependency and markdown rendering
        "nvim-treesitter/nvim-treesitter",
        branch = ts_branch,
        lazy = false,                                      -- 该插件不支持懒加载
        build = ":TSUpdate",                               -- 自动安装更新解析器
        dependencies = {
            {
                "nvim-treesitter/nvim-treesitter-textobjects", -- 增强文本对象
                branch = ts_branch,
                init = function()
                    -- 禁用内置 ftplugin 映射，避免与显式键位冲突
                    vim.g.no_plugin_maps = true
                end,
            },
        },
        config = function()
            local ensure_installed = { 'lua', 'python', 'json', 'yaml', 'markdown', 'bash', 'rust' }

            if nvim_012 then
                -- main 分支（重写版）：需显式安装解析器并启用高亮
                require("nvim-treesitter").setup({})
                require("nvim-treesitter").install(ensure_installed)
                vim.api.nvim_create_autocmd("FileType", {
                    callback = function()
                        pcall(vim.treesitter.start)
                    end,
                })

                -- textobjects（main 分支）：setup + 显式键位
                require("nvim-treesitter-textobjects").setup({
                    select = { lookahead = true },
                    move = { set_jumps = true },
                })

                local function ts_select(query)
                    return function()
                        require("nvim-treesitter-textobjects.select").select_textobject(query, "textobjects")
                    end
                end
                local function ts_move(fn, query)
                    return function()
                        require("nvim-treesitter-textobjects.move")[fn](query, "textobjects")
                    end
                end
                local function ts_swap(fn, query)
                    return function()
                        require("nvim-treesitter-textobjects.swap")[fn](query)
                    end
                end

                -- 选择
                vim.keymap.set({ "x", "o" }, "am", ts_select("@function.outer"), { desc = "TS: 函数(外)" })
                vim.keymap.set({ "x", "o" }, "im", ts_select("@function.inner"), { desc = "TS: 函数(内)" })
                vim.keymap.set({ "x", "o" }, "ac", ts_select("@class.outer"), { desc = "TS: 类(外)" })
                vim.keymap.set({ "x", "o" }, "ic", ts_select("@class.inner"), { desc = "TS: 类(内)" })

                -- 移动
                vim.keymap.set({ "n", "x", "o" }, "]m", ts_move("goto_next_start", "@function.outer"), { desc = "TS: 下一函数开头" })
                vim.keymap.set({ "n", "x", "o" }, "[m", ts_move("goto_previous_start", "@function.outer"), { desc = "TS: 上一函数开头" })
                vim.keymap.set({ "n", "x", "o" }, "]M", ts_move("goto_next_end", "@function.outer"), { desc = "TS: 下一函数结尾" })
                vim.keymap.set({ "n", "x", "o" }, "[M", ts_move("goto_previous_end", "@function.outer"), { desc = "TS: 上一函数结尾" })
                vim.keymap.set({ "n", "x", "o" }, "]]", ts_move("goto_next_start", "@class.outer"), { desc = "TS: 下一类开头" })
                vim.keymap.set({ "n", "x", "o" }, "[[", ts_move("goto_previous_start", "@class.outer"), { desc = "TS: 上一类开头" })
                vim.keymap.set({ "n", "x", "o" }, "][", ts_move("goto_next_end", "@class.outer"), { desc = "TS: 下一类结尾" })
                vim.keymap.set({ "n", "x", "o" }, "[]", ts_move("goto_previous_end", "@class.outer"), { desc = "TS: 上一类结尾" })

                -- 交换
                vim.keymap.set("n", "<leader>sn", ts_swap("swap_next", "@parameter.inner"), { desc = "TS: 与下一参数交换" })
                vim.keymap.set("n", "<leader>sN", ts_swap("swap_previous", "@parameter.inner"), { desc = "TS: 与上一参数交换" })
            else
                -- master 分支（旧版）：沿用 configs 模块
                require("nvim-treesitter.configs").setup({
                    sync_install = false, -- 异步安装解析器
                    auto_install = true,  -- 自动安装缺失的解析器
                    ensure_installed = ensure_installed,

                    highlight = {
                        enable = true,
                        additional_vim_regex_highlighting = false, -- 禁用旧版 regex 高亮（提升性能）
                    },

                    -- 其他模块（按需启用）
                    -- indent = { enable = true },                -- 缩进（实验性）
                    incremental_selection = { enable = true }, -- 增量选择

                    -- textobjects（master 分支）：通过 configs 注册显式键位
                    textobjects = {
                        select = {
                            enable = true,
                            lookahead = true,
                            keymaps = {
                                ["am"] = "@function.outer",
                                ["im"] = "@function.inner",
                                ["ac"] = "@class.outer",
                                ["ic"] = "@class.inner",
                            },
                        },
                        move = {
                            enable = true,
                            set_jumps = true,
                            goto_next_start = { ["]m"] = "@function.outer", ["]]"] = "@class.outer" },
                            goto_next_end = { ["]M"] = "@function.outer", ["]["] = "@class.outer" },
                            goto_previous_start = { ["[m"] = "@function.outer", ["[["] = "@class.outer" },
                            goto_previous_end = { ["[M"] = "@function.outer", ["[]"] = "@class.outer" },
                        },
                        swap = {
                            enable = true,
                            swap_next = { ["<leader>sn"] = "@parameter.inner" },
                            swap_previous = { ["<leader>sN"] = "@parameter.inner" },
                        },
                    },
                })
            end
        end,
    },

    {
        "NeogitOrg/neogit",
        dependencies = {
            "nvim-lua/plenary.nvim",  -- required
            "sindrets/diffview.nvim", -- optional - Diff integration

            -- Only one of these is needed.
            "ibhagwan/fzf-lua",       -- optional
            "folke/snacks.nvim",      -- optional
        },
    },
    -- Auto-completion engine
    {
        "hrsh7th/nvim-cmp",
        dependencies = {
            "hrsh7th/cmp-nvim-lsp",
            "hrsh7th/cmp-buffer",
            "hrsh7th/cmp-path",
            "hrsh7th/cmp-cmdline",
            "L3MON4D3/LuaSnip",
            "saadparwaiz1/cmp_luasnip",
        },
        config = function()
            require("config.nvim-cmp")
        end,
    },
    -- Code snipted engine
    {
        "L3MON4D3/LuaSnip",
        dependencies = { "rafamadriz/friendly-snippets" },
        config = function()
            require("luasnip").setup()
        end,
    },
    -- LSP manager
    "williamboman/mason.nvim",
    "williamboman/mason-lspconfig.nvim",
    "neovim/nvim-lspconfig",

    -- Imporves LSP UI
    {
        'nvimdev/lspsaga.nvim',
        dependencies = {
            'nvim-tree/nvim-web-devicons',
        },
        event = 'LspAttach',
        opts = {
            -- -------------------------------
            -- 悬停文档 (Hover)
            -- -------------------------------
            hover = {
                max_width = 0.6,  -- 窗口宽度占编辑器比例
                max_height = 0.6, -- 窗口高度比例
                border = 'rounded',
                title = ' Documentation ',
            },

            -- -------------------------------
            -- 代码动作 (Code Action)
            -- 增强：支持数字快捷键、预览 diff
            -- -------------------------------
            code_action = {
                num_shortcut = true,     -- 按数字快速选择动作
                show_server_name = true, -- 显示 LSP 服务器名
                keys = {
                    exec = '<CR>',       -- 执行当前动作
                    quit = { 'q', '<Esc>' },
                },
            },

            -- -------------------------------
            -- 代码动作灯泡 (Lightbulb)
            -- 只保留行末提示，关闭行号左侧 sign，避免符号出现时文字横向抖动
            -- -------------------------------
            lightbulb = {
                enable = true,
                sign = false,        -- 关掉 sign（推挤文字的来源）
                virtual_text = true, -- 行末灯泡，overlay 不占布局宽度
                debounce = 10,
                sign_priority = 40,
                enable_in_insert = false,
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
                default = 'def+ref+imp', -- 默认同时查定义、引用和实现
                keys = {
                    vsplit = 'v',        -- 垂直分屏打开
                    split = 's',         -- 水平分屏打开
                    quit = { 'q', '<Esc>' },
                },
            },

            -- -------------------------------
            -- 符号大纲 (Outline)
            -- -------------------------------
            outline = {
                layout = 'normal',     -- 使用分屏窗口，而不是浮动窗口
                win_position = 'left', -- 放在右侧
                win_width = 30,
                auto_preview = true,   -- 光标移动时自动预览符号位置
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
        },
    },

    -- DAP
    require("dapcfg"),

    -- Spellcheck
    {
        "nvimtools/none-ls.nvim",
        dependencies = {
            "davidmh/cspell.nvim",
        },
    },

    -- For vim configure LSP
    {
        "folke/lazydev.nvim",
        ft = "lua",
        opts = {
            library = {
                { path = "lazy.nvim", words = { "LazyVim" } },
            },
        },
    },
    -- dashboard
    {
        "nvimdev/dashboard-nvim",
        event = "VimEnter",
        config = function()
            require("dashboard").setup({
                theme = "hyper",
                config = {
                    header = {
                        "",
                        " ███╗   ██╗ ███████╗ ██████╗  ██╗   ██╗ ██╗ ███╗   ███╗",
                        " ████╗  ██║ ██╔════╝██╔═══██╗ ██║   ██║ ██║ ████╗ ████║",
                        " ██╔██╗ ██║ █████╗  ██║   ██║ ██║   ██║ ██║ ██╔████╔██║",
                        " ██║╚██╗██║ ██╔══╝  ██║   ██║ ╚██╗ ██╔╝ ██║ ██║╚██╔╝██║",
                        " ██║ ╚████║ ███████╗╚██████╔╝  ╚████╔╝  ██║ ██║ ╚═╝ ██║",
                        " ╚═╝  ╚═══╝ ╚══════╝ ╚═════╝    ╚═══╝   ╚═╝ ╚═╝     ╚═╝",
                        ""
                    },
                    -- week_header = {
                    -- enable = true,
                    -- },
                    -- 「最近项目」默认 action 是 `Telescope find_files cwd=`，
                    -- 本仓库未安装 Telescope，改用 fzf-lua。插件在调用 action 前
                    -- 已 `lcd` 进项目目录，直接用函数打开文件选择器即可。
                    project = {
                        action = function()
                            require("fzf-lua").files()
                        end,
                        limit = 8,
                    },
                },
            })
        end,
        dependencies = { { 'nvim-tree/nvim-web-devicons' } }
    },

    -- file manager
    {
        "nvim-tree/nvim-tree.lua",
        version = "*",
        lazy = false,
        dependencies = {
            "nvim-tree/nvim-web-devicons",
        },
        config = function()
            -- 禁用内置netrw
            vim.g.loaded_netrw = 1
            vim.g.loaded_netrwPlugin = 1

            require("nvim-tree").setup({
                -- 基本设置
                sort_by = "case_sensitive",
                view = {
                    width = 30,
                    adaptive_size = true,
                },
                -- 渲染设置
                renderer = {
                    group_empty = true,
                    icons = {
                        show = {
                            file = true,
                            folder = true,
                            folder_arrow = true,
                            git = true,
                        },
                    },
                },
                -- 过滤器设置
                filters = {
                    dotfiles = false,
                    custom = { "^.git$" },
                    exclude = { ".gitignore" },
                },
                -- Git 支持
                git = {
                    enable = true,
                    ignore = false,
                    timeout = 500,
                },
                -- 文件监视
                update_focused_file = {
                    enable = true,
                    update_cwd = true,
                },
                -- 诊断集成
                diagnostics = {
                    enable = true,
                    show_on_dirs = true,
                },
                -- 性能优化
                actions = {
                    use_system_clipboard = true,
                    change_dir = {
                        enable = true,
                        global = false,
                    },
                    open_file = {
                        quit_on_open = false,
                        resize_window = true,
                    },
                },
            })

            -- 设置快捷键
            vim.keymap.set('n', '<leader>e', ':NvimTreeToggle<CR>', { noremap = true, silent = true })
            vim.keymap.set('n', '<leader>tf', ':NvimTreeFocus<CR>', { noremap = true, silent = true })
            vim.keymap.set('n', '<leader>tr', ':NvimTreeRefresh<CR>', { noremap = true, silent = true })
        end,
    },
    {
        "ibhagwan/fzf-lua",
        -- optional for icon support
        dependencies = { "nvim-tree/nvim-web-devicons" },
        config = function()
            -- calling `setup` is optional for customization
            require("fzf-lua").setup({})
        end
    },

    -- Org mode
    "nvim-neorg/neorg",

    -- vim.suda
    "lambdalisue/vim-suda",

    -- AI code completion via minuet-ai.nvim
    {
        "milanglacier/minuet-ai.nvim",
        cond = function()
            local has_key = (vim.env.DEEPSEEK_API_KEY or "") ~= ""
            local target = minuet_local_target()
            if not has_key and not target then
                vim.notify(
                    "[minuet-ai] 未检测到本地模型（llama.cpp:8090 / ollama qwen3.5），且 $DEEPSEEK_API_KEY 未设置，AI 补全功能已跳过",
                    vim.log.levels.INFO
                )
            end
            return has_key or target ~= nil
        end,
        config = function()
            -- AI 补全走 virtualtext（ghost text）前端，而不是 nvim-cmp 菜单。
            -- cmp 菜单每个候选只能显示一行，多行补全会被截断；virtualtext
            -- 用 virt_text + virt_lines 渲染，多行内容可完整内联显示。
            local virtualtext = {
                -- 自动触发的文件类型；想全部启用可改为 { "*" }。
                -- 留空则仅能通过 <A-]> 手动触发。
                auto_trigger_ft = {
                    "lua", "python", "javascript", "typescript",
                    "go", "rust", "c", "cpp", "bash", "markdown",
                },
                keymap = {
                    accept = "<A-a>",         -- 整段接受
                    accept_line = "<A-l>",    -- 只接受一行
                    accept_n_lines = "<A-A>", -- 接受 N 行（会提示输入行数）
                    prev = "<A-[>",           -- 上一条候选
                    next = "<A-]>",           -- 下一条候选 / 无建议时手动触发
                    dismiss = "<A-e>",        -- 取消
                },
                -- minuet 已不再作为 cmp 源，此选项保持默认即可
                show_on_completion_menu = false,
            }

            local target = minuet_local_target()
            if target then
                -- 本地模型（优先 llama.cpp 的 Qwen3.6-35B-A3B，其次 ollama qwen3.5）
                -- 都是思考模型且不支持 FIM（无 insert capability），所以走 chat 端点，
                -- 并显式关闭思考。
                local optional = { max_tokens = 256 }
                if target.name == "llama.cpp" then
                    -- llama.cpp（--jinja）：用 chat_template_kwargs 关思考
                    optional.chat_template_kwargs = { enable_thinking = false }
                else
                    -- ollama /v1 端点：用 reasoning_effort 关思考
                    -- （实测 think = false 在 /v1 端点无效）
                    optional.reasoning_effort = "none"
                end
                require("minuet").setup({
                    provider = "openai_compatible",
                    n_completions = 1, -- 本地模型省资源
                    context_window = 2048,
                    -- 全局开关：<leader>ta 切换，仅拦自动触发（手动 <A-]> 仍可用）
                    enable_predicates = {
                        function()
                            return vim.g.minuet_ai_enabled ~= false
                        end,
                    },
                    provider_options = {
                        openai_compatible = {
                            model = target.model,
                            end_point = target.end_point,
                            -- minuet 的 api_key 是环境变量名：llama 用 SUGARSOURCE_API_KEY，ollama 用 TERM
                            api_key = target.api_key,
                            name = target.name,
                            optional = optional,
                        },
                    },
                    virtualtext = virtualtext,
                })
            else
                require("minuet").setup({
                    provider = "openai_fim_compatible",
                    -- 全局开关：<leader>ta 切换，仅拦自动触发（手动 <A-]> 仍可用）
                    enable_predicates = {
                        function()
                            return vim.g.minuet_ai_enabled ~= false
                        end,
                    },
                    provider_options = {
                        openai_fim_compatible = {
                            api_key = "DEEPSEEK_API_KEY",
                        },
                    },
                    virtualtext = virtualtext,
                })
            end

            -- 开关 AI 补全：全局生效，关闭时清掉当前 ghost text。
            -- 仅拦自动触发，手动 <A-]> 仍可用（minuet 设计如此）。
            vim.keymap.set("n", "<leader>ta", function()
                vim.g.minuet_ai_enabled = not (vim.g.minuet_ai_enabled ~= false)
                if not vim.g.minuet_ai_enabled then
                    require("minuet.virtualtext").action.dismiss()
                end
                vim.notify(
                    "[minuet-ai] AI completion "
                        .. (vim.g.minuet_ai_enabled and "enabled" or "disabled"),
                    vim.log.levels.INFO
                )
            end, { desc = "Toggle AI Completion" })
        end,
    },

    -- AI plugin /avante.nvim
    {
        "yetone/avante.nvim",
        event = "VeryLazy",
        version = false, -- set this if you want to always pull the latest change
        opts = {
            -- 默认优先使用 Crysta；
            -- 需要时用 :AvanteSwitchProvider claude / deepseek 临时切换。
            provider = "llama_local",
            auto_suggestions_provider = "llama_local",
            providers = {
                -- Crysta（llama-server）
                -- api_key_name = "SUGARSOURCE_API_KEY" 从环境变量读；SUGARSOURCE_API_KEY
                llama_local = {
                    __inherited_from = "openai",
                    api_key_name = "SUGARSOURCE_API_KEY",
                    endpoint = "https://llm.sugarsource.club/v1",
                    model = "Crysta",
                    use_response_api = false,
                    timeout = 10000, -- 10秒
                    extra_request_body = {
                        temperature = 0.6,
                        max_tokens = 12288,
                        -- 本地 44 t/s，
                        chat_template_kwargs = { enable_thinking = false },
                    },
                },
                claude = {
                    endpoint = "https://api.anthropic.com",
                    model = "claude-sonnet-4-20250514",
                    timeout = 30000,
                    extra_request_body = {
                        temperature = 0.75,
                        max_tokens = 20480,
                    },
                },
                deepseek = {
                    __inherited_from = "openai",
                    -- avante 会优先读 AVANTE_DEEPSEEK_API_KEY，其次读这里指定的变量
                    api_key_name = "DEEPSEEK_API_KEY",
                    endpoint = "https://api.deepseek.com/",
                    -- deepseek-coder 已下线，官方等价模型为 deepseek-chat
                    model = "deepseek-chat",
                },
            },

        },
        build = avante_build_cmd,
        dependencies = {
            "stevearc/dressing.nvim",
            "nvim-lua/plenary.nvim",
            "MunifTanjim/nui.nvim",
            -- avante 命令解析依赖（纯 Lua，非 luarocks）
            {
                "ColinKennedy/mega.cmdparse",
                dependencies = { "ColinKennedy/mega.logging" },
            },
            --- The below dependencies are optional,
            "nvim-tree/nvim-web-devicons", -- or echasnovski/mini.icons
            "zbirenbaum/copilot.lua",      -- for providers='copilot'
            {
                -- support for image pasting
                "HakonHarnes/img-clip.nvim",
                event = "VeryLazy",
                opts = {
                    -- recommended settings
                    default = {
                        embed_image_as_base64 = false,
                        prompt_for_file_name = false,
                        drag_and_drop = {
                            insert_mode = true,
                        },
                        -- required for Windows users
                        use_absolute_path = true,
                    },
                },
            },
            {
                -- Make sure to set this up properly if you have lazy=true
                'MeanderingProgrammer/render-markdown.nvim',
                opts = {
                    file_types = { "markdown", "Avante" },
                },
                ft = { "markdown", "Avante" },
            },
        },
    },


    -- git
    {
        "ThePrimeagen/git-worktree.nvim",
        -- config={ },
    },
    -- yazi
    {
        "mikavilpas/yazi.nvim",
        event = "VeryLazy",
        dependencies = {
            "folke/snacks.nvim"
        },
        keys = {
            {
                "<leader>-",
                mode = { "n", "v" },
                "<cmd>Yazi<cr>",
                desc = "Open yazi at current file",
            },
            {
                "<leader>cw",
                "<cmd>Yazi cwd<cr>",
                desc = "Open the file manager in nvim's working directory",
            },
            {
                "<leader>yl",
                "<cmd>Yazi toggle<cr>",
                desc = "Resume the last yazi session",
            },
        },
        ---@type YaziConfig | {}
        opts = {
            open_for_directories = false,
            keymaps = {
                show_help = "<leader>yh",
            },
        },
        -- if use `open_for_directories=true`, recommended add a setting as below
        init = function()
            -- more details: https://github.com/mikavilpas/yazi.nvim/issues/802
            -- vim.g.loaded_netrw = 1
            vim.g.loaded_netrwPlugin = 1
        end,
    },

    -- minimap
    {
        'gorbit99/codewindow.nvim',
        config = function()
            local codewindow = require('codewindow')
            codewindow.setup({
                active_in_terminals = false,
                auto_enable = false,
                exclude_filetypes = { 'help' },
                max_minimap_height = nil,
                max_lines = nil,
                minimap_width = 13,
                use_lsp = true,
                use_treesitter = true,
                use_git = true,
                width_multiplier = 3,
                z_index = 1,
                show_cursor = true,
                screen_bounds = 'lines',
                window_border = 'single',
                relative = 'win',
                events = { 'TextChanged', 'InsertLeave', 'DiagnosticChanged', 'FileWritepost' }
            })
            codewindow.apply_default_keybinds()

            -- optional: custom Highlites set
            -- vim.api.nvim_set_hl(0, 'CodewindowBorder', { fg = '#ffff00' })
        end,
        enabled = false, -- disabled for new version of nvim-treesitter
    },

    -- which key
    {
        "folke/which-key.nvim",
        event = "VeryLazy",
        init = function()
            vim.o.timeout = true
            vim.o.timeoutlen = 300 -- 按下前缀键后等待 300 毫秒弹出提示面板
        end,
        opts = {
            spec = {
                { "<leader>w",  group = "Workspace" },
                { "<leader>r",  group = "Rename/Symbol" },
                { "<leader>c",  group = "Code Action" },
                { "<leader>a",  group = "Avante" },
                { "<leader>l",  group = "LSP Tools" }, -- 可用来存放 leader 下的 LSP 功能
                { "<leader>t",  group = "Toggle" },
                -- 可以进一步细化
                { "<leader>o",  desc = "Outline" },
                { "<leader>ta", desc = "Toggle AI Completion" },
                { "<leader>th", desc = "Toggle Inlay Hints" },
                { "<leader>tw", desc = "Toggle Winbar" },
            },
        }
    },
    -- others...

})
