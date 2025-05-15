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
                ensure_installed = { "lua", "python", "json", "yaml", "markdown", "bash" }, -- 按需添加语言
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

    -- AI plugin /avante.nvim
    {
        "yetone/avante.nvim",
        event = "VeryLazy",
        lazy = false,
        version = false, -- set this if you want to always pull the latest change
        opts = {
            -- add any opts here
            provider = "deepseek",
            vendors = {
                deepseek = {
                    __inherited_from = "openai",
                    -- api_key_name = "",
                    endpoint = "https://api.deepseek.com/",
                    model = "deepseek-coder",
                },
            },
        },
        -- if you want to build from source then do `make BUILD_FROM_SOURCE=true`
        build = "make",
        -- build = "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false", -- for windows
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

    -- file manager side bar     
    "preservim/nerdtree",
    "Xuyuanp/nerdtree-git-plugin", -- add git support    
    "ryanoasis/vim-devicons", -- add icons    
    "scrooloose/nerdtree-project-plugin", --saves and restore the sate between sessions.    
    "PhiLRunninger/nerdtree-buffer-ops", -- Highlites open files, and closes a buffer directly from NERDTree

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
                auto_enable = true,
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
