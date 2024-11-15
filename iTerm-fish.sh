#!/usr/bin/env bash
#title         :iTerm-fish.sh
#description   :This script will install and configure Fish Shell +Fisher
#author        :BGoodatit
#date          :2024-04-03
#version       :1.1
#usage         :bash <(curl --silent --location "https://github.com/BGoodatit/iterm-fish-fisher-osx/blob/master/install.sh?raw=true")
#bash_version  :5.0.17(1)-release
#===================================================================================

set -ueo pipefail

FORCE_INSTALL=${1:-""}
TEMP_DIR=$(mktemp -d)
COLOR_SCHEME_URL="https://raw.githubusercontent.com/BGoodatit/dotfiles/main/Riptide-htb.itermcolors?raw=true"
NERD_FONT_URL="https://github.com/ryanoasis/nerd-fonts/blob/bc4416e176d4ac2092345efd7bcb4abef9d6411e/patched-fonts/Hack/Regular/complete/Hack%20Regular%20Nerd%20Font%20Complete.ttf?raw=true"
PLUGINS_INSTALLER_URL="https://github.com/BGoodatit/iterm-fish-fisher-osx/blob/master/install_plugins.sh?raw=true"

INFO_LEVEL="\033[0;33m"
SUCCESS_LEVEL="\033[0;32m"

function print_info() {
  echo -e "${INFO_LEVEL}$1\033[0m"
}

function print_success() {
  echo -e "${SUCCESS_LEVEL}$1\033[0m"
}

function print_banner() {
  print_info "                                               "
  print_info "   ____ _ ____ _  _ ____ _  _ ____ _    _      "
  print_info "   |___ | [__  |__| [__  |__| |___ |    |      "
  print_info "   |    | ___] |  | ___] |  | |___ |___ |___   "
  print_info "                                               "
  print_info "  iTerm2@beta + Riptide + Fish Shell           "
  print_info " + Fisher Plugins  Optimized for Apple Silicon "
}

function install_iterm() {
  if [[ -d /Applications/iTerm.app ]]; then
    print_success "iTerm 2 already installed, skipping..."
  else
    print_info "Installing iTerm 2 optimized for Apple Silicon MacBooks..."
    brew install --cask iterm2@beta
  fi
}

function install_fish_shell() {
  if command -v fish &>/dev/null; then
    print_success "Fish Shell already installed, skipping..."
  else
    print_info "Installing Fish Shell..."
    brew install fish
    command -v fish | sudo tee -a /etc/shells
    chsh -s "$(command -v fish)"
  fi
}

function install_fisher_and_plugins() {
  # Check if Oh My Fish is already installed
  if fish -c "omf --version" &>/dev/null; then
    print_success "Oh My Fish already installed, skipping..."
  else
    print_info "Installing Oh My Fish..."
    fish -c "curl --silent --location https://raw.githubusercontent.com/oh-my-fish/oh-my-fish/master/bin/install | source"
    # Install Fisher and other tools within Fish shell
    fish -c "curl --silent --location https://git.io/fisher | source && \
             brew install terminal-notifier grc && \
             fisher install jorgebucaran/fisher \
                           edc/bass \
                           patrickf1/colored_man_pages.fish \
                           franciscolourenco/done \
                           small-tech/gills \
                           jorgebucaran/nvm.fish \
                           nickeb96/puffer-fish \
                           markcial/upto \
                           patrickf1/fzf.fish \
                           jethrokuan/z \
                           jorgebucaran/fnm && \
             omf install bass \
                         fish-spec \
                         foreign-env \
                         expand \
                         fish_logo \
                         vcs && \
             set --universal --export theme_nerd_fonts yes; \
             set --universal --export theme_color_scheme zenburn; \
             set --universal --export PROJECT_PATHS ~/Library/Projects && \
             fish_update_completions"
    print_success "Fisher and plugins installed successfully."
  fi
}

function print_post_installation() {
  print_success "                 "
  print_success "!!! IMPORTANT !!!"
  print_success "                 "

  print_success "The script accomplished all the commands it was told to do"
  print_success "Some things can't be automated and you need to do them manually"
  print_success " "
  print_success "1) Open iTerm -> Preferences -> Profiles -> Colors -> Color Presets and apply Riptide-htb.itermcolors preset"
  print_success "2) Open iTerm -> Preferences -> Profiles -> Text -> Font and apply Hack Nerd Font with ligatures checkbox ticked"
  print_success "3) Open iTerm -> Preferences -> Profiles -> Text -> Use a different font for non-ASCII text and apply FiraCode Nerd Font with ligatures checkbox ticked"
}

# Check for necessary commands
if ! command -v curl &>/dev/null || ! command -v tar &>/dev/null; then
  echo "This script requires 'curl' and 'tar' to be installed."
  exit 1
fi

# Install Riptide-htb.itermcolors profile and set it as default
echo "Installing Riptide-htb.itermcolors profile..."
if [ ! -f Riptide-htb.itermcolors ]; then
  curl --silent --location "https://raw.githubusercontent.com/BGoodatit/dotfiles/main/Riptide-htb.itermcolors" -o Riptide-htb.itermcolors
fi
open Riptide-htb.itermcolors
defaults write com.googlecode.iterm2 "Default Bookmark" "Riptide-htb"
defaults write com.googlecode.iterm2 "New Bookmarks" -array-add "Riptide-htb"

# Import riptide.json configuration
# Import iTerm2.json configuration
if [ ! -f iTerm2.json ]; then
  curl --silent --location "https://raw.githubusercontent.com/BGoodatit/dotfiles/main/iTerm2.json" -o iTerm2.json
fi
defaults import com.googlecode.iterm2 iTerm2.json
# Temporary directory for the installation files
tide_tmp_dir=$(mktemp -d)

# Download Tide prompt from the official source
print_info "Downloading Tide from the official repository..."
curl -L https://git.io/tide | fish

# Configure Tide with default options
print_info "Configuring Tide prompt..."
fish -c "tide configure style=lean"
fish -c "tide configure prompt_colors=true_color"
fish -c "tide configure time_format=12_hour"
fish -c "tide configure prompt_height=two_lines"
fish -c "tide configure prompt_connection=disconnected"
fish -c "tide configure prompt_spacing=sparse"
fish -c "tide configure icons=few_icons"
fish -c "source ~/.config/fish/conf.d/_tide_init.fish"
fish -c "exec fish --init-command 'set -g fish_greeting; emit _tide_init_install'"

print_success "Tide installation and configuration complete. Restart your Fish shell to apply changes."
rm -r "$tide_tmp_dir"
fish -c "exec fish --init-command 'set -g fish_greeting; emit _tide_init_install'"

echo "Installation completed. Please restart your Fish shell."
rm -r "$tide_tmp_dir"

install_iterm
install_fish_shell
install_fisher_and_plugins
print_post_installation
