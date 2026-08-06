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
- `lazy-lock.json` 在 `.gitignore` 中，提交前需 `git add -f lazy-lock.json` 或修改 `.gitignore`

## LSP 特殊行为
- **有条件安装**：部分 LSP 只对用户 `mein` 安装（`slint_lsp`, `omnisharp`, `rust_analyzer`, `nil_ls`）
- **前置依赖检查**：缺少 `cargo`/`npm`/`nix`/`unzip` 时静默跳过对应 LSP，启动时弹出黄色警告
- **格式化冲突**：`pyright` 和 `ts_ls` 的 `documentFormattingProvider` 被强制禁用（`lsp.lua:313-316`），Python 由 `ruff` 处理，JS/TS 由 `biome` 处理
- **保存时自动格式化**：通过 `BufWritePre` 同步执行（`async = false`），只有保留 format 能力的 server 才触发
- **nvim-cmp 被配置了两次**：`config/nvim-cmp.lua`（被 `plugins.lua` require）和 `lsp.lua` 都调用了 `cmp.setup()`。后加载的 `lsp.lua` 中的配置生效

## 编辑器特性
- **Leader 键**：空格
- **colorscheme**：`monokai-pro`，日夜双滤镜（均为 `spectrum`）
- **跨平台**：`options.lua` 中区分 Windows（pwsh）、Linux（zsh）、WSL、Neovide，分别设置 shell、剪切板、字体等
- **Treesitter 自动安装解析器**：lua, python, json, yaml, markdown, bash, rust
- **spell check**：`cspell.json` 位于 repo 根目录，CSpell 通过 `null-ls` 集成

## AI 插件
- **avante.nvim**：主 provider 为 Claude（`claude-sonnet-4-20250514`），备选 DeepSeek。需手动 `make` 编译
- **windsurf.nvim**（Codeium 改版）：autocomplete 后端指向 `api.deepseek.com`

## 调试（DAP）
- Python：`debugpy`（Mason 安装）
- Go：`delve`（Mason 安装）
- Unity/C#：`nvim-dap-unity`
- 快捷键：F5/10/11/12，`<leader>b`/`<leader>B`

## 构建 & 测试
**不存在**。这是 Neovim 配置文件仓库，没有 CI、测试框架、代码检查或构建脚本。无需运行任何测试/lint 命令。
