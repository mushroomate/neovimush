local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath)then
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

    -- theme
    "tanvirtin/monokai.nvim",
    {
        "loctvl842/monokai-pro.nvim",
        config = {
            day_night = {
                enable = true, -- turn off by default
                day_filter = "spectrum", -- classic | octagon | pro | machine | ristretto | spectrum
                night_filter = "spectrum", -- classic | octagon | pro | machine | ristretto | spectrum
            },
        },
    },

    {
        -- treesitter for minimap dependency
        "nvim-treesitter/nvim-treesitter",
        build = ":TSUpdate",  -- 自动安装更新解析器
        event = { "BufReadPost", "BufNewFile" }, -- 延迟加载
        dependencies = {
            "nvim-treesitter/nvim-treesitter-textobjects", -- 增强文本对象（可选）
        },
        config = function()
            require("nvim-treesitter.configs").setup({
                -- 核心功能配置
                ensure_installed = { "lua", "python", "json", "yaml", "markdown", "bash", "rust" }, -- 按需添加语言
                sync_install = false, -- 异步安装解析器
                auto_install = true,  -- 自动安装缺失的解析器（首次打开文件时）

                -- 启用高亮
                highlight = {
                    enable = true,
                    additional_vim_regex_highlighting = false, -- 禁用旧版 regex 高亮（提升性能）
                },

                -- 其他模块（按需启用）
                indent = { enable = true },          -- 缩进（实验性）
                incremental_selection = { enable = true }, -- 增量选择
                textobjects = { enable = true },     -- 文本对象（如函数/类选择）
            })
        end,
    },

    {
        "NeogitOrg/neogit",
        dependencies = {
            "nvim-lua/plenary.nvim",         -- required
            "sindrets/diffview.nvim",        -- optional - Diff integration

            -- Only one of these is needed.
            "nvim-telescope/telescope.nvim", -- optional
            "ibhagwan/fzf-lua",              -- optional
            "echasnovski/mini.pick",         -- optional
            "folke/snacks.nvim",             -- optional
        },
    },
    -- Vscode-like pictograms
    {
        "onsails/lspkind.nvim",
        event = { "VimEnter" },
    },
    -- Auto-completion engine
    {
        "hrsh7th/nvim-cmp",
        dependencies = {
            "lspkind.nvim",
            "hrsh7th/cmp-nvim-lsp",
            "hrsh7th/cmp-buffer",
            "hrsh7th/cmp-path",
            "hrsh7th/cmp-cmdline",
        },
        config = function()
            require("config.nvim-cmp")
        end,
    },
    -- Code snipted engine
    {
        "L3MON4D3/LuaSnip",
        version = "v2.*",
    },
    --LSP manager
    "williamboman/mason.nvim",
    "williamboman/mason-lspconfig.nvim",
    "neovim/nvim-lspconfig",

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

    -- Orgmode
    "nvim-orgmode/orgmode",
    "nvim-neorg/neorg",

    -- vim.suda
    "lambdalisue/vim-suda",

    -- AI auto-completion Exafunction/windsurf.nvim 
    -- https://github.com/Exafunction/windsurf.nvim
    {
        "Exafunction/windsurf.nvim",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "hrsh7th/nvim-cmp",
        },
        config = function()
            require("codeium").setup({
            })
        end,
        opts = {
            api = {
                host = "api.deepseek.com",
                port = 443,
                path = "/v1/completions",
            }
        },
    },

    -- AI plugin /avante.nvim
    {
        "yetone/avante.nvim",
        event = "VeryLazy",
        lazy = false,
        version = false, -- set this if you want to always pull the latest change
        opts = {
            -- add any opts here
            -- provider = "deepseek",
            -- provider = "cloude",
            auto_suggestions_provider = "claude",
            providers = {
                claude = {
                    endpoint = "https://api.anthropic.com",
                    model = "claude-3-5-sonnet-20241022",
                    extra_request_body = {
                        temperature = 0.75,
                        max_tokens = 4096,
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
            "zbirenbaum/copilot.lua", -- for providers='copilot'
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
        end
    },
    -- others...

})

require("mason").setup()
