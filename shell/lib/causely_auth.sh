#!/bin/sh
#
# Causely API Authentication Library
#
# POSIX-compliant library for Causely API authentication
# This file is meant to be SOURCED by other scripts, not executed directly.
#
# Usage:
#   . "$(dirname "$0")/lib/causely_auth.sh"
#   TOKEN=$(authenticate_frontegg "$HOST" "$CLIENT_ID" "$CLIENT_SECRET")
#

# Prevent script from being executed directly
if [ "${0##*/}" = "causely_auth.sh" ]; then
    echo "Error: This file is a library and should be sourced, not executed directly." >&2
    echo "Usage: . \$(dirname \"\$0\")/lib/causely_auth.sh" >&2
    exit 1
fi

# Source common utilities (colors, printing, script protection, help messages)
# Find the directory where this library file is located
# This works because the parent script used SCRIPT_DIR to source us
_causely_lib_dir="${SCRIPT_DIR:-.}/lib"
. "$_causely_lib_dir/causely_common.sh"

# ============================================================================
# Authentication Functions
# ============================================================================

# Function to authenticate with Frontegg
# Returns the access token on stdout, or exits with error
# Arguments:
#   $1 - identity_host (Frontegg auth endpoint)
#   $2 - client_id (Frontegg client ID)
#   $3 - client_secret (Frontegg client secret)
# Returns:
#   Prints access token to stdout
#   Exits with code 1 on failure
authenticate_frontegg() {
    _fg_identity_host="$1"
    _fg_client_id="$2"
    _fg_client_secret="$3"
    
    if [ -z "$_fg_identity_host" ] || [ -z "$_fg_client_id" ] || [ -z "$_fg_client_secret" ]; then
        print_error "Error: authenticate_frontegg requires 3 arguments"
        return 1
    fi
    
    print_info "Authenticating with Frontegg..." >&2
    
    _fg_auth_response=$(curl -sS -X POST "$_fg_identity_host" \
        -H "Content-Type: application/json" \
        -d "{\"clientId\":\"$_fg_client_id\",\"secret\":\"$_fg_client_secret\"}")
    
    # Extract token (handle both access_token and accessToken)
    _fg_token=$(echo "$_fg_auth_response" | jq -r '.access_token // .accessToken')
    
    if [ -z "$_fg_token" ] || [ "$_fg_token" = "null" ]; then
        print_error "Authentication failed"
        echo "Response: $_fg_auth_response" >&2
        return 1
    fi
    
    print_success "Authentication successful" >&2
    echo "$_fg_token"
    return 0
}

# Function to detect and perform authentication based on environment variables
# Sets the global variables: TOKEN and API_URL (used by calling script)
# Returns: 0 on success, 1 on failure
#
# Output Variables (set for caller):
#   TOKEN   - Authentication token (set in Frontegg mode)
#   API_URL - API endpoint URL (set in Frontegg mode)
setup_causely_auth() {
    if [ -n "$FRONTEGG_CLIENT_ID" ] && [ -n "$FRONTEGG_CLIENT_SECRET" ]; then

        # Set defaults for environment variables
        APP_BASE_URL="${APP_BASE_URL:-$CAUSELY_API_URL_DEFAULT}"
        FRONTEGG_IDENTITY_HOST="${FRONTEGG_IDENTITY_HOST:-https://auth.causely.app/identity/resources/auth/v2/api-token}"
        
        # Authenticate and get token
        # shellcheck disable=SC2034  # TOKEN used by caller
        TOKEN=$(authenticate_frontegg "$FRONTEGG_IDENTITY_HOST" "$FRONTEGG_CLIENT_ID" "$FRONTEGG_CLIENT_SECRET")
        if [ $? -ne 0 ]; then
            return 1
        fi
        # shellcheck disable=SC2034  # API_URL used by caller
        API_URL="$APP_BASE_URL"
        return 0
    else
        # Direct token mode - caller must provide API_URL and TOKEN
        print_info "Using direct token authentication"
        return 0
    fi
}
