#!/usr/bin/env bash
# Author  : Combined by Brice Goodwin
# License : GPLv3

set -ueo pipefail

# Configurable Parameters
STRAP_GIT_EMAIL="BriceGoodwin0313@icloud.com"
STRAP_GITHUB_USER="BGoodatit"
STRAP_GITHUB_TOKEN="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"
HOMEBREW_BREWFILE_URL="https://raw.githubusercontent.com/$STRAP_GITHUB_USER/homebrew-brewfile/refs/heads/main/Brewfile"
HOMEBREW_BREWFILE_REPO="https://github.com/$STRAP_GITHUB_USER/homebrew-brewfile.git"
HOMEBREW_BREWFILE_DIR="$HOME/.brewfile"
DOTFILES_REPO="https://github.com/$STRAP_GITHUB_USER/dotfiles.git"
DOTFILES_DIR="$HOME/.files"
LOG_FILE="bootstrap.log"

trap 'echo "Error occurred on line $LINENO. Exiting."; exit 1' ERR

# Logging Helper
log() { echo "[LOG] $1" | tee -a "$LOG_FILE"; }

# Confirm Script Execution
read -p "This script will configure your macOS setup. Proceed? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  log "Aborted by user."
  exit 0
fi

# Run defaults.sh for initial setup (Add this section)
if [ -f "$(dirname "$0")/defaults.sh" ]; then
  log "Running defaults.sh for initial configuration..."
  source "$(dirname "$0")/defaults.sh" || log "Failed to source defaults.sh"
else
  log "defaults.sh not found!"
fi

# Check Internet Connectivity
ping -c 1 google.com &>/dev/null || log "No internet connection. Continuing with offline tasks..."

# Install Rosetta (Apple Silicon only)
if [[ "$(uname -m)" == "arm64" ]] && ! /usr/libexec/rosetta --help &>/dev/null; then
  log "Installing Rosetta..."
  sudo softwareupdate --install-rosetta --agree-to-license || log "Rosetta installation skipped."
else
  log "Rosetta already installed or not required."
fi

# Install Xcode Command Line Tools
if ! xcode-select -p &>/dev/null; then
  log "Installing Xcode Command Line Tools..."
  sudo xcode-select --install || true
  until xcode-select -p &>/dev/null; do
    sleep 5
  done
else
  log "Xcode Command Line Tools already installed."
fi

# ──────────────────────────────────────────────────────────────────────────────
# Ensure Homebrew is on PATH for both Intel and Apple Silicon
if [ -d "/opt/homebrew/bin" ]; then
  export PATH="/opt/homebrew/bin:$PATH"
elif [ -d "/usr/local/bin" ]; then
  export PATH="/usr/local/bin:$PATH"
fi

# Install Homebrew (if missing) and load it into the session
if ! command -v brew &>/dev/null; then
  log "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || log "Homebrew installation skipped."
  eval "$(brew shellenv)"
else
  log "Homebrew already installed."
  eval "$(brew shellenv)"
fi

# Configure Homebrew
log "Configuring Homebrew..."
brew analytics off || true
brew update || log "Homebrew update skipped."
brew upgrade || log "Homebrew upgrade skipped."
brew autoupdate start 43200 || log "Homebrew auto-update configuration skipped."

# Install Essential Tools
log "Installing essential tools..."
essential_tools=("rbenv" "pyenv" "n" "node" "yarn" "git" "wget" "python" "zsh" "bash" "fish")
for tool in "${essential_tools[@]}"; do
  if brew list "$tool" &>/dev/null || brew list --cask "$tool" &>/dev/null; then
    log "$tool is already installed."
  else
    brew install "$tool" || log "Failed to install $tool."
  fi
done

# Install Visual Studio Code
if ! brew list --cask visual-studio-code &>/dev/null; then
  log "Installing Visual Studio Code..."
  brew install --cask visual-studio-code || log "Failed to install Visual Studio Code."
else
  log "Visual Studio Code already installed."
fi

# Set up Oh My Zsh
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  log "Setting up Oh My Zsh..."
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || log "Oh My Zsh setup skipped."
else
  log "Oh My Zsh already installed."
fi

# Git Configuration
log "Configuring Git..."
{
  git config --global user.name "$STRAP_GITHUB_USER" || true
  git config --global user.email "$STRAP_GIT_EMAIL" || true
  git config --global github.user "$STRAP_GITHUB_USER" || true
  git config --global push.default simple || true
  printf 'protocol=https\nhost=github.com\nusername=%s\npassword=%s\n' \
    "$STRAP_GITHUB_USER" "$STRAP_GITHUB_TOKEN" |
    git credential approve || true
}

# Check and Enable FileVault
log "Checking FileVault status..."
if ! fdesetup status | grep -q "FileVault is On"; then
  log "Enabling FileVault..."
  sudo fdesetup enable -user "$USER" | tee "$HOME/Desktop/FileVault_Recovery_Key.txt" || log "FileVault setup skipped."
else
  log "FileVault is already enabled."
fi

# Set up rbenv and Ruby
log "Setting up Ruby environment..."
if command -v rbenv &>/dev/null; then
  latest_ruby=$(rbenv install -l | grep -v - | tail -1)
  rbenv install "$latest_ruby" && rbenv global "$latest_ruby" || log "Ruby setup skipped."
else
  log "rbenv not installed. Skipping Ruby setup."
fi

# Set up pyenv and Python
log "Setting up Python environment..."
if command -v pyenv &>/dev/null; then
  latest_python=$(pyenv install -l | grep -v - | grep -v b | tail -1)
  pyenv install "$latest_python" && pyenv global "$latest_python" || log "Python setup skipped."
else
  log "pyenv not installed. Skipping Python setup."
fi

# Set up Node.js
log "Setting up Node.js environment..."
if command -v n &>/dev/null; then
  n stable || log "Node.js setup skipped."
else
  log "n not installed. Skipping Node.js setup."
fi

# Set up Dotfiles
if [ ! -d "$DOTFILES_DIR" ]; then
  log "Cloning dotfiles repository..."
  git clone "$DOTFILES_REPO" "$DOTFILES_DIR" || log "Failed to clone dotfiles repository."
else
  log "Dotfiles repository already cloned. Pulling updates..."
  git -C "$DOTFILES_DIR" pull || log "Failed to update dotfiles repository."
fi

# Create Symlinks for Dotfiles
log "Creating symlinks for dotfiles..."
EXCLUDE=("install.sh" ".git" ".gitignore" ".gitattributes")
for file in "$DOTFILES_DIR"/.* "$DOTFILES_DIR"/*; do
  filename=$(basename "$file")

  # Skip excluded files and directories
  if [[ " ${EXCLUDE[*]} " =~ " $filename " || "$filename" == "." || "$filename" == ".." ]]; then
    continue
  fi

  # Special handling for .config directory
  if [ "$filename" == ".config" ]; then
    log "Handling .config directory..."
    mkdir -p "$HOME/.config" # Ensure .config exists
    for config_file in "$file"/*; do
      config_filename=$(basename "$config_file")
      config_target="$HOME/.config/$config_filename"

      # Remove existing files/directories inside .config to replace with symlinks
      if [ -e "$config_target" ] || [ -L "$config_target" ]; then
        log "Removing existing $config_target to replace with symlink..."
        rm -rf "$config_target"
      fi

      ln -sf "$config_file" "$config_target"
      log "Linked $config_filename to $config_target."
    done
    continue
  fi

  # Handle regular files and directories
  target="$HOME/$filename"
  if [ -e "$target" ] || [ -L "$target" ]; then
    log "Removing existing $target to replace with symlink..."
    rm -rf "$target"
  fi

  ln -sf "$file" "$target"
  log "Linked $filename to $target."
done

# Set up Brewfile
log "Setting up Homebrew Brewfile..."
if curl --head --silent --fail "$HOMEBREW_BREWFILE_URL" > /dev/null; then
  log "Downloading Brewfile from raw URL..."
  curl -fsSL "$HOMEBREW_BREWFILE_URL" -o "$HOME/.Brewfile" || log "Failed to download Brewfile."
elif [ ! -d "$HOMEBREW_BREWFILE_DIR" ]; then
  log "Cloning Brewfile repository..."
  git clone "$HOMEBREW_BREWFILE_REPO" "$HOMEBREW_BREWFILE_DIR" || log "Failed to clone Brewfile repository."
else
  log "Brewfile repository already cloned. Pulling updates..."
  git -C "$HOMEBREW_BREWFILE_DIR" pull || log "Failed to update Brewfile repository."
fi

# Symlink and Install Brewfile
if [ -f "$HOME/.Brewfile" ]; then
  log "Installing dependencies from Brewfile..."
  brew bundle --global || log "Brewfile installation skipped or failed."
else
  log "No Brewfile found. Skipping dependency installation."
fi

# Terminal Profile
log "Configuring Terminal Profile..."
if [ ! -f HTB.terminal ]; then
  curl --silent --location "https://raw.githubusercontent.com/BGoodatit/macos-bootstrap/main/Riptide-htb.terminal" \
    -o HTB.terminal || log "Failed to download HTB terminal profile."
fi
open HTB.terminal || log "Failed to open HTB terminal profile."
defaults write com.apple.Terminal "Default Window Settings" "HTB" || log "Failed to set default terminal profile."
defaults write com.apple.Terminal "Startup Window Settings" "HTB" || log "Failed to set startup terminal profile."

# Run Fish iTerm2 Setup Script
if [ -f "$HOME/macos-bootstrap/iTerm2-setup.fish" ]; then
  log "Running Fish iTerm2 setup script from macos-bootstrap..."
  fish "$HOME/macos-bootstrap/iTerm2-setup.fish" || log "Failed to run Fish iTerm2 setup script."
else
  log "Fish iTerm2 setup script not found in macos-bootstrap. Skipping."
fi

# Finish Setup
log "Bootstrap and installation complete. Restart your terminal!"
