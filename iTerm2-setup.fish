#!/usr/bin/env fish
# iTerm2 and Fish Shell Setup Script

# Install iTerm2 Beta if not already installed
if not test -d /Applications/iTerm.app
    echo "Installing iTerm2 Beta..."
    brew install --cask iterm2-beta
else
    echo "iTerm2 Beta is already installed. Skipping installation."
end

# Install Fisher Package Manager for Fish Shell
if not type -q fisher
    echo "Installing Fisher..."
    curl -sL https://git.io/fisher | source
    fisher install jorgebucaran/fisher
else
    echo "Fisher is already installed."
end

# Install Tide Prompt Theme for Fish
if not fish -c "fisher list | grep -q ilancosman/tide"
    echo "Installing Tide..."
    fish -c "fisher install ilancosman/tide"
else
    echo "Tide is already installed."
end

# Configure iTerm2 settings
if not test -f ~/iTerm2Beta.json
    echo "Creating iTerm2 configuration file..."
    set iterm_config ~/iTerm2Beta.json
    echo "{
        \"Working Directory\": \"~/\",
        \"Color Scheme\": \"Riptide\",
        \"Font\": \"HackNFP-Regular 13\",
        \"Non-ASCII Font\": \"MesloLGS-NF-Regular 13\",
        \"Cursor\": {
            \"Color\": \"#FFFFFF\",
            \"TextColor\": \"#000000\"
        },
        \"Powerline\": true,
        \"Mouse Reporting\": true,
        \"Ligatures\": true
    }" > $iterm_config
    echo "Importing iTerm2 configuration..."
    defaults import com.googlecode.iterm2 $iterm_config
else
    echo "iTerm2 configuration already exists."
end

# Cleanup
if test -f ~/iTerm2Beta.json
    echo "Cleaning up temporary files..."
    rm ~/iTerm2Beta.json
end

echo "iTerm2 and Fish Shell setup completed!"