# 编辑器设置
export EDITOR=nvim

# XDG Base Directory 规范
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"

# zsh 配置目录
export ZDOTDIR="$XDG_CONFIG_HOME/zsh"

# 禁用 macOS zsh session
export SHELL_SESSIONS_DISABLE=1

# zsh 补全缓存
export ZSH_COMPDUMP="$XDG_CACHE_HOME/zsh/.zcompdump"

# Wget
export WGETRC="$XDG_CONFIG_HOME/wget/wgetrc"

# NVM
export NVM_DIR="$XDG_DATA_HOME/nvm"

# npm
export npm_config_userconfig="$XDG_CONFIG_HOME/npm/npmrc"
export npm_config_cache="$XDG_CACHE_HOME/npm"

# Less
export LESSHISTFILE="$XDG_STATE_HOME/less/history"

# z
export _Z_DATA="$XDG_DATA_HOME/z"

# Go
export GOPATH="$XDG_DATA_HOME/go"
export GOPROXY="https://goproxy.cn,direct"
export GOMODCACHE="$XDG_CACHE_HOME/go/mod"
export PATH=$GOPATH/bin:$PATH
# Cargo/Rust
export CARGO_HOME="$XDG_DATA_HOME/cargo"
export RUSTUP_HOME="$XDG_DATA_HOME/rustup"

# Python pip
export PIP_CONFIG_FILE="$XDG_CONFIG_HOME/pip/pip.conf"

# GnuPG
export GNUPGHOME="$XDG_DATA_HOME/gnupg"

# SQLite
export SQLITE_HISTORY="$XDG_CACHE_HOME/sqlite_history"

# CUDA
export CUDA_CACHE_PATH="$XDG_CACHE_HOME/nv"

# Docker
export DOCKER_CONFIG="$XDG_CONFIG_HOME/docker"

# HomeBrew
export HOMEBREW_API_DOMAIN="https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles/api"
export HOMEBREW_BOTTLE_DOMAIN="https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles"

# TLDR
export TLDR_CACHE_DIR="$XDG_CACHE_HOME/tldr"

# Claude Code
export CLAUDE_CONFIG_DIR="$XDG_CONFIG_HOME/claude"

# Cursor (VSCode 系列)
export CURSOR_CONFIG_DIR="$XDG_CONFIG_HOME/Cursor"

# Oh My Zsh
export ZSH="$XDG_DATA_HOME/oh-my-zsh"

# bun (尝试使用 XDG，但 bun 不完全支持)
export BUN_INSTALL="$XDG_DATA_HOME/bun"
export PATH="$BUN_INSTALL/bin:$PATH"
