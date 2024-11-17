#!/usr/bin/env bash
# Author  : Combined by [Your Name]
# License : GPLv3

set -ueo pipefail

# Configurable Parameters
HOMEBREW_INSTALL_URL="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"
DOTFILES_REPO="https://github.com/BGoodatit/dotfiles.git"
DOTFILES_DIR="$HOME/.files"
LOG_FILE="bootstrap.log"

# Function for installing packages with error handling
install_package() {
  local package_name="$1"
  if ! brew install "$package_name"; then
    echo "Error installing $package_name. Please check your Homebrew setup." >&2
    exit 1
  fi
}

# Set up logging
exec > >(tee -i "$LOG_FILE")
exec 2>&1

# Check Internet Connectivity
if ! ping -c 1 google.com &>/dev/null; then
  echo "Error: No internet connection. Please connect to the internet and retry."
  exit 1
fi

# Confirm Script Execution
read -p "This script will configure your macOS setup. Proceed? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "Aborted."
  exit 0
fi

# Install Rosetta (Apple Silicon only)
if [[ "$(uname -m)" == "arm64" ]] && ! /usr/libexec/rosetta --help &>/dev/null; then
  echo "Installing Rosetta..."
  sudo softwareupdate --install-rosetta --agree-to-license
fi

# Install Xcode Command Line Tools
if ! xcode-select -p &>/dev/null; then
  echo "Installing Xcode Command Line Tools..."
  sudo xcode-select --install
  until xcode-select -p &>/dev/null; do
    sleep 5
  done
else
  echo "Xcode Command Line Tools already installed."
fi

# Install Homebrew
if ! command -v brew &>/dev/null; then
  echo "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL $HOMEBREW_INSTALL_URL)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
else
  echo "Homebrew already installed."
fi

# Configure Homebrew
brew analytics off
brew update
brew upgrade
brew autoupdate start 43200

# Install essential tools in parallel
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

# Add security configurations
log "Configuring macOS security settings:"
sudo defaults write com.apple.screensaver askForPassword -int 1
sudo defaults write com.apple.screensaver askForPasswordDelay -int 0
sudo defaults write /Library/Preferences/com.apple.alf globalstate -int 1
sudo launchctl load /System/Library/LaunchDaemons/com.apple.alf.agent.plist 2>/dev/null
logk

# Check and enable full-disk encryption
log "Checking FileVault status:"
if fdesetup status | grep -E "FileVault is (On|Off, but will be enabled after the next restart)."; then
  logk
else
  echo "FileVault not enabled. Enabling it now."
  sudo fdesetup enable -user "$USER" | tee "$HOME/Desktop/FileVault_Recovery_Key.txt"
  logk
fi

# Prevent sleep during execution
caffeinate -s -w $$ &

# TouchID setup for sudo
log "Configuring TouchID for sudo authentication:"
if grep -q pam_tid /etc/pam.d/sudo /etc/pam.d/sudo_local 2>/dev/null; then
  logk
else
  PAM_FILE="/etc/pam.d/sudo"
  FIRST_LINE="# sudo: auth account password session"
  TOUCHID_LINE="auth       sufficient     pam_tid.so"
  sudo sed -i.bak -e "s/$FIRST_LINE/$FIRST_LINE\n$TOUCHID_LINE/" "$PAM_FILE"
  sudo rm "$PAM_FILE.bak"
  logk
fi

# Post-Install Verification
if ! command -v brew &>/dev/null; then
  echo "Error: Homebrew installation failed."
  exit 1
fi
if ! command -v fish &>/dev/null; then
  echo "Error: Fish shell installation failed."
  exit 1
fi

# Cleanup Temporary Files
echo "Cleaning up..."
rm -rf "$DOTFILES_DIR/tmp"

echo "Bootstrap and installation complete. Restart your terminal!"

# Cleanup Temporary Files
echo "Cleaning up..."
rm -rf "$DOTFILES_DIR/tmp"

echo "Bootstrap and installation complete. Restart your terminal!"
echo "Bootstrap and installation complete. Restart your terminal!"
