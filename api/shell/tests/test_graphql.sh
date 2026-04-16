#!/bin/sh
#
# Tests for causely_graphql.sh
#

set -e

# Setup paths
SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
. "$SCRIPT_DIR/tests/test_framework.sh"
. "$SCRIPT_DIR/lib/causely_common.sh"
. "$SCRIPT_DIR/lib/causely_graphql.sh"

# ============================================================================
# Test: build_graphql_payload
# ============================================================================

test_suite "build_graphql_payload"

# Test simple query without variables
payload=$(build_graphql_payload "query { test }")
assert_success "echo '$payload' | jq -e '.query' >/dev/null" \
    "Builds payload with query field"

assert_contains "$payload" "query { test }" \
    "Payload contains the query string"

# Test query with variables
payload=$(build_graphql_payload "query { test }" '{"key": "value"}')
assert_success "echo '$payload' | jq -e '.variables' >/dev/null" \
    "Builds payload with variables field"

assert_success "echo '$payload' | jq -e '.variables.key' >/dev/null" \
    "Payload variables are valid JSON"

# Test that missing query fails
assert_failure "build_graphql_payload '' 2>/dev/null" \
    "Fails when query is empty"

# ============================================================================
# Test: build_jq_object
# ============================================================================

test_suite "build_jq_object"

result=$(build_jq_object --arg name "test" --arg value "123" '{name: $name, value: $value}')

assert_success "echo '$result' | jq -e '.name' >/dev/null" \
    "Builds valid JSON object"

name_value=$(echo "$result" | jq -r '.name')
assert_equals "test" "$name_value" \
    "Object contains correct name value"

value_value=$(echo "$result" | jq -r '.value')
assert_equals "123" "$value_value" \
    "Object contains correct value"

# ============================================================================
# Test: build_key_value_pair
# ============================================================================

test_suite "build_key_value_pair"

result=$(build_key_value_pair "environment" "production")

assert_success "echo '$result' | jq -e '.key' >/dev/null" \
    "Creates object with key field"

assert_success "echo '$result' | jq -e '.value' >/dev/null" \
    "Creates object with value field"

key=$(echo "$result" | jq -r '.key')
assert_equals "environment" "$key" \
    "Key field has correct value"

value=$(echo "$result" | jq -r '.value')
assert_equals "production" "$value" \
    "Value field has correct value"

# ============================================================================
# Test: build_tags_array
# ============================================================================

test_suite "build_tags_array"

# Create tags input (newline-separated)
tags_input="env=prod
version=1.2.3
region=us-west-2"

result=$(echo "$tags_input" | build_tags_array)

assert_success "echo '$result' | jq -e '.' >/dev/null" \
    "Builds valid JSON array"

count=$(echo "$result" | jq 'length')
assert_equals "3" "$count" \
    "Array has correct number of elements"

first_key=$(echo "$result" | jq -r '.[0].key')
assert_equals "env" "$first_key" \
    "First tag has correct key"

first_value=$(echo "$result" | jq -r '.[0].value')
assert_equals "prod" "$first_value" \
    "First tag has correct value"

# Test empty input
result=$(echo "" | build_tags_array)
assert_equals "[]" "$result" \
    "Empty input produces empty array"

# ============================================================================
# Test: build_time_filter
# ============================================================================

test_suite "build_time_filter"

# Test with both start and end
result=$(build_time_filter "2025-01-01T00:00:00Z" "2025-01-01T01:00:00Z")
assert_success "echo '$result' | jq -e '.from' >/dev/null" \
    "Time filter includes 'from' field"

assert_success "echo '$result' | jq -e '.to' >/dev/null" \
    "Time filter includes 'to' field"

# Test with only start
result=$(build_time_filter "2025-01-01T00:00:00Z" "")
assert_success "echo '$result' | jq -e '.from' >/dev/null" \
    "Time filter with only start includes 'from'"

assert_failure "echo '$result' | jq -e '.to' >/dev/null 2>&1" \
    "Time filter with only start excludes 'to'"

# Test with only end
result=$(build_time_filter "" "2025-01-01T01:00:00Z")
assert_success "echo '$result' | jq -e '.to' >/dev/null" \
    "Time filter with only end includes 'to'"

assert_failure "echo '$result' | jq -e '.from' >/dev/null 2>&1" \
    "Time filter with only end excludes 'from'"

# Test with neither (should return null)
result=$(build_time_filter "" "")
assert_equals "null" "$result" \
    "Empty time filter returns null"

# ============================================================================
# Test: extract_graphql_data
# ============================================================================

test_suite "extract_graphql_data"

# Create a mock response
mock_response='{"data":{"user":{"id":"123","name":"Test User"}}}'

result=$(extract_graphql_data "$mock_response" ".data.user.id")
id_value=$(echo "$result" | jq -r '.')
assert_equals "123" "$id_value" \
    "Extracts nested data correctly"

result=$(extract_graphql_data "$mock_response" ".data.user")
assert_success "echo '$result' | jq -e '.name' >/dev/null" \
    "Extracts object data"

# Test with missing path
assert_failure "extract_graphql_data '$mock_response' '.data.nonexistent' 2>/dev/null" \
    "Fails when data path doesn't exist"

# ============================================================================
# Test: has_graphql_errors
# ============================================================================

test_suite "has_graphql_errors"

# Response with errors
error_response='{"errors":[{"message":"Something went wrong"}]}'
assert_success "has_graphql_errors '$error_response'" \
    "Detects GraphQL errors"

# Response without errors
success_response='{"data":{"result":"success"}}'
assert_failure "has_graphql_errors '$success_response'" \
    "Returns false when no errors present"

# ============================================================================
# Test: validate_required
# ============================================================================

test_suite "validate_required"

assert_success "validate_required 'test_field' 'some_value' 2>/dev/null" \
    "Succeeds when value is provided"

assert_failure "validate_required 'test_field' '' 2>/dev/null" \
    "Fails when value is empty"

# ============================================================================
# Test: validate_env_vars
# ============================================================================

test_suite "validate_env_vars"

# Set test variables
TEST_VAR_1="value1"
TEST_VAR_2="value2"

assert_success "validate_env_vars TEST_VAR_1 TEST_VAR_2 2>/dev/null" \
    "Succeeds when all variables are set"

assert_failure "validate_env_vars TEST_VAR_1 MISSING_VAR_12345 2>/dev/null" \
    "Fails when a variable is missing"

# ============================================================================
# Test: now_rfc3339
# ============================================================================

test_suite "Time Utilities"

result=$(now_rfc3339)
assert_not_empty "$result" \
    "now_rfc3339 returns a value"

# Check format (should be ISO 8601 / RFC3339)
assert_contains "$result" "T" \
    "Timestamp contains 'T' separator"

assert_contains "$result" "Z" \
    "Timestamp contains 'Z' (UTC indicator)"

# ============================================================================
# Test: Include Guard
# ============================================================================

test_suite "Include Guard"

# Source the file again - should be fast due to include guard
assert_success ". '$SCRIPT_DIR/lib/causely_graphql.sh'" \
    "Include guard prevents double-sourcing"

assert_equals "1" "$CAUSELY_GRAPHQL_LOADED" \
    "Include guard variable is set"

# ============================================================================
# Summary
# ============================================================================

test_summary

