#!/bin/sh
#
# Tests for causely_common.sh
#

set -e

# Setup paths
SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
. "$SCRIPT_DIR/tests/test_framework.sh"
. "$SCRIPT_DIR/lib/causely_common.sh"

# ============================================================================
# Test: command_exists
# ============================================================================

test_suite "command_exists"

assert_success "command_exists sh" \
    "Detects existing command (sh)"

assert_success "command_exists test" \
    "Detects existing command (test)"

assert_failure "command_exists fake_command_that_does_not_exist_12345" \
    "Returns false for non-existent command"

# ============================================================================
# Test: check_dependencies
# ============================================================================

test_suite "check_dependencies"

assert_success "check_dependencies sh test" \
    "Succeeds with available dependencies"

# Test missing dependencies (should fail)
assert_failure "check_dependencies fake_cmd_12345 2>/dev/null" \
    "Fails with missing dependency"

# ============================================================================
# Test: prevent_sourcing
# ============================================================================

test_suite "prevent_sourcing"

# Note: This function is difficult to test directly because it checks $0
# which depends on how the script is invoked. We verify it exists and can be called.

assert_success "command -v prevent_sourcing >/dev/null" \
    "prevent_sourcing function is defined"

# The function will check if ${0##*/} matches the script name
# Since we're in a test context, we just verify it doesn't crash
skip_test "prevent_sourcing behavior (requires execution context)"

# ============================================================================
# Test: Print Functions
# ============================================================================

test_suite "Print Functions"

# Test that print functions work without errors
assert_success "print_error 'test error' 2>/dev/null" \
    "print_error executes without error"

assert_success "print_success 'test success' >/dev/null" \
    "print_success executes without error"

assert_success "print_info 'test info' >/dev/null" \
    "print_info executes without error"

assert_success "print_warning 'test warning' >/dev/null" \
    "print_warning executes without error"

assert_success "print_header 'test header' >/dev/null" \
    "print_header executes without error"

# Test that output contains the message
output=$(print_success "hello world" 2>&1)
assert_contains "$output" "hello world" \
    "print_success outputs the message"

# ============================================================================
# Test: Color Constants
# ============================================================================

test_suite "Color Constants"

assert_not_empty "$CAUSELY_RED" \
    "CAUSELY_RED is defined"

assert_not_empty "$CAUSELY_GREEN" \
    "CAUSELY_GREEN is defined"

assert_not_empty "$CAUSELY_BLUE" \
    "CAUSELY_BLUE is defined"

assert_not_empty "$CAUSELY_YELLOW" \
    "CAUSELY_YELLOW is defined"

assert_not_empty "$CAUSELY_NC" \
    "CAUSELY_NC is defined"

# ============================================================================
# Test: Include Guard
# ============================================================================

test_suite "Include Guard"

# Source the file again - should be fast due to include guard
assert_success ". '$SCRIPT_DIR/lib/causely_common.sh'" \
    "Include guard prevents double-sourcing"

assert_equals "1" "$CAUSELY_COMMON_LOADED" \
    "Include guard variable is set"

# ============================================================================
# Summary
# ============================================================================

test_summary

