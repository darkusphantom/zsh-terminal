#!/bin/bash
# ZSH Terminal Installation Script - Enhanced Version
# Author: Enhanced for security, maintainability, and scalability
# Version: 2.0.0
# Description: Secure and modular installation script for ZSH with Oh My ZSH,
#              Powerlevel10k theme, and essential plugins

# Script directory and library loading
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/lib"

# Check if library files exist
if [[ ! -f "${LIB_DIR}/common.sh" ]] || [[ ! -f "${LIB_DIR}/install.sh" ]]; then
    echo "ERROR: Required library files not found in ${LIB_DIR}/" >&2
    echo "Please ensure common.sh and install.sh are present in the lib directory" >&2
    exit 1
fi

# Source library functions
# shellcheck source=lib/common.sh
source "${LIB_DIR}/common.sh"
# shellcheck source=lib/install.sh
source "${LIB_DIR}/install.sh"

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
    mkdir -p "$TEMP_DIR"
    
    # Display header
    displayHeader
    
    logInfo "Script initialization completed successfully"
}

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
        
        if validateInput "$choice" "1" "2" "3" "4" "5" "6" "7"; then
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
            installCustomTerminal
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
