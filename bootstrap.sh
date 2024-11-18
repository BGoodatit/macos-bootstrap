#!/usr/bin/env bash
# Enhanced Bootstrap Script with Git, Brewfile Setup, and macOS Configuration
# Author: Brice Goodwin
# Date: YYYY-MM-DD
# Version: 1.0

set -euo pipefail

# Configurable Parameters
STRAP_GIT_EMAIL='BriceGoodwin0313@icloud.com'
STRAP_GITHUB_USER='BGoodatit'
STRAP_GITHUB_TOKEN='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'
HOMEBREW_BREWFILE_URL="https://github.com/$STRAP_GITHUB_USER/homebrew-brewfile"
HOMEBREW_INSTALL_URL="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"
DOTFILES_REPO="https://github.com/$STRAP_GITHUB_USER/dotfiles.git"
DOTFILES_DIR="$HOME/.files"
LOG_FILE="bootstrap.log"

# Utility Functions
log() {
    echo "--> $*"
}

abort() {
    echo "!!! $*" >&2
    exit 1
}

install_package() {
    local package_name="$1"
    if ! brew install "$package_name"; then
        echo "Error installing $package_name. Please check your Homebrew setup." >&2
        exit 1
    fi
}

# Check Internet Connectivity
check_internet() {
    log "Checking internet connectivity..."
    if ! ping -c 1 google.com &>/dev/null; then
        abort "No internet connection. Please connect and retry."
    fi
}

# Confirm Script Execution
confirm_execution() {
    read -p "This script will configure your macOS setup. Proceed? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log "Aborted."
        exit 0
    fi
}

# Install Rosetta (Apple Silicon only)
install_rosetta() {
    if [[ "$(uname -m)" == "arm64" ]] && ! /usr/libexec/rosetta --help &>/dev/null; then
        log "Installing Rosetta..."
        sudo softwareupdate --install-rosetta --agree-to-license
    fi
}

# Install Xcode Command Line Tools
install_xcode_tools() {
    if ! xcode-select -p &>/dev/null; then
        log "Installing Xcode Command Line Tools..."
        sudo xcode-select --install
        until xcode-select -p &>/dev/null; do
            sleep 5
        done
    else
        log "Xcode Command Line Tools already installed."
    fi
}

# Install Homebrew
install_homebrew() {
    if ! command -v brew &>/dev/null; then
        log "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL $HOMEBREW_INSTALL_URL)"
        eval "$(/opt/homebrew/bin/brew shellenv)"
    else
        log "Homebrew already installed."
    fi
}

# Configure Homebrew
configure_homebrew() {
    log "Configuring Homebrew..."
    brew analytics off
    brew update
    brew upgrade
    brew autoupdate start 43200
}

# Git Configuration
setup_git() {
    log "Configuring Git..."
    git config --global user.name "$STRAP_GITHUB_USER"
    git config --global user.email "$STRAP_GIT_EMAIL"
    git config --global github.user "$STRAP_GITHUB_USER"
    git config --global push.default simple

    if [ -n "$STRAP_GITHUB_TOKEN" ]; then
        printf 'protocol=https\nhost=github.com\nusername=%s\npassword=%s\n' \
            "$STRAP_GITHUB_USER" "$STRAP_GITHUB_TOKEN" |
            git credential approve
    fi
    log "Git configured successfully."
}

# Brewfile Setup
setup_brewfile() {
    log "Setting up Homebrew Brewfile..."
    if git ls-remote "$HOMEBREW_BREWFILE_URL" &>/dev/null; then
        [ ! -d "$HOME/.homebrew-brewfile" ] && git clone "$HOMEBREW_BREWFILE_URL" "$HOME/.homebrew-brewfile"
        (cd "$HOME/.homebrew-brewfile" && git pull)
        ln -sf "$HOME/.homebrew-brewfile/Brewfile" "$HOME/.Brewfile"
        brew bundle --global || abort "Brewfile dependency installation failed."
        log "Brewfile dependencies installed successfully."
    else
        abort "Brewfile repository not found or inaccessible."
    fi
}

# Install Essential Tools
install_tools() {
    log "Installing essential tools..."
    install_package rbenv &
    install_package pyenv &
    install_package n &
    install_package yarn &
    install_package git &
    install_package wget &
    install_package python &
    install_package zsh &
    install_package fish &
    install_package --cask visual-studio-code &
    wait
    log "Tools installed successfully."
}

# macOS Configuration
configure_macos() {
    log "Configuring macOS security settings..."
    sudo defaults write com.apple.screensaver askForPassword -int 1
    sudo defaults write com.apple.screensaver askForPasswordDelay -int 0
    sudo defaults write /Library/Preferences/com.apple.alf globalstate -int 1
    sudo launchctl load /System/Library/LaunchDaemons/com.apple.alf.agent.plist 2>/dev/null

    # Enable FileVault
    log "Checking FileVault status..."
    if ! fdesetup status | grep -q "FileVault is On"; then
        log "Enabling FileVault..."
        sudo fdesetup enable -user "$USER" | tee "$HOME/Desktop/FileVault_Recovery_Key.txt"
    fi

    # Configure TouchID for sudo
    log "Configuring TouchID for sudo authentication..."
    if ! grep -q pam_tid /etc/pam.d/sudo 2>/dev/null; then
        sudo sed -i.bak '1 a\auth       sufficient     pam_tid.so' /etc/pam.d/sudo
    fi
}

# Cleanup
cleanup() {
    log "Cleaning up temporary files..."
    rm -rf "$DOTFILES_DIR/tmp"
}

# Post-Install Verification
verify_installations() {
    log "Verifying installations..."
    command -v brew &>/dev/null || abort "Homebrew installation failed."
    command -v fish &>/dev/null || abort "Fish shell installation failed."
}

# Main Script Execution
main() {
    exec > >(tee -i "$LOG_FILE")
    exec 2>&1

    check_internet
    confirm_execution
    install_rosetta
    install_xcode_tools
    install_homebrew
    configure_homebrew
    setup_git
    setup_brewfile
    install_tools
    configure_macos
    verify_installations
    cleanup

    log "Bootstrap and installation complete. Restart your terminal!"
}

main
