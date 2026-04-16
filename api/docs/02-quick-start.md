# Quick Start

Get up and running with Causely API Client in minutes.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Authentication Setup](#authentication-setup)
- [Your First Snapshot](#your-first-snapshot)
- [Next Steps](#next-steps)

## Prerequisites

### Shell/Bash (Recommended)

- POSIX-compliant shell (sh, bash, zsh, dash, ash)
- `jq` 1.5+ (JSON processing)
- `curl` (HTTP requests)
- `bc` (floating-point math)

### Installation

**macOS:**
```bash
brew install jq
```

**Ubuntu/Debian:**
```bash
sudo apt-get update && sudo apt-get install -y jq bc
```

**CentOS/RHEL:**
```bash
sudo yum install jq bc
```

## Authentication Setup

### Step 1: Get Frontegg Credentials

1. Login to [Causely Portal](https://portal.causely.app/)
2. Click **User Settings** (top right bubble icon with your initials)
3. Click **Admin Portal** (opens new tab)
4. Navigate to **API Tokens** (bottom of left menu)
5. Click **Generate Token**
6. Fill in description, set `Role` = "Admin", click **Create**
7. **Save the Client ID and Client Secret** (shown only once!)

### Step 2: Set Environment Variables

```bash
export FRONTEGG_CLIENT_ID="your-client-id"
export FRONTEGG_CLIENT_SECRET="your-client-secret"
export APP_BASE_URL="https://api.causely.app/query"  # Optional
```

For GitHub Actions, add these as repository secrets (see [GitHub Actions Guide](06-github-actions.md)).

## Your First Snapshot

### Using Shell Scripts

```bash
# Navigate to shell directory
cd shell

# Create a snapshot
./create_snapshot.sh \
  --name "My First Snapshot" \
  --description "Testing the API" \
  --start-time "$(date -u -d '2 hours ago' +'%Y-%m-%dT%H:%M:%SZ')"
```

**Output:**
```
=== Creating Snapshot: My First Snapshot ===
✅ Snapshot created successfully!

{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "name": "My First Snapshot",
  "status": "PENDING",
  ...
}

Snapshot ID: 550e8400-e29b-41d4-a716-446655440000
```

**Note:** The snapshot is processing in the background. Use polling to wait for completion (see [Shell Implementation](05-shell-implementation.md#polling-for-completion)).

### Using the GraphQL Library

```bash
#!/bin/sh
set -e

# Source the library
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/shell/lib/causely_graphql.sh"

# Authenticate
setup_causely_auth || exit 1

# Create snapshot
MUTATION='mutation CreateSnapshot($options: SnapshotOptionsInput!) {
  createSnapshot(options: $options) {
    id
    name
    status
  }
}'

VARS=$(jq -n \
  --arg name "My Snapshot" \
  --arg desc "Test snapshot" \
  --arg start "$(now_rfc3339)" \
  '{options: {name: $name, description: $desc, startTime: $start}}')

RESPONSE=$(execute_graphql "$API_URL" "$TOKEN" "$MUTATION" "$VARS")
SNAPSHOT=$(extract_graphql_data "$RESPONSE" ".data.createSnapshot")
SNAPSHOT_ID=$(echo "$SNAPSHOT" | jq -r '.id')

print_success "Created snapshot: $SNAPSHOT_ID"
```

## Understanding Snapshot Processing

**Important:** The `createSnapshot` mutation returns immediately with `id`, `name`, and `status` fields. Snapshot processing happens asynchronously in the background.

- **Initial Status**: `PENDING` (processing in background)
- **Processing Time**: A few minutes to 45 minutes depending on environment size
- **Terminal States**: `COMPLETE` (success) or `FAILED` (error)

To wait for completion, use the `getSnapshot` query or the `poll_snapshot_status()` helper function (see [Shell Implementation](05-shell-implementation.md#polling-for-completion)).

## Next Steps

1. **[API Reference](03-api-reference.md)** - Complete GraphQL API documentation
2. **[Authentication Guide](04-authentication.md)** - Detailed authentication setup
3. **[Shell Implementation](05-shell-implementation.md)** - Comprehensive Shell/Bash guide
4. **[GitHub Actions](06-github-actions.md)** - CI/CD integration
5. **[Examples and Use Cases](07-examples-and-use-cases.md)** - Real-world examples

## Troubleshooting

### Authentication Errors

**Problem:** `❌ Authentication failed`

**Solutions:**
1. Verify `FRONTEGG_CLIENT_ID` and `FRONTEGG_CLIENT_SECRET` are set correctly
2. Check that credentials are valid and not expired
3. Ensure you're using the correct API endpoint

### Script Not Found

**Problem:** `create_snapshot.sh: No such file or directory`

**Solution:** Ensure you're in the `shell/` directory or provide the correct path:
```bash
./shell/create_snapshot.sh ...
```

### jq Not Found

**Problem:** `jq: command not found`

**Solution:** Install jq (see [Installation](#installation) above).

### Date Command Compatibility

**Problem:** Date parsing errors on different systems

**Solution:** The scripts handle both GNU date (Linux) and BSD date (macOS) automatically. For manual use:

```bash
# Linux (GNU date)
date -u -d "2 hours ago" +"%Y-%m-%dT%H:%M:%SZ"

# macOS (BSD date)
date -u -v-2H +"%Y-%m-%dT%H:%M:%SZ"
```
