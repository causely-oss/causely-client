#!/bin/sh
#
# Simple Test Framework for Shell Scripts
#
# POSIX-compliant testing framework with minimal dependencies
# Usage: Source this file in test scripts
#

# Prevent direct execution
if [ "${0##*/}" = "test_framework.sh" ]; then
    echo "Error: This file should be sourced, not executed." >&2
    exit 1
fi

# ============================================================================
# Test State
# ============================================================================

TEST_COUNT=0
TEST_PASS=0
TEST_FAIL=0
CURRENT_SUITE=""

# ============================================================================
# Output Formatting
# ============================================================================

# Colors
if [ -t 1 ]; then
    TEST_GREEN='\033[0;32m'
    TEST_RED='\033[0;31m'
    TEST_BLUE='\033[0;34m'
    TEST_YELLOW='\033[1;33m'
    TEST_NC='\033[0m'
else
    TEST_GREEN=''
    TEST_RED=''
    TEST_BLUE=''
    TEST_YELLOW=''
    TEST_NC=''
fi

# ============================================================================
# Test Suite Management
# ============================================================================

# Start a test suite
# Arguments: $1 - suite name
test_suite() {
    CURRENT_SUITE="$1"
    echo ""
    printf '%b\n' "${TEST_BLUE}=== $CURRENT_SUITE ===${TEST_NC}"
}

# ============================================================================
# Assertions
# ============================================================================

# Assert that a command succeeds
# Arguments: $1 - command to run, $2 - test description
assert_success() {
    _cmd="$1"
    _desc="$2"
    TEST_COUNT=$((TEST_COUNT + 1))
    
    if eval "$_cmd" >/dev/null 2>&1; then
        TEST_PASS=$((TEST_PASS + 1))
        printf '%b\n' "${TEST_GREEN}  ✓ $_desc${TEST_NC}"
        return 0
    else
        TEST_FAIL=$((TEST_FAIL + 1))
        printf '%b\n' "${TEST_RED}  ✗ $_desc${TEST_NC}"
        return 1
    fi
}

# Assert that a command fails
# Arguments: $1 - command to run, $2 - test description
assert_failure() {
    _cmd="$1"
    _desc="$2"
    TEST_COUNT=$((TEST_COUNT + 1))
    
    if eval "$_cmd" >/dev/null 2>&1; then
        TEST_FAIL=$((TEST_FAIL + 1))
        printf '%b\n' "${TEST_RED}  ✗ $_desc (expected failure)${TEST_NC}"
        return 1
    else
        TEST_PASS=$((TEST_PASS + 1))
        printf '%b\n' "${TEST_GREEN}  ✓ $_desc${TEST_NC}"
        return 0
    fi
}

# Assert that two strings are equal
# Arguments: $1 - expected, $2 - actual, $3 - test description
assert_equals() {
    _expected="$1"
    _actual="$2"
    _desc="$3"
    TEST_COUNT=$((TEST_COUNT + 1))
    
    if [ "$_expected" = "$_actual" ]; then
        TEST_PASS=$((TEST_PASS + 1))
        printf '%b\n' "${TEST_GREEN}  ✓ $_desc${TEST_NC}"
        return 0
    else
        TEST_FAIL=$((TEST_FAIL + 1))
        printf '%b\n' "${TEST_RED}  ✗ $_desc${TEST_NC}"
        printf '    Expected: %s\n' "$_expected"
        printf '    Actual:   %s\n' "$_actual"
        return 1
    fi
}

# Assert that a string contains a substring
# Arguments: $1 - haystack, $2 - needle, $3 - test description
assert_contains() {
    _haystack="$1"
    _needle="$2"
    _desc="$3"
    TEST_COUNT=$((TEST_COUNT + 1))
    
    if echo "$_haystack" | grep -q "$_needle"; then
        TEST_PASS=$((TEST_PASS + 1))
        printf '%b\n' "${TEST_GREEN}  ✓ $_desc${TEST_NC}"
        return 0
    else
        TEST_FAIL=$((TEST_FAIL + 1))
        printf '%b\n' "${TEST_RED}  ✗ $_desc${TEST_NC}"
        printf '    String does not contain: %s\n' "$_needle"
        return 1
    fi
}

# Assert that a variable is empty
# Arguments: $1 - variable value, $2 - test description
assert_empty() {
    _value="$1"
    _desc="$2"
    TEST_COUNT=$((TEST_COUNT + 1))
    
    if [ -z "$_value" ]; then
        TEST_PASS=$((TEST_PASS + 1))
        printf '%b\n' "${TEST_GREEN}  ✓ $_desc${TEST_NC}"
        return 0
    else
        TEST_FAIL=$((TEST_FAIL + 1))
        printf '%b\n' "${TEST_RED}  ✗ $_desc${TEST_NC}"
        printf '    Expected empty, got: %s\n' "$_value"
        return 1
    fi
}

# Assert that a variable is not empty
# Arguments: $1 - variable value, $2 - test description
assert_not_empty() {
    _value="$1"
    _desc="$2"
    TEST_COUNT=$((TEST_COUNT + 1))
    
    if [ -n "$_value" ]; then
        TEST_PASS=$((TEST_PASS + 1))
        printf '%b\n' "${TEST_GREEN}  ✓ $_desc${TEST_NC}"
        return 0
    else
        TEST_FAIL=$((TEST_FAIL + 1))
        printf '%b\n' "${TEST_RED}  ✗ $_desc${TEST_NC}"
        return 1
    fi
}

# ============================================================================
# Test Results
# ============================================================================

# Print test summary
test_summary() {
    echo ""
    echo "========================================"
    
    if [ $TEST_FAIL -eq 0 ]; then
        printf '%b\n' "${TEST_GREEN}All tests passed!${TEST_NC}"
    else
        printf '%b\n' "${TEST_RED}Some tests failed!${TEST_NC}"
    fi
    
    echo "Total:  $TEST_COUNT tests"
    printf '%b\n' "${TEST_GREEN}Passed: $TEST_PASS${TEST_NC}"
    
    if [ $TEST_FAIL -gt 0 ]; then
        printf '%b\n' "${TEST_RED}Failed: $TEST_FAIL${TEST_NC}"
    fi
    
    echo "========================================"
    
    # Return non-zero if any tests failed
    [ $TEST_FAIL -eq 0 ]
}

# ============================================================================
# Utility Functions
# ============================================================================

# Skip a test (counts as neither pass nor fail)
skip_test() {
    _desc="$1"
    printf '%b\n' "${TEST_YELLOW}  ⊘ $_desc (skipped)${TEST_NC}"
}

# Run a test with captured output
# Arguments: $1 - command, $2 - variable name for output
capture_output() {
    _cmd="$1"
    _output=$(eval "$_cmd" 2>&1)
    echo "$_output"
}

