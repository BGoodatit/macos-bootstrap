# macOS Bootstrap

This repository contains a script to bootstrap a macOS Apple Silicon system.

## How to Use

1. Clone this repository:
    ```bash
    git clone https://github.com/BGoodatit/macos-bootstrap.git
    cd macos-bootstrap
    ```

2. Make the script executable:
    ```bash
    chmod +x bootstrap.sh
    ```

3. Run the script:
    ```bash
    ./bootstrap.sh
    ```
## What the Script Does

The `bootstrap.sh` script automates the following tasks:

1. **Rosetta Installation (Apple Silicon Only):** Ensures compatibility with Intel-based applications by installing Rosetta.
2. **Xcode Command Line Tools:** Installs necessary tools required by Homebrew and development environments.
3. **Homebrew Setup:** Installs Homebrew and configures it for your shell environment.
4. **Language Environments:**
    - Sets up `rbenv` and installs the latest version of Ruby.
    - Sets up `pyenv` and installs the latest version of Python.
    - Installs `n` and the latest stable version of Node.js.
5. **Essential Tools:** Installs Git, wget, zsh, fish, and other frequently used tools.
6. **Shell Customization:**
    - Installs `Oh My Zsh` for zsh customization.
    - Configures the Fish shell with plugins.
7. **Editor Setup:** Installs Visual Studio Code using Homebrew.
8. **Dotfiles:** Clones your dotfiles repository and runs its setup script to apply your custom configurations.
9. **Terminal Profiles:** Configures terminal profiles for iTerm2 or Terminal with custom themes.
10. **Validation:** Verifies the successful installation of critical tools.

## Advanced Options

The script is designed to be modular. If you want to skip certain steps (e.g., skipping Fish shell setup or VS Code installation), you can edit the script to comment out the relevant sections.

## Notes

- Ensure your macOS system is updated before running the script.
- The script assumes a clean macOS installation but can be used on existing setups. Duplicate configurations (e.g., multiple shell settings) are automatically ignored.

## Contributing

If you encounter issues or have suggestions for improvements, feel free to open a pull request or issue on GitHub.

This will install essential packages and set up your development environment.
