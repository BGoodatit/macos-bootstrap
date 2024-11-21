#!/usr/bin/env bash
# Author  : Combined by Brice Goodwin
# License : GPLv3

set -ueo pipefail

# Configurable Parameters
STRAP_GIT_EMAIL='BriceGoodwin0313@icloud.com'
STRAP_GITHUB_USER='BGoodatit'
STRAP_GITHUB_TOKEN='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'
HOMEBREW_BREWFILE_URL="https://github.com/$STRAP_GITHUB_USER/homebrew-brewfile"
HOMEBREW_INSTALL_URL="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"
DOTFILES_REPO="https://github.com/$STRAP_GITHUB_USER/dotfiles.git"
DOTFILES_DIR="$HOME/.files"
LOG_FILE="bootstrap.log"

trap 'echo "Error occurred on line $LINENO. Exiting."; exit 1' ERR

# Check Internet Connectivity
ping -c 1 google.com &>/dev/null || {
  echo "Error: No internet connection. Continuing with offline tasks..." >> "$LOG_FILE"
}

# Confirm Script Execution
read -p "This script will configure your macOS setup. Proceed? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "Aborted."
  exit 0
fi

# Install Rosetta (Apple Silicon only)
if [[ "$(uname -m)" == "arm64" ]] && ! /usr/libexec/rosetta --help &>/dev/null; then
  sudo softwareupdate --install-rosetta --agree-to-license || true
fi

# Install Xcode Command Line Tools
if ! xcode-select -p &>/dev/null; then
  sudo xcode-select --install || true
  until xcode-select -p &>/dev/null; do
    sleep 5
  done
fi

# Install Homebrew
if ! command -v brew &>/dev/null; then
  /bin/bash -c "$(curl -fsSL $HOMEBREW_INSTALL_URL)" || true
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Configure Homebrew
brew analytics off || true
brew update || true
brew upgrade || true
brew autoupdate start 43200 || true

# Install essential tools in parallel
{
  brew install rbenv pyenv n node yarn git wget python zsh bash fish || true
  brew install --cask visual-studio-code || true
} &

# Set up Oh My Zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || true

# Set up Fish shell
fish iTerm2-setup.fish || true

# Git Configuration
{
  git config --global user.name "$STRAP_GITHUB_USER" || true
  git config --global user.email "$STRAP_GIT_EMAIL" || true
  git config --global github.user "$STRAP_GITHUB_USER" || true
  git config --global push.default simple || true
  printf 'protocol=https\nhost=github.com\nusername=%s\npassword=%s\n' \
    "$STRAP_GITHUB_USER" "$STRAP_GITHUB_TOKEN" |
    git credential approve || true
}

# macOS Security Configurations
sudo defaults write com.apple.screensaver askForPassword -int 1 || true
sudo defaults write com.apple.screensaver askForPasswordDelay -int 0 || true
sudo defaults write /Library/Preferences/com.apple.alf globalstate -int 1 || true
sudo launchctl load /System/Library/LaunchDaemons/com.apple.alf.agent.plist 2>/dev/null || true

# Check and enable FileVault
if ! fdesetup status | grep -q "FileVault is On"; then
  sudo fdesetup enable -user "$USER" | tee "$HOME/Desktop/FileVault_Recovery_Key.txt" || true
fi

# Set up rbenv and Ruby
if command -v rbenv &>/dev/null; then
  latest_ruby=$(rbenv install -l | grep -v - | tail -1)
  rbenv install "$latest_ruby" && rbenv global "$latest_ruby" || true
fi

# Set up pyenv and Python
if command -v pyenv &>/dev/null; then
  latest_python=$(pyenv install -l | grep -v - | grep -v b | tail -1)
  pyenv install "$latest_python" && pyenv global "$latest_python" || true
fi

# Set up Node.js
if command -v n &>/dev/null; then
  n stable || true
fi

# Clone dotfiles repository
if [ ! -d "$DOTFILES_DIR" ]; then
  git clone "$DOTFILES_REPO" "$DOTFILES_DIR" || true
fi

# Create symlinks for dotfiles
for item in "$DOTFILES_DIR"/.*; do
  [ "$item" != "$DOTFILES_DIR/." ] && [ "$item" != "$DOTFILES_DIR/.." ] && ln -sf "$item" "$HOME/$(basename "$item")" || true
done

# Install Brewfile
if [ -f "$HOME/.Brewfile" ]; then
  brew bundle check --global &>/dev/null || brew bundle --global || true
fi

# Terminal Profile
if [ ! -f HTB.terminal ]; then
  curl --silent --location "https://raw.githubusercontent.com/BGoodatit/macos-bootstrap/main/Riptide-htb.terminal" -o HTB.terminal || true
fi
open HTB.terminal || true
defaults write com.apple.Terminal "Default Window Settings" "HTB" || true
defaults write com.apple.Terminal "Startup Window Settings" "HTB" || true

wait
echo "Bootstrap and installation complete. Restart your terminal!"
