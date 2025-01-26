#!/usr/bin/env bash

# Adapted from https://mths.be/macos
set -euo pipefail  # Enable strict error handling
IFS=$'\n\t'

LOG_FILE="${HOME}/macos_setup.log"
exec > >(tee -a "$LOG_FILE") 2>&1  # Log stdout and stderr to file

error_handler() {
    echo "[ERROR] Command failed: $BASH_COMMAND"
    echo "How would you like to proceed? (r: retry, s: skip, a: abort)"
    while true; do
        read -rp "Your choice: " choice
        case "$choice" in
            r|R)
                echo "[INFO] Retrying the command..."
                return 1  # Retry the command
                ;;
            s|S)
                echo "[INFO] Skipping the command..."
                return 0  # Skip the command
                ;;
            a|A)
                echo "[INFO] Aborting the script."
                exit 1  # Abort the script
                ;;
            *)
                echo "Invalid choice. Please enter r, s, or a."
                ;;
        esac
    done
}

log_info() {
    echo "[INFO] $1"
}

trap 'error_handler' ERR

log_info "Starting macOS customization script"

# Configuration settings
COMPUTER_NAME="it"
LANGUAGES=(en nl)
LOCALE="en_US@currency=USD"
MEASUREMENT_UNITS="Inches"

# Close any open System Preferences panes
log_info "Closing System Preferences panes"
osascript -e 'tell application "System Preferences" to quit'

# Ask for the administrator password upfront
log_info "Requesting administrator privileges"
sudo -v

# Keep-alive: update `sudo` timestamp until `.macos` has finished
log_info "Ensuring sudo stays active"
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# Set computer and host names
log_info "Setting computer and host names"
sudo scutil --set ComputerName "$COMPUTER_NAME"
sudo scutil --set HostName "$COMPUTER_NAME"
sudo scutil --set LocalHostName "$COMPUTER_NAME"
sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName -string "$COMPUTER_NAME"

# Localization settings
log_info "Configuring localization settings"
defaults write NSGlobalDomain AppleLanguages -array "${LANGUAGES[@]}"
defaults write NSGlobalDomain AppleLocale -string "$LOCALE"
defaults write NSGlobalDomain AppleMeasurementUnits -string "$MEASUREMENT_UNITS"
defaults write NSGlobalDomain AppleMetricUnits -bool true

sudo defaults write /Library/Preferences/com.apple.timezone.auto Active -bool YES
sudo systemsetup -setusingnetworktime on

# System settings
log_info "Applying system settings"
sudo systemsetup -setrestartfreeze on 2>/dev/null || log_info "Restart freeze not supported (non-critical)"
# sudo pmset -a sleep 15
# sudo pmset -a displaysleep 10
# sudo pmset -a hibernatemode 3
# sudo pmset -a standby 1
# sudo pmset -a standbydelayhigh 1800
sudo pmset repeat restart MTWRFSU 00:00:00
sudo nvram SystemAudioVolume=" "

defaults write NSGlobalDomain NSTableViewDefaultSizeMode -int 2
defaults write NSGlobalDomain AppleShowScrollBars -string "WhenScrolling"
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true

# Screen settings
log_info "Configuring screen settings"
defaults write com.apple.screensaver askForPassword -int 1
defaults write com.apple.screensaver askForPasswordDelay -int 0
defaults write com.apple.screencapture location -string "${HOME}/Pictures"
defaults write com.apple.screencapture type -string "JPG"
defaults write com.apple.screencapture disable-shadow -bool true
defaults write NSGlobalDomain AppleFontSmoothing -int 2
sudo defaults write /Library/Preferences/com.apple.windowserver DisplayResolutionEnabled -bool true

# Dock, Dashboard, and Hot Corners
log_info "Configuring Dock and Hot Corners"
defaults write com.apple.dock enable-spring-load-actions-on-all-items -bool true
defaults write com.apple.dock show-process-indicators -bool true
defaults write com.apple.dock expose-animation-duration -float 0.1
defaults write com.apple.dock showhidden -bool true
defaults write com.apple.dock wvous-bl-corner -int 11
defaults write com.apple.dock wvous-bl-modifier -int 0

# Finder settings
log_info "Configuring Finder settings"
defaults write com.apple.finder QuitMenuItem -bool true
defaults write com.apple.finder NewWindowTarget -string "PfLo"
defaults write com.apple.finder NewWindowTargetPath -string "file://${HOME}/"
defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool false
defaults write com.apple.finder ShowHardDrivesOnDesktop -bool false
defaults write com.apple.finder ShowMountedServersOnDesktop -bool false
defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool false
defaults write com.apple.finder AppleShowAllFiles -bool true
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
defaults write com.apple.finder ShowStatusBar -bool true
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder _FXShowPosixPathInTitle -bool false
defaults write com.apple.finder _FXSortFoldersFirst -bool true
defaults write com.apple.finder FXDefaultSearchScope -string "SCev"
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
defaults write NSGlobalDomain com.apple.springing.enabled -bool true
defaults write NSGlobalDomain com.apple.springing.delay -float 0
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true
sudo defaults write /Library/Preferences/com.apple.SpotlightServer.plist ExternalVolumesIgnore -bool false
defaults write com.apple.frameworks.diskimages skip-verify -bool true
defaults write com.apple.frameworks.diskimages skip-verify-locked -bool true
defaults write com.apple.frameworks.diskimages skip-verify-remote -bool true
defaults write com.apple.frameworks.diskimages auto-open-ro-root -bool true
defaults write com.apple.frameworks.diskimages auto-open-rw-root -bool true
defaults write com.apple.finder OpenWindowForNewRemovableDisk -bool true
defaults write com.apple.finder FXPreferredViewStyle -string "clmv"
defaults write com.apple.finder WarnOnEmptyTrash -bool false
defaults write com.apple.NetworkBrowser BrowseAllInterfaces -bool true
defaults write com.apple.finder FXInfoPanesExpanded -dict \
  General -bool true \
  OpenWith -bool true \
  Privileges -bool true

# Additional settings
log_info "Configuring additional settings"
defaults write NSGlobalDomain com.apple.swipescrolldirection -bool true
defaults write com.apple.BluetoothAudioAgent "Apple Bitpool Min (editable)" -int 40
defaults write com.apple.print.PrintingPrefs "Quit When Finished" -bool true
defaults write com.apple.LaunchServices LSQuarantine -bool false
defaults write com.apple.CrashReporter DialogType -string "none"
defaults write com.apple.BezelServices kDim -bool true
defaults write com.apple.BezelServices kDimTime -int 300
defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadCornerSecondaryClick -int 2
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadRightClick -bool true
defaults -currentHost write NSGlobalDomain com.apple.trackpad.trackpadCornerClickBehavior -int 1
defaults -currentHost write NSGlobalDomain com.apple.trackpad.enableSecondaryClick -bool true
defaults write NSGlobalDomain AppleEnableSwipeNavigateWithScrolls -bool true
defaults -currentHost write NSGlobalDomain com.apple.trackpad.threeFingerHorizSwipeGesture -int 1
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerHorizSwipeGesture -int 1

# Software Updates
log_info "Configuring software updates"
defaults write com.apple.SoftwareUpdate AutomaticCheckEnabled -bool true
defaults write com.apple.SoftwareUpdate ScheduleFrequency -string 7
defaults write com.apple.SoftwareUpdate AutomaticDownload -bool true
defaults write com.apple.SoftwareUpdate CriticalUpdateInstall -bool true
defaults write com.apple.commerce AutoUpdate -bool true
defaults write com.apple.commerce AutoUpdateRestartRequired -bool true

# Kill affected applications
log_info "Restarting affected applications"
for app in "Address Book" "Calendar" "Contacts" "Dock" "Finder" "Mail" "Safari" "SystemUIServer" "iCal"; do
    if killall "${app}" &> /dev/null; then
        log_info "Restarted ${app}"
    else
        log_info "${app} was not running"
    fi
done

log_info "macOS customization script completed successfully"
