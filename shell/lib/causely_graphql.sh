#!/bin/sh
#
# Causely GraphQL Library
#
# POSIX-compliant library for GraphQL API operations
# This file is meant to be SOURCED by other scripts, not executed directly.
#
# Usage:
#   . "$(dirname "$0")/lib/causely_graphql.sh"
#
# Provides functions for:
#   - Building GraphQL requests
#   - Executing GraphQL queries and mutations
#   - Handling responses and errors
#   - Building variables with jq
#

# Prevent script from being executed directly
if [ "${0##*/}" = "causely_graphql.sh" ]; then
    echo "Error: This file is a library and should be sourced, not executed directly." >&2
    echo "Usage: . \$(dirname \"\$0\")/lib/causely_graphql.sh" >&2
    exit 1
fi

# Include guard
if [ -n "$CAUSELY_GRAPHQL_LOADED" ]; then
    return 0
fi
CAUSELY_GRAPHQL_LOADED=1

# Source dependencies
_causely_lib_dir="${SCRIPT_DIR:-.}/lib"
. "$_causely_lib_dir/causely_common.sh"

# ============================================================================
# GraphQL Request Building
# ============================================================================

# Build a GraphQL request payload
# Arguments:
#   $1 - GraphQL query/mutation string
#   $2 - Variables JSON string
# Returns:
#   Prints complete request payload JSON to stdout
build_graphql_payload() {
    _query="$1"
    _variables="$2"
    
    if [ -z "$_query" ]; then
        print_error "build_graphql_payload: query is required"
        return 1
    fi
    
    if [ -z "$_variables" ]; then
        # No variables - simple payload
        jq -n --arg query "$_query" '{query: $query}'
    else
        # With variables
        jq -n \
            --arg query "$_query" \
            --argjson variables "$_variables" \
            '{query: $query, variables: $variables}'
    fi
}

# ============================================================================
# GraphQL Request Execution
# ============================================================================

# Execute a GraphQL request
# Arguments:
#   $1 - API URL
#   $2 - Auth token
#   $3 - Request payload (JSON)
# Returns:
#   Prints response JSON to stdout
#   Returns 0 on success, 1 on failure
execute_graphql_request() {
    _api_url="$1"
    _token="$2"
    _payload="$3"
    
    if [ -z "$_api_url" ] || [ -z "$_token" ] || [ -z "$_payload" ]; then
        print_error "execute_graphql_request: all arguments required (url, token, payload)"
        return 1
    fi
    
    curl -sS -X POST "$_api_url" \
        -H "Authorization: Bearer $_token" \
        -H "Content-Type: application/json" \
        -d "$_payload"
}

# Execute a GraphQL query with error handling
# Arguments:
#   $1 - API URL
#   $2 - Auth token
#   $3 - GraphQL query/mutation string
#   $4 - Variables JSON (optional)
# Returns:
#   Prints response data to stdout
#   Exits with code 1 on error
execute_graphql() {
    _api_url="$1"
    _token="$2"
    _query="$3"
    _variables="${4:-}"
    
    # Build payload
    _payload=$(build_graphql_payload "$_query" "$_variables")
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    # Execute request
    _response=$(execute_graphql_request "$_api_url" "$_token" "$_payload")
    if [ $? -ne 0 ]; then
        print_error "Request failed"
        return 1
    fi
    
    # Check for GraphQL errors
    if echo "$_response" | jq -e '.errors' > /dev/null 2>&1; then
        print_error "GraphQL Error:"
        echo "$_response" | jq '.errors' >&2
        return 1
    fi
    
    # Return full response
    echo "$_response"
    return 0
}

# ============================================================================
# Response Parsing & Validation
# ============================================================================

# Extract data from GraphQL response
# Arguments:
#   $1 - Response JSON
#   $2 - Data path (e.g., ".data.createSnapshot")
# Returns:
#   Prints extracted data to stdout
#   Returns 1 if path doesn't exist
extract_graphql_data() {
    _response="$1"
    _path="$2"
    
    if [ -z "$_response" ] || [ -z "$_path" ]; then
        print_error "extract_graphql_data: response and path required"
        return 1
    fi
    
    if ! echo "$_response" | jq -e "$_path" > /dev/null 2>&1; then
        print_error "Expected data path not found: $_path"
        echo "Response: $_response" >&2
        return 1
    fi
    
    echo "$_response" | jq "$_path"
}

# Check if GraphQL response has errors
# Arguments:
#   $1 - Response JSON
# Returns:
#   0 if errors exist, 1 if no errors
has_graphql_errors() {
    _response="$1"
    echo "$_response" | jq -e '.errors' > /dev/null 2>&1
}

# ============================================================================
# Variable Building Helpers
# ============================================================================

# Build a simple variables object with jq
# Usage: build_variables --arg name value --arg name2 value2 --filter '{key: $name}'
# This is a wrapper around jq -n that makes it easier to build variables
#
# Example:
#   vars=$(build_jq_object \
#     --arg name "Test" \
#     --arg desc "Description" \
#     '{name: $name, description: $desc}')
build_jq_object() {
    jq -n "$@"
}

# Build an array from newline-separated values
# Arguments:
#   stdin - newline-separated values
# Returns:
#   JSON array
build_json_array() {
    jq -R . | jq -s .
}

# Build key-value pair object
# Arguments:
#   $1 - key
#   $2 - value
# Returns:
#   JSON object: {key: "key", value: "value"}
build_key_value_pair() {
    _key="$1"
    _value="$2"
    jq -n --arg k "$_key" --arg v "$_value" '{key: $k, value: $v}'
}

# Build tags array from newline-separated KEY=VALUE strings
# Arguments:
#   stdin - newline-separated KEY=VALUE strings
# Returns:
#   JSON array of {key, value} objects
build_tags_array() {
    while IFS= read -r tag; do
        if [ -n "$tag" ]; then
            key=$(echo "$tag" | cut -d= -f1)
            value=$(echo "$tag" | cut -d= -f2-)
            build_key_value_pair "$key" "$value"
        fi
    done | jq -s '.'
}

# ============================================================================
# Common Variable Builders
# ============================================================================

# Build time filter variables
# Arguments:
#   $1 - start time (optional)
#   $2 - end time (optional)
# Returns:
#   JSON timeFilter object (empty if no times provided)
build_time_filter() {
    _start="$1"
    _end="$2"
    
    if [ -z "$_start" ] && [ -z "$_end" ]; then
        echo "null"
        return 0
    fi
    
    if [ -n "$_start" ] && [ -n "$_end" ]; then
        jq -n --arg start "$_start" --arg end "$_end" \
            '. + {"from": $start, "to": $end}'
    elif [ -n "$_start" ]; then
        jq -n --arg start "$_start" '. + {"from": $start}'
    else
        jq -n --arg end "$_end" '. + {"to": $end}'
    fi
}

# Build pagination variables
# Arguments:
#   $1 - first (optional)
#   $2 - after (optional)
#   $3 - last (optional)
#   $4 - before (optional)
# Returns:
#   JSON object with pagination fields
build_pagination_vars() {
    _first="$1"
    _after="$2"
    _last="$3"
    _before="$4"
    
    _filter='{}'
    
    if [ -n "$_first" ]; then
        _filter=$(echo "$_filter" | jq --argjson first "$_first" '. + {first: $first}')
    fi
    if [ -n "$_after" ]; then
        _filter=$(echo "$_filter" | jq --arg after "$_after" '. + {after: $after}')
    fi
    if [ -n "$_last" ]; then
        _filter=$(echo "$_filter" | jq --argjson last "$_last" '. + {last: $last}')
    fi
    if [ -n "$_before" ]; then
        _filter=$(echo "$_filter" | jq --arg before "$_before" '. + {before: $before}')
    fi
    
    echo "$_filter"
}

# ============================================================================
# Mutation Helpers
# ============================================================================

# Execute a mutation and return the ID of the created/updated object
# Arguments:
#   $1 - API URL
#   $2 - Auth token
#   $3 - GraphQL mutation
#   $4 - Variables JSON
#   $5 - Data path (e.g., "data.createSnapshot")
# Returns:
#   Prints the created object's ID
execute_mutation_get_id() {
    _api_url="$1"
    _token="$2"
    _mutation="$3"
    _variables="$4"
    _data_path="$5"
    
    _response=$(execute_graphql "$_api_url" "$_token" "$_mutation" "$_variables")
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    _data=$(extract_graphql_data "$_response" ".$_data_path")
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    echo "$_data" | jq -r '.id'
}

# ============================================================================
# Query Helpers
# ============================================================================

# Execute a query with pagination
# Arguments:
#   $1 - API URL
#   $2 - Auth token
#   $3 - GraphQL query
#   $4 - Base variables JSON (without pagination)
#   $5 - first/limit
#   $6 - after cursor (optional)
# Returns:
#   Response data
execute_paginated_query() {
    _api_url="$1"
    _token="$2"
    _query="$3"
    _base_vars="$4"
    _first="$5"
    _after="${6:-}"
    
    # Merge base variables with pagination
    if [ -n "$_after" ]; then
        _variables=$(echo "$_base_vars" | jq \
            --argjson first "$_first" \
            --arg after "$_after" \
            '. + {first: $first, after: $after}')
    else
        _variables=$(echo "$_base_vars" | jq \
            --argjson first "$_first" \
            '. + {first: $first}')
    fi
    
    execute_graphql "$_api_url" "$_token" "$_query" "$_variables"
}

# ============================================================================
# Validation Helpers
# ============================================================================

# Validate required environment variables are set
# Arguments:
#   $@ - Variable names to check
# Returns:
#   0 if all set, 1 if any missing
validate_env_vars() {
    _missing=""
    
    for _var in "$@"; do
        eval _value=\$$_var
        if [ -z "$_value" ]; then
            _missing="$_missing $_var"
        fi
    done
    
    if [ -n "$_missing" ]; then
        print_error "Missing required environment variables:$_missing"
        return 1
    fi
    
    return 0
}

# Validate required arguments are provided
# Arguments:
#   $1 - argument name
#   $2 - argument value
# Returns:
#   0 if value is set, 1 if empty
validate_required() {
    _name="$1"
    _value="$2"
    
    if [ -z "$_value" ]; then
        print_error "Missing required argument: $_name"
        return 1
    fi
    return 0
}

# ============================================================================
# Utility Functions
# ============================================================================

# Format timestamp to RFC3339
# Arguments:
#   $1 - timestamp (if empty, uses current time)
# Returns:
#   RFC3339 formatted timestamp
format_rfc3339() {
    _time="${1:-now}"
    
    if [ "$_time" = "now" ]; then
        date -u +"%Y-%m-%dT%H:%M:%SZ"
    else
        # Pass through - assume already formatted
        echo "$_time"
    fi
}

# Get current timestamp in RFC3339 format
now_rfc3339() {
    date -u +"%Y-%m-%dT%H:%M:%SZ"
}

# Calculate time offset (e.g., 2 hours ago)
# Arguments:
#   $1 - offset (e.g., "-2H", "-1d")
# Returns:
#   RFC3339 formatted timestamp
# Note: Uses GNU date or BSD date syntax
time_offset() {
    _offset="$1"
    
    # Try GNU date first (Linux)
    if date --version >/dev/null 2>&1; then
        date -u -d "$_offset" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null && return 0
    fi
    
    # Fall back to BSD date (macOS)
    date -u -v"$_offset" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null && return 0
    
    print_error "Failed to calculate time offset: $_offset"
    return 1
}

