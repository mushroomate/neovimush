return {
    "mfussenegger/nvim-dap",
     dependencies = {
        "rcarriga/nvim-dap-ui",
        "nvim-neotest/nvim-nio",
        "jay-babu/mason-nvim-dap.nvim",
        "mfussenegger/nvim-dap-python",
        {
            "ownself/nvim-dap-unity",
            build = function()
                require("nvim-dap-unity").install()
            end,
        },
     },
    config = function()
        local dap, dapui = require("dap"), require("dapui")
        dapui.setup()

        dap.listeners.before.attach.dapui_config = function() dapui.open() end

        dap.listeners.before.launch.dapui_config = function() dapui.open() end

        dap.listeners.before.event_terminated.dapui_config = function() dapui.close() end

        dap.listeners.before.event_exited.dapui_config = function() dapui.close() end


        dap.configurations.cs = dap.configurations.cs or {}

        require("mason-nvim-dap").setup({
            -- Avaliable Dap adapters: See https://github.com/jay-babu/mason-nvim-dap.nvim/blob/main/lua/mason-nvim-dap/mappings/source.lua
            ensure_installed = { "python", "delve" },
            automatic_installation = true,
            handlers = {},
        })

        local debugpy_path
        if vim.fn.has("win32") == 1 or vim.fn.has("whin64") == 1 then
            debugpy_path = vim.fn.stdpath("data") .. "/mason/packages/debugpy/venv/Scripts/python.exe"
        else
            debugpy_path = vim.fn.stdpath("data") .. "/mason/packages/debugpy/venv/bin/python"
        end

        require("dap-python").setup(debugpy_path)

        -- F5: 继续/开始调试
        vim.keymap.set('n', '<F5>', function() require('dap').continue() end, { desc = 'Debug: Start/Continue' })
        -- F10: 单步跳过 (Step Over)
        vim.keymap.set('n', '<F10>', function() require('dap').step_over() end, { desc = 'Debug: Step Over' })
        -- F11: 单步进入 (Step Into)
        vim.keymap.set('n', '<F11>', function() require('dap').step_into() end, { desc = 'Debug: Step Into' })
        -- F12: 单步跳出 (Step Out)
        vim.keymap.set('n', '<F12>', function() require('dap').step_out() end, { desc = 'Debug: Step Out' })
        -- Leader + b: 切换断点 (Toggle Breakpoint)
        vim.keymap.set('n', '<leader>b', function() require('dap').toggle_breakpoint() end, { desc = 'Debug: Toggle Breakpoint' })
        -- Leader + B: 设置条件断点
        vim.keymap.set('n', '<leader>B', function() require('dap').set_breakpoint(vim.fn.input('Breakpoint condition: ')) end, { desc = 'Debug: Set Condition Breakpoint' })

    end,
}
