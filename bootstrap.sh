#!/usr/bin/env bash
# Author  : Chad Mayfield (chad@chadmayfield.com)
# License : GPLv3

# setup macOS using Homebrew

# install rosetta on apple silicon
if [[ "$(sysctl -n machdep.cpu.brand_string)" == *'Apple'* ]]; then
  if [ ! -d "/usr/libexec/rosetta" ]; then
    echo "Installing Rosetta..."
    sudo softwareupdate --install-rosetta --agree-to-license
  fi
  # show our install history, we should have rosetta
  sudo softwareupdate --history
fi

# install xcode cli tools
command -v "xcode-select -p" >/dev/null 2>&1
has_xcode=1 || { has_xcode=0; }
if [ "$has_xcode" -eq 0 ]; then
  echo "Installing XCode CLI Tools..."
  sudo xcode-select --install
else
  # show path
  xcode-select -p
  # show version
  xcode-select --version
  # show compiler version
  #gcc -v
  #llvm-gcc -v
  #clang -v
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
curl -L https://get.oh-my.fish | fish
fish -c "omf install bobthefish"

# Install VS Code
brew install --cask visual-studio-code

# Clone your dotfiles and set them up
git clone https://github.com/BGoodatit/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh

echo "Bootstrap complete!"
