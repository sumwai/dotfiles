#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

# 颜色
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }

# GitHub 加速代理（gh-proxy）
GH_PROXY="https://gh-proxy.com"

git_clone() {
    # 通过 gh-proxy 加速 GitHub clone
    local repo="$1" dst="$2"
    if git clone "${GH_PROXY}/https://github.com/${repo}.git" "$dst" 2>/dev/null; then
        return 0
    else
        warn "gh-proxy 加速失败，尝试直连..."
        git clone "https://github.com/${repo}.git" "$dst"
    fi
}

# ==================== Homebrew ====================
if ! command -v brew &>/dev/null; then
    info "安装 Homebrew..."
    /bin/bash -c "$(curl -fsSL "${GH_PROXY}/https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh")"
    eval "$(/opt/homebrew/bin/brew shellenv zsh)"
else
    info "Homebrew 已安装"
fi

# 配置 Homebrew 镜像源（清华）
info "配置 Homebrew 清华镜像..."
export HOMEBREW_API_DOMAIN="https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles/api"
export HOMEBREW_BOTTLE_DOMAIN="https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles"

# ==================== Formulae ====================
FORMULAE=(
    neovim tmux
    bat btop dust eza fd fzf glow ripgrep tree
    tree-sitter tree-sitter-cli
    tldr wget z zoxide
    curlie gh httpie nmap
    go ruby nvm
    witr crush opencode
)

info "安装 formulae: ${FORMULAE[*]}"
brew install "${FORMULAE[@]}" 2>/dev/null || brew upgrade "${FORMULAE[@]}" 2>/dev/null || true

# ==================== Casks ====================
CASKS=(
    claude claude-code
    docker-desktop
    font-jetbrains-mono-nerd-font
    ghostty
)

info "安装 casks: ${CASKS[*]}"
brew install --cask "${CASKS[@]}" 2>/dev/null || true

# ==================== 镜像源配置 ====================
info "配置各工具镜像源..."

# npm 淘宝镜像
if command -v npm &>/dev/null; then
    npm config set registry https://registry.npmmirror.com 2>/dev/null || true
fi

# pnpm 淘宝镜像
if command -v pnpm &>/dev/null; then
    pnpm config set registry https://registry.npmmirror.com 2>/dev/null || true
fi

# pip 清华镜像
if command -v pip3 &>/dev/null; then
    pip3 config set global.index-url https://mirrors.tuna.tsinghua.edu.cn/pypi/web/simple 2>/dev/null || true
fi

# Go 代理（goproxy.cn）
if command -v go &>/dev/null; then
    go env -w GOPROXY=https://goproxy.cn,direct 2>/dev/null || true
fi

# Cargo/Rust 清华镜像
if command -v cargo &>/dev/null; then
    mkdir -p "$HOME/.cargo"
    cat > "$HOME/.cargo/config.toml" << 'CARGO_EOF'
[source.crates-io]
replace-with = "rsproxy"

[source.rsproxy]
registry = "https://rsproxy.cn/crates.io-index"

[net]
git-fetch-with-cli = true
CARGO_EOF
fi

# ==================== Oh My Zsh ====================
if [[ ! -d "$HOME/.local/share/oh-my-zsh" ]]; then
    info "安装 Oh My Zsh（国内镜像）..."
    RUNZSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL "${GH_PROXY}/https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh")"
else
    info "Oh My Zsh 已安装"
fi

# Oh My Zsh 插件
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.local/share/oh-my-zsh/custom}"

if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]]; then
    info "安装 zsh-autosuggestions..."
    git_clone zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
fi

if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]]; then
    info "安装 zsh-syntax-highlighting..."
    git_clone zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
fi

# ==================== fzf ====================
info "配置 fzf..."
/opt/homebrew/opt/fzf/install --all --no-bash --no-fish 2>/dev/null || true

# ==================== uv ====================
if ! command -v uv &>/dev/null; then
    info "安装 uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
else
    info "uv 已安装"
fi

# ==================== Miniconda ====================
if [[ ! -f "/opt/miniconda3/bin/conda" ]]; then
    info "安装 Miniconda（USTC 镜像）..."
    curl -fsSL https://mirrors.ustc.edu.cn/anaconda/miniconda/Miniconda3-latest-MacOSX-arm64.sh -o /tmp/miniconda.sh
    bash /tmp/miniconda.sh -b -p /opt/miniconda3
    rm /tmp/miniconda.sh
else
    info "Miniconda 已安装"
fi

# 配置 conda 镜像源（清华）
if command -v conda &>/dev/null; then
    info "配置 conda 清华镜像..."
    conda config --set show_channel_urls true
    conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/main/
    conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/free/
    conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud/conda-forge/
    conda config --set channel_priority strict
fi

# ==================== 符号链接 ====================
info "创建符号链接..."

link_file() {
    local src="$1" dst="$2"
    if [[ -L "$dst" ]]; then
        rm "$dst"
    elif [[ -e "$dst" ]]; then
        warn "备份已存在: $dst → ${dst}.bak"
        mv "$dst" "${dst}.bak"
    fi
    ln -sf "$src" "$dst"
    info "  $dst → $src"
}

# 根目录配置
link_file "$DOTFILES_DIR/.zshenv" "$HOME/.zshenv"
link_file "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"
link_file "$DOTFILES_DIR/.tmux.conf" "$HOME/.tmux.conf"
link_file "$DOTFILES_DIR/.gitconfig" "$HOME/.gitconfig"

# .config 目录
mkdir -p "$HOME/.config"
for dir in zsh nvim ghostty btop wget pip docker; do
    if [[ -d "$DOTFILES_DIR/.config/$dir" ]]; then
        link_file "$DOTFILES_DIR/.config/$dir" "$HOME/.config/$dir"
    fi
done

# ==================== 复制 .example 文件 ====================
info "复制 .example 模板文件..."

copy_example() {
    local src="$1" dst="$2"
    if [[ -f "$src" && ! -e "$dst" ]]; then
        cp "$src" "$dst"
        info "  已复制: $dst"
    elif [[ -e "$dst" ]]; then
        warn "  已存在，跳过: $dst"
    fi
}

copy_example "$DOTFILES_DIR/.config/zsh/.zshrc.local.example" "$HOME/.config/zsh/.zshrc.local"
copy_example "$DOTFILES_DIR/.config/claude/settings.json.example" "$HOME/.config/claude/settings.json"
copy_example "$DOTFILES_DIR/.config/opencode/opencode.json.example" "$HOME/.config/opencode/opencode.json"
copy_example "$DOTFILES_DIR/.ssh/config.example" "$HOME/.ssh/config"

# ==================== 完成 ====================
info "安装完成！"
echo ""
echo "下一步："
echo "  1. 编辑 ~/.config/zsh/.zshrc.local 填入敏感信息"
echo "  2. 编辑 ~/.ssh/config 填入服务器信息"
echo "  3. 打开新终端验证 shell 加载"
echo ""
echo "验证命令："
echo "  echo \$ZDOTDIR"
echo "  which nvim tmux fzf bat"
echo "  git status -s  # 确认 dotfiles 无敏感文件"
