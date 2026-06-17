export HISTCONTROL=ignoredups
export HISTIGNORE="history*:fc*:exit"

if [ -f ~/.dotfiles/shell/.aliases ]; then
    source ~/.dotfiles/shell/.aliases
fi

export PATH="$HOME/.local/bin:$PATH"

eval "$(starship init bash)"
eval "$(fnm env --use-on-cd --shell bash)"

if [ -n "$PATH" ]; then
    export PATH=$(echo "$PATH" | tr ':' '\n' | awk '!a[$0]++' | paste -sd ':' -)
fi
