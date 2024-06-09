#!/usr/bin/env bash
#title         :macos-bootstrap-installer.sh
#description   :This script will set up a macOS environment including iTerm2, Fish shell, and other tools.
#author        :BGoodatit
#date          :2024-04-03
#version       :1.0
#usage         :bash <(curl --silent --location "URL_OF_THIS_SCRIPT")
#bash_version  :5.0.17(1)-release
#===================================================================================

set -ueo pipefail

echo "Starting macOS bootstrap installation..."

# Check for Rosetta (Apple Silicon only)
if [[ "$(uname -m)" == "arm64" ]]; then
  /usr/sbin/softwareupdate --install-rosetta --agree-to-license
fi

# Install Xcode Command Line Tools
xcode-select --install 2>/dev/null || echo "Xcode Command Line Tools already installed"

# Check if Homebrew is installed, install if we don't have it
if test ! $(which brew); then
  echo "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
  echo "Homebrew already installed"
fi

echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >>~/.zprofile
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >>~/.bash_profile
echo 'set -gx PATH /opt/homebrew/bin $PATH' >>~/.config/fish/config.fish

brew analytics off
brew update
brew upgrade

# Install and configure rbenv and Ruby
if ! brew list rbenv &>/dev/null; then
  brew install rbenv
  echo 'if command -v rbenv &>/dev/null; then eval "$(rbenv init -)"; fi' >>~/.bash_profile
  echo 'if command -v rbenv &>/dev/null; then eval "$(rbenv init -)"; fi' >>~/.zprofile
  echo 'status is-login; and source (rbenv init -|psub)' >>~/.config/fish/config.fish

  latest_ruby=$(rbenv install -l | grep -v - | tail -1)
  rbenv install $latest_ruby && rbenv global $latest_ruby
  echo "Ruby $latest_ruby installed."
else
  echo "rbenv already installed"
fi

# Install and configure pyenv and Python
if ! brew list pyenv &>/dev/null; then
  brew install pyenv
  echo 'if command -v pyenv &>/dev/null; then eval "$(pyenv init --path)"; fi' >>~/.zprofile
  echo 'if command -v pyenv &>/dev/null; then eval "$(pyenv init -)"; fi' >>~/.bash_profile
  echo 'if command -v pyenv &>/dev/null; then eval "$(pyenv init --path)"; fi' >>~/.bashrc
  echo 'status is-login; and source (pyenv init -|psub)' >>~/.config/fish/config.fish

  latest_python=$(pyenv install -l | grep -v - | grep -v b | tail -1)
  pyenv install $latest_python && pyenv global $latest_python
  echo "Python $latest_python installed."
else
  echo "pyenv already installed"
fi

# Install Node.js and npm using n
if ! brew list n &>/dev/null; then
  brew install n
  n stable
else
  echo "n already installed"
fi

# Install Yarn
if ! brew list yarn &>/dev/null; then
  brew install yarn
else
  echo "Yarn already installed"
fi

# Set Homebrew to update automatically every 12 hours
brew autoupdate start 43200

# Refresh shell environments
source ~/.zshrc || true
source ~/.bashrc || true
source ~/.config/fish/config.fish || true

# Install VS Code
if ! brew list --cask visual-studio-code &>/dev/null; then
  brew install --cask visual-studio-code
else
  echo "VS Code already installed"
fi

# Clone and set up dotfiles
if [ ! -d ~/dotfiles ]; then
  git clone https://github.com/BGoodatit/dotfiles.git ~/dotfiles
  cd ~/dotfiles
  ./install.sh
else
  echo "dotfiles already cloned"
fi

# Set up Fish shell
echo "Setting up Fish shell..."
if [ ! -f iTerm-fish.sh ]; then
  curl --silent --location "https://github.com/BGoodatit/iterm-fish-fisher-osx/blob/master/install.sh?raw=true" -o iTerm-fish.sh
fi
chmod +x iTerm-fish.sh
./iTerm-fish.sh

# Install Riptide-htb.itermcolors profile and set it as default
echo "Installing Riptide-htb.itermcolors profile..."
if [ ! -f Riptide-htb.itermcolors ]; then
  curl --silent --location "https://raw.githubusercontent.com/BGoodatit/dotfiles/main/Riptide-htb.itermcolors" -o Riptide-htb.itermcolors
fi
open Riptide-htb.itermcolors
defaults write com.googlecode.iterm2 "Default Bookmark" "Riptide-htb"
defaults write com.googlecode.iterm2 "New Bookmarks" -array-add "Riptide-htb"

# Import riptide.json configuration
echo "Importing riptide.json configuration..."
if [ ! -f riptide.json ]; then
  curl --silent --location "https://raw.githubusercontent.com/BGoodatit/dotfiles/main/Riptide.json" -o riptide.json
fi
defaults import com.googlecode.iterm2 riptide.json

# Install HTB.terminal profile and set it as default
echo "Installing HTB.terminal profile..."
if [ ! -f HTB.terminal ]; then
  curl --silent --location "https://raw.githubusercontent.com/BGoodatit/dotfiles/main/Riptide-htb.terminal" -o HTB.terminal
fi
open HTB.terminal
defaults write com.apple.Terminal "Default Window Settings" "HTB"
defaults write com.apple.Terminal "Startup Window Settings" "HTB"

echo "Installation complete. Please restart your terminal."
