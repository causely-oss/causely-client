#!/bin/sh
#
# Tests for causely_auth.sh
#
# Note: Most auth functions require real credentials, so we test:
# - Function existence and basic behavior
# - Error handling
# - Variable validation
#

set -e

# Setup paths
SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
. "$SCRIPT_DIR/tests/test_framework.sh"
. "$SCRIPT_DIR/lib/causely_common.sh"
. "$SCRIPT_DIR/lib/causely_auth.sh"

# ============================================================================
# Test: authenticate_frontegg - Error Handling
# ============================================================================

test_suite "authenticate_frontegg - Error Handling"

# Test that function exists
assert_success "command -v authenticate_frontegg >/dev/null" \
    "authenticate_frontegg function is defined"

# Test with missing arguments (should fail gracefully)
assert_failure "authenticate_frontegg '' '' '' 2>/dev/null" \
    "Fails when arguments are missing"

assert_failure "authenticate_frontegg 'host' '' '' 2>/dev/null" \
    "Fails when client_id is missing"

assert_failure "authenticate_frontegg 'host' 'id' '' 2>/dev/null" \
    "Fails when client_secret is missing"

# Test with invalid credentials (should fail gracefully)
# Using fake endpoint that will fail quickly
assert_failure "authenticate_frontegg 'https://invalid.example.com' 'fake_id' 'fake_secret' 2>/dev/null" \
    "Fails gracefully with invalid credentials"

# ============================================================================
# Test: setup_causely_auth - Without Credentials
# ============================================================================

test_suite "setup_causely_auth - Without Frontegg Vars"

# Clear Frontegg variables if they exist
FRONTEGG_CLIENT_ID_backup="$FRONTEGG_CLIENT_ID"
FRONTEGG_CLIENT_SECRET_backup="$FRONTEGG_CLIENT_SECRET"
unset FRONTEGG_CLIENT_ID
unset FRONTEGG_CLIENT_SECRET

# Without Frontegg vars, should use direct token mode
assert_success "setup_causely_auth 2>/dev/null" \
    "setup_causely_auth succeeds in direct token mode"

# Restore variables if they existed
FRONTEGG_CLIENT_ID="$FRONTEGG_CLIENT_ID_backup"
FRONTEGG_CLIENT_SECRET="$FRONTEGG_CLIENT_SECRET_backup"

# ============================================================================
# Test: setup_causely_auth - With Partial Credentials
# ============================================================================

test_suite "setup_causely_auth - With Partial Credentials"

# Test with only CLIENT_ID set (missing SECRET)
FRONTEGG_CLIENT_ID_backup="$FRONTEGG_CLIENT_ID"
FRONTEGG_CLIENT_SECRET_backup="$FRONTEGG_CLIENT_SECRET"

FRONTEGG_CLIENT_ID="test_id"
unset FRONTEGG_CLIENT_SECRET

# Should fall back to direct token mode
assert_success "setup_causely_auth 2>/dev/null" \
    "Falls back to direct mode when SECRET is missing"

# Restore
FRONTEGG_CLIENT_ID="$FRONTEGG_CLIENT_ID_backup"
FRONTEGG_CLIENT_SECRET="$FRONTEGG_CLIENT_SECRET_backup"

# ============================================================================
# Test: Default Environment Variables
# ============================================================================

test_suite "Default Environment Variables"

# Clear variables
APP_BASE_URL_backup="$APP_BASE_URL"
FRONTEGG_IDENTITY_HOST_backup="$FRONTEGG_IDENTITY_HOST"
unset APP_BASE_URL
unset FRONTEGG_IDENTITY_HOST

# Mock Frontegg setup (without actual authentication)
FRONTEGG_CLIENT_ID="test_id"
FRONTEGG_CLIENT_SECRET="test_secret"

# The function will try to authenticate and fail, but we can check defaults are set
# Capture the attempt (will fail but that's OK)
setup_causely_auth 2>/dev/null || true

# Check that defaults were set before auth attempt
# Note: These get set in setup_causely_auth before calling authenticate_frontegg
assert_not_empty "$APP_BASE_URL" \
    "APP_BASE_URL is set to default when not provided"

assert_not_empty "$FRONTEGG_IDENTITY_HOST" \
    "FRONTEGG_IDENTITY_HOST is set to default when not provided"

# Check default values
assert_contains "$APP_BASE_URL" "api.causely.app" \
    "Default APP_BASE_URL points to api.causely.app"

assert_contains "$FRONTEGG_IDENTITY_HOST" "auth.causely.app" \
    "Default FRONTEGG_IDENTITY_HOST points to auth.causely.app"

# Restore
APP_BASE_URL="$APP_BASE_URL_backup"
FRONTEGG_IDENTITY_HOST="$FRONTEGG_IDENTITY_HOST_backup"
unset FRONTEGG_CLIENT_ID
unset FRONTEGG_CLIENT_SECRET

# ============================================================================
# Test: Authentication Modes
# ============================================================================

test_suite "Authentication Modes"

# Test that help functions exist and work
assert_success "command -v print_frontegg_auth_help >/dev/null" \
    "print_frontegg_auth_help function exists"

assert_success "print_frontegg_auth_help >/dev/null 2>&1" \
    "print_frontegg_auth_help executes without error"

output=$(print_frontegg_auth_help 2>&1)
assert_contains "$output" "FRONTEGG_CLIENT_ID" \
    "Auth help mentions CLIENT_ID"

assert_contains "$output" "FRONTEGG_CLIENT_SECRET" \
    "Auth help mentions CLIENT_SECRET"

# ============================================================================
# Summary
# ============================================================================

test_summary

