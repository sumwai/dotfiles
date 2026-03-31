# Oh My Zsh 配置
# 主题设置
ZSH_THEME="robbyrussell"

# 插件
plugins=(git z zsh-autosuggestions zsh-syntax-highlighting)

# 加载 Oh My Zsh
source $ZSH/oh-my-zsh.sh

# 加载本地私密配置（token、密码等）
[[ -f "$ZDOTDIR/.zshrc.local" ]] && source "$ZDOTDIR/.zshrc.local"

# z 插件
. /opt/homebrew/etc/profile.d/z.sh

# NVM - 确保 NVM_DIR 正确
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"
[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"

# PATH


alias vim="nvim"
alias nv="nvim"
# Aliases
# Functions
tunnel() {
    ssh -N -f -L $1:127.0.0.1:$1 $2
}

# Github
source "$ZDOTDIR/completions/gh.zsh"

# pnpm
export PNPM_HOME="$XDG_DATA_HOME/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

# bun completions
[ -s "$BUN_INSTALL/_bun" ] && source "$BUN_INSTALL/_bun"

. "$HOME/.local/share/../bin/env"

# eval "$(starship init zsh)"

mdurl() { curl -s --header "Accept: text/markdown" "$1" | glow; }

alias vz="vim $XDG_CONFIG_HOME/zsh/.zshrc"

alias du="dust"
export PATH="/opt/homebrew/opt/ruby/bin:/opt/homebrew/lib/ruby/gems/4.0.0/bin:$PATH"

eval "$(try init ~/src/tries)"

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/opt/miniconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/opt/miniconda3/etc/profile.d/conda.sh" ]; then
        . "/opt/miniconda3/etc/profile.d/conda.sh"
    else
        export PATH="/opt/miniconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

# 加载根目录 .zshrc（因 ZDOTDIR 设置，zsh 不会自动加载 ~/.zshrc）
[[ -f "$HOME/.zshrc" ]] && source "$HOME/.zshrc"
