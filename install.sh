#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

# 颜色
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }

# ==================== 系统检测 ====================
OS=""
PKG_MANAGER=""
ARCH=""
ARCH_GO=""
ARCH_CONDA=""

detect_os() {
    case "$OSTYPE" in
        darwin*)  OS="macos" ; PKG_MANAGER="brew" ;;
        linux*)   OS="linux"
                  if command -v apt-get &>/dev/null; then   PKG_MANAGER="apt"
                  elif command -v dnf &>/dev/null; then      PKG_MANAGER="dnf"
                  elif command -v pacman &>/dev/null; then    PKG_MANAGER="pacman"
                  elif command -v yum &>/dev/null; then       PKG_MANAGER="yum"
                  else error "未找到支持的包管理器 (apt/dnf/pacman/yum)"
                  fi
                  ;;
        *)        error "不支持的操作系统: $OSTYPE" ;;
    esac

    case "$(uname -m)" in
        x86_64|amd64)  ARCH="amd64" ; ARCH_GO="linux-amd64" ; ARCH_CONDA="x86_64" ;;
        aarch64|arm64) ARCH="arm64" ; ARCH_GO="linux-arm64" ; ARCH_CONDA="aarch64" ;;
    esac

    info "系统: $OS | 包管理器: $PKG_MANAGER | 架构: $ARCH"
}

# ==================== 包管理器抽象 ====================
pkg_install() {
    case "$PKG_MANAGER" in
        brew)    brew install "$@" ;;
        apt)     sudo apt-get install -y "$@" ;;
        dnf)     sudo dnf install -y "$@" ;;
        pacman)  sudo pacman -S --noconfirm "$@" ;;
        yum)     sudo yum install -y "$@" ;;
    esac
}

# GitHub 加速代理
GH_PROXY="https://gh-proxy.com"

git_clone() {
    local repo="$1" dst="$2"
    if git clone "${GH_PROXY}/https://github.com/${repo}.git" "$dst" 2>/dev/null; then
        return 0
    else
        warn "gh-proxy 加速失败，尝试直连..."
        git clone "https://github.com/${repo}.git" "$dst"
    fi
}

# ==================== Homebrew (macOS) ====================
install_homebrew() {
    if [[ "$OS" != "macos" ]]; then return; fi
    if command -v brew &>/dev/null; then
        info "Homebrew 已安装"
        return
    fi
    info "安装 Homebrew..."
    /bin/bash -c "$(curl -fsSL "${GH_PROXY}/https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh")"
    eval "$(/opt/homebrew/bin/brew shellenv zsh)" 2>/dev/null || true
}

# ==================== Homebrew 镜像 (macOS) ====================
setup_brew_mirror() {
    if [[ "$OS" != "macos" ]]; then return; fi
    info "配置 Homebrew 清华镜像..."
    export HOMEBREW_API_DOMAIN="https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles/api"
    export HOMEBREW_BOTTLE_DOMAIN="https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles"
}

# ==================== 第三方 repo 安装 ====================

# GitHub CLI — apt/dnf 需加官方源
install_gh() {
    if command -v gh &>/dev/null; then info "gh 已安装"; return; fi
    case "$PKG_MANAGER" in
        brew) brew install gh ;;
        apt)
            info "添加 GitHub CLI 官方 apt 源..."
            (type -p wget >/dev/null || sudo apt-get install -y wget)
            sudo mkdir -p -m 755 /etc/apt/keyrings
            wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg \
                | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null
            sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
                | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
            sudo apt-get update -y && sudo apt-get install -y gh
            ;;
        dnf)
            info "添加 GitHub CLI 官方 dnf 源..."
            sudo dnf config-manager addrepo --from-repofile=https://cli.github.com/packages/rpm/gh.repo 2>/dev/null \
                || sudo dnf install -y 'dnf-command(config-manager)' && \
                   sudo dnf config-manager addrepo --from-repofile=https://cli.github.com/packages/rpm/gh.repo
            sudo dnf install -y gh
            ;;
        pacman) sudo pacman -S --noconfirm github-cli ;;
        yum)
            info "添加 GitHub CLI 官方 yum 源..."
            sudo yum-config-manager --add-repo https://cli.github.com/packages/rpm/gh.repo 2>/dev/null \
                || sudo dnf install -y 'dnf-command(config-manager)' && \
                   sudo dnf config-manager addrepo --from-repofile=https://cli.github.com/packages/rpm/gh.repo
            sudo yum install -y gh
            ;;
    esac
}

# eza — apt 需加 gierens.de 第三方源
install_eza() {
    if command -v eza &>/dev/null; then info "eza 已安装"; return; fi
    case "$PKG_MANAGER" in
        brew) brew install eza ;;
        apt)
            info "添加 eza 第三方 apt 源..."
            sudo mkdir -p /etc/apt/keyrings
            wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc \
                | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
            echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" \
                | sudo tee /etc/apt/sources.list.d/gierens.list
            sudo apt-get update -y && sudo apt-get install -y eza
            ;;
        dnf) sudo dnf install -y eza ;;
        pacman) sudo pacman -S --noconfirm eza ;;
        yum) pkg_install eza || install_via_script "eza" "https://github.com/eza-community/eza/releases/latest/download/eza_${ARCH}.tar.gz" ;;
    esac
}

# glow / crush — Charm apt/yum repo
setup_charm_repo() {
    case "$PKG_MANAGER" in
        apt)
            if [[ ! -f /etc/apt/sources.list.d/charm.list ]]; then
                info "添加 Charm apt 源..."
                sudo mkdir -p /etc/apt/keyrings
                curl -fsSL https://repo.charm.sh/apt/gpg.key \
                    | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg
                echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt * *" \
                    | sudo tee /etc/apt/sources.list.d/charm.list
                sudo apt-get update -y
            fi
            ;;
        dnf)
            if [[ ! -f /etc/yum.repos.d/charm.repo ]]; then
                info "添加 Charm yum 源..."
                sudo tee /etc/yum.repos.d/charm.repo << 'EOF'
[charm]
name=Charm
baseurl=https://repo.charm.sh/yum/
enabled=1
gpgcheck=1
gpgkey=https://repo.charm.sh/yum/gpg.key
EOF
            fi
            ;;
    esac
}

install_glow() {
    if command -v glow &>/dev/null; then info "glow 已安装"; return; fi
    case "$PKG_MANAGER" in
        brew) brew install glow ;;
        apt)  setup_charm_repo; pkg_install glow ;;
        dnf)  setup_charm_repo; pkg_install glow ;;
        pacman) pkg_install glow ;;
        yum) setup_charm_repo; pkg_install glow || true ;;
    esac
}

install_crush() {
    if command -v crush &>/dev/null; then info "crush 已安装"; return; fi
    case "$PKG_MANAGER" in
        brew) brew install charmbracelet/tap/crush ;;
        apt)  setup_charm_repo; pkg_install crush ;;
        dnf)  setup_charm_repo; pkg_install crush ;;
        pacman) warn "crush 无 pacman 包，请用 AUR 或 brew 安装" ;;
        yum) setup_charm_repo; pkg_install crush || true ;;
    esac
}

# ==================== 脚本安装工具 ====================

install_via_script() {
    local name="$1" url="$2"
    info "通过脚本安装 $name..."
    curl -fsSL "$url" | bash
}

install_nvm() {
    export NVM_DIR="${NVM_DIR:-$HOME/.local/share/nvm}"
    if [[ -s "$NVM_DIR/nvm.sh" ]]; then info "nvm 已安装"; return; fi
    info "安装 nvm..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh | bash
    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
}

install_uv() {
    if command -v uv &>/dev/null; then info "uv 已安装"; return; fi
    info "安装 uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
}

install_opencode() {
    if command -v opencode &>/dev/null; then info "opencode 已安装"; return; fi
    case "$PKG_MANAGER" in
        brew) brew install opencode ;;
        *)    install_via_script "opencode" "https://opencode.ai/install" ;;
    esac
}

install_dust() {
    if command -v dust &>/dev/null; then info "dust 已安装"; return; fi
    case "$PKG_MANAGER" in
        brew) brew install dust ;;
        *)
            info "通过脚本安装 dust..."
            local tmpdir
            tmpdir="$(mktemp -d)"
            curl -fsSL "https://github.com/bootandy/dust/releases/latest/download/du-dust_${ARCH_GO}.tar.gz" \
                | tar xz -C "$tmpdir"
            sudo mv "$tmpdir/dust" /usr/local/bin/
            rm -rf "$tmpdir"
            ;;
    esac
}

install_zoxide() {
    if command -v zoxide &>/dev/null; then info "zoxide 已安装"; return; fi
    case "$PKG_MANAGER" in
        brew) brew install zoxide ;;
        dnf)  pkg_install zoxide ;;
        pacman) pkg_install zoxide ;;
        *)    install_via_script "zoxide" "https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh" ;;
    esac
}

install_curlie() {
    if command -v curlie &>/dev/null; then info "curlie 已安装"; return; fi
    case "$PKG_MANAGER" in
        brew) brew install curlie ;;
        *)
            info "通过脚本安装 curlie..."
            local tmpdir
            tmpdir="$(mktemp -d)"
            curl -fsSL "https://github.com/rs/curlie/releases/latest/download/curlie_${ARCH}_linux_${PKG_MANAGER:-tar}.tar.gz" \
                | tar xz -C "$tmpdir" 2>/dev/null || \
            curl -fsSL "https://github.com/rs/curlie/releases/latest/download/curlie_${ARCH}_linux.tar.gz" \
                | tar xz -C "$tmpdir"
            sudo mv "$tmpdir/curlie" /usr/local/bin/
            rm -rf "$tmpdir"
            ;;
    esac
}

install_go() {
    if command -v go &>/dev/null; then info "go 已安装"; return; fi
    case "$PKG_MANAGER" in
        brew) brew install go ;;
        pacman) pkg_install go ;;
        *)
            info "通过官方 tarball 安装 Go..."
            local go_version="1.24.1"
            local tmpdir
            tmpdir="$(mktemp -d)"
            curl -fsSL "https://go.dev/dl/go${go_version}.${ARCH_GO}.tar.gz" \
                | sudo tar xz -C /usr/local
            rm -rf "$tmpdir"
            ;;
    esac
}

install_miniconda() {
    if [[ -f "${CONDA_PREFIX:-/opt/miniconda3}/bin/conda" ]]; then info "Miniconda 已安装"; return; fi
    local conda_prefix="${CONDA_PREFIX:-/opt/miniconda3}"
    info "安装 Miniconda（USTC 镜像）..."
    curl -fsSL "https://mirrors.ustc.edu.cn/anaconda/miniconda/Miniconda3-latest-MacOSX-${ARCH_CONDA}.sh" \
        -o /tmp/miniconda.sh 2>/dev/null || \
    curl -fsSL "https://mirrors.ustc.edu.cn/anaconda/miniconda/Miniconda3-latest-Linux-${ARCH_CONDA}.sh" \
        -o /tmp/miniconda.sh
    sudo bash /tmp/miniconda.sh -b -p "$conda_prefix"
    rm /tmp/miniconda.sh
}

# ==================== macOS only 工具 ====================
install_macos_only() {
    if [[ "$OS" != "macos" ]]; then return; fi
    info "安装 macOS 专属工具..."
    brew install --cask claude claude-code font-jetbrains-mono-nerd-font 2>/dev/null || true
}

# ==================== apt 符号链接修复 ====================
fix_apt_symlinks() {
    [[ "$PKG_MANAGER" != "apt" ]] && return
    # bat → batcat
    if command -v batcat &>/dev/null && ! command -v bat &>/dev/null; then
        info "创建 bat 符号链接 (batcat → bat)..."
        sudo ln -sf "$(which batcat)" /usr/local/bin/bat
    fi
    # fd → fdfind
    if command -v fdfind &>/dev/null && ! command -v fd &>/dev/null; then
        info "创建 fd 符号链接 (fdfind → fd)..."
        sudo ln -sf "$(which fdfind)" /usr/local/bin/fd
    fi
}

# ==================== 镜像源配置 ====================
setup_mirrors() {
    info "配置镜像源..."

    # npm 淘宝镜像
    if command -v npm &>/dev/null; then
        npm config set registry https://registry.npmmirror.com 2>/dev/null || true
    fi

    # pnpm 淘宝镜像
    if command -v pnpm &>/dev/null; then
        pnpm config set registry https://registry.npmmirror.com 2>/dev/null || true
    fi

    # pip 清华镜像
    if command -v pip3 &>/dev/null || command -v pip &>/dev/null; then
        mkdir -p "$HOME/.config/pip"
        cat > "$HOME/.config/pip/pip.conf" << 'PIP_EOF'
[global]
index-url = https://mirrors.tuna.tsinghua.edu.cn/pypi/web/simple
PIP_EOF
    fi

    # Go 代理
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

    # conda 清华镜像
    if command -v conda &>/dev/null; then
        info "配置 conda 清华镜像..."
        conda config --set show_channel_urls true
        conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/main/
        conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/free/
        conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud/conda-forge/
        conda config --set channel_priority strict
    fi
}

# ==================== Oh My Zsh ====================
install_ohmyzsh() {
    if [[ -d "$HOME/.local/share/oh-my-zsh" ]]; then
        info "Oh My Zsh 已安装"
        return
    fi
    info "安装 Oh My Zsh（国内镜像）..."
    RUNZSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL "${GH_PROXY}/https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh")"
}

install_zsh_plugins() {
    local ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.local/share/oh-my-zsh/custom}"

    if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]]; then
        info "安装 zsh-autosuggestions..."
        git_clone zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
    fi

    if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]]; then
        info "安装 zsh-syntax-highlighting..."
        git_clone zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
    fi
}

# ==================== fzf ====================
setup_fzf() {
    info "配置 fzf..."
    if [[ "$OS" == "macos" ]]; then
        /opt/homebrew/opt/fzf/install --all --no-bash --no-fish 2>/dev/null || true
    else
        if command -v fzf &>/dev/null; then
            # 尝试运行 fzf 的 install 脚本
            local fzf_base
            fzf_base="$(dirname "$(dirname "$(which fzf)")")"
            [[ -f "${fzf_base}/share/fzf/install" ]] && \
                "${fzf_base}/share/fzf/install" --all --no-bash --no-fish 2>/dev/null || true
        fi
    fi
}

# ==================== 符号链接 ====================
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

setup_symlinks() {
    info "创建符号链接..."

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
}

# ==================== 复制 .example 文件 ====================
setup_examples() {
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
}

# ==================== 主流程 ====================
main() {
    detect_os

    # macOS: 安装 Homebrew
    install_homebrew
    setup_brew_mirror

    # ==================== 基础工具安装 ====================
    info "安装基础工具..."

    if [[ "$OS" == "macos" ]]; then
        # macOS: 全部用 brew
        local FORMULAE=(
            git neovim tmux
            bat btop dust eza fd fzf glow ripgrep tree
            tree-sitter tree-sitter-cli
            tldr wget z zoxide
            curlie gh httpie nmap
            go ruby
            witr crush opencode
        )
        info "brew install: ${FORMULAE[*]}"
        brew install "${FORMULAE[@]}" 2>/dev/null || brew upgrade "${FORMULAE[@]}" 2>/dev/null || true
    else
        # Linux: 按包管理器安装
        info "通过 $PKG_MANAGER 安装基础包..."
        local COMMON_LINUX_PACKAGES=(
            git neovim tmux bat fzf ripgrep tree wget httpie nmap ruby
        )

        case "$PKG_MANAGER" in
            apt)
                sudo apt-get update -y
                pkg_install "${COMMON_LINUX_PACKAGES[@]}" fd-find || pkg_install "${COMMON_LINUX_PACKAGES[@]}"
                ;;
            dnf)
                pkg_install "${COMMON_LINUX_PACKAGES[@]}" python3-neovim fd-find btop
                ;;
            pacman)
                pkg_install "${COMMON_LINUX_PACKAGES[@]}" fd go btop zoxide glow
                ;;
            yum)
                pkg_install "${COMMON_LINUX_PACKAGES[@]}"
                ;;
        esac

        # 需要特殊处理的工具
        install_gh
        install_eza
        install_glow
        install_crush
        install_dust
        install_zoxide
        install_curlie
        install_go
        fix_apt_symlinks
    fi

    # ==================== 脚本安装工具 ====================
    install_nvm
    install_uv
    install_opencode
    install_miniconda

    # ==================== macOS only ====================
    install_macos_only

    # ==================== nvm → Node ====================
    export NVM_DIR="${NVM_DIR:-$HOME/.local/share/nvm}"
    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
    if command -v nvm &>/dev/null; then
        info "通过 nvm 安装最新 LTS Node..."
        nvm install --lts 2>/dev/null || warn "nvm install 失败，请手动执行: nvm install --lts"
    else
        warn "nvm 未找到，跳过 Node 安装"
    fi

    # ==================== conda → Python ====================
    local conda_bin="${CONDA_PREFIX:-/opt/miniconda3}/bin/conda"
    if [[ -x "$conda_bin" ]]; then
        info "通过 conda 安装 Python 3..."
        "$conda_bin" install -y python=3 2>/dev/null || warn "conda install python 失败，请手动执行"
    fi

    # ==================== 镜像源 ====================
    setup_mirrors

    # ==================== Oh My Zsh ====================
    install_ohmyzsh
    install_zsh_plugins

    # ==================== fzf ====================
    setup_fzf

    # ==================== 符号链接 ====================
    setup_symlinks

    # ==================== 示例文件 ====================
    setup_examples

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
}

main "$@"
