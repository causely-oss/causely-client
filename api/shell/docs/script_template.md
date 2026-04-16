#!/bin/sh
#
# <This script does X>
#
# Usage:
#   ./<script-name>.sh [OPTIONS]
#
# Required Arguments:
#   -f, --foo <FOO>              <description>
#
# Optional Options:
#   -s, --start-time TIME        Start time (RFC3339: YYYY-MM-DDTHH:MM:SSZ)
#   -h, --help                   Show help message
#
# Authentication:
#   Set environment variables: FRONTEGG_CLIENT_ID, FRONTEGG_CLIENT_SECRET
#   Or provide: -t/--token
#
# Dependencies:
#  - `lib` (causely shell)
#  - `jq`
#  - `curl`

set -e  # Exit on error

# Source libraries
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/lib/causely_common.sh"
. "$SCRIPT_DIR/lib/causely_auth.sh"
. "$SCRIPT_DIR/lib/causely_graphql.sh"

prevent_sourcing "create_snapshot.sh" || exit 1
check_dependencies jq curl || exit 1

# ============================================================================
# Help & Usage
# ============================================================================

show_usage() {
cat << EOF
Usage: $0 [OPTIONS]

Required Options:
-f, --foo FOO              <description>

Optional Options:
-s, --start-time TIME        Start time (RFC3339 format: YYYY-MM-DDTHH:MM:SSZ)
Defaults to 2 hours before end-time
-h, --help                   Show this help message

Authentication (choose one method):

Method 1: Frontegg (recommended for CI/CD)
Set environment variables:
FRONTEGG_CLIENT_ID       Frontegg client ID
FRONTEGG_CLIENT_SECRET   Frontegg client secret

Method 2: Direct token
-t, --token TOKEN          JWT authentication token
-u, --api-url URL          API endpoint URL (default: https://api.causely.app/query)

Examples:

# Using Frontegg authentication with explicit start time
export FRONTEGG_CLIENT_ID="your-client-id"
export FRONTEGG_CLIENT_SECRET="your-secret"
$0 \\
--foo "Some Value" \\
--start-time "\$(date -u -v-2H +\"%Y-%m-%dT%H:%M:%SZ\")" 


EOF
exit "${1:-1}"
}

# ============================================================================
# Argument Parsing
# ============================================================================

FOO=""

while [ $# -gt 0 ]; do
case "$1" in
-n|--name) NAME="$2"; shift 2 ;;
-s|--start-time) START_TIME="$2"; shift 2 ;;
-u|--api-url) API_URL="$2"; shift 2 ;;
-t|--token) TOKEN="$2"; shift 2 ;;
-h|--help) show_usage 0 ;;
*)
print_error "Unknown option: $1"
show_usage 1
;;
esac
done

# ============================================================================
# Validation & Authentication
# ============================================================================

# Validate required arguments
validate_required "foo" "$FOO" || show_usage 1

# Set up authentication
if [ -n "$FRONTEGG_CLIENT_ID" ] && [ -n "$FRONTEGG_CLIENT_SECRET" ]; then
if [ -n "$TOKEN" ]; then
print_warning "Warning: --token ignored when using Frontegg authentication"
fi
# API_URL can be overridden via --api-url or APP_BASE_URL env var
setup_causely_auth || exit 1
elif [ -n "$TOKEN" ]; then
print_info "Using direct token authentication"
print_info "API URL: $API_URL"
else
print_error "Error: No authentication method provided"
echo ""
echo "Either set FRONTEGG_CLIENT_ID and FRONTEGG_CLIENT_SECRET environment variables,"
echo "or provide --token argument (API URL defaults to production)."
show_usage 1
fi

# ============================================================================
# Build GraphQL Mutation & Variables
# ============================================================================

# The mutation
# NOTE: ignore shellcheck2016 - using single quotes to prevent bash expansion
MUTATION='mutation CreateSnapshot($options: SnapshotOptionsInput!) {
createSnapshot(options: $options) {
id
name
description
createdAt
startTime
endTime
}
}'

# Build base variables (start with required fields)
VARS=$(jq -n \
--arg name "$NAME" \
'{options: {name: $name}')

# Add optional time fields if provided
if [ -n "$START_TIME" ]; then
VARS=$(echo "$VARS" | jq --arg startTime "$START_TIME" '.options.startTime = $startTime')
fi

# ============================================================================
# Execute Request
# ============================================================================

print_header "Doing Foo: $FOO"

# Execute GraphQL request (exit on failure)
if ! RESPONSE=$(execute_graphql "$API_URL" "$TOKEN" "$MUTATION" "$VARS"); then
exit 1
fi

# Extract and display result (exit on failure)
if ! RESULT=$(extract_graphql_data "$RESPONSE" ".data.foo"); then
exit 1
fi
