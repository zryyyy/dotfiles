<#
.SYNOPSIS
    Windows dotfiles setup script
#>

$ErrorActionPreference = "Stop"

if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "[!] Please run this script as an administrator in order to create symbolic links." -ForegroundColor Yellow
    exit 1
}

# ──────────────────────────────────────────────────
# Colors & logging
# ──────────────────────────────────────────────────
function info($msg) { Write-Host "[✓] $msg" -ForegroundColor Green }
function warn($msg) { Write-Host "[!] $msg" -ForegroundColor Yellow }
function section($msg) { Write-Host "`n── $msg ──" -ForegroundColor Yellow }
function die($msg) { Write-Host "[✗] $msg" -ForegroundColor Red; exit 1 }

# ──────────────────────────────────────────────────
# Update Winget
# ──────────────────────────────────────────────────
section "Winget Update"

info "Updating winget package sources..."
winget source update

# ──────────────────────────────────────────────────
# SSH
# ──────────────────────────────────────────────────
section "SSH"

$ErrorActionPreference = "Continue"
$sshOutput = ssh -T -o StrictHostKeyChecking=accept-new git@github.com 2>&1
$ErrorActionPreference = "Stop"
$sshOutputStr = $sshOutput -join " "

if ($sshOutputStr -match "successfully authenticated") {
    info "GitHub SSH connection is already configured and working, skipping SSH setup"
} else {
    warn "GitHub SSH is not yet configured, starting setup..."

    # Generate key
    $sshKeyPath = "$HOME\.ssh\id_ed25519"
    if (Test-Path $sshKeyPath) {
        info "SSH key already exists, skipping generation"
    } else {
        # Create .ssh directory if not exists
        if (-Not (Test-Path "$HOME\.ssh")) { New-Item -ItemType Directory -Path "$HOME\.ssh" | Out-Null }
        ssh-keygen -t ed25519 -f $sshKeyPath -N ""
        info "SSH key generated"
    }

    # Copy public key and wait for user
    Get-Content "$sshKeyPath.pub" | Set-Clipboard
    info "Public key copied to clipboard"

    Write-Host "`n"
    Start-Process "https://github.com/settings/keys"
    Write-Host "The GitHub SSH Keys page has been opened in the browser" -ForegroundColor Yellow
    Write-Host "Press Enter to continue after you have added the key..." -ForegroundColor Yellow
    Read-Host

    # Test connection again
    $ErrorActionPreference = "Continue"
    $sshOutput = ssh -T git@github.com 2>&1
    $ErrorActionPreference = "Stop"
    $sshOutputStr = $sshOutput -join " "

    if ($sshOutputStr -match "successfully authenticated") {
        info "SSH connection successful!"
    } else {
        die "SSH connection failed: $sshOutputStr"
    }
}

# ──────────────────────────────────────────────────
# Git
# ──────────────────────────────────────────────────
section "Git"

if (Get-Command git -ErrorAction SilentlyContinue) {
    $gitVersion = (git --version)
    info "git already installed ($gitVersion), skipping"
} else {
    info "Installing git..."
    winget install --id Git.Git -e --source winget --accept-source-agreements --accept-package-agreements
    info "git installed."
    # Refresh PATH temporarily for the current session
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
}

# ──────────────────────────────────────────────────
# Clone dotfiles
# ──────────────────────────────────────────────────
section "Dotfiles"

$DOTFILES_DIR = "$HOME\.dotfiles"

if (Test-Path $DOTFILES_DIR) {
    info "Dotfiles already exist at $DOTFILES_DIR, skipping"
} else {
    git clone git@github.com:zryyyy/dotfiles.git $DOTFILES_DIR
    info "Cloned dotfiles to $DOTFILES_DIR"
}

# ──────────────────────────────────────────────────
# Restore
# ──────────────────────────────────────────────────
section "Restore"

$bashExe = "bash"
if (-Not (Get-Command bash -ErrorAction SilentlyContinue)) {
    $gitBashPath = "C:\Program Files\Git\bin\bash.exe"
    if (Test-Path $gitBashPath) {
        $bashExe = $gitBashPath
    } else {
        warn "Could not find bash.exe. The restore script might fail."
    }
}

$env:MSYS = "winsymlinks:nativestrict"
& $bashExe "$DOTFILES_DIR\scripts\restore.sh"

# helix
$helixConfig = "$HOME\.dotfiles\helix"
$helixAppData = "$Env:AppData\helix"

if (-Not (Test-Path $helixAppData)) {
    # Ensure the target directory exists first, otherwise junction might break
    if (-Not (Test-Path $helixConfig)) { New-Item -ItemType Directory -Path $helixConfig -Force | Out-Null }
    New-Item -ItemType Junction -Path $helixAppData -Target $helixConfig | Out-Null
    info "Created Helix junction"
} else {
    info "Helix config folder/junction already exists in AppData, skipping"
}

# ──────────────────────────────────────────────────
# Winget Package Installation
# ──────────────────────────────────────────────────
section "Winget Packages"

$WINGET_LIST = "$DOTFILES_DIR\packages\winget.list"

if (Test-Path $WINGET_LIST) {
    info "Reading packages from $WINGET_LIST..."

    # Extract valid package IDs (non-comment, non-empty lines)
    $packages = Get-Content $WINGET_LIST | Where-Object { $_ -match '\S' -and $_ -notmatch '^#' } | ForEach-Object { $_.Trim() }

    if ($packages.Count -gt 0) {
        info "Installing packages..."
        foreach ($pkg in $packages) {
            info "Installing $pkg..."
            # Using -e for exact match of the ID
            winget install --id $pkg -e --accept-source-agreements --accept-package-agreements
            if ($LASTEXITCODE -ne 0) {
                warn "Failed to install $pkg (Exit Code: $LASTEXITCODE). Skipping to the next package."
            }
        }
        info "Packages installed successfully"
    } else {
        warn "No packages found in $WINGET_LIST"
    }
} else {
    warn "winget.list not found at $WINGET_LIST, skipping package installation"
}

# ──────────────────────────────────────────────────
info "All done!"
