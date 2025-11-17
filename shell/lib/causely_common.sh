#!/bin/sh
#
# Causely Common Utilities Library
#
# POSIX-compliant library for common utilities used across Causely scripts
# This file is meant to be SOURCED by other scripts, not executed directly.
#
# Usage:
#   . "$(dirname "$0")/lib/causely_common.sh"
#

# Prevent script from being executed directly
if [ "${0##*/}" = "causely_common.sh" ]; then
    echo "Error: This file is a library and should be sourced, not executed directly." >&2
    echo "Usage: . \$(dirname \"\$0\")/lib/causely_common.sh" >&2
    exit 1
fi

# Include guard - prevent double-sourcing overhead
if [ -n "$CAUSELY_COMMON_LOADED" ]; then
    return 0
fi
CAUSELY_COMMON_LOADED=1

# ============================================================================
# Constants
# ============================================================================

# Default API endpoint
CAUSELY_API_URL_DEFAULT="https://api.causely.app/query"

# ============================================================================
# Color Codes
# ============================================================================

CAUSELY_RED='\033[0;31m'
CAUSELY_GREEN='\033[0;32m'
CAUSELY_YELLOW='\033[1;33m'
CAUSELY_BLUE='\033[0;34m'
CAUSELY_NC='\033[0m' # No Color

# ============================================================================
# Dependency Checking
# ============================================================================

# Check if a command is available
# Arguments:
#   $1 - command name
# Returns:
#   0 if available, 1 if not
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check required dependencies and exit if missing
# Arguments:
#   $@ - list of required commands
# Returns:
#   Exits with code 1 if any dependency is missing
check_dependencies() {
    _missing=""
    
    for _cmd in "$@"; do
        if ! command_exists "$_cmd"; then
            _missing="$_missing $_cmd"
        fi
    done
    
    if [ -n "$_missing" ]; then
        print_error "Missing required dependencies:$_missing"
        echo "" >&2
        echo "Installation instructions:" >&2
        
        # Provide specific installation instructions
        for _cmd in $_missing; do
            case "$_cmd" in
                jq)
                    echo "  jq: https://jqlang.github.io/jq/download/" >&2
                    echo "    - macOS: brew install jq" >&2
                    echo "    - Debian/Ubuntu: apt-get install jq" >&2
                    echo "    - RHEL/CentOS: yum install jq" >&2
                    ;;
                curl)
                    echo "  curl: https://curl.se/download.html" >&2
                    echo "    - Usually pre-installed on most systems" >&2
                    ;;
                *)
                    echo "  $_cmd: Please install using your system package manager" >&2
                    ;;
            esac
        done
        return 1
    fi
    
    # Check for broken Anaconda jq
    if command_exists jq; then
        _jq_path=$(command -v jq)
        if echo "$_jq_path" | grep -q "anaconda"; then
            print_warning "⚠️  Warning: Anaconda's jq is known to have bugs" >&2
            echo "   Consider using system jq or: conda deactivate" >&2
            echo "   Found at: $_jq_path" >&2
            echo "" >&2
        fi
    fi
    
    return 0
}

# ============================================================================
# Script Protection Utilities
# ============================================================================

# Function to prevent a script from being sourced to guard against shell pollution
# Call this at the top of executable scripts
# Arguments:
#   $1 - script name (e.g., "create_snapshot.sh")
prevent_sourcing() {
    _script_name="$1"
    _script_basename="${0##*/}"
    
    # Check if the basename of $0 matches the expected script name
    if [ "$_script_basename" = "$_script_name" ]; then
        return 0  # Script is being executed (correct)
    else
        echo "Error: This script must be executed, not sourced." >&2
        echo "Usage: ./$_script_name [args]" >&2
        return 1 2>/dev/null || exit 1
    fi
}

# ============================================================================
# Printing Utilities
# ============================================================================

# Print error message in red
# Arguments: message text
print_error() {
    printf '%b\n' "${CAUSELY_RED}$*${CAUSELY_NC}" >&2
}

# Print success message in green
# Arguments: message text
print_success() {
    printf '%b\n' "${CAUSELY_GREEN}$*${CAUSELY_NC}"
}

# Print info message in blue
# Arguments: message text
print_info() {
    printf '%b\n' "${CAUSELY_BLUE}$*${CAUSELY_NC}"
}

# Print warning message in yellow
# Arguments: message text
print_warning() {
    printf '%b\n' "${CAUSELY_YELLOW}$*${CAUSELY_NC}"
}

# Print section header
# Arguments: header text
print_header() {
    echo ""
    printf '%b\n' "${CAUSELY_BLUE}=== $* ===${CAUSELY_NC}"
}

# Print usage line
# Arguments: usage text
print_usage() {
    echo "Usage: $*"
}

# Print example
# Arguments: example text
print_example() {
    echo "  $*"
}

# ============================================================================
# Help Message Utilities
# ============================================================================

# Print common Frontegg authentication help
print_frontegg_auth_help() {
    echo ""
    echo "Environment variables required for Frontegg authentication:"
    echo "  FRONTEGG_CLIENT_ID      - Frontegg client ID"
    echo "  FRONTEGG_CLIENT_SECRET  - Frontegg client secret"
    echo ""
    echo "Optional environment variables:"
    echo "  APP_BASE_URL            - API endpoint (default: https://api.causely.app/query)"
    echo "  FRONTEGG_IDENTITY_HOST  - Auth endpoint (default: https://auth.causely.app/identity/resources/auth/v2/api-token)"
}

# Print common environment variable setup example
print_env_setup_example() {
    echo ""
    echo "Example environment setup:"
    print_example 'export FRONTEGG_CLIENT_ID="your-client-id"'
    print_example 'export FRONTEGG_CLIENT_SECRET="your-client-secret"'
}

# Print authentication mode info
print_auth_mode_info() {
    echo ""
    echo "Authentication modes:"
    echo "  1. Frontegg (GitHub Actions): Set FRONTEGG_CLIENT_ID and FRONTEGG_CLIENT_SECRET"
    echo "  2. Direct token: Provide API URL and token as arguments"
}

