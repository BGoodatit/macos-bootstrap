
#!/usr/bin/env bash
# Author  : Combined by [Your Name]
# License : GPLv3

set -ueo pipefail

# Configurable Parameters
# HOMEBREW_INSTALL_URL="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"
# DOTFILES_REPO="https://github.com/BGoodatit/dotfiles.git"
# DOTFILES_DIR="$HOME/.files"
# Configurable Parameters
STRAP_GIT_EMAIL='BriceGoodwin0313@icloud.com'
STRAP_GITHUB_USER='BGoodatit'
STRAP_GITHUB_TOKEN='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'
HOMEBREW_BREWFILE_URL="https://github.com/$STRAP_GITHUB_USER/homebrew-brewfile"
HOMEBREW_INSTALL_URL="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"
DOTFILES_REPO="https://github.com/$STRAP_GITHUB_USER/dotfiles.git"
DOTFILES_DIR="$HOME/.files"
LOG_FILE="bootstrap.log"

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

# # Install essential tools in parallel
brew install rbenv &
brew install pyenv &
brew install n &
brew install node &
brew install yarn &
brew install git &
brew install wget &
brew install python &
brew install zsh &
brew install bash &
brew install fish &
brew install --cask visual-studio-code &

# Set up Oh My Zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Set up Fish shell
Fish iTerm2-setup.fish

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
DOTFILES_DIR="$HOME/.files"
if [ ! -d "$DOTFILES_DIR" ]; then
  git clone $DOTFILES_REPO "$DOTFILES_DIR"
fi

# Create symlinks for dotfiles
for item in "$DOTFILES_DIR"/.*; do
  if [[ "$item" == "$DOTFILES_DIR/." || "$item" == "$DOTFILES_DIR/.." || "$item" == "$DOTFILES_DIR/.git" ]]; then
    continue
  fi
  ln -sf "$item" "$HOME/$(basename "$item")"
  echo "Linked $(basename "$item")"
done

wait
if [ -n "$STRAP_GITHUB_USER" ] && { [ ! -f "$HOME/.Brewfile" ] || [ "$HOME/.Brewfile" -ef "$HOME/.homebrew-brewfile/Brewfile" ]; }; then
  HOMEBREW_BREWFILE_URL="https://github.com/$STRAP_GITHUB_USER/homebrew-brewfile"

  if git ls-remote "$HOMEBREW_BREWFILE_URL" &>/dev/null; then
    log "Fetching $STRAP_GITHUB_USER/homebrew-brewfile from GitHub:"
    if [ ! -d "$HOME/.homebrew-brewfile" ]; then
      log "Cloning to ~/.homebrew-brewfile:"
      git clone $Q "$HOMEBREW_BREWFILE_URL" ~/.homebrew-brewfile
      logk
    else
      (
        cd ~/.homebrew-brewfile
        git pull $Q
      )
    fi
    ln -sf ~/.homebrew-brewfile/Brewfile ~/.Brewfile
    logk
  fi
fi

# Install from local Brewfile
if [ -f "$HOME/.Brewfile" ]; then
  log "Installing from user Brewfile on GitHub:"
  brew bundle check --global &>/dev/null || brew bundle --global
  logk
fi

# Basic System Info and Homebrew Status
hb = `#{brew_prefix}/bin/brew -v`
bv = `bash -c 'echo $BASH_VERSION'`
sh = `echo $SHELL`
now = DateTime.now.strftime("%B %d %Y")
au = ENV.fetch("HOMEBREW_AUTO_UPDATE_COMMAND", "true")
status = au != "false" ? "True" : "true"
abort("ERROR: Homebrew does not appear to be installed!") unless hb.include? "Homebrew"
puts("--------------------------------")
puts("HOMEBREW_PRODUCT    : " + ENV.fetch("HOMEBREW_PRODUCT", "Unknown"))
puts("HOMEBREW_SYSTEM     : " + ENV.fetch("HOMEBREW_SYSTEM", "Unknown"))
puts("HOMEBREW_OS_VERSION : " + ENV.fetch("HOMEBREW_OS_VERSION", "Unknown"))
puts("HOMEBREW_VERSION    : " + ENV.fetch("HOMEBREW_VERSION", "Unknown"))
puts("HOMEBREW_PROCESSOR  : " + ENV.fetch("HOMEBREW_PROCESSOR", "Unknown"))
puts("AUTO_UPDATE_ENABLED : " + status + " (" + au + ")")
puts("BASH_VERSION        : " + bv)
puts("CURRENT_USER_SHELL  : " + sh)
puts("--------------------------------")
puts("\n")

# Install Terminal profile
if [ ! -f HTB.terminal ]; then
  curl --silent --location "https://raw.githubusercontent.com/BGoodatit/macos-bootstrap/refs/heads/main/Riptide-htb.terminal" -o HTB.terminal
fi
open HTB.terminal
defaults write com.apple.Terminal "Default Window Settings" "HTB"
defaults write com.apple.Terminal "Startup Window Settings" "HTB"
and

echo "Bootstrap and installation complete. Restart your terminal!"
