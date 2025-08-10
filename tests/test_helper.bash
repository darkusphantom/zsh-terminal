#!/usr/bin/env bash
# BATS test helper functions
# This file contains utility functions for testing

# Helper function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Helper function to create a mock command
create_mock_command() {
    local command_name="$1"
    local mock_behavior="$2"
    local mock_dir="$TEST_TEMP_DIR/mock_bin"
    
    mkdir -p "$mock_dir"
    
    cat > "$mock_dir/$command_name" << EOF
#!/bin/bash
$mock_behavior
EOF
    
    chmod +x "$mock_dir/$command_name"
    export PATH="$mock_dir:$PATH"
}

# Helper function to remove mock commands
cleanup_mocks() {
    if [[ -d "$TEST_TEMP_DIR/mock_bin" ]]; then
        rm -rf "$TEST_TEMP_DIR/mock_bin"
    fi
}

# Helper function to assert file exists
assert_file_exists() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        echo "Expected file '$file' to exist, but it doesn't"
        return 1
    fi
}

# Helper function to assert directory exists
assert_dir_exists() {
    local dir="$1"
    if [[ ! -d "$dir" ]]; then
        echo "Expected directory '$dir' to exist, but it doesn't"
        return 1
    fi
}

# Helper function to assert file contains text
assert_file_contains() {
    local file="$1"
    local text="$2"
    
    if [[ ! -f "$file" ]]; then
        echo "File '$file' does not exist"
        return 1
    fi
    
    if ! grep -q "$text" "$file"; then
        echo "File '$file' does not contain '$text'"
        echo "File contents:"
        cat "$file"
        return 1
    fi
}

# Helper function to assert command output
assert_output_contains() {
    local expected="$1"
    if [[ "$output" != *"$expected"* ]]; then
        echo "Expected output to contain '$expected'"
        echo "Actual output: '$output'"
        return 1
    fi
}

# Helper function to assert command output matches regex
assert_output_matches() {
    local pattern="$1"
    if [[ ! "$output" =~ $pattern ]]; then
        echo "Expected output to match pattern '$pattern'"
        echo "Actual output: '$output'"
        return 1
    fi
}

# Helper function to create test configuration
create_test_config() {
    local config_file="$TEST_TEMP_DIR/test_install.conf"
    
    cat > "$config_file" << 'EOF'
# Test configuration for ZSH Terminal Installation

# URLs and repositories
OH_MY_ZSH_URL="https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh"
POWERLEVEL10K_REPO="https://github.com/romkatv/powerlevel10k.git"
NERD_FONTS_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.2/Meslo.zip"

# Directories
ZSH_CUSTOM_DIR="$HOME/.oh-my-zsh/custom"
THEMES_DIR="$ZSH_CUSTOM_DIR/themes/powerlevel10k"
PLUGINS_DIR="$ZSH_CUSTOM_DIR/plugins"
FONTS_DIR="$HOME/.local/share/fonts"
LOG_DIR="$HOME/.zsh-install/logs"
BACKUP_DIR="$HOME/.zsh-install/backup"

# Package names by OS
UBUNTU_PACKAGES=("zsh" "git" "curl" "wget" "fontconfig")
FEDORA_PACKAGES=("zsh" "git" "curl" "wget" "fontconfig")
ARCH_PACKAGES=("zsh" "git" "curl" "wget" "fontconfig")
MACOS_PACKAGES=("zsh" "git" "curl" "wget")

# Installation options
CREATE_BACKUP="true"
VERBOSE_MODE="false"
FORCE_INSTALL="false"
SKIP_FONTS="false"
SKIP_PLUGINS="false"

# Timeouts and retries
DOWNLOAD_TIMEOUT="30"
MAX_RETRIES="3"
RETRY_DELAY="5"

# Colors for output
COLOR_RED="\033[0;31m"
COLOR_GREEN="\033[0;32m"
COLOR_YELLOW="\033[1;33m"
COLOR_BLUE="\033[0;34m"
COLOR_PURPLE="\033[0;35m"
COLOR_CYAN="\033[0;36m"
COLOR_NC="\033[0m"

# Version requirements
MIN_BASH_VERSION="4.0"
MIN_ZSH_VERSION="5.0"

# Checksums for verification (example)
OH_MY_ZSH_CHECKSUM=""
POWERLEVEL10K_CHECKSUM=""
EOF
    
    echo "$config_file"
}

# Helper function to setup test environment with mocks
setup_test_environment() {
    # Create mock package managers
    create_mock_command "apt" "echo 'Mock apt: $*'; exit 0"
    create_mock_command "yum" "echo 'Mock yum: $*'; exit 0"
    create_mock_command "dnf" "echo 'Mock dnf: $*'; exit 0"
    create_mock_command "pacman" "echo 'Mock pacman: $*'; exit 0"
    create_mock_command "brew" "echo 'Mock brew: $*'; exit 0"
    
    # Create mock git
    create_mock_command "git" "echo 'Mock git: $*'; exit 0"
    
    # Create mock curl
    create_mock_command "curl" "echo 'Mock curl: $*'; exit 0"
    
    # Create mock wget
    create_mock_command "wget" "echo 'Mock wget: $*'; exit 0"
    
    # Create mock zsh
    create_mock_command "zsh" "echo 'Mock zsh: $*'; exit 0"
}

# Helper function to simulate different operating systems
simulate_os() {
    local os_type="$1"
    
    case "$os_type" in
        "ubuntu")
            export OS="Ubuntu"
            export PACKAGE_MANAGER="apt"
            create_mock_command "lsb_release" "echo 'Ubuntu 20.04.3 LTS'"
            ;;
        "fedora")
            export OS="Fedora"
            export PACKAGE_MANAGER="dnf"
            create_mock_command "lsb_release" "echo 'Fedora 35'"
            ;;
        "arch")
            export OS="Arch"
            export PACKAGE_MANAGER="pacman"
            create_mock_command "lsb_release" "echo 'Arch Linux'"
            ;;
        "macos")
            export OS="macOS"
            export PACKAGE_MANAGER="brew"
            create_mock_command "sw_vers" "echo 'macOS 12.0'"
            ;;
        *)
            echo "Unknown OS type: $os_type"
            return 1
            ;;
    esac
}

# Helper function to check if running in CI environment
is_ci() {
    [[ -n "$CI" ]] || [[ -n "$GITHUB_ACTIONS" ]] || [[ -n "$TRAVIS" ]] || [[ -n "$CIRCLECI" ]]
}

# Helper function to skip test if not in appropriate environment
skip_if_not_linux() {
    if [[ "$(uname)" != "Linux" ]]; then
        skip "This test requires Linux"
    fi
}

skip_if_not_macos() {
    if [[ "$(uname)" != "Darwin" ]]; then
        skip "This test requires macOS"
    fi
}

skip_if_ci() {
    if is_ci; then
        skip "Skipping test in CI environment"
    fi
}

# Helper function to generate random string
generate_random_string() {
    local length="${1:-10}"
    tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c "$length"
}

# Helper function to wait for condition
wait_for_condition() {
    local condition="$1"
    local timeout="${2:-10}"
    local interval="${3:-1}"
    
    local elapsed=0
    while [[ $elapsed -lt $timeout ]]; do
        if eval "$condition"; then
            return 0
        fi
        sleep "$interval"
        ((elapsed += interval))
    done
    
    return 1
}

# Helper function to capture stderr
capture_stderr() {
    local command="$1"
    local stderr_file="$TEST_TEMP_DIR/stderr.txt"
    
    eval "$command" 2>"$stderr_file"
    local exit_code=$?
    
    export captured_stderr
    captured_stderr=$(cat "$stderr_file")
    
    return $exit_code
}

# Helper function to assert exit code
assert_exit_code() {
    local expected="$1"
    local actual="$status"
    
    if [[ "$actual" -ne "$expected" ]]; then
        echo "Expected exit code $expected, but got $actual"
        echo "Output: $output"
        return 1
    fi
}

# Helper function to create temporary file with content
create_temp_file() {
    local content="$1"
    local filename="${2:-temp_file}"
    local filepath="$TEST_TEMP_DIR/$filename"
    
    echo "$content" > "$filepath"
    echo "$filepath"
}

# Helper function to verify log file format
verify_log_format() {
    local log_file="$1"
    local expected_level="$2"
    
    if [[ ! -f "$log_file" ]]; then
        echo "Log file '$log_file' does not exist"
        return 1
    fi
    
    # Check if log contains timestamp and level
    if ! grep -q "\[.*\] \[$expected_level\]" "$log_file"; then
        echo "Log file does not contain expected format with level '$expected_level'"
        echo "Log contents:"
        cat "$log_file"
        return 1
    fi
}

# Export all functions for use in tests
export -f command_exists
export -f create_mock_command
export -f cleanup_mocks
export -f assert_file_exists
export -f assert_dir_exists
export -f assert_file_contains
export -f assert_output_contains
export -f assert_output_matches
export -f create_test_config
export -f setup_test_environment
export -f simulate_os
export -f is_ci
export -f skip_if_not_linux
export -f skip_if_not_macos
export -f skip_if_ci
export -f generate_random_string
export -f wait_for_condition
export -f capture_stderr
export -f assert_exit_code
export -f create_temp_file
export -f verify_log_format