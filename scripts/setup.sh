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
# SSH
# ──────────────────────────────────────────────────
section "SSH"

SSH_OUTPUT=$(ssh -T git@github.com 2>&1 || true)

if echo "$SSH_OUTPUT" | grep -q "successfully authenticated"; then
    info "GitHub SSH connection is already configured and working, skipping SSH setup"
else
    warn "GitHub SSH is not yet configured, starting setup..."

    # Generate key
    if [[ -f "$HOME/.ssh/id_ed25519" ]]; then
        info "SSH key already exists, skipping"
    else
        ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N ""
        info "SSH key generated"
    fi

    # Copy public key and wait for user
    pbcopy <"$HOME/.ssh/id_ed25519.pub"
    info "Public key copied to clipboard"

    echo ""
    open "https://github.com/settings/keys"
    echo -e "${YELLOW}The GitHub SSH Keys page has been opened in the browser${NC}"
    echo -e "${YELLOW}Press Enter to continue...${NC}"
    read -r || true

    # Test connection
    SSH_OUTPUT=$(ssh -T git@github.com 2>&1 || true)

    if echo "$SSH_OUTPUT" | grep -q "successfully authenticated"; then
        info "SSH connection successful!"
    else
        die "SSH connection failed: $SSH_OUTPUT"
    fi
fi

# ──────────────────────────────────────────────────
# Homebrew
# ──────────────────────────────────────────────────
section "Homebrew"

if command -v brew &>/dev/null; then
    info "Homebrew already installed, skipping"
else
    info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    if [[ -f /opt/homebrew/bin/brew ]]; then
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi

    info "Homebrew installed"
fi

brew update
brew upgrade
brew cleanup

# ──────────────────────────────────────────────────
# Git
# ──────────────────────────────────────────────────
section "Git"

if command -v git &>/dev/null; then
    info "git already installed ($(git --version)), skipping"
else
    brew install git
    info "git installed"
fi

# ──────────────────────────────────────────────────
# Clone dotfiles
# ──────────────────────────────────────────────────
section "Dotfiles"

DOTFILES_DIR="$HOME/.dotfiles"

if [[ -d "$DOTFILES_DIR" ]]; then
    info "Dotfiles already exist at $DOTFILES_DIR, skipping"
else
    git clone git@github.com:zryyyy/dotfiles.git "$DOTFILES_DIR"
    info "Cloned dotfiles to $DOTFILES_DIR"
fi

# ──────────────────────────────────────────────────
# Restore
# ──────────────────────────────────────────────────
section "Restore"

RESTORE_SCRIPT="$DOTFILES_DIR/scripts/restore.sh"

[[ -f "$RESTORE_SCRIPT" ]] || die "restore.sh not found at $RESTORE_SCRIPT"

bash "$RESTORE_SCRIPT"
