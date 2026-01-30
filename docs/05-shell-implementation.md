# Shell/Bash Implementation

Complete guide to the Shell/Bash implementation of the Causely API Client. This is the most comprehensive and feature-rich implementation.

## Table of Contents

- [Overview](#overview)
- [Quick Start](#quick-start)
- [Library Structure](#library-structure)
- [Core Functions](#core-functions)
- [Snapshot Operations](#snapshot-operations)
- [Polling for Completion](#polling-for-completion)
- [Creating Custom Workflows](#creating-custom-workflows)
- [Scripts Reference](#scripts-reference)
- [Testing](#testing)

## Overview

The Shell/Bash implementation provides:

- **Reusable GraphQL Library** (`shell/lib/causely_graphql.sh`) - Helper functions for GraphQL operations
- **Authentication Library** (`shell/lib/causely_auth.sh`) - Frontegg OAuth support
- **Common Utilities** (`shell/lib/causely_common.sh`) - Colors, printing, validation
- **Production Scripts** - `create_snapshot.sh`, `compare_snapshots.sh`, `snapshot_workflow.sh`
- **POSIX-Compliant** - Works with sh, bash, zsh, dash, ash

## Quick Start

```bash
# 1. Set up authentication
export FRONTEGG_CLIENT_ID="your-client-id"
export FRONTEGG_CLIENT_SECRET="your-client-secret"

# 2. Create a snapshot
cd shell
./create_snapshot.sh \
  --name "My Snapshot" \
  --description "Test snapshot" \
  --start-time "$(date -u -d '2 hours ago' +'%Y-%m-%dT%H:%M:%SZ')"
```

## Library Structure

```
shell/lib/
├── causely_common.sh     # Colors, printing, utilities (136 lines)
├── causely_auth.sh       # Frontegg authentication (98 lines)
└── causely_graphql.sh   # GraphQL operations (447+ lines)
```

### Library Usage Patterns

**Pattern 1: Full Auth + Utilities (Recommended)**

```bash
#!/bin/sh
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/lib/causely_auth.sh"  # Includes common utilities

prevent_sourcing "my_script.sh" || exit 1

# Now you have access to:
# - setup_causely_auth()
# - print_error(), print_success(), etc.
# - Color variables
```

**Pattern 2: GraphQL Library**

```bash
#!/bin/sh
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/lib/causely_graphql.sh"  # Includes auth and common

setup_causely_auth || exit 1

# Now you have access to:
# - execute_graphql()
# - extract_graphql_data()
# - poll_snapshot_status()
# - All helper functions
```

## Core Functions

### Request Building & Execution

```bash
# Build GraphQL payload
payload=$(build_graphql_payload "$QUERY" "$VARIABLES")

# Execute GraphQL request with full control
response=$(execute_graphql_request "$API_URL" "$TOKEN" "$payload")

# Execute with automatic error handling (recommended)
response=$(execute_graphql "$API_URL" "$TOKEN" "$QUERY" "$VARIABLES")
```

### Response Handling

```bash
# Extract data from response
data=$(extract_graphql_data "$response" ".data.createSnapshot")

# Check for errors
if has_graphql_errors "$response"; then
    print_error "Request failed"
    exit 1
fi
```

### Variable Building Helpers

```bash
# Build JSON objects
vars=$(build_jq_object \
    --arg name "Test" \
    --arg desc "Description" \
    '{name: $name, description: $desc}')

# Build tags array from KEY=VALUE strings
tags=$(echo -e "env=prod\nversion=1.2.3" | build_tags_array)
# Result: [{"key":"env","value":"prod"},{"key":"version","value":"1.2.3"}]

# Build time filter
time_filter=$(build_time_filter "$START_TIME" "$END_TIME")

# Build pagination variables
pagination=$(build_pagination_vars "10" "cursor123" "" "")
```

### Time Utilities

```bash
# Get current time in RFC3339
now=$(now_rfc3339)

# Calculate time offsets
two_hours_ago=$(time_offset "-2H")
yesterday=$(time_offset "-1d")
```

### Validation Helpers

```bash
# Validate environment variables
validate_env_vars FRONTEGG_CLIENT_ID FRONTEGG_CLIENT_SECRET || exit 1

# Validate required arguments
validate_required "name" "$NAME" || exit 1
```

## Snapshot Operations

### Creating Snapshots

```bash
# Using the script
./create_snapshot.sh \
  --name "Production Baseline" \
  --description "Baseline before deployment" \
  --start-time "$(time_offset "-2H")" \
  --tag "environment=production" \
  --tag "version=1.2.3"

# Using the library
MUTATION='mutation CreateSnapshot($options: SnapshotOptionsInput!) {
  createSnapshot(options: $options) {
    id
    name
    status
  }
}'

VARS=$(jq -n \
  --arg name "My Snapshot" \
  --arg desc "Test" \
  --arg start "$(now_rfc3339)" \
  '{options: {name: $name, description: $desc, startTime: $start}}')

RESPONSE=$(execute_graphql "$API_URL" "$TOKEN" "$MUTATION" "$VARS")
SNAPSHOT=$(extract_graphql_data "$RESPONSE" ".data.createSnapshot")
SNAPSHOT_ID=$(echo "$SNAPSHOT" | jq -r '.id')
```

## Polling for Completion

**Important:** Snapshots process asynchronously. The `createSnapshot` mutation returns immediately with `status: PENDING`. You must poll to wait for completion.

### Using the Poll Helper

```bash
# Poll until completion (default: 30s interval, 45min max)
FINAL_SNAPSHOT=$(poll_snapshot_status \
  "$API_URL" \
  "$TOKEN" \
  "$SNAPSHOT_ID")

# Poll with custom interval and timeout
FINAL_SNAPSHOT=$(poll_snapshot_status \
  "$API_URL" \
  "$TOKEN" \
  "$SNAPSHOT_ID" \
  "60" \      # Poll every 60 seconds
  "3600")     # Max wait 1 hour
```

### Manual Polling

```bash
while true; do
    STATUS=$(get_snapshot_status "$API_URL" "$TOKEN" "$SNAPSHOT_ID")
    
    case "$STATUS" in
        COMPLETE)
            print_success "Snapshot completed!"
            break
            ;;
        FAILED)
            print_error "Snapshot failed!"
            exit 1
            ;;
        PENDING)
            print_info "Still processing... (status: $STATUS)"
            sleep 30
            ;;
    esac
done
```

### Status Values

- `PENDING`: Snapshot is being processed
- `COMPLETE`: Snapshot finished successfully
- `FAILED`: Snapshot processing failed

## Creating Custom Workflows

### Example: List Entities

```bash
#!/bin/sh
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/lib/causely_graphql.sh"

setup_causely_auth || exit 1

QUERY='query GetEntities($filter: EntityFilter, $first: Int) {
  entityConnection(entityFilter: $filter, first: $first) {
    edges { node { id name typeName } }
  }
}'

FILTER=$(jq -n '{entityTypes: ["Service", "Database"]}')
VARS=$(jq -n --argjson filter "$FILTER" '{entityFilter: $filter, first: 20}')

RESPONSE=$(execute_graphql "$API_URL" "$TOKEN" "$QUERY" "$VARS")
ENTITIES=$(extract_graphql_data "$RESPONSE" ".data.entityConnection.edges")

echo "$ENTITIES" | jq '.[].node'
```

### Example: Query Root Causes

```bash
#!/bin/sh
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/lib/causely_graphql.sh"

setup_causely_auth || exit 1

QUERY='query GetDefects($filter: DefectFilter, $first: Int) {
  defectConnection(defectFilter: $filter, first: $first) {
    edges { node { id name severity entityType fromTime } }
  }
}'

FILTER=$(jq -n '{state: "ACTIVE", severities: ["Critical"]}')
VARS=$(jq -n --argjson filter "$FILTER" '{defectFilter: $filter, first: 10}')

RESPONSE=$(execute_graphql "$API_URL" "$TOKEN" "$QUERY" "$VARS")
DEFECTS=$(extract_graphql_data "$RESPONSE" ".data.defectConnection.edges")

print_success "Critical Root Causes:"
echo "$DEFECTS" | jq -r '.[].node | "  • \(.name) on \(.entityType) (Severity: \(.severity))"'
```

## Scripts Reference

### create_snapshot.sh

Create a new snapshot.

**Usage:**
```bash
./create_snapshot.sh \
  --name "Snapshot Name" \
  --description "Description" \
  --start-time "2025-01-01T00:00:00Z" \
  --end-time "2025-01-01T02:00:00Z" \
  --tag "key=value" \
  --tag "key2=value2"
```

**Arguments:**
- `--name`, `-n`: Snapshot name (required)
- `--description`, `-d`: Snapshot description (required)
- `--start-time`, `-s`: Start time in RFC3339 format (optional, defaults to 2 hours ago)
- `--end-time`, `-e`: End time in RFC3339 format (optional, defaults to now)
- `--tag`: Add a tag (can be specified multiple times)
- `--api-url`, `-u`: API endpoint URL (optional if using Frontegg auth)
- `--token`, `-t`: JWT token (optional if using Frontegg auth)

### compare_snapshots.sh

Compare multiple snapshots.

**Usage:**
```bash
./compare_snapshots.sh \
  "snapshot-id-1" \
  "snapshot-id-2" \
  "snapshot-id-3"  # Optional additional snapshots
```

### snapshot_workflow.sh

Complete pre/post deployment workflow.

**Usage:**
```bash
./snapshot_workflow.sh \
  --wait 300 \  # Wait 5 minutes between snapshots
  --tag "environment=production"
```

## Function Reference

### Request Handling

- `build_graphql_payload(query, variables)` - Build GraphQL request payload
- `execute_graphql_request(url, token, payload)` - Execute raw GraphQL request
- `execute_graphql(url, token, query, variables)` - Execute with error handling
- `execute_paginated_query(url, token, query, base_vars, first, after)` - Execute paginated query

### Response Parsing

- `extract_graphql_data(response, path)` - Extract data from response
- `has_graphql_errors(response)` - Check if response has errors

### Variable Building

- `build_jq_object(...)` - Build JSON objects with jq
- `build_json_array()` - Build JSON array from stdin
- `build_tags_array()` - Build tags array from KEY=VALUE strings
- `build_time_filter(start, end)` - Build time filter object
- `build_pagination_vars(first, after, last, before)` - Build pagination variables

### Snapshot Operations

- `get_snapshot(url, token, snapshot_id)` - Query snapshot by ID
- `get_snapshot_status(url, token, snapshot_id)` - Get snapshot status
- `poll_snapshot_status(url, token, snapshot_id, interval, max_wait)` - Poll until completion

### Validation

- `validate_env_vars(...)` - Validate environment variables are set
- `validate_required(name, value)` - Validate required argument

### Time Utilities

- `now_rfc3339()` - Get current time in RFC3339 format
- `format_rfc3339(time)` - Format timestamp to RFC3339
- `time_offset(offset)` - Calculate time offset (e.g., "-2H", "-1d")

### Printing (from causely_common.sh)

- `print_error(message)` - Print error in red
- `print_success(message)` - Print success in green
- `print_warning(message)` - Print warning in yellow
- `print_info(message)` - Print info in blue
- `print_header(text)` - Print section header

## Requirements

- **Shell**: POSIX-compliant (sh, bash, zsh, dash, ash)
- **jq**: 1.5+ (JSON processing)
- **curl**: Any recent version
- **bc**: For floating-point math (in comparison scripts)

## Related Documentation

- **[API Reference](03-api-reference.md)** - Complete GraphQL API documentation
- **[Authentication](04-authentication.md)** - Authentication setup
- **[GitHub Actions](06-github-actions.md)** - CI/CD integration
- **[Examples](07-examples-and-use-cases.md)** - Real-world examples
