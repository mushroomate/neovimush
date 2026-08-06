# Neovimush 配置体检报告

日期：2026-08-06
范围：`init.lua`、`lua/options.lua`、`lua/keymaps.lua`、`lua/plugins.lua`、`lua/plugins/dankcolors.lua`、`lua/colorscheme.lua`、`lua/lsp.lua`、`lua/dapcfg.lua`、`lua/config/nvim-cmp.lua`、`cspell.json`、`lazy-lock.json`、`AGENTS.md`、`README.md`
验证方式：对照 `C:\neovim_config\nvim-data\lazy` 下实际安装的插件源码（lazy.nvim 11.17.1、nvim-treesitter main、nvim-cmp、minuet-ai、monokai-pro 等）

---

## 严重 — 配置被"静默忽略"，与意图不符

| # | 位置 | 问题 | 后果 |
|---|------|------|------|
| 1 | `lua/plugins.lua:68` | `require("nvim-treesitter").setup({...})` 传了参数，但新版 nvim-treesitter 的 `M.setup()` 不接受参数（源码 `lua/nvim-treesitter.lua` 已确认，插件入口 `plugin/nvim-treesitter.lua` 也是无参调用） | `highlight` / `auto_install` / `incremental_selection` 全部未生效。默认 `highlight.enable = false`，**Treesitter 高亮实际是关闭的**，缺失解析器也不会自动安装。提交 93716d2 "enable treesitter highlight for nvim 0.12" 实际未生效 |
| 2 | `lua/lsp.lua:121-229` | lspsaga 声明为 `event = "LspAttach"`（懒加载，`lua/plugins.lua:143`），启动阶段 `pcall(require, 'lspsaga')` 失败 → `saga.setup({...})` 从未执行 | hover 尺寸、code_action 数字快捷键、finder 方法、outline 布局、symbol_in_winbar 等全部自定义丢失，插件用默认配置 |
| 3 | `lua/lsp.lua:317-331` | which-key 是 `event = "VeryLazy"`（懒加载），lsp.lua 启动时 `pcall(require, "which-key")` 失败 → `wk.add({...})` 从未执行 | "Workspace / Toggle / LSP Tools" 等分组注册无效（`init` 中的 timeout 设置仍生效） |
| 4 | `lua/plugins.lua:40-46` | monokai-pro 的 `config = { day_night = {...} }` 是表而非函数；lazy.nvim 对非函数 `config` 走 `require("monokai-pro").setup(opts)` 且 `opts` 为空（源码 `lua/lazy/core/loader.lua:375-395`） | **日夜双滤镜（spectrum）配置丢失**，AGENTS.md 描述的该功能实际未生效 |
| 5 | `lua/options.lua:15` | `vim.g.clipboard = 'osc52'` 是字符串，剪贴板 provider 必须是表 | **OSC52 剪贴板实际未启用**，TUI 下 `+` 寄存器走默认 unnamed 行为 |
| 6 | `lua/options.lua:101` | Neovide 兜底分支 `vim.g.clipboard = "unnamedplus"` 同错 | 应改为 `vim.opt.clipboard = 'unnamedplus'` |
| 7 | `lua/plugins/dankcolors.lua` | 从未被任何文件 `require`；base16-nvim 未安装（不在 lazy-lock.json） | **整文件为死代码**，AGENTS.md 所述"实时主题重载"（uv.new_fs_event）实际未激活 |

## 中等 — 快捷键冲突 / 冗余

- **`<leader>t` 前缀冲突**：`keymaps.lua:44` translator 的 `<leader>t` 是完整映射，与 nvim-tree 的 `<leader>tf`/`<leader>tr`（`plugins.lua:269-270`）、LSP 的 `<leader>th`/`<leader>tw`、which-key "Toggle" 组（`lsp.lua:325`）撞车 → 按下后需等 300ms 超时，行为混乱，`tf/tr` 可能误触翻译
- **`<C-k>` 冲突**：`keymaps.lua:19` 全局 = 窗口上移；`lsp.lua:283` on_attach buffer-local = 签名帮助。LSP 缓冲区内 buffer-local 优先，**窗口上移失效**
- **`<leader>w`**：`keymaps.lua:47` translator 与 which-key "Workspace" 组（`lsp.lua:320`）同前缀冲突
- **mason.setup() 调用两次**：`plugins.lua:475` + `lsp.lua:1`，后者覆盖前者（lsp.lua 附带 ui.icons）
- **nvim-cmp 配置两次**：`lua/config/nvim-cmp.lua` + `lua/lsp.lua`。因 nvim-cmp 的 `misc.merge` 是递归合并，sources 以 lsp.lua 为准、Tab/S-Tab 映射保留，勉强共存但脆弱
- **avante `lazy=false` 与 `event="VeryLazy"` 矛盾**：`plugins.lua:318-319`，lazy=false 时 event 被忽略
- **`dapcfg.lua:38` 拼写错误**：`vim.fn.has("whin64")` 应为 `"win64"`，当前被 `win32` 短路掩盖（Windows 下行为正确，但仍是 bug）
- **orgmode + neorg 同时启用**：`plugins.lua:284-285`，两者均未懒加载，启动开销 + 潜在冲突
- **neogit 依赖 4 个 picker**：telescope / fzf-lua / mini.pick / snacks 全部安装（`plugins.lua:94-97`），注释写明"只需一个"
- **windsurf.nvim 残留安装**：已被 minuet-ai 替代（提交 994c868），仍占用磁盘，可用 `:Lazy clean` 清理
- **lspkind.nvim 声明未接线**：作为 nvim-cmp 依赖，但 `format` 用的是自定义 menu 标签
- **tanvirtin/monokai.nvim 未使用**：colorscheme 用的是 monokai-pro

## 轻微

- `lua/options.lua:42` `vim.opt.encoding = 'utf-8'` 在 Neovim 中为 no-op
- `lua/keymaps.lua:15` 注释笔误 `vim.map.set()`，应为 `vim.keymap.set()`
- `lua/config/nvim-cmp.lua:2` `unpack = unpack or table.unpack` 污染全局（LuaJIT 下为 no-op，但应加 local）
- **AGENTS.md 多处过时**：
  - 仍写 windsurf.nvim，实际已被 minuet-ai 替换（提交 994c868）
  - "保存时自动格式化（BufWritePre 同步）" 已在提交 9be7986 移除，当前无保存格式化
  - "日夜双滤镜" 因严重项 #4 实际未生效
  - lsp.lua 行号引用已偏移（313-316 → 现 310-313）
- **README.md 过时/不完整**：插件列表与现状不符（缺 avante、yazi、minuet 等）
- **lazy-lock.json 被 gitignore**：建议纳入版本控制保证可复现（当前需 `git add -f`）

## 正常项（已验证）

- lspconfig root_dir 0.12 异步包装逻辑正确（`lsp.lua:563-580`）
- minuet-ai provider 默认配置已指向 DeepSeek（`api.deepseek.com/beta/completions`），`plugins.lua:303-312` 只需 `api_key`，配置等效可精简
- none-ls.nvim 提供 `null-ls` 模块别名，与 `require("null-ls")` 匹配
- cspell.nvim 模块名为 `cspell`，与 `require("cspell")` 匹配
- mason 条件安装行为正确：本机用户 peixuan.zhang ≠ mein，正确跳过 slint_lsp / omnisharp / rust_analyzer / nil_ls 自动安装（但后两者已手动安装，仍可用）；nix 缺失 → nil_ls 正确跳过
- DEEPSEEK_API_KEY 环境变量已设置，minuet 源与 cmp 源条件一致
