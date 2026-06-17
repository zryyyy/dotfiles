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
# Sudo Keep-alive
# ──────────────────────────────────────────────────
info "Prompting for sudo password..."
sudo -v
# Keep-alive
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# ──────────────────────────────────────────────────
# DNF System Update
# ──────────────────────────────────────────────────
section "System Update"

info "Updating and upgrading DNF packages..."
sudo dnf upgrade --refresh -y || warn "dnf upgrade encountered some errors..."
sudo dnf autoremove -y

info "Installing base utilities"
sudo dnf install -y curl wget gnupg2 openssh-clients gawk

# ──────────────────────────────────────────────────
# SSH
# ──────────────────────────────────────────────────
section "SSH"

SSH_AVAILABLE=false
SSH_OUTPUT=$(ssh -T -o StrictHostKeyChecking=accept-new git@github.com 2>&1 || true)

if echo "$SSH_OUTPUT" | grep -q "successfully authenticated"; then
    SSH_AVAILABLE=true
    info "GitHub SSH connection is already configured and working, skipping SSH setup"
else
    warn "GitHub SSH is not yet configured, starting setup..."

    # Generate key
    if [[ -f "$HOME/.ssh/id_ed25519" ]]; then
        info "SSH key already exists, skipping generation"
    else
        ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N ""
        info "SSH key generated"
    fi

    # Print public key and wait for user
    echo -e "\n${YELLOW}====================================================================${NC}"
    cat "$HOME/.ssh/id_ed25519.pub"
    echo -e "${YELLOW}====================================================================${NC}\n"

    info "Please copy the SSH public key above."

    echo ""
    if command -v xdg-open &>/dev/null; then
        xdg-open "https://github.com/settings/keys" &>/dev/null || true
        echo -e "${YELLOW}Attempting to open GitHub SSH Keys page in your browser...${NC}"
    else
        echo -e "${YELLOW}Please manually open: https://github.com/settings/keys${NC}"
    fi

    echo -e "${YELLOW}Press Enter to continue after you have added the key...${NC}"
    read -r || true

    # Test connection
    SSH_OUTPUT=$(ssh -T git@github.com 2>&1 || true)

    if echo "$SSH_OUTPUT" | grep -q "successfully authenticated"; then
        SSH_AVAILABLE=true
        info "SSH connection successful!"
    else
        warn "SSH connection failed: $SSH_OUTPUT"
        warn "Continuing with HTTPS origin"
    fi
fi

# ──────────────────────────────────────────────────
# Git
# ──────────────────────────────────────────────────
section "Git"

if command -v git &>/dev/null; then
    info "git already installed ($(git --version)), skipping"
else
    info "Installing git..."
    sudo dnf install -y git
    info "git installed"
fi

# ──────────────────────────────────────────────────
# Clone dotfiles
# ──────────────────────────────────────────────────
section "Dotfiles"

DOTFILES_DIR="$HOME/.dotfiles"
HTTPS_REPO_URL="https://github.com/zryyyy/dotfiles.git"
SSH_REPO_URL="git@github.com:zryyyy/dotfiles.git"

if [[ -d "$DOTFILES_DIR" ]]; then
    info "Dotfiles already exist at $DOTFILES_DIR, skipping"
    git -C "$DOTFILES_DIR" pull || warn "Failed to pull latest dotfiles, continuing with existing..."
else
    git clone "$HTTPS_REPO_URL" "$DOTFILES_DIR"
    if [[ "$SSH_AVAILABLE" == true ]]; then
        git -C "$DOTFILES_DIR" remote set-url origin "$SSH_REPO_URL"
        info "Updated dotfiles origin to SSH"
    fi
    info "Cloned dotfiles to $DOTFILES_DIR"
fi

# ──────────────────────────────────────────────────
# Restore
# ──────────────────────────────────────────────────
section "Restore"

RESTORE_SCRIPT="$DOTFILES_DIR/scripts/restore.sh"

[[ -f "$RESTORE_SCRIPT" ]] || die "restore.sh not found at $RESTORE_SCRIPT"

bash "$RESTORE_SCRIPT"

# ──────────────────────────────────────────────────
# DNF Package Installation
# ──────────────────────────────────────────────────
section "DNF Packages"

DNF_LIST="$DOTFILES_DIR/packages/dnf.list"

if [[ -f "$DNF_LIST" ]]; then
    info "Reading packages from $DNF_LIST..."

    # Extract package names from non-comment, non-empty lines
    mapfile -t PKG_ARRAY < <(awk '/^[^#]/{print $1}' "$DNF_LIST")

    if [[ ${#PKG_ARRAY[@]} -gt 0 ]]; then
        info "Installing packages..."
        sudo dnf install -y --skip-broken --skip-unavailable "${PKG_ARRAY[@]}"
        info "Packages installed successfully"
    else
        warn "No packages found in $DNF_LIST"
    fi
else
    warn "dnf.list not found at $DNF_LIST, skipping package installation"
fi

# ──────────────────────────────────────────────────
# Manual Installs
# ──────────────────────────────────────────────────
section "Manual Installs"

# fnm
curl -fsSL https://fnm.vercel.app/install | bash -s -- --skip-shell --install-dir "$HOME/.local/share/fnm"
mkdir -p "$HOME/.local/bin"
ln -sf "$HOME/.local/share/fnm/fnm" "$HOME/.local/bin/fnm"
# starship
curl -sS https://starship.rs/install.sh | sh -s -- -y

# ──────────────────────────────────────────────────
info "All done!"
