# Neovimush — AGENTS.md

## 交流语言
与本仓库相关的问题，请使用 **中文** 交流。

## 启动入口与加载顺序
`init.lua` 按顺序加载模块，顺序敏感：
```lua
require('options')    -- 全局选项，跨平台配置
require('keymaps')    -- 通用快捷键
require('plugins')    -- lazy.nvim + 全部插件声明
require('colorscheme') -- 必须在 plugins 之后（colorscheme 插件需先安装）
require('lsp')        -- Mason, LSP, nvim-cmp, lspsaga, DAP keymaps
```

## 包管理
- 插件管理器：**lazy.nvim**，首次启动自动克隆自身
- 声明位置：`lua/plugins.lua` 和 `lua/dapcfg.lua`（返回 lazy spec）
- `lazy-lock.json` 已纳入版本控制，锁定插件版本保证可复现

## LSP 特殊行为
- **有条件安装**：部分 LSP 只对用户 `mein` 安装（`slint_lsp`, `omnisharp`, `rust_analyzer`, `nil_ls`）
- **前置依赖检查**：缺少 `cargo`/`npm`/`nix`/`unzip` 时静默跳过对应 LSP，启动时弹出黄色警告
- **格式化冲突**：`pyright` 和 `ts_ls` 的 `documentFormattingProvider` 被强制禁用（`lsp.lua:198-199`），Python 由 `ruff` 处理，JS/TS 由 `biome` 处理
- **nvim-cmp 配置**：集中在 `config/nvim-cmp.lua`（被 `plugins.lua` require），`lsp.lua` 仅提供 `capabilities`
- **lspsaga / which-key 配置**：位于 `plugins.lua` 各自 spec 的 `opts` 中，由 `LspAttach`/`VeryLazy` 懒加载触发

## 编辑器特性
- **Leader 键**：空格
- **colorscheme**：`monokai-pro`，日夜双滤镜（均为 `spectrum`）
- **跨平台**：`options.lua` 中区分 Windows（pwsh）、Linux（zsh）、WSL、Neovide，分别设置 shell、剪切板、字体等
- **Treesitter 自动安装解析器**：通过 `configs.setup` 配置，`ensure_installed` 显式安装 lua, python, json, yaml, markdown, bash, rust
- **spell check**：`cspell.json` 位于 repo 根目录，CSpell 通过 `null-ls` 集成
- **Org 笔记**：`neorg`

## AI 插件
- **avante.nvim**：主 provider 为 Claude（`claude-sonnet-4-20250514`），备选 DeepSeek。需手动 `make` 编译
- **minuet-ai.nvim**：AI 代码补全，仅当设置 `DEEPSEEK_API_KEY` 时加载，后端指向 `api.deepseek.com`

## 调试（DAP）
- Python：`debugpy`（Mason 安装）
- Go：`delve`（Mason 安装）
- Unity/C#：`nvim-dap-unity`
- 快捷键：F5/10/11/12，`<leader>b`/`<leader>B`

## 构建 & 测试
**不存在**。这是 Neovim 配置文件仓库，没有 CI、测试框架、代码检查或构建脚本。无需运行任何测试/lint 命令。
