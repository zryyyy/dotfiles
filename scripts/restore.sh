#!/bin/bash

set -Eeuo pipefail
IFS=$'\n\t'

# ──────────────────────────────────────────────────
# Colors & logging
# ──────────────────────────────────────────────────
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info() { echo -e "${GREEN}[✓]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
section() { echo -e "\n${YELLOW}── $* ──${NC}"; }
die() {
    echo -e "${RED}[✗]${NC} $*" >&2
    exit 1
}

trap 'die "Error on line $LINENO"' ERR

# ──────────────────────────────────────────────────
# Preparation
# ──────────────────────────────────────────────────
section "Preparation"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIG_DIR="$HOME/.config"

info "Dotfiles: $DOTFILES_DIR"
info "Config:   $CONFIG_DIR"

mkdir -p "$CONFIG_DIR"

# ──────────────────────────────────────────────────
# Functions
# ──────────────────────────────────────────────────
link_dir() {
    local src="$1" dst="$2"
    rm -rf "$dst"
    ln -s "$src" "$dst"
    info "Linked dir  $dst → $src"
}

link_file() {
    local src="$1" dst="$2"
    mkdir -p "$(dirname "$dst")"
    ln -sf "$src" "$dst"
    info "Linked file $dst → $src"
}

# ──────────────────────────────────────────────────
# Config dirs & files
# ──────────────────────────────────────────────────
section "Config dirs & files"

for dir in ghostty helix; do
    link_dir "$DOTFILES_DIR/$dir" "$CONFIG_DIR/$dir"
done

for file in "bash/.bashrc" "zsh/.zshrc" "git/.gitconfig"; do
    filename=$(basename "$file")
    link_file "$DOTFILES_DIR/$file" "$HOME/$filename"
done

link_file "$DOTFILES_DIR/starship/starship.toml" "$CONFIG_DIR/starship.toml"

# ──────────────────────────────────────────────────
# Brew bundle
# ──────────────────────────────────────────────────
section "Brew bundle"

brew bundle --file="$DOTFILES_DIR/Brewfile"
