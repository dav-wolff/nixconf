# [--powerlevel10k--]
# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/temp_home/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
	source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

source @P10K@/powerlevel10k.zsh-theme
source $ZDOTDIR/p10k.zsh

# [--aliases--]
alias ls='ls --color'
alias la='ls -la'
alias nd='nix develop --command zsh'
function ns() {
	nix shell $1 --command zsh
}

# [--completion--]
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# [--histoy--]
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

bindkey '^p' history-search-backward
bindkey '^n' history-search-forward

# [--zsh-syntax-highlighting--]
source @SYNTAX_HIGHLIGHTING@/zsh-syntax-highlighting.zsh

# [--zsh-autosuggestions--]
source @AUTOSUGGESTIONS@/zsh-autosuggestions.zsh

# [--fzf--]
path=(@FZF@ $path)
source <(fzf --zsh)
bindkey '^w' fzf-history-widget
bindkey '^x' fzf-file-widget

# [--zsh-completions--]
fpath=(@COMPLETIONS@ $fpath)
# compinit should occur after all completions have been added
autoload -U compinit && compinit

# [--zoxide--]
path=(@ZOXIDE@ $path)
eval "$(zoxide init --cmd cd zsh)"
