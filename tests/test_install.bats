#!/usr/bin/env bats
# BATS test suite for ZSH Terminal Installation Script
# Run with: bats tests/test_install.bats

# Setup function run before each test
setup() {
    # Load common functions for testing
    load "test_helper"
    
    # Set up test environment
    export TEST_TEMP_DIR="/tmp/zsh-install-test-$$"
    export TEST_HOME="$TEST_TEMP_DIR/home"
    export HOME="$TEST_HOME"
    
    # Create test directories
    mkdir -p "$TEST_TEMP_DIR"
    mkdir -p "$TEST_HOME"
    
    # Source the script functions
    source "$BATS_TEST_DIRNAME/../lib/common.sh"
}

# Teardown function run after each test
teardown() {
    # Clean up test environment
    if [[ -d "$TEST_TEMP_DIR" ]]; then
        rm -rf "$TEST_TEMP_DIR"
    fi
}

# Test OS detection
@test "detectOS should identify the operating system correctly" {
    run detectOS
    [ "$status" -eq 0 ]
    [ -n "$OS" ]
    [ -n "$PACKAGE_MANAGER" ]
}

# Test command existence check
@test "commandExists should return true for existing commands" {
    run commandExists "bash"
    [ "$status" -eq 0 ]
}

@test "commandExists should return false for non-existing commands" {
    run commandExists "nonexistentcommand12345"
    [ "$status" -eq 1 ]
}

# Test input validation
@test "validateInput should accept valid options" {
    run validateInput "1" "1" "2" "3"
    [ "$status" -eq 0 ]
}

@test "validateInput should reject invalid options" {
    run validateInput "4" "1" "2" "3"
    [ "$status" -eq 1 ]
}

# Test logging functions
@test "logInfo should output formatted info message" {
    run logInfo "Test message"
    [ "$status" -eq 0 ]
    [[ "$output" =~ \[INFO\] ]]
    [[ "$output" =~ "Test message" ]]
}

@test "logError should output formatted error message" {
    run logError "Test error"
    [ "$status" -eq 0 ]
    [[ "$output" =~ \[ERROR\] ]]
    [[ "$output" =~ "Test error" ]]
}

# Test backup functionality
@test "createBackup should create backup file when original exists" {
    # Create a test file
    echo "test content" > "$TEST_HOME/test.txt"
    
    # Set backup configuration
    export CREATE_BACKUP="true"
    export BACKUP_DIR="$TEST_HOME/.backup"
    
    run createBackup "$TEST_HOME/test.txt" "test"
    [ "$status" -eq 0 ]
    
    # Check if backup directory was created
    [ -d "$BACKUP_DIR" ]
    
    # Check if backup file exists (with timestamp)
    backup_files=("$BACKUP_DIR"/test_*.bak)
    [ -f "${backup_files[0]}" ]
}

# Test checksum validation
@test "validateChecksum should pass with correct checksum" {
    # Create test file with known content
    echo -n "test" > "$TEST_TEMP_DIR/test.txt"
    
    # SHA256 of "test" is: 9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08
    local expected_checksum="9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08"
    
    run validateChecksum "$TEST_TEMP_DIR/test.txt" "$expected_checksum"
    [ "$status" -eq 0 ]
}

@test "validateChecksum should fail with incorrect checksum" {
    # Create test file
    echo -n "test" > "$TEST_TEMP_DIR/test.txt"
    
    # Use wrong checksum
    local wrong_checksum="wrongchecksum"
    
    run validateChecksum "$TEST_TEMP_DIR/test.txt" "$wrong_checksum"
    [ "$status" -eq 1 ]
}

# Test bash version validation
@test "validateBashVersion should pass with current bash version" {
    export MIN_BASH_VERSION="3.0"
    run validateBashVersion
    [ "$status" -eq 0 ]
}

# Test not running as root
@test "checkNotRoot should fail when running as root" {
    # Skip this test if not running as root
    if [[ $EUID -ne 0 ]]; then
        skip "Not running as root"
    fi
    
    run checkNotRoot
    [ "$status" -eq 1 ]
}

@test "checkNotRoot should pass when not running as root" {
    # Skip this test if running as root
    if [[ $EUID -eq 0 ]]; then
        skip "Running as root"
    fi
    
    run checkNotRoot
    [ "$status" -eq 0 ]
}

# Test configuration loading
@test "configuration file should be loadable" {
    # Test if config file exists and is readable
    [ -f "$BATS_TEST_DIRNAME/../config/install.conf" ]
    
    # Source config and check if variables are set
    source "$BATS_TEST_DIRNAME/../config/install.conf"
    [ -n "$OH_MY_ZSH_URL" ]
    [ -n "$POWERLEVEL10K_REPO" ]
    [ -n "$LOG_DIR" ]
}

# Test script help functionality
@test "script should display help when called with --help" {
    run "$BATS_TEST_DIRNAME/../install.sh" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]]
    [[ "$output" =~ "Options:" ]]
}

# Test script with invalid argument
@test "script should fail with invalid argument" {
    run "$BATS_TEST_DIRNAME/../install.sh" --invalid-option
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Unknown option" ]]
}

# Integration test - verify script structure
@test "main script should have proper structure" {
    # Check if main script exists and is executable
    [ -f "$BATS_TEST_DIRNAME/../install.sh" ]
    [ -x "$BATS_TEST_DIRNAME/../install.sh" ]
    
    # Check if it sources the required libraries
    grep -q "source.*lib/common.sh" "$BATS_TEST_DIRNAME/../install.sh"
    grep -q "source.*lib/install.sh" "$BATS_TEST_DIRNAME/../install.sh"
}

# Test library files existence
@test "required library files should exist" {
    [ -f "$BATS_TEST_DIRNAME/../lib/common.sh" ]
    [ -f "$BATS_TEST_DIRNAME/../lib/install.sh" ]
    [ -f "$BATS_TEST_DIRNAME/../config/install.conf" ]
}

# Test library files are sourceable
@test "library files should be sourceable without errors" {
    # Test common.sh
    run bash -c "source '$BATS_TEST_DIRNAME/../config/install.conf' && source '$BATS_TEST_DIRNAME/../lib/common.sh'"
    [ "$status" -eq 0 ]
    
    # Test install.sh
    run bash -c "source '$BATS_TEST_DIRNAME/../config/install.conf' && source '$BATS_TEST_DIRNAME/../lib/common.sh' && source '$BATS_TEST_DIRNAME/../lib/install.sh'"
    [ "$status" -eq 0 ]
}