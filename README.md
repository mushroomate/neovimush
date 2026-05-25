# Neovimush

个人 Neovim 配置，基于 lazy.nvim。

## 核心能力

- **LSP**：Mason + lspconfig + lspsaga（lua_ls / pyright / ruff / ts_ls / biome / jsonls / marksman / rust-analyzer / omnisharp 等）
- **补全**：nvim-cmp + LuaSnip，AI 补全 minuet-ai（DeepSeek）
- **AI 助手**：avante.nvim（Claude 主 / DeepSeek 备选）
- **主题**：Monokai Pro（日夜双滤镜）
- **文件管理**：nvim-tree、yazi
- **Git**：Neogit + diffview + fzf-lua
- **调试**：nvim-dap（Python / Go / Unity）
- **Org 笔记**：neorg
- **其它**：which-key、dashboard-nvim、none-ls + cspell 拼写检查

## 文档

- [AGENTS.md](AGENTS.md) — 配置结构与约定
- [HEALTH-CHECK.md](HEALTH-CHECK.md) — 配置体检报告

## Neovim 0.12+ 兼容说明

使用 `vim.lsp.enable()` 新 API 配置 LSP 时注意：

- **`cmd` 需显式指定**：新 API 不会自动拼接 `lsp-proxy` 等参数，部分 LSP（如 biome）必须显式设 `cmd`
- **`workspace_required = false`**：新 API 默认 `true`，会阻止无工作区时启动 LSP，需配合 `single_file_support`
- **`root_dir` 参数类型**：新 API 传入的是 buffer number（数字），需用 `vim.api.nvim_buf_get_name(bufnr)` 转为文件路径后再传给 `util.root_pattern()`
