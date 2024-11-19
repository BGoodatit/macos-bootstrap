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
    echo '{
        "Close Sessions On End": true,
        "Ansi 15 Color (Dark)": {
            "Red Component": 0.99999600648880005,
            "Color Space": "sRGB",
            "Blue Component": 1,
            "Alpha Component": 1,
            "Green Component": 1
        },
        "Non-ASCII Anti Aliased": true,
        "Cursor Text Color": {
            "Red Component": 0.99999600648880005,
            "Color Space": "sRGB",
            "Blue Component": 1,
            "Alpha Component": 1,
            "Green Component": 1
        },
        "Smart Cursor Color": true,
        "Prompt Before Closing 2": false,
        "Ansi 3 Color (Dark)": {
            "Red Component": 1,
            "Color Space": "sRGB",
            "Blue Component": 0,
            "Alpha Component": 1,
            "Green Component": 0.68627452850341797
        },
        "Ansi 12 Color (Dark)": {
            "Red Component": 0.36078432202339172,
            "Color Space": "sRGB",
            "Blue Component": 1,
            "Alpha Component": 1,
            "Green Component": 0.69803923368453979
        },
        "Mouse Reporting": true,
        "Use Underline Color (Light)": false,
        "Disable Window Resizing": true,
        "BM Growl": true,
        "Background Color (Dark)": {
            "Red Component": 0.10196078568696976,
            "Color Space": "sRGB",
            "Blue Component": 0.19607843458652496,
            "Alpha Component": 1,
            "Green Component": 0.13725490868091583
        },
        "Guid": "4363E596-A47F-47BE-A509-4BEE981F7A57",
        "Cursor Color (Dark)": {
            "Red Component": 0.19215686619281769,
            "Color Space": "sRGB",
            "Blue Component": 0.3333333432674408,
            "Alpha Component": 1,
            "Green Component": 0.24705882370471954
        },
        "Initial Text": "",
        "Selection Color (Dark)": {
            "Red Component": 0.19215686619281769,
            "Color Space": "sRGB",
            "Blue Component": 0.3333333432674408,
            "Alpha Component": 1,
            "Green Component": 0.24705882370471954
        },
        "Scrollback Lines": 1000,
        "Badge Color (Dark)": {
            "Red Component": 1,
            "Color Space": "sRGB",
            "Blue Component": 0,
            "Alpha Component": 0.5,
            "Green Component": 0.1491314172744751
        },
        "Open Password Manager Automatically": true,
        "Faint Text Alpha": 0.5,
        "Ansi 0 Color (Dark)": {
            "Red Component": 0,
            "Color Space": "sRGB",
            "Blue Component": 0,
            "Alpha Component": 1,
            "Green Component": 0
        },
        "Transparency": 0,
        "Use Bright Bold": true,
        "Horizontal Spacing": 1,
        "Ansi 13 Color (Light)": {
            "Red Component": 0.75686275959014893,
            "Color Space": "sRGB",
            "Blue Component": 0.98039215803146362,
            "Alpha Component": 1,
            "Green Component": 0.42352941632270813
        },
        "Blur": false,
        "Ansi 13 Color": {
            "Red Component": 0.75686275959014893,
            "Color Space": "sRGB",
            "Blue Component": 0.98039215803146362,
            "Alpha Component": 1,
            "Green Component": 0.42352941632270813
        },
        "Ansi 2 Color (Dark)": {
            "Red Component": 0.62352943420410156,
            "Color Space": "sRGB",
            "Blue Component": 0,
            "Alpha Component": 1,
            "Green Component": 0.93725490570068359
        },
        "Cursor Color": {
            "Red Component": 0.74117647058823533,
            "Color Space": "P3",
            "Blue Component": 0,
            "Alpha Component": 1,
            "Green Component": 1
        },
        "Use Cursor Guide (Light)": false,
        "Option Key Sends": 0,
        "Idle Code": 0,
        "Ansi 13 Color (Dark)": {
            "Red Component": 0.75686275959014893,
            "Color Space": "sRGB",
            "Blue Component": 0.98039215803146362,
            "Alpha Component": 1,
            "Green Component": 0.42352941632270813
        },
        "Send Code When Idle": false,
        "Selection Color": {
            "Red Component": 0.19215686619281769,
            "Color Space": "sRGB",
            "Blue Component": 0.3333333432674408,
            "Alpha Component": 1,
            "Green Component": 0.24705882370471954
        },
        "Non-ASCII Ligatures": true,
        "Terminal Type": "xterm-256color",
        "Cursor Boost (Dark)": 0,
        "Right Option Key Sends": 0,
        "Background Color": {
            "Red Component": 0.10196078568696976,
            "Color Space": "sRGB",
            "Blue Component": 0.19607843458652496,
            "Alpha Component": 1,
            "Green Component": 0.13725490868091583
        },
        "Ansi 10 Color (Dark)": {
            "Red Component": 0.77254903316497803,
            "Color Space": "sRGB",
            "Blue Component": 0.40392157435417175,
            "Alpha Component": 1,
            "Green Component": 0.95686274766921997
        }
    }' > $iterm_config
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
