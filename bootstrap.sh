#!/usr/bin/env bash
# Enhanced Bootstrap Script with Git and Brewfile Setup
# Author: Brice Goodwin
# Date: YYYY-MM-DD
# Version: 1.0

# Set strict error handling
set -euo pipefail

# Environment Variables
export STRAP_GIT_EMAIL='BriceGoodwin0313@icloud.com'
export STRAP_GITHUB_USER='BGoodatit'
export STRAP_GITHUB_TOKEN='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'
export HOMEBREW_BREWFILE_URL="https://github.com/$STRAP_GITHUB_USER/homebrew-brewfile"
STRAP_ISSUES_URL='https://github.com/MikeMcQuaid/strap/issues/new'

# Utility Functions
log() {
    echo "--> $*"
}

abort() {
    echo "!!! $*" >&2
    exit 1
}

# Function to set up Git
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

# Function to set up and install Brewfile dependencies
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

# Function to install necessary tools
install_tools() {
    log "Installing essential tools..."
    brew install rbenv pyenv n yarn git wget python zsh fish
    brew install --cask visual-studio-code
    log "Tools installed successfully."
}

# Function to configure macOS settings
configure_macos() {
    log "Configuring macOS security and preferences..."
    sudo defaults write com.apple.screensaver askForPassword -int 1
    sudo defaults write com.apple.screensaver askForPasswordDelay -int 0
    sudo defaults write /Library/Preferences/com.apple.alf globalstate -int 1
    sudo launchctl load /System/Library/LaunchDaemons/com.apple.alf.agent.plist
    log "macOS configuration complete."
}

# Function to install Homebrew
install_homebrew() {
    if ! command -v brew &>/dev/null; then
        log "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        eval "$(/opt/homebrew/bin/brew shellenv)"
    else
        log "Homebrew is already installed."
    fi
}

# Check Internet Connectivity
check_internet() {
    log "Checking internet connectivity..."
    ping -c 1 google.com &>/dev/null || abort "No internet connection. Please connect and retry."
    log "Internet connection verified."
}

# Main Script Execution
log "Starting Bootstrap Script..."
check_internet
install_homebrew
setup_git
setup_brewfile
install_tools
configure_macos

log "Bootstrap Script completed successfully. Restart your terminal!"
