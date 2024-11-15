#!/usr/bin/env bash
# Author  : Combined by [Your Name]
# License : GPLv3

set -ueo pipefail

# Configurable Parameters
HOMEBREW_INSTALL_URL="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"
DOTFILES_REPO="https://github.com/BGoodatit/dotfiles.git"
DOTFILES_DIR="$HOME/.files"

# Function for installing packages with error handling
install_package() {
  local package_name="$1"
  if ! brew install "$package_name"; then
    echo "Error installing $package_name. Please check your Homebrew setup." >&2
    exit 1
  fi
}

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

# Set up rbenv and Ruby
if command -v rbenv &>/dev/null; then
  latest_ruby=$(rbenv install -l | grep -v - | tail -1)
  rbenv install $latest_ruby && rbenv global $latest_ruby
  echo "Ruby $latest_ruby installed."
fi

# Set up pyenv and Python
if command -v pyenv &>/dev/null; then
  latest_python=$(pyenv install -l | grep -v - | grep -v b | tail -1)
  pyenv install $latest_python && pyenv global $latest_python
  echo "Python $latest_python installed."
fi

# Set up Node.js and npm
if command -v n &>/dev/null; then
  n stable
  echo "Node.js and npm installed."
fi

# Clone dotfiles repository
if [ ! -d "$DOTFILES_DIR" ]; then
  if ! git clone $DOTFILES_REPO "$DOTFILES_DIR"; then
    echo "Error: Failed to clone dotfiles repository."
    exit 1
  fi
fi

# Create symlinks for dotfiles
for item in "$DOTFILES_DIR"/.*; do
  if [[ "$item" == "$DOTFILES_DIR/." || "$item" == "$DOTFILES_DIR/.." || "$item" == "$DOTFILES_DIR/.git" ]]; then
    continue
  fi
  ln -sf "$item" "$HOME/$(basename "$item")"
  echo "Linked $(basename "$item")"
done

# Install iTerm2 profile
if [ ! -f HTB.terminal ]; then
  curl --silent --location "https://raw.githubusercontent.com/BGoodatit/dotfiles/main/Riptide-htb.terminal" -o HTB.terminal
fi
open HTB.terminal
defaults write com.apple.Terminal "Default Window Settings" "HTB"
defaults write com.apple.Terminal "Startup Window Settings" "HTB"

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
