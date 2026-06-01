export HISTCONTROL=ignoredups
export HISTIGNORE="history*:fc*:exit"

if [ -f ~/.dotfiles/shell/.aliases ]; then
    source ~/.dotfiles/shell/.aliases
fi

eval "$(starship init bash)"
eval "$(fnm env --use-on-cd --shell bash)"
