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

  # turn off brew analytics
  brew analytics off
fi

# update brew
brew update

# run brewfile to install packages
#brew bundle install

# check for issues
brew doctor

# set brew to update every 12 hours (in seconds)
brew autoupdate start 43200

# show brew auto update status for feedback
brew autoupdate status

# display outdated apps and auto-update status
brew cu --include-mas

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
