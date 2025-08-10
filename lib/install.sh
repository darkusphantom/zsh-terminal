#!/bin/bash
# Installation library functions for ZSH Terminal Setup
# Contains modular functions for installing each component

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./common.sh
source "${SCRIPT_DIR}/common.sh"

# Install package if missing (idempotent)
installPackageIfMissing() {
    local package="$1"
    local command_check="${2:-$package}"
    
    if commandExists "$command_check"; then
        logInfo "$package is already installed"
        return 0
    fi
    
    logInfo "Installing $package..."
    
    # Check if sudo is available
    if [[ "$SUDO_AVAILABLE" == "false" ]]; then
        logWarn "Sudo not available - cannot install $package automatically"
        logInfo "Please install $package manually using your system's package manager"
        return 1
    fi
    
    case "$PACKAGE_MANAGER" in
        apt)
            sudo apt update && sudo apt install -y "$package"
            ;;
        yum)
            sudo yum install -y "$package"
            ;;
        dnf)
            sudo dnf install -y "$package"
            ;;
        brew)
            brew install "$package"
            ;;
        manual)
            logWarn "Manual package manager detected - skipping automatic installation of $package"
            logInfo "Please install $package manually if needed"
            return 0
            ;;
        *)
            logError "Unsupported package manager: $PACKAGE_MANAGER"
            return 1
            ;;
    esac
    
    if commandExists "$command_check"; then
        logSuccess "$package installed successfully"
    else
        logError "Failed to install $package"
        return 1
    fi
}

# Install required packages
installRequiredPackages() {
    logInfo "Installing required packages for $OS..."
    
    for package in "${PACKAGES[@]}"; do
        installPackageIfMissing "$package"
    done
    
    logSuccess "All required packages installed"
}

# Install ZSH shell
installZSH() {
    logInfo "Installing ZSH shell..."
    
    if commandExists zsh; then
        local zsh_version
        zsh_version=$(zsh --version | grep -oE '[0-9]+\.[0-9]+' | head -n1)
        logInfo "ZSH is already installed (version: $zsh_version)"
        
        # Validate minimum version
        if ! awk -v curr="$zsh_version" -v min="$MIN_ZSH_VERSION" 'BEGIN{exit(curr<min)}'; then
            logWarn "ZSH version $zsh_version is below minimum required: $MIN_ZSH_VERSION"
            logInfo "Attempting to upgrade ZSH..."
            installPackageIfMissing "zsh" "zsh"
        fi
    else
        # Special handling for Windows environments
        if [[ "$OS" == "windows" ]]; then
            logWarn "ZSH is not natively available on Windows"
            logInfo "For Windows users, consider these alternatives:"
            logInfo "1. Use Windows Subsystem for Linux (WSL) with Ubuntu/Debian"
            logInfo "2. Install ZSH via MSYS2: pacman -S zsh"
            logInfo "3. Use Git Bash with enhanced configuration"
            logInfo "4. Install Windows Terminal with PowerShell customization"
            logInfo "Continuing with Oh My ZSH configuration for future use..."
            return 0
        else
            installPackageIfMissing "zsh" "zsh"
        fi
    fi
    
    # Verify installation (skip for Windows)
    if [[ "$OS" != "windows" ]] && ! commandExists zsh; then
        logError "ZSH installation failed"
        return 1
    fi
    
    logSuccess "ZSH installation completed"
}

# Change default shell to ZSH
changeDefaultShell() {
    if [[ "$DEFAULT_SHELL_CHANGE" != "true" ]]; then
        logInfo "Skipping default shell change (disabled in configuration)"
        return 0
    fi
    
    # Special handling for Windows environments
    if [[ "$OS" == "windows" ]]; then
        logInfo "Default shell change not applicable on Windows"
        logInfo "Use Windows Terminal or configure your terminal emulator to use ZSH"
        return 0
    fi
    
    local current_shell
    current_shell=$(basename "$SHELL")
    
    if [[ "$current_shell" == "zsh" ]]; then
        logInfo "ZSH is already the default shell"
        return 0
    fi
    
    logInfo "Changing default shell to ZSH..."
    
    local zsh_path
    zsh_path=$(which zsh)
    
    if [[ -z "$zsh_path" ]]; then
        logWarn "ZSH executable not found - skipping shell change"
        logInfo "Install ZSH first, then run: chsh -s $(which zsh)"
        return 0
    fi
    
    # Check if zsh is in /etc/shells
    if ! grep -q "^$zsh_path$" /etc/shells; then
        logInfo "Adding ZSH to /etc/shells..."
        echo "$zsh_path" | sudo tee -a /etc/shells > /dev/null
    fi
    
    # Change shell
    if chsh -s "$zsh_path"; then
        logSuccess "Default shell changed to ZSH"
        logInfo "Please log out and log back in for the change to take effect"
    else
        logError "Failed to change default shell"
        return 1
    fi
}

# Install Oh My ZSH
installOhMyZSH() {
    logInfo "Installing Oh My ZSH..."
    
    # Check if already installed
    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        logInfo "Oh My ZSH is already installed"
        return 0
    fi
    
    # Special handling for Windows environments
    if [[ "$OS" == "windows" ]] && ! commandExists zsh; then
        logWarn "ZSH is not available - downloading Oh My ZSH for future use"
        logInfo "Oh My ZSH will be ready when you install ZSH"
        
        # Create temporary directory
        mkdir -p "$TEMP_DIR"
        local install_script="$TEMP_DIR/install_ohmyzsh.sh"
        
        # Download installation script for future use
        if ! safeDownload "$OH_MY_ZSH_URL" "$install_script" "$OH_MY_ZSH_CHECKSUM"; then
            logError "Failed to download Oh My ZSH installation script"
            return 1
        fi
        
        logInfo "Oh My ZSH installer downloaded to: $install_script"
        logInfo "Run this script after installing ZSH: RUNZSH=no CHSH=no sh $install_script"
        return 0
    fi
    
    # Create backup of existing .zshrc
    createBackup "$HOME/.zshrc" "zshrc"
    
    # Create temporary directory
    mkdir -p "$TEMP_DIR"
    local install_script="$TEMP_DIR/install_ohmyzsh.sh"
    
    # Download installation script
    if ! safeDownload "$OH_MY_ZSH_URL" "$install_script" "$OH_MY_ZSH_CHECKSUM"; then
        logError "Failed to download Oh My ZSH installation script"
        return 1
    fi
    
    # Make script executable
    chmod +x "$install_script"
    
    # Install Oh My ZSH in unattended mode
    if RUNZSH=no CHSH=no sh "$install_script"; then
        logSuccess "Oh My ZSH installed successfully"
    else
        logError "Oh My ZSH installation failed"
        return 1
    fi
    
    # Verify installation (skip for Windows without ZSH)
    if [[ "$OS" != "windows" ]] && [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        logError "Oh My ZSH directory not found after installation"
        return 1
    fi
}

# Install Powerlevel10k theme
installPowerlevel10k() {
    logInfo "Installing Powerlevel10k theme..."
    
    local theme_dir="${ZSH_CUSTOM}/themes/powerlevel10k"
    
    # Check if already installed
    if [[ -d "$theme_dir" ]]; then
        logInfo "Powerlevel10k is already installed"
        return 0
    fi
    
    # Ensure ZSH_CUSTOM directory exists
    mkdir -p "${ZSH_CUSTOM}/themes"
    
    # Clone repository
    if ! safeGitClone "$POWERLEVEL10K_REPO" "$theme_dir" 1; then
        logError "Failed to clone Powerlevel10k repository"
        return 1
    fi
    
    # Update .zshrc to use the theme
    if [[ -f "$HOME/.zshrc" ]]; then
        # Create backup
        createBackup "$HOME/.zshrc" "zshrc_before_p10k"
        
        # Update theme in .zshrc
        if grep -q '^ZSH_THEME=' "$HOME/.zshrc"; then
            sed -i 's/^ZSH_THEME=.*/ZSH_THEME="powerlevel10k\/powerlevel10k"/' "$HOME/.zshrc"
        else
            echo 'ZSH_THEME="powerlevel10k/powerlevel10k"' >> "$HOME/.zshrc"
        fi
        
        logSuccess "Powerlevel10k theme configured in .zshrc"
    else
        logWarn ".zshrc file not found - theme configuration skipped"
    fi
    
    logSuccess "Powerlevel10k theme installed successfully"
}

# Install fonts for Powerlevel10k
installPowerlevel10kFonts() {
    logInfo "Installing Powerlevel10k fonts..."
    
    case "$OS" in
        ubuntu|centos|fedora)
            # Install powerline fonts package
            case "$PACKAGE_MANAGER" in
                apt)
                    installPackageIfMissing "fonts-powerline"
                    ;;
                yum|dnf)
                    installPackageIfMissing "powerline-fonts"
                    ;;
            esac
            
            # Download and install MesloLGS font
            local font_file="$TEMP_DIR/MesloLGS_NF_Regular.ttf"
            
            if safeDownload "$FONT_URL" "$font_file" "$FONT_CHECKSUM"; then
                # Create font directory
                sudo mkdir -p "$FONT_DIR"
                
                # Install font
                if sudo cp "$font_file" "$FONT_DIR/"; then
                    # Update font cache
                    if commandExists fc-cache; then
                        sudo fc-cache -f -v
                    fi
                    logSuccess "MesloLGS font installed successfully"
                else
                    logWarn "Failed to install MesloLGS font"
                fi
            else
                logWarn "Failed to download MesloLGS font"
            fi
            ;;
        macos)
            logInfo "On macOS, please install fonts manually from:"
            logInfo "https://github.com/romkatv/powerlevel10k#meslo-nerd-font-patched-for-powerlevel10k"
            ;;
    esac
}

# Install ZSH plugins
installZSHPlugins() {
    logInfo "Installing ZSH plugins..."
    
    local plugins_dir="${ZSH_CUSTOM}/plugins"
    mkdir -p "$plugins_dir"
    
    # Array of plugins to install
    local -A plugins=(
        ["zsh-syntax-highlighting"]="$ZSH_SYNTAX_HIGHLIGHTING_REPO"
        ["zsh-autosuggestions"]="$ZSH_AUTOSUGGESTIONS_REPO"
        ["alias-tips"]="$ALIAS_TIPS_REPO"
    )
    
    for plugin_name in "${!plugins[@]}"; do
        local plugin_dir="${plugins_dir}/${plugin_name}"
        local repo_url="${plugins[$plugin_name]}"
        
        if [[ -d "$plugin_dir" ]]; then
            logInfo "Plugin $plugin_name is already installed"
            continue
        fi
        
        logInfo "Installing plugin: $plugin_name"
        
        if safeGitClone "$repo_url" "$plugin_dir" 1; then
            logSuccess "Plugin $plugin_name installed successfully"
        else
            logWarn "Failed to install plugin: $plugin_name"
        fi
    done
    
    # Update .zshrc to enable plugins
    if [[ -f "$HOME/.zshrc" ]]; then
        updateZSHPluginsConfig
    fi
    
    logSuccess "ZSH plugins installation completed"
}

# Update .zshrc to enable installed plugins
updateZSHPluginsConfig() {
    local zshrc="$HOME/.zshrc"
    
    # Create backup
    createBackup "$zshrc" "zshrc_before_plugins"
    
    # Define plugins to enable
    local plugins_to_enable="git zsh-syntax-highlighting zsh-autosuggestions alias-tips"
    
    # Update plugins line in .zshrc
    if grep -q '^plugins=' "$zshrc"; then
        sed -i "s/^plugins=.*/plugins=($plugins_to_enable)/" "$zshrc"
    else
        echo "plugins=($plugins_to_enable)" >> "$zshrc"
    fi
    
    logSuccess "ZSH plugins configuration updated"
}

# Install custom terminal configuration
installCustomTerminal() {
    logInfo "Installing custom terminal configuration..."
    
    # Check if already installed
    if [[ -d "$CONFIG_ZSH_DIR" ]]; then
        logWarn "Custom terminal configuration already exists at $CONFIG_ZSH_DIR"
        read -p "Do you want to overwrite it? (y/N): " -r
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            logInfo "Skipping custom terminal installation"
            return 0
        fi
        
        # Create backup
        createBackup "$CONFIG_ZSH_DIR" "config_zsh_dir"
        rm -rf "$CONFIG_ZSH_DIR"
    fi
    
    # Clone custom terminal repository
    local temp_repo="$TEMP_DIR/My-Custom-Terminal"
    
    if ! safeGitClone "$CUSTOM_TERMINAL_REPO" "$temp_repo" 1; then
        logError "Failed to clone custom terminal repository"
        return 1
    fi
    
    # Create config directory
    mkdir -p "$(dirname "$CONFIG_ZSH_DIR")"
    
    # Move to final location
    if mv "$temp_repo" "$CONFIG_ZSH_DIR"; then
        logSuccess "Custom terminal configuration installed"
    else
        logError "Failed to move custom terminal configuration"
        return 1
    fi
    
    # Create symlink to .zshrc
    local custom_zshrc="$CONFIG_ZSH_DIR/.zshrc"
    
    if [[ -f "$custom_zshrc" ]]; then
        # Backup existing .zshrc
        createBackup "$HOME/.zshrc" "zshrc_before_custom"
        
        # Create symlink
        if ln -sf "$custom_zshrc" "$HOME/.zshrc"; then
            logSuccess "Symlink created: $HOME/.zshrc -> $custom_zshrc"
        else
            logWarn "Failed to create symlink to custom .zshrc"
        fi
    else
        logWarn "Custom .zshrc not found in repository"
    fi
}

# Verify installation
verifyInstallation() {
    logInfo "Verifying installation..."
    
    local errors=0
    
    # Check ZSH
    if ! commandExists zsh; then
        logError "ZSH is not installed"
        ((errors++))
    else
        logSuccess "ZSH is installed"
    fi
    
    # Check Oh My ZSH
    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        logError "Oh My ZSH is not installed"
        ((errors++))
    else
        logSuccess "Oh My ZSH is installed"
    fi
    
    # Check Powerlevel10k
    if [[ ! -d "${ZSH_CUSTOM}/themes/powerlevel10k" ]]; then
        logWarn "Powerlevel10k theme is not installed"
    else
        logSuccess "Powerlevel10k theme is installed"
    fi
    
    # Check plugins
    local plugin_errors=0
    for plugin in "zsh-syntax-highlighting" "zsh-autosuggestions" "alias-tips"; do
        if [[ ! -d "${ZSH_CUSTOM}/plugins/$plugin" ]]; then
            logWarn "Plugin $plugin is not installed"
            ((plugin_errors++))
        fi
    done
    
    if [[ $plugin_errors -eq 0 ]]; then
        logSuccess "All plugins are installed"
    fi
    
    # Check .zshrc
    if [[ ! -f "$HOME/.zshrc" ]]; then
        logError ".zshrc file is missing"
        ((errors++))
    else
        logSuccess ".zshrc file exists"
    fi
    
    if [[ $errors -eq 0 ]]; then
        logSuccess "Installation verification completed successfully"
        return 0
    else
        logError "Installation verification found $errors critical errors"
        return 1
    fi
}