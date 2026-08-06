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

-- require of the monoka
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
        branch = 'main',
        build = ":TSUpdate",                               -- 自动安装更新解析器
        event = { "BufReadPost", "BufNewFile" },           -- 延迟加载
        dependencies = {
            "nvim-treesitter/nvim-treesitter-textobjects", -- 增强文本对象（可选）
            branch = 'main',
            event = 'VeryLazy',
            config = function()
                require 'nvim-treesitter-textobjects'.setup({
                    select = { enable = true },
                    swap = { enable = true },
                    move = { enable = true },
                })
            end
        },
        config = function()
            require("nvim-treesitter.configs").setup({
                -- 核心功能配置
                sync_install = false, -- 异步安装解析器
                auto_install = true,  -- 自动安装缺失的解析器
                ensure_installed = { 'lua', 'python', 'json', 'yaml', 'markdown', 'bash', 'rust' },

                -- 启用 treesitter 高亮（Neovim 0.12 新版 nvim-treesitter 需要显式开启）
                highlight = {
                    enable = true,
                    additional_vim_regex_highlighting = false, -- 禁用旧版 regex 高亮（提升性能）
                },

                -- 其他模块（按需启用）
                -- indent = { enable = true },                -- 缩进（实验性）
                incremental_selection = { enable = true }, -- 增量选择
            })
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
            'nvim-treesitter/nvim-treesitter',
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
                lightbulb = { -- 当有可用动作时，行号边显示灯泡
                    enable = false,
                    sign = true,
                    virtual_text = true,
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
                -- 系统设置
                system_open = {
                    cmd = nil,
                    args = {},
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
            local has_key = vim.fn.environ()["DEEPSEEK_API_KEY"] ~= nil
            if not has_key then
                vim.notify(
                    "[minuet-ai] $DEEPSEEK_API_KEY 未设置，AI 补全功能已跳过",
                    vim.log.levels.INFO
                )
            end
            return has_key
        end,
        config = function()
            require("minuet").setup({
                provider = "openai_fim_compatible",
                provider_options = {
                    openai_fim_compatible = {
                        api_key = "DEEPSEEK_API_KEY",
                    },
                },
            })
        end,
    },

    -- AI plugin /avante.nvim
    {
        "yetone/avante.nvim",
        event = "VeryLazy",
        version = false, -- set this if you want to always pull the latest change
        opts = {
            -- add any opts here
            -- provider = "deepseek",
            -- provider = "cloude",
            auto_suggestions_provider = "claude",
            providers = {
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
                    api_key_name = "",
                    endpoint = "https://api.deepseek.com/",
                    model = "deepseek-coder",
                },
            },

        },
        build = avante_build_cmd,
        dependencies = {
            "nvim-treesitter/nvim-treesitter",
            "stevearc/dressing.nvim",
            "nvim-lua/plenary.nvim",
            "MunifTanjim/nui.nvim",
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
                { "<leader>th", desc = "Toggle Inlay Hints" },
                { "<leader>tw", desc = "Toggle Winbar" },
            },
        }
    },
    -- others...

})
