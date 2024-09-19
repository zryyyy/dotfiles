# Desc: Install software using Homebrew

# Make sure we’re using the latest Homebrew.
brew update
# Upgrade any already-installed formulae.
brew upgrade

# Install env
# brew install nvm

# Install software
brew install miaoyan

brew install --cask keka
brew install --cask prettyclean
brew install --cask microsoft-edge
brew install --cask visual-studio-code

# Install command-line tools
brew install starship
brew install --cask wezterm

# Install Localsend
# brew tap localsend/localsend
# brew install localsend

# Other
# Fork https://git-fork.com/
# brew install --cask fork
# Arc https://arc.net/
# brew install --cask arc
# Raycast https://raycast.com/
# brew install --cask raycast
# Warp https://warp.dev/
# brew install --cask warp
# Logi Options Plus https://www.logitech.com/en-us/software/logi-options-plus.html
# brew install --cask logi-options+

# Remove outdated versions from the cellar.
brew cleanup
