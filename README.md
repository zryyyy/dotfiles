# Dotfiles

My personal dotfiles and configs

## Usage

```sh
# 🍎 macOS
bash <(curl -fsSL https://raw.githubusercontent.com/zryyyy/dotfiles/HEAD/scripts/mac.sh)

# 🐧 Ubuntu
bash <(curl -fsSL https://raw.githubusercontent.com/zryyyy/dotfiles/HEAD/scripts/ubuntu.sh)

# 🪟 Windows
powershell -ep Bypass -c "irm 'https://raw.githubusercontent.com/zryyyy/dotfiles/HEAD/scripts/install.ps1' | iex"
```

## Generate Brewfile

```sh
brew bundle dump --force --file=./packages/Brewfile
```

## References

- [soerenmartius/awesome-dotfiles](https://github.com/soerenmartius/awesome-dotfiles)
- [hendrikmi/dotfiles](https://github.com/hendrikmi/dotfiles)
- [mattmc3/zephyr](https://github.com/mattmc3/zephyr)
- [ANRlm/dotfiles](https://github.com/ANRlm/dotfiles)
