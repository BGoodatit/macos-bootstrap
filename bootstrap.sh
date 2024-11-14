#!/usr/bin/env bash
# Author  : Chad Mayfield (chad@chadmayfield.com)
# License : GPLv3

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
command -v brew >/dev/null 2>&1
has_brew=1 || { has_brew=0; }
if [ "$has_brew" -eq 0 ]; then
  echo "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # add 'brew --prefix' location to $PATH
  # https://applehelpwriter.com/2018/03/21/how-homebrew-invites-users-to-get-pwned/
  # https://www.n00py.io/2016/10/privilege-escalation-on-os-x-without-exploits/
  if [[ "$(sysctl -n machdep.cpu.brand_string)" == *'Apple'* ]]; then
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >>/Users/${USER}/.zprofile
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >>/Users/${USER}/.bash_profile
    eval "$(/opt/homebrew/bin/brew shellenv)"
  else
    echo 'export PATH="/usr/local/sbin:$PATH"' >>/Users/${USER}/.bash_profile
  fi

  source /Users/${USER}/.bash_profile

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
brew install git
brew install wget
brew install node
brew install python
brew install zsh
brew install fish

# Set up Oh My Zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Set up Fish shell
bash iTerm-fish.sh

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
