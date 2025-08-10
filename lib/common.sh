#!/bin/bash
# Common library functions for ZSH Terminal Installation
# Provides logging, validation, OS detection, and error handling

# Source configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/../config/install.conf"

if [[ -f "$CONFIG_FILE" ]]; then
    # shellcheck source=../config/install.conf
    source "$CONFIG_FILE"
else
    echo "ERROR: Configuration file not found: $CONFIG_FILE" >&2
    exit 1
fi

# Initialize logging directory
initializeLogging() {
    mkdir -p "$LOG_DIR"
    LOG_FILE="${LOG_DIR}/install_$(date +%Y%m%d_%H%M%S).log"
    
    if [[ "$VERBOSE_LOGGING" == "true" ]]; then
        exec 1> >(tee -a "$LOG_FILE")
        exec 2> >(tee -a "$LOG_FILE" >&2)
    else
        exec 1> "$LOG_FILE"
        exec 2> "$LOG_FILE"
    fi
}

# Logging functions with colors and timestamps
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

logDebug() {
    if [[ "${DEBUG:-false}" == "true" ]]; then
        echo -e "[DEBUG] $(date '+%Y-%m-%d %H:%M:%S') - $*" >&2
    fi
}

# Error handling and cleanup
cleanupOnExit() {
    local exit_code=$?
    logDebug "Cleanup function called with exit code: $exit_code"
    
    # Remove temporary directory if it exists
    if [[ -d "$TEMP_DIR" ]]; then
        logInfo "Cleaning up temporary directory: $TEMP_DIR"
        rm -rf "$TEMP_DIR"
    fi
    
    # Log final status
    if [[ $exit_code -eq 0 ]]; then
        logSuccess "Installation completed successfully"
    else
        logError "Installation failed with exit code: $exit_code"
    fi
    
    exit $exit_code
}

# Set up error handling
setupErrorHandling() {
    if [[ "$STRICT_MODE" == "true" ]]; then
        set -euo pipefail
    fi
    
    trap cleanupOnExit EXIT INT TERM
}

# OS Detection
detectOS() {
    local os_name
    os_name=$(uname -s)
    
    # Check for WSL
    if [[ -f /proc/version ]] && grep -q Microsoft /proc/version; then
        logInfo "Detected WSL environment"
        export WSL_ENV="true"
    fi
    
    case "$os_name" in
        Linux*)
            if command -v apt &> /dev/null; then
                OS="ubuntu"
                PACKAGE_MANAGER="apt"
                PACKAGES=("${UBUNTU_PACKAGES[@]}")
            elif command -v yum &> /dev/null; then
                OS="centos"
                PACKAGE_MANAGER="yum"
                PACKAGES=("${CENTOS_PACKAGES[@]}")
            elif command -v dnf &> /dev/null; then
                OS="fedora"
                PACKAGE_MANAGER="dnf"
                PACKAGES=("${CENTOS_PACKAGES[@]}")
            else
                logError "Unsupported Linux distribution"
                return 1
            fi
            ;;
        Darwin*)
            OS="macos"
            PACKAGE_MANAGER="brew"
            PACKAGES=("${MACOS_PACKAGES[@]}")
            ;;
        MINGW*|MSYS*|CYGWIN*)
            logInfo "Detected Windows environment (Git Bash/MSYS2/Cygwin)"
            OS="windows"
            PACKAGE_MANAGER="manual"
            PACKAGES=()
            export WINDOWS_ENV="true"
            ;;
        *)
            logWarn "Unknown operating system: $os_name - attempting to continue"
            OS="unknown"
            PACKAGE_MANAGER="manual"
            PACKAGES=()
            ;;
    esac
    
    logInfo "Detected OS: $OS with package manager: $PACKAGE_MANAGER"
    export OS PACKAGE_MANAGER PACKAGES
}

# Check if running as root (should not be)
checkNotRoot() {
    if [[ $EUID -eq 0 ]]; then
        logError "This script should not be run as root for security reasons"
        logError "Please run as a regular user. Sudo will be used when necessary"
        return 1
    fi
}

# Check sudo access without password prompt
checkSudoAccess() {
    # Check if sudo is available and working
    if ! command -v sudo >/dev/null 2>&1; then
        logWarn "Sudo not available - some features may be limited"
        export SUDO_AVAILABLE="false"
        return 0
    fi
    
    if ! sudo -n true 2>/dev/null; then
        logWarn "Sudo access not configured for passwordless operation"
        logInfo "Some package installations may require manual intervention"
        
        # Try to test sudo access
        if sudo true 2>/dev/null; then
            logSuccess "Sudo access confirmed (with password prompt)"
            export SUDO_AVAILABLE="true"
        else
            logWarn "Sudo access failed - continuing with limited functionality"
            logInfo "You may need to install packages manually"
            export SUDO_AVAILABLE="false"
        fi
    else
        logSuccess "Sudo access confirmed (passwordless)"
        export SUDO_AVAILABLE="true"
    fi
}

# Validate bash version
validateBashVersion() {
    local current_version
    current_version=$(bash --version | head -n1 | grep -oE '[0-9]+\.[0-9]+' | head -n1)
    
    if ! awk -v curr="$current_version" -v min="$MIN_BASH_VERSION" 'BEGIN{exit(curr<min)}'; then
        logError "Bash version $current_version is too old. Minimum required: $MIN_BASH_VERSION"
        return 1
    fi
    
    logInfo "Bash version $current_version is compatible"
}

# Validate input against allowed options
validateInput() {
    local input="$1"
    shift
    local valid_options=("$@")
    
    for option in "${valid_options[@]}"; do
        if [[ "$input" == "$option" ]]; then
            return 0
        fi
    done
    
    logError "Invalid input: '$input'. Valid options: ${valid_options[*]}"
    return 1
}

# Check if command exists
commandExists() {
    command -v "$1" &> /dev/null
}

# Create backup of existing configuration
createBackup() {
    local file="$1"
    local backup_name="$2"
    
    if [[ "$CREATE_BACKUP" == "true" && -f "$file" ]]; then
        mkdir -p "$BACKUP_DIR"
        local backup_file="${BACKUP_DIR}/${backup_name}_$(date +%Y%m%d_%H%M%S).bak"
        
        if cp "$file" "$backup_file"; then
            logSuccess "Backup created: $backup_file"
        else
            logWarn "Failed to create backup of $file"
        fi
    fi
}

# Validate file checksum
validateChecksum() {
    local file="$1"
    local expected_checksum="$2"
    
    if [[ -z "$expected_checksum" ]]; then
        logWarn "No checksum provided for $file - skipping validation"
        return 0
    fi
    
    if ! commandExists sha256sum; then
        logWarn "sha256sum not available - skipping checksum validation"
        return 0
    fi
    
    local actual_checksum
    actual_checksum=$(sha256sum "$file" | cut -d' ' -f1)
    
    if [[ "$actual_checksum" == "$expected_checksum" ]]; then
        logSuccess "Checksum validation passed for $file"
        return 0
    else
        logError "Checksum validation failed for $file"
        logError "Expected: $expected_checksum"
        logError "Actual: $actual_checksum"
        return 1
    fi
}

# Safe download with timeout and checksum validation
safeDownload() {
    local url="$1"
    local output_file="$2"
    local expected_checksum="${3:-}"
    
    logInfo "Downloading: $url"
    
    if commandExists wget; then
        if wget --timeout="$DOWNLOAD_TIMEOUT" -O "$output_file" "$url"; then
            logSuccess "Download completed: $output_file"
        else
            logError "Download failed: $url"
            return 1
        fi
    elif commandExists curl; then
        if curl --max-time "$DOWNLOAD_TIMEOUT" -L -o "$output_file" "$url"; then
            logSuccess "Download completed: $output_file"
        else
            logError "Download failed: $url"
            return 1
        fi
    else
        logError "Neither wget nor curl is available"
        return 1
    fi
    
    # Validate checksum if provided
    if [[ -n "$expected_checksum" ]]; then
        validateChecksum "$output_file" "$expected_checksum"
    fi
}

# Safe git clone with timeout
safeGitClone() {
    local repo_url="$1"
    local target_dir="$2"
    local depth="${3:-1}"
    
    logInfo "Cloning repository: $repo_url"
    
    if timeout "$GIT_CLONE_TIMEOUT" git clone --depth="$depth" "$repo_url" "$target_dir"; then
        logSuccess "Repository cloned successfully: $target_dir"
    else
        logError "Failed to clone repository: $repo_url"
        return 1
    fi
}

# Display script header
displayHeader() {
    echo -e "${COLOR_BLUE}"
    echo "=========================================="
    echo "    ZSH Terminal Installation Script"
    echo "    Version: $SCRIPT_VERSION"
    echo "    OS: $OS"
    echo "=========================================="
    echo -e "${COLOR_NC}"
}