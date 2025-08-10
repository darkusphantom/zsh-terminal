#!/bin/bash
# Script para generar el instalador standalone desde el proyecto original
# Autor: Sistema automatizado
# Versión: 1.0.0
# Descripción: Genera un script autocontenido que incluye todos los archivos necesarios

set -euo pipefail

# Configuración
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_FILE="${SCRIPT_DIR}/zsh-installer-standalone.sh"
TEMP_DIR="/tmp/zsh-standalone-generator-$$"

# Colores para output
COLOR_RED='\033[0;31m'
COLOR_GREEN='\033[0;32m'
COLOR_YELLOW='\033[1;33m'
COLOR_BLUE='\033[0;34m'
COLOR_NC='\033[0m' # No Color

# Funciones de logging
logInfo() {
    echo -e "${COLOR_BLUE}[INFO]${COLOR_NC} $*"
}

logSuccess() {
    echo -e "${COLOR_GREEN}[SUCCESS]${COLOR_NC} $*"
}

logWarn() {
    echo -e "${COLOR_YELLOW}[WARN]${COLOR_NC} $*"
}

logError() {
    echo -e "${COLOR_RED}[ERROR]${COLOR_NC} $*" >&2
}

# Cleanup function
cleanup() {
    if [[ -d "$TEMP_DIR" ]]; then
        rm -rf "$TEMP_DIR"
    fi
}

# Error handling
trap cleanup EXIT
trap 'logError "Script failed at line $LINENO"' ERR

# Verificar archivos requeridos
verifySourceFiles() {
    logInfo "Verificando archivos fuente..."
    
    local required_files=(
        "install.sh"
        "lib/common.sh"
        "lib/install.sh"
        "config/install.conf"
        "alias/git/alias.zsh"
        "alias/shell/alias.zsh"
        "env/var.zsh"
    )
    
    for file in "${required_files[@]}"; do
        if [[ ! -f "${SCRIPT_DIR}/${file}" ]]; then
            logError "Archivo requerido no encontrado: ${file}"
            return 1
        fi
    done
    
    logSuccess "Todos los archivos fuente verificados"
}

# Leer contenido de archivo y escapar para embedding
readAndEscapeFile() {
    local file_path="$1"
    local var_name="$2"
    
    if [[ ! -f "$file_path" ]]; then
        logError "Archivo no encontrado: $file_path"
        return 1
    fi
    
    # Leer archivo y escapar caracteres especiales para embedding
    local content
    content=$(cat "$file_path" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | sed 's/`/\\`/g' | sed 's/\$/\\$/g')
    
    echo "# Embedded content from: $file_path"
    echo "read -r -d '' $var_name << 'EOF' || true"
    cat "$file_path"
    echo "EOF"
    echo ""
}

# Generar el script standalone
generateStandaloneScript() {
    logInfo "Generando script standalone..."
    
    mkdir -p "$TEMP_DIR"
    local temp_script="${TEMP_DIR}/standalone.sh"
    
    # Crear el header del script
    cat > "$temp_script" << 'HEADER'
#!/bin/bash
# ZSH Terminal Standalone Installer
# Self-contained executable that includes all necessary files
# Version: 2.0.0
# Description: Standalone installer for ZSH with Oh My ZSH, Powerlevel10k theme, and essential plugins
# Generated automatically from the original project

# Exit on any error
set -euo pipefail

# Global variables
SCRIPT_VERSION="2.0.0"
TEMP_INSTALL_DIR="/tmp/zsh-install-$$"
LOG_DIR="${HOME}/.local/log/zsh-install"
BACKUP_DIR="${HOME}/.local/backup/zsh-install"
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
FONT_DIR="/usr/share/fonts/MesloLGS"
CONFIG_ZSH_DIR="${HOME}/.config/zsh"

# Colors for output
COLOR_RED='\033[0;31m'
COLOR_GREEN='\033[0;32m'
COLOR_YELLOW='\033[1;33m'
COLOR_BLUE='\033[0;34m'
COLOR_NC='\033[0m' # No Color

# URLs and repositories
OH_MY_ZSH_URL="https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh"
POWERLEVEL10K_REPO="https://github.com/romkatv/powerlevel10k.git"
FONT_URL="https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf"
ZSH_SYNTAX_HIGHLIGHTING_REPO="https://github.com/zsh-users/zsh-syntax-highlighting.git"
ZSH_AUTOSUGGESTIONS_REPO="https://github.com/zsh-users/zsh-autosuggestions"
ALIAS_TIPS_REPO="https://github.com/djui/alias-tips.git"

# Package names by OS
UBUNTU_PACKAGES=("zsh" "wget" "git" "fonts-powerline")
CENTOS_PACKAGES=("zsh" "wget" "git" "powerline-fonts")
MACOS_PACKAGES=("zsh" "wget" "git")

# Installation options
DEFAULT_SHELL_CHANGE=true
CREATE_BACKUP=true
VERBOSE_LOGGING=true
STRICT_MODE=true

# Timeout settings (in seconds)
DOWNLOAD_TIMEOUT=30
GIT_CLONE_TIMEOUT=60
COMMAND_TIMEOUT=120

# Global variables for OS detection
OS_TYPE=""
PACKAGE_MANAGER=""
SUDO_AVAILABLE="false"

HEADER

    # Embebido de archivos de configuración como variables
    echo "# ============================================" >> "$temp_script"
    echo "# EMBEDDED CONFIGURATION FILES" >> "$temp_script"
    echo "# ============================================" >> "$temp_script"
    echo "" >> "$temp_script"
    
    # Embebido de aliases y configuración
    echo "# Git aliases content" >> "$temp_script"
    echo "GIT_ALIASES_CONTENT='$(cat "${SCRIPT_DIR}/alias/git/alias.zsh")'" >> "$temp_script"
    echo "" >> "$temp_script"
    
    echo "# Shell aliases content" >> "$temp_script"
    echo "SHELL_ALIASES_CONTENT='$(cat "${SCRIPT_DIR}/alias/shell/alias.zsh" | sed "s/'/'\\\''/g")'" >> "$temp_script"
    echo "" >> "$temp_script"
    
    echo "# Environment variables content" >> "$temp_script"
    echo "ENV_VARS_CONTENT='$(cat "${SCRIPT_DIR}/env/var.zsh")'" >> "$temp_script"
    echo "" >> "$temp_script"
    
    # Agregar las funciones principales
    cat >> "$temp_script" << 'FUNCTIONS'
# ============================================
# CORE FUNCTIONS
# ============================================

# Logging functions
logInfo() {
    echo -e "${COLOR_BLUE}[INFO]${COLOR_NC} $(date '+%Y-%m-%d %H:%M:%S') - $*"
}

logSuccess() {
    echo -e "${COLOR_GREEN}[SUCCESS]${COLOR_NC} $(date '+%Y-%m-%d %H:%M:%S') - $*"
}

logWarn() {
    echo -e "${COLOR_YELLOW}[WARN]${COLOR_NC} $(date '+%Y-%m-%d %H:%M:%S') - $*" >&2
}

logError() {
    echo -e "${COLOR_RED}[ERROR]${COLOR_NC} $(date '+%Y-%m-%d %H:%M:%S') - $*" >&2
}

# Error handling
setupErrorHandling() {
    trap 'cleanup; logError "Script failed at line $LINENO"' ERR
    trap 'cleanup; logInfo "Script interrupted by user"' INT TERM
}

# Cleanup function
cleanup() {
    if [[ -d "$TEMP_INSTALL_DIR" ]]; then
        rm -rf "$TEMP_INSTALL_DIR"
        logInfo "Cleaned up temporary directory: $TEMP_INSTALL_DIR"
    fi
}

# Check if command exists
commandExists() {
    command -v "$1" >/dev/null 2>&1
}

# Validate bash version
validateBashVersion() {
    if [[ ${BASH_VERSION%%.*} -lt 4 ]]; then
        logError "This script requires Bash 4.0 or higher. Current version: $BASH_VERSION"
        exit 1
    fi
    logInfo "Bash version validation passed: $BASH_VERSION"
}

# Check if running as root
checkNotRoot() {
    if [[ $EUID -eq 0 ]]; then
        logError "This script should not be run as root for security reasons"
        logInfo "Please run as a regular user with sudo privileges"
        exit 1
    fi
    logInfo "Root check passed - running as regular user"
}

# Check sudo access
checkSudoAccess() {
    if sudo -n true 2>/dev/null; then
        SUDO_AVAILABLE="true"
        logInfo "Sudo access confirmed"
    elif sudo -v 2>/dev/null; then
        SUDO_AVAILABLE="true"
        logInfo "Sudo access granted after password prompt"
    else
        SUDO_AVAILABLE="false"
        logWarn "Sudo access not available - some features may be limited"
    fi
}

# Detect operating system
detectOS() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if commandExists apt; then
            OS_TYPE="ubuntu"
            PACKAGE_MANAGER="apt"
        elif commandExists yum; then
            OS_TYPE="centos"
            PACKAGE_MANAGER="yum"
        elif commandExists dnf; then
            OS_TYPE="fedora"
            PACKAGE_MANAGER="dnf"
        else
            OS_TYPE="linux"
            PACKAGE_MANAGER="manual"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS_TYPE="macos"
        if commandExists brew; then
            PACKAGE_MANAGER="brew"
        else
            PACKAGE_MANAGER="manual"
        fi
    else
        OS_TYPE="unknown"
        PACKAGE_MANAGER="manual"
    fi
    
    logInfo "Detected OS: $OS_TYPE with package manager: $PACKAGE_MANAGER"
}

# Initialize logging
initializeLogging() {
    mkdir -p "$LOG_DIR"
    LOG_FILE="${LOG_DIR}/install_$(date +%Y%m%d_%H%M%S).log"
    
    if [[ "$VERBOSE_LOGGING" == "true" ]]; then
        exec 1> >(tee -a "$LOG_FILE")
        exec 2> >(tee -a "$LOG_FILE" >&2)
    fi
    
    logInfo "Logging initialized: $LOG_FILE"
}

# Display header
displayHeader() {
    echo -e "${COLOR_BLUE}"
    echo "=========================================="
    echo "    ZSH Terminal Standalone Installer"
    echo "    Version: $SCRIPT_VERSION"
    echo "=========================================="
    echo -e "${COLOR_NC}"
}

FUNCTIONS

    # Agregar funciones de instalación desde lib/install.sh (versión simplificada)
    cat >> "$temp_script" << 'INSTALL_FUNCTIONS'
# ============================================
# INSTALLATION FUNCTIONS
# ============================================

# Install package if missing
installPackageIfMissing() {
    local package="$1"
    local command_check="${2:-$package}"
    
    if commandExists "$command_check"; then
        logInfo "$package is already installed"
        return 0
    fi
    
    logInfo "Installing $package..."
    
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
        return 0
    else
        logError "Failed to install $package"
        return 1
    fi
}

# Install required packages
installRequiredPackages() {
    logInfo "Installing required packages for $OS_TYPE..."
    
    local packages
    case "$OS_TYPE" in
        ubuntu)
            packages=("${UBUNTU_PACKAGES[@]}")
            ;;
        centos|fedora)
            packages=("${CENTOS_PACKAGES[@]}")
            ;;
        macos)
            packages=("${MACOS_PACKAGES[@]}")
            ;;
        *)
            logWarn "Unknown OS type: $OS_TYPE - skipping package installation"
            return 0
            ;;
    esac
    
    for package in "${packages[@]}"; do
        installPackageIfMissing "$package" || {
            logWarn "Failed to install $package - continuing anyway"
        }
    done
    
    logSuccess "Required packages installation completed"
}

# Install ZSH
installZSH() {
    if commandExists zsh; then
        logInfo "ZSH is already installed: $(zsh --version)"
        return 0
    fi
    
    logInfo "Installing ZSH..."
    installPackageIfMissing "zsh" "zsh" || {
        logError "Failed to install ZSH"
        return 1
    }
    
    logSuccess "ZSH installed successfully"
}

# Install Oh My ZSH
installOhMyZSH() {
    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        logInfo "Oh My ZSH is already installed"
        return 0
    fi
    
    logInfo "Installing Oh My ZSH..."
    
    # Download and install Oh My ZSH
    if commandExists curl; then
        sh -c "$(curl -fsSL $OH_MY_ZSH_URL)" "" --unattended
    elif commandExists wget; then
        sh -c "$(wget -O- $OH_MY_ZSH_URL)" "" --unattended
    else
        logError "Neither curl nor wget is available"
        return 1
    fi
    
    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        logSuccess "Oh My ZSH installed successfully"
        return 0
    else
        logError "Oh My ZSH installation failed"
        return 1
    fi
}

# Install Powerlevel10k theme
installPowerlevel10k() {
    local theme_dir="${ZSH_CUSTOM}/themes/powerlevel10k"
    
    if [[ -d "$theme_dir" ]]; then
        logInfo "Powerlevel10k theme is already installed"
        return 0
    fi
    
    logInfo "Installing Powerlevel10k theme..."
    
    mkdir -p "${ZSH_CUSTOM}/themes"
    
    if ! git clone --depth=1 "$POWERLEVEL10K_REPO" "$theme_dir"; then
        logError "Failed to clone Powerlevel10k repository"
        return 1
    fi
    
    logSuccess "Powerlevel10k theme installed successfully"
}

# Install Powerlevel10k fonts
installPowerlevel10kFonts() {
    if [[ "$OS_TYPE" == "macos" ]]; then
        logInfo "Font installation on macOS should be done manually"
        logInfo "Please download and install MesloLGS NF fonts from: $FONT_URL"
        return 0
    fi
    
    if [[ "$SUDO_AVAILABLE" == "false" ]]; then
        logWarn "Sudo not available - cannot install fonts automatically"
        return 1
    fi
    
    logInfo "Installing Powerlevel10k fonts..."
    
    sudo mkdir -p "$FONT_DIR"
    
    if commandExists wget; then
        sudo wget -O "${FONT_DIR}/MesloLGS_NF_Regular.ttf" "$FONT_URL"
    elif commandExists curl; then
        sudo curl -L -o "${FONT_DIR}/MesloLGS_NF_Regular.ttf" "$FONT_URL"
    else
        logError "Neither wget nor curl is available for font download"
        return 1
    fi
    
    # Update font cache
    if commandExists fc-cache; then
        sudo fc-cache -fv
        logSuccess "Fonts installed and cache updated"
    else
        logWarn "fc-cache not available - fonts installed but cache not updated"
    fi
}

# Install ZSH plugins
installZSHPlugins() {
    logInfo "Installing ZSH plugins..."
    
    local plugins_dir="${ZSH_CUSTOM}/plugins"
    mkdir -p "$plugins_dir"
    
    # Install zsh-syntax-highlighting
    if [[ ! -d "${plugins_dir}/zsh-syntax-highlighting" ]]; then
        logInfo "Installing zsh-syntax-highlighting..."
        git clone "$ZSH_SYNTAX_HIGHLIGHTING_REPO" "${plugins_dir}/zsh-syntax-highlighting"
    fi
    
    # Install zsh-autosuggestions
    if [[ ! -d "${plugins_dir}/zsh-autosuggestions" ]]; then
        logInfo "Installing zsh-autosuggestions..."
        git clone "$ZSH_AUTOSUGGESTIONS_REPO" "${plugins_dir}/zsh-autosuggestions"
    fi
    
    # Install alias-tips
    if [[ ! -d "${plugins_dir}/alias-tips" ]]; then
        logInfo "Installing alias-tips..."
        git clone "$ALIAS_TIPS_REPO" "${plugins_dir}/alias-tips"
    fi
    
    logSuccess "ZSH plugins installed successfully"
}

# Create custom aliases and environment variables
installCustomConfiguration() {
    logInfo "Installing custom configuration..."
    
    mkdir -p "$CONFIG_ZSH_DIR"
    
    # Create git aliases
    echo "$GIT_ALIASES_CONTENT" > "${CONFIG_ZSH_DIR}/git_aliases.zsh"
    
    # Create shell aliases
    echo "$SHELL_ALIASES_CONTENT" > "${CONFIG_ZSH_DIR}/shell_aliases.zsh"
    
    # Create environment variables
    echo "$ENV_VARS_CONTENT" > "${CONFIG_ZSH_DIR}/environment.zsh"
    
    # Create C++ aliases placeholder
    cat > "${CONFIG_ZSH_DIR}/cpp_aliases.zsh" << 'EOF'
# C++ development aliases (add your C++ specific aliases here)
# Example: alias compile="g++ -std=c++17 -Wall -Wextra"
EOF
    
    logSuccess "Custom configuration files created in $CONFIG_ZSH_DIR"
}

# Update .zshrc with custom configuration
updateZshrc() {
    logInfo "Updating .zshrc configuration..."
    
    local zshrc="$HOME/.zshrc"
    
    # Backup existing .zshrc
    if [[ -f "$zshrc" ]] && [[ "$CREATE_BACKUP" == "true" ]]; then
        mkdir -p "$BACKUP_DIR"
        cp "$zshrc" "${BACKUP_DIR}/.zshrc.backup.$(date +%Y%m%d_%H%M%S)"
        logInfo "Backed up existing .zshrc"
    fi
    
    # Add custom configuration to .zshrc
    cat >> "$zshrc" << EOF

# Custom ZSH Terminal Configuration
# Added by zsh-installer-standalone.sh

# Set Powerlevel10k theme
ZSH_THEME="powerlevel10k/powerlevel10k"

# Enable plugins
plugins=(git zsh-syntax-highlighting zsh-autosuggestions alias-tips)

# Source custom configuration files
if [[ -d "$CONFIG_ZSH_DIR" ]]; then
    for config_file in "$CONFIG_ZSH_DIR"/*.zsh; do
        [[ -r "\$config_file" ]] && source "\$config_file"
    done
fi
EOF
    
    logSuccess ".zshrc updated with custom configuration"
}

# Change default shell to ZSH
changeDefaultShell() {
    if [[ "$DEFAULT_SHELL_CHANGE" != "true" ]]; then
        logInfo "Skipping default shell change (disabled in configuration)"
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
        logError "ZSH executable not found"
        return 1
    fi
    
    # Add ZSH to /etc/shells if not present
    if ! grep -q "$zsh_path" /etc/shells 2>/dev/null; then
        if [[ "$SUDO_AVAILABLE" == "true" ]]; then
            echo "$zsh_path" | sudo tee -a /etc/shells
            logInfo "Added ZSH to /etc/shells"
        else
            logWarn "Cannot add ZSH to /etc/shells - sudo not available"
        fi
    fi
    
    # Change user's default shell
    if chsh -s "$zsh_path"; then
        logSuccess "Default shell changed to ZSH"
        logInfo "Please log out and log back in for the change to take effect"
    else
        logError "Failed to change default shell"
        return 1
    fi
}

# Verify installation
verifyInstallation() {
    logInfo "Verifying installation..."
    
    local errors=0
    
    # Check ZSH
    if commandExists zsh; then
        logSuccess "✓ ZSH is installed: $(zsh --version)"
    else
        logError "✗ ZSH is not installed"
        ((errors++))
    fi
    
    # Check Oh My ZSH
    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        logSuccess "✓ Oh My ZSH is installed"
    else
        logError "✗ Oh My ZSH is not installed"
        ((errors++))
    fi
    
    # Check Powerlevel10k
    if [[ -d "${ZSH_CUSTOM}/themes/powerlevel10k" ]]; then
        logSuccess "✓ Powerlevel10k theme is installed"
    else
        logError "✗ Powerlevel10k theme is not installed"
        ((errors++))
    fi
    
    # Check plugins
    local plugins=("zsh-syntax-highlighting" "zsh-autosuggestions" "alias-tips")
    for plugin in "${plugins[@]}"; do
        if [[ -d "${ZSH_CUSTOM}/plugins/$plugin" ]]; then
            logSuccess "✓ Plugin $plugin is installed"
        else
            logError "✗ Plugin $plugin is not installed"
            ((errors++))
        fi
    done
    
    # Check custom configuration
    if [[ -d "$CONFIG_ZSH_DIR" ]]; then
        logSuccess "✓ Custom configuration directory exists"
    else
        logError "✗ Custom configuration directory not found"
        ((errors++))
    fi
    
    if [[ $errors -eq 0 ]]; then
        logSuccess "All components verified successfully!"
        return 0
    else
        logError "Verification failed with $errors errors"
        return 1
    fi
}

INSTALL_FUNCTIONS

    # Agregar funciones de menú y main
    cat >> "$temp_script" << 'MAIN_FUNCTIONS'
# ============================================
# MENU AND MAIN FUNCTIONS
# ============================================

# Display main menu
displayMenu() {
    echo -e "${COLOR_BLUE}"
    echo "==========================================="
    echo "    ZSH Terminal Installation Options"
    echo "==========================================="
    echo -e "${COLOR_NC}"
    echo "1. Complete Installation (Recommended)"
    echo "2. Install ZSH and Oh My ZSH only"
    echo "3. Install Powerlevel10k theme"
    echo "4. Install ZSH plugins"
    echo "5. Install custom terminal configuration"
    echo "6. Verify current installation"
    echo "7. Exit"
    echo ""
}

# Get user input with validation
getUserChoice() {
    local choice
    while true; do
        read -p "Please select an option (1-7): " choice
        
        if [[ "$choice" =~ ^[1-7]$ ]]; then
            echo "$choice"
            return 0
        else
            logWarn "Invalid option. Please select a number between 1 and 7."
        fi
    done
}

# Complete installation function
completeInstallation() {
    logInfo "Starting complete ZSH terminal installation..."
    
    # Install required packages
    installRequiredPackages || return 1
    
    # Install ZSH
    installZSH || return 1
    
    # Install Oh My ZSH
    installOhMyZSH || return 1
    
    # Install Powerlevel10k theme
    installPowerlevel10k || return 1
    
    # Install fonts
    installPowerlevel10kFonts || return 1
    
    # Install plugins
    installZSHPlugins || return 1
    
    # Install custom configuration
    installCustomConfiguration || return 1
    
    # Update .zshrc
    updateZshrc || return 1
    
    # Change default shell
    changeDefaultShell || return 1
    
    # Verify installation
    verifyInstallation || return 1
    
    logSuccess "Complete installation finished successfully!"
    logInfo "Please restart your terminal or run 'exec zsh' to start using ZSH"
    
    return 0
}

# Handle user menu selection
handleMenuSelection() {
    local choice="$1"
    
    case "$choice" in
        1)
            logInfo "Selected: Complete Installation"
            completeInstallation
            ;;
        2)
            logInfo "Selected: Install ZSH and Oh My ZSH only"
            installRequiredPackages && installZSH && installOhMyZSH
            ;;
        3)
            logInfo "Selected: Install Powerlevel10k theme"
            installPowerlevel10k && installPowerlevel10kFonts
            ;;
        4)
            logInfo "Selected: Install ZSH plugins"
            installZSHPlugins
            ;;
        5)
            logInfo "Selected: Install custom terminal configuration"
            installCustomConfiguration && updateZshrc
            ;;
        6)
            logInfo "Selected: Verify current installation"
            verifyInstallation
            ;;
        7)
            logInfo "Selected: Exit"
            logInfo "Thank you for using the ZSH Terminal Installation Script!"
            exit 0
            ;;
        *)
            logError "Invalid selection: $choice"
            return 1
            ;;
    esac
}

# Initialize script
initializeScript() {
    # Set up error handling and logging
    setupErrorHandling
    initializeLogging
    
    # Validate environment
    validateBashVersion
    checkNotRoot
    checkSudoAccess
    detectOS
    
    # Create temporary directory
    mkdir -p "$TEMP_INSTALL_DIR"
    
    # Display header
    displayHeader
    
    logInfo "Script initialization completed successfully"
}

# Main execution function
main() {
    # Initialize script environment
    initializeScript
    
    # Check for command line arguments for automated installation
    if [[ $# -gt 0 ]]; then
        case "$1" in
            --complete|--full)
                logInfo "Running automated complete installation"
                completeInstallation
                exit $?
                ;;
            --zsh-only)
                logInfo "Running automated ZSH-only installation"
                installRequiredPackages && installZSH && installOhMyZSH
                exit $?
                ;;
            --verify)
                logInfo "Running installation verification"
                verifyInstallation
                exit $?
                ;;
            --help|-h)
                echo "Usage: $0 [OPTION]"
                echo "Options:"
                echo "  --complete, --full    Run complete installation"
                echo "  --zsh-only           Install ZSH and Oh My ZSH only"
                echo "  --verify             Verify current installation"
                echo "  --help, -h           Show this help message"
                exit 0
                ;;
            *)
                logError "Unknown option: $1"
                logInfo "Use --help for available options"
                exit 1
                ;;
        esac
    fi
    
    # Interactive mode
    while true; do
        clear
        displayMenu
        
        local choice
        choice=$(getUserChoice)
        
        echo ""
        logInfo "Processing selection: $choice"
        
        if handleMenuSelection "$choice"; then
            if [[ "$choice" != "7" ]]; then
                echo ""
                read -p "Press Enter to continue..." -r
            fi
        else
            logError "Operation failed"
            read -p "Press Enter to continue..." -r
        fi
        
        # Exit if user selected exit option
        if [[ "$choice" == "7" ]]; then
            break
        fi
    done
}

# Execute main function with all arguments
main "$@"

MAIN_FUNCTIONS

    # Copiar el script temporal al archivo final
    cp "$temp_script" "$OUTPUT_FILE"
    chmod +x "$OUTPUT_FILE"
    
    logSuccess "Script standalone generado: $OUTPUT_FILE"
}

# Función principal
main() {
    logInfo "Iniciando generación del instalador standalone..."
    
    # Verificar archivos fuente
    verifySourceFiles
    
    # Generar script standalone
    generateStandaloneScript
    
    # Verificar que el script generado sea válido
    if bash -n "$OUTPUT_FILE"; then
        logSuccess "Script standalone generado y validado correctamente"
        logInfo "Archivo: $OUTPUT_FILE"
        logInfo "Tamaño: $(du -h "$OUTPUT_FILE" | cut -f1)"
    else
        logError "El script generado contiene errores de sintaxis"
        return 1
    fi
    
    logSuccess "Proceso completado exitosamente"
}

# Ejecutar función principal
main "$@"