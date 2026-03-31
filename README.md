# Dotfiles

macOS 开发环境配置备份，支持一键恢复。

## 包含的配置

| 配置 | 说明 |
|------|------|
| `.zshenv` | XDG 规范、PATH、环境变量 |
| `.zshrc` | 入口点：代理补全、工具加载 |
| `.config/zsh/.zshrc` | Oh My Zsh、插件、别名、函数 |
| `.config/zsh/.zprofile` | Homebrew、OrbStack |
| `.tmux.conf` | Catppuccin 主题、vim 键绑定 |
| `.gitconfig` | Git 配置 |
| `.config/nvim/` | Neovim 配置 |
| `.config/ghostty/` | Ghostty 终端配置 |
| `.config/btop/` | btop 系统监控配置 |
| `.config/wget/` | wget 配置 |
| `.config/pip/` | pip 配置 |
| `.config/docker/` | Docker 配置 |

## 快速安装

```bash
git clone git@github.com:sumwai/dotfiles.git ~/dotfiles
cd ~/dotfiles && ./install.sh
```

`install.sh` 会自动：
1. 安装 Homebrew（如未安装）
2. 安装所有 formulae 和 casks
3. 安装 Oh My Zsh 及插件
4. 安装 uv、Miniconda
5. 创建符号链接（已有文件备份为 `.bak`）
6. 复制 `.example` 模板文件

## Shell 加载流程

```
zsh 启动
  → ~/.zshenv          # 始终加载，设 ZDOTDIR、XDG 变量
  → $ZDOTDIR/.zprofile # login shell 加载，Homebrew/OrbStack
  → $ZDOTDIR/.zshrc    # 交互式 shell 加载
    → Oh My Zsh        # 框架 + 插件
    → .zshrc.local     # 敏感信息（TOKEN 等），已 gitignore
    → ~/.zshrc         # 代理补全、工具 init
```

## 敏感信息

以下文件包含敏感信息，**不会**提交到仓库：

- `.config/zsh/.zshrc.local` — GitHub Token、API Key 等
- `.config/claude/settings.json` — Claude API 配置
- `.config/opencode/opencode.json` — AI 工具 API Key
- `.ssh/config` — 服务器 IP 和 SSH 配置
- `.openclaw/` — OpenClaw 密钥和 token

首次使用时，将对应的 `.example` 文件复制并填入真实值：

```bash
cp .config/zsh/.zshrc.local.example ~/.config/zsh/.zshrc.local
# 然后编辑填入你的 token
```

## 自定义

- 别名和函数：编辑 `~/.config/zsh/.zshrc`
- 敏感配置：编辑 `~/.config/zsh/.zshrc.local`
- Oh My Zsh 插件：编辑 `.zshrc` 中的 `plugins=(...)`
- 终端主题：编辑 `~/.config/ghostty/config`
