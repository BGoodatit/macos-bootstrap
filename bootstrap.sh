#!/usr/bin/env bash
# Author  : Chad Mayfield (chad@chadmayfield.com)
# License : GPLv3

# Common URLs
HOMEBREW_INSTALL_URL="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"
DOTFILES_REPO="https://github.com/BGoodatit/dotfiles.git"

# setup macOS using Homebrew

# install rosetta on apple silicon
if [[ "$(uname -m)" == "arm64" ]] && ! /usr/libexec/rosetta --help &>/dev/null; then
  echo "Installing Rosetta..."
  sudo softwareupdate --install-rosetta --agree-to-license
fi

# install xcode cli tools
if ! xcode-select -p &>/dev/null; then
  echo "Installing Xcode Command Line Tools..."
  sudo xcode-select --install
  until xcode-select -p &>/dev/null; do
    sleep 5
  done
else
  # show path
  xcode-select -p
  # show version
  xcode-select --version
fi

# install homebrew
if command -v brew &>/dev/null; then
  echo "Homebrew is already installed."
else
  echo "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
  echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
  echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.bash_profile
fi

brew analytics off
brew update
brew upgrade
brew analytics off
brew update
brew upgrade

# Install and configure rbenv and Ruby
brew install rbenv
echo 'if command -v rbenv &>/dev/null; then eval "$(rbenv init -)"; fi' >>~/.bash_profile
echo 'if command -v rbenv &>/dev/null; then eval "$(rbenv init -)"; fi' >>~/.zprofile
echo 'status is-login; and source (rbenv init -|psub)' >>~/.config/fish/config.fish

latest_ruby=$(rbenv install -l | grep -v - | tail -1)
rbenv install $latest_ruby && rbenv global $latest_ruby
echo "Ruby $latest_ruby installed."

# Install and configure pyenv and Python
brew install pyenv
echo 'if command -v pyenv &>/dev/null; then eval "$(pyenv init --path)"; fi' >>~/.zprofile
echo 'if command -v pyenv &>/dev/null; then eval "$(pyenv init -)"; fi' >>~/.bash_profile
echo 'if command -v pyenv &>/dev/null; then eval "$(pyenv init --path)"; fi' >>~/.bashrc
echo 'status is-login; and source (pyenv init -|psub)' >>~/.config/fish/config.fish

latest_python=$(pyenv install -l | grep -v - | grep -v b | tail -1)
pyenv install $latest_python && pyenv global $latest_python
echo "Python $latest_python installed."

# Install Node.js and npm using n
brew install n
n stable

# Install Yarn
brew install yarn

# Set Homebrew to update automatically every 12 hours
brew autoupdate start 43200

# Refresh shell environments
source ~/.zshrc
source ~/.bashrc
source ~/.config/fish/config.fish

echo "Installation complete. Please restart your terminal."


#EOF

# Install essential packages
# Install essential packages with error handling
install_package() {
  local package_name="$1"
  if ! brew install "$package_name"; then
    echo "Error installing $package_name. Please check your Homebrew setup." >&2
    exit 1
  fi
}

install_package git
install_package wget
install_package node
install_package python
install_package zsh
install_package fish

# Install VS Code
# Install HTB.terminal profile and set it as default
echo "Installing HTB.terminal profile..."
if [ ! -f HTB.terminal ]; then
  curl --silent --location "https://raw.githubusercontent.com/BGoodatit/dotfiles/main/Riptide-htb.terminal" -o HTB.terminal
fi
open HTB.terminal
defaults write com.apple.Terminal "Default Window Settings" "HTB"
defaults write com.apple.Terminal "Startup Window Settings" "HTB"

brew install --cask visual-studio-code

# Clone your dotfiles and set them up
git clone https://github.com/BGoodatit/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh

echo "Bootstrap complete!"
