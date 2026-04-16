#!/bin/sh
#
# Tests for create_snapshot.sh
#
# Note: These tests focus on argument parsing, validation, and error handling
# without making real API calls.
#

set -e

# Setup paths
SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
. "$SCRIPT_DIR/tests/test_framework.sh"

SCRIPT_PATH="$SCRIPT_DIR/create_snapshot.sh"

# ============================================================================
# Test: Script Exists and is Executable
# ============================================================================

test_suite "Script Validation"

assert_success "[ -f '$SCRIPT_PATH' ]" \
    "create_snapshot.sh exists"

assert_success "[ -x '$SCRIPT_PATH' ]" \
    "create_snapshot.sh is executable"

# ============================================================================
# Test: Help Message
# ============================================================================

test_suite "Help Message"

output=$(sh "$SCRIPT_PATH" --help 2>&1)

assert_contains "$output" "Usage:" \
    "Help message contains usage"

assert_contains "$output" "Required Options" \
    "Help message contains required options section"

assert_contains "$output" "name NAME" \
    "Help message mentions --name option"

assert_contains "$output" "description DESC" \
    "Help message mentions --description option"

assert_contains "$output" "Frontegg" \
    "Help message mentions Frontegg authentication"

assert_contains "$output" "api.causely.app" \
    "Help message shows default API URL"

# ============================================================================
# Test: Required Arguments Validation
# ============================================================================

test_suite "Required Arguments Validation"

# Test missing name
output=$(sh "$SCRIPT_PATH" --description "Test" 2>&1 || true)
assert_contains "$output" "name" \
    "Fails when --name is missing"

# Test missing description
output=$(sh "$SCRIPT_PATH" --name "Test" 2>&1 || true)
assert_contains "$output" "description" \
    "Fails when --description is missing"

# ============================================================================
# Test: Authentication Validation
# ============================================================================

test_suite "Authentication Validation"

# Test missing authentication
output=$(sh "$SCRIPT_PATH" --name "Test" --description "Desc" 2>&1 || true)
assert_contains "$output" "authentication" \
    "Fails when no authentication is provided"

# ============================================================================
# Test: Tag Format Validation
# ============================================================================

test_suite "Tag Format Validation"

# Test invalid tag format (missing =)
output=$(sh "$SCRIPT_PATH" \
    --name "Test" \
    --description "Desc" \
    --tag "invalidtag" \
    2>&1 || true)
assert_contains "$output" "Invalid tag format" \
    "Fails with invalid tag format (no equals sign)"

# Test invalid tag format (no value)
output=$(sh "$SCRIPT_PATH" \
    --name "Test" \
    --description "Desc" \
    --tag "key=" \
    2>&1 || true)
assert_contains "$output" "Invalid tag format" \
    "Fails with invalid tag format (no value)"

# Test invalid tag format (no key)
output=$(sh "$SCRIPT_PATH" \
    --name "Test" \
    --description "Desc" \
    --tag "=value" \
    2>&1 || true)
assert_contains "$output" "Invalid tag format" \
    "Fails with invalid tag format (no key)"

# ============================================================================
# Test: Unknown Options
# ============================================================================

test_suite "Unknown Options Handling"

output=$(sh "$SCRIPT_PATH" \
    --name "Test" \
    --description "Desc" \
    --unknown-option \
    2>&1 || true)
assert_contains "$output" "Unknown option" \
    "Fails with unknown option"

# ============================================================================
# Test: API URL Default
# ============================================================================

test_suite "API URL Default"

# Source the libraries to check the constant
. "$SCRIPT_DIR/lib/causely_common.sh"

assert_not_empty "$CAUSELY_API_URL_DEFAULT" \
    "CAUSELY_API_URL_DEFAULT constant is set"

assert_contains "$CAUSELY_API_URL_DEFAULT" "causely.app" \
    "Default API URL points to causely.app"

# ============================================================================
# Test: Script Structure
# ============================================================================

test_suite "Script Structure"

# Check for proper shebang
first_line=$(head -n 1 "$SCRIPT_PATH")
assert_contains "$first_line" "#!/bin/sh" \
    "Script has POSIX shell shebang"

# Check for set -e (exit on error)
assert_success "grep -q 'set -e' '$SCRIPT_PATH'" \
    "Script uses 'set -e' for error handling"

# Check for library sourcing
assert_success "grep -q 'causely_common.sh' '$SCRIPT_PATH'" \
    "Script sources causely_common.sh"

assert_success "grep -q 'causely_auth.sh' '$SCRIPT_PATH'" \
    "Script sources causely_auth.sh"

assert_success "grep -q 'causely_graphql.sh' '$SCRIPT_PATH'" \
    "Script sources causely_graphql.sh"

# Check for dependency checking
assert_success "grep -q 'check_dependencies' '$SCRIPT_PATH'" \
    "Script checks dependencies"

# Check for source protection
assert_success "grep -q 'prevent_sourcing' '$SCRIPT_PATH'" \
    "Script prevents sourcing"

# ============================================================================
# Test: GraphQL Mutation
# ============================================================================

test_suite "GraphQL Mutation"

# Check that the mutation is properly defined
assert_success "grep -q 'mutation CreateSnapshot' '$SCRIPT_PATH'" \
    "Script contains CreateSnapshot mutation"

assert_success "grep -q 'SnapshotOptionsInput' '$SCRIPT_PATH'" \
    "Script uses correct input type"

# Check that required fields are queried
assert_success "grep -q 'id' '$SCRIPT_PATH'" \
    "Mutation queries snapshot id"

assert_success "grep -q 'name' '$SCRIPT_PATH'" \
    "Mutation queries snapshot name"

# ============================================================================
# Test: Documentation
# ============================================================================

test_suite "Documentation"

# Check for proper comments at top of file
assert_success "head -n 10 '$SCRIPT_PATH' | grep -q 'Create a Causely Snapshot'" \
    "Script has descriptive header comment"

assert_success "head -n 30 '$SCRIPT_PATH' | grep -q 'Usage:'" \
    "Script has usage documentation in comments"

# ============================================================================
# Summary
# ============================================================================

test_summary

