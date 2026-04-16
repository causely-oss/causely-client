#!/bin/sh
#
# Create a Causely Snapshot
#
# Usage:
#   ./create_snapshot.sh [OPTIONS]
#
# Required Arguments:
#   -n, --name NAME              Snapshot name
#   -d, --description DESC       Snapshot description
#
# Optional Options:
#   -s, --start-time TIME        Start time (RFC3339: YYYY-MM-DDTHH:MM:SSZ)
#                                Defaults to 2 hours before end-time
#   -e, --end-time TIME          End time (RFC3339: YYYY-MM-DDTHH:MM:SSZ)
#                                Defaults to now
#   --tag KEY=VALUE              Add a tag (repeatable)
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
  -n, --name NAME              Snapshot name
  -d, --description DESC       Snapshot description

Optional Options:
  -s, --start-time TIME        Start time (RFC3339 format: YYYY-MM-DDTHH:MM:SSZ)
                               Defaults to 2 hours before end-time
  -e, --end-time TIME          End time (RFC3339 format: YYYY-MM-DDTHH:MM:SSZ)
                               Defaults to now
  --tag KEY=VALUE              Add a tag (can be specified multiple times)
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
    --name "Production Baseline" \\
    --description "Baseline snapshot before deployment" \\
    --start-time "\$(date -u -v-2H +\"%Y-%m-%dT%H:%M:%SZ\")" \\
    --tag "environment=production" \\
    --tag "version=1.2.3"

  # Let backend default times (captures last 2 hours from now)
  $0 \\
    --name "Quick Snapshot" \\
    --description "Snapshot with default time range"

  # Specify only end time (start will be 2 hours before end)
  $0 \\
    --name "Historical Snapshot" \\
    --description "Specific time range" \\
    --end-time "2025-01-01T12:00:00Z"

EOF
    exit "${1:-1}"
}

# ============================================================================
# Argument Parsing
# ============================================================================

NAME=""
DESCRIPTION=""
START_TIME=""
END_TIME=""
API_URL="$CAUSELY_API_URL_DEFAULT"
TOKEN=""
TAGS=""  # Newline-separated list

# Tag separator (newline) for accumulation - used by build_tags_array
# Using literal newline because $(printf '\n') loses the newline in command substitution
TAG_SEPARATOR='
' ## <---- Intentionally separated to newline!

while [ $# -gt 0 ]; do
    case "$1" in
        -n|--name) NAME="$2"; shift 2 ;;
        -d|--description) DESCRIPTION="$2"; shift 2 ;;
        -s|--start-time) START_TIME="$2"; shift 2 ;;
        -e|--end-time) END_TIME="$2"; shift 2 ;;
        --tag)
            if ! echo "$2" | grep -q '^[^=]\+=.\+$'; then
                print_error "Invalid tag format: $2 (expected KEY=VALUE)"
                show_usage 1
            fi
            # Append tag with separator (skip separator if TAGS is empty)
            if [ -z "$TAGS" ]; then
                TAGS="$2"
            else
                TAGS="${TAGS}${TAG_SEPARATOR}$2"
            fi
            shift 2
            ;;
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
validate_required "name" "$NAME" || show_usage 1
validate_required "description" "$DESCRIPTION" || show_usage 1

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
    --arg description "$DESCRIPTION" \
    '{options: {name: $name, description: $description}}')

# Add optional time fields if provided
if [ -n "$START_TIME" ]; then
    VARS=$(echo "$VARS" | jq --arg startTime "$START_TIME" '.options.startTime = $startTime')
fi

if [ -n "$END_TIME" ]; then
    VARS=$(echo "$VARS" | jq --arg endTime "$END_TIME" '.options.endTime = $endTime')
fi

# Add tags if provided
if [ -n "$TAGS" ]; then
    TAGS_JSON=$(echo "$TAGS" | build_tags_array)
    VARS=$(echo "$VARS" | jq --argjson tags "$TAGS_JSON" '.options.tags = $tags')
fi

# ============================================================================
# Execute Request
# ============================================================================

print_header "Creating Snapshot: $NAME"

# Execute GraphQL request (exit on failure)
if ! RESPONSE=$(execute_graphql "$API_URL" "$TOKEN" "$MUTATION" "$VARS"); then
    exit 1
fi

# Extract and display result (exit on failure)
if ! SNAPSHOT=$(extract_graphql_data "$RESPONSE" ".data.createSnapshot"); then
    exit 1
fi

print_success "✅ Snapshot created successfully!"
echo ""
echo "$SNAPSHOT" | jq '.'

SNAPSHOT_ID=$(echo "$SNAPSHOT" | jq -r '.id')
echo ""
print_success "Snapshot ID: $SNAPSHOT_ID"
