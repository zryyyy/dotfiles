if [ -f ~/.dotfiles/shell/.aliases ]; then
    source ~/.dotfiles/shell/.aliases
fi

eval "$(starship init zsh)"
eval "$(fnm env --use-on-cd --shell zsh)"
