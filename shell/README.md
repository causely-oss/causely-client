# Bash Snapshot API Examples

Bash/shell script examples for the Causely Snapshot API using curl and jq.

## Prerequisites

- Bash shell
- `curl` - for making HTTP requests
- `jq` - for JSON processing
- `bc` - for floating-point arithmetic (usually pre-installed)

## Installation

Most systems have curl pre-installed. To install jq:

**macOS:**
```bash
brew install jq
```

**Ubuntu/Debian:**
```bash
sudo apt-get install jq
```

**CentOS/RHEL:**
```bash
sudo yum install jq
```

## Making Scripts Executable

Before running the scripts, make them executable:

```bash
chmod +x create_snapshot.sh
chmod +x compare_snapshots.sh
chmod +x snapshot_workflow.sh
```

## Scripts

### 1. create_snapshot.sh

Create a new snapshot of your system state. Supports both direct token authentication and Frontegg authentication.

**Usage Option 1 - Direct Token:**
```bash
./create_snapshot.sh \
  "https://api.causely.app/query" \
  "YOUR_JWT_TOKEN" \
  "Production Baseline" \
  "Baseline snapshot before deployment" \
  "2025-10-20T10:00:00Z" \
  "2025-10-20T11:00:00Z"
```

**Arguments (Direct Token Mode):**
1. API URL (required)
2. JWT token (required)
3. Snapshot name (required)
4. Snapshot description (required)
5. Start time in RFC3339 format (required)
6. End time in RFC3339 format (optional)

**Usage Option 2 - Frontegg Authentication (GitHub Actions):**
```bash
# Set environment variables
export FRONTEGG_CLIENT_ID="your-client-id"
export FRONTEGG_CLIENT_SECRET="your-client-secret"
export APP_BASE_URL="https://api.causely.app/query"
export FRONTEGG_IDENTITY_HOST="https://auth.causely.app/identity/resources/auth/v2/api-token"

# Call with simplified arguments
./create_snapshot.sh \
  "Production Baseline" \
  "Baseline snapshot before deployment" \
  "2025-10-20T10:00:00Z" \
  "2025-10-20T11:00:00Z"
```

**Arguments (Frontegg Mode):**
1. Snapshot name (required)
2. Snapshot description (required)
3. Start time in RFC3339 format (required)
4. End time in RFC3339 format (optional)

**Environment Variables (Frontegg Mode):**
- `FRONTEGG_CLIENT_ID` - Frontegg client ID (required)
- `FRONTEGG_CLIENT_SECRET` - Frontegg client secret (required)
- `APP_BASE_URL` - API endpoint (optional, default: https://api.causely.app/query)
- `FRONTEGG_IDENTITY_HOST` - Auth endpoint (optional, default: https://auth.causely.app/identity/resources/auth/v2/api-token)

The script automatically detects which mode to use based on whether `FRONTEGG_CLIENT_ID` and `FRONTEGG_CLIENT_SECRET` environment variables are set.

### 2. compare_snapshots.sh

Compare multiple snapshots to identify differences.

**Usage:**
```bash
./compare_snapshots.sh \
  "https://api.causely.io/graphql" \
  "YOUR_JWT_TOKEN" \
  "550e8400-e29b-41d4-a716-446655440000" \
  "660f9511-f30c-52e5-b827-557766551111"
```

**Arguments:**
1. API URL (required)
2. JWT token (required)
3. First snapshot ID (required)
4. Second snapshot ID (required)
5. Additional snapshot IDs (optional)

### 3. snapshot_workflow.sh

Complete workflow demonstrating snapshot creation, comparison, and assessment.

**Usage:**
```bash
./snapshot_workflow.sh \
  "https://api.causely.io/graphql" \
  "YOUR_JWT_TOKEN" \
  60
```

**Arguments:**
1. API URL (required)
2. JWT token (required)
3. Wait seconds between snapshots (optional, default: 60)

## Exit Codes

All scripts use standard exit codes:
- `0`: Success (for comparisons, all assessments were ACCEPTED)
- `1`: Error or failure (for comparisons, one or more assessments were REJECTED)

## Integration with CI/CD

These scripts can be easily integrated into CI/CD pipelines.

### GitHub Actions Integration

For GitHub Actions, use the Frontegg authentication mode. See [github-actions/README.md](../github-actions/README.md) for complete examples.

**Quick Example:**
```yaml
name: Create Snapshot
on: workflow_dispatch
jobs:
  create:
    runs-on: ubuntu-latest
    env:
      FRONTEGG_CLIENT_ID: ${{ secrets.FRONTEGG_CLIENT_ID }}
      FRONTEGG_CLIENT_SECRET: ${{ secrets.FRONTEGG_CLIENT_SECRET }}
      APP_BASE_URL: https://api.causely.app/query
    steps:
      - uses: actions/checkout@v4
      - name: Install deps
        run: sudo apt-get update && sudo apt-get install -y jq
      - name: Create snapshot
        run: |
          START_TIME=$(date -u -d "2 hours ago" +"%Y-%m-%dT%H:%M:%SZ")
          END_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
          bash ./docs/examples/bash/create_snapshot.sh \
            "My Snapshot" \
            "Description" \
            "$START_TIME" \
            "$END_TIME"
```

### Generic CI/CD Integration

For other CI/CD systems using direct token authentication:

```bash
#!/bin/bash
# deployment-with-validation.sh

set -e  # Exit on error

# Store API credentials
API_URL="https://api.causely.app/query"
CAUSELY_TOKEN="${CAUSELY_TOKEN}"  # From environment

# Run snapshot workflow
./snapshot_workflow.sh "$API_URL" "$CAUSELY_TOKEN" 120

# Check exit code
if [ $? -ne 0 ]; then
  echo "❌ Snapshot comparison failed - deployment validation failed"
  # Add rollback logic here
  exit 1
fi

echo "✅ Deployment validation passed"
```

## Examples

### Create a snapshot for the last hour

```bash
#!/bin/bash

API_URL="https://api.causely.io/graphql"
TOKEN="$CAUSELY_TOKEN"

# Calculate times (macOS compatible)
END_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
START_TIME=$(date -u -v-1H +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || \
             date -u -d "1 hour ago" +"%Y-%m-%dT%H:%M:%SZ")

./create_snapshot.sh \
  "$API_URL" \
  "$TOKEN" \
  "Hourly Snapshot" \
  "Automated hourly snapshot" \
  "$START_TIME" \
  "$END_TIME"
```

### Automated pre/post deployment comparison

```bash
#!/bin/bash
set -e

API_URL="https://api.causely.io/graphql"
TOKEN="$CAUSELY_TOKEN"

# Function to create snapshot
create_snapshot() {
    local name="$1"
    local description="$2"
    
    END_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    START_TIME=$(date -u -v-1H +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || \
                 date -u -d "1 hour ago" +"%Y-%m-%dT%H:%M:%SZ")
    
    RESPONSE=$(./create_snapshot.sh "$API_URL" "$TOKEN" \
        "$name" "$description" "$START_TIME" "$END_TIME" 2>&1)
    
    echo "$RESPONSE" | grep "Snapshot ID:" | awk '{print $NF}'
}

echo "Creating pre-deployment snapshot..."
PRE_ID=$(create_snapshot "Pre-Deploy" "Before deployment")
echo "Pre-deployment snapshot: $PRE_ID"

echo "Deploying application..."
# Your deployment commands here
kubectl apply -f deployment.yaml

echo "Waiting 2 minutes for system to stabilize..."
sleep 120

echo "Creating post-deployment snapshot..."
POST_ID=$(create_snapshot "Post-Deploy" "After deployment")
echo "Post-deployment snapshot: $POST_ID"

echo "Comparing snapshots..."
./compare_snapshots.sh "$API_URL" "$TOKEN" "$PRE_ID" "$POST_ID"

if [ $? -ne 0 ]; then
    echo "❌ Deployment validation failed!"
    exit 1
fi

echo "✅ Deployment validation passed!"
```

## Environment Variables

You can use environment variables to avoid passing sensitive tokens on the command line:

```bash
# Set environment variables
export CAUSELY_API_URL="https://api.causely.io/graphql"
export CAUSELY_TOKEN="your-jwt-token"

# Modify scripts to use environment variables
./snapshot_workflow.sh "$CAUSELY_API_URL" "$CAUSELY_TOKEN"
```

## Troubleshooting

### jq Command Not Found

Install jq using your package manager (see Prerequisites section).

### bc Command Not Found

Install bc using your package manager:
```bash
# Ubuntu/Debian
sudo apt-get install bc

# macOS (usually pre-installed)
brew install bc
```

### Date Command Compatibility

The scripts include compatibility for both GNU date (Linux) and BSD date (macOS):
```bash
# macOS format
date -u -v-1H +"%Y-%m-%dT%H:%M:%SZ"

# Linux format
date -u -d "1 hour ago" +"%Y-%m-%dT%H:%M:%SZ"
```

### Authentication Errors

If you see authentication errors:
1. Verify your JWT token is valid and not expired
2. Ensure the token has appropriate permissions
3. Check that the token is properly quoted in the command

### Curl SSL Certificate Errors

If you encounter SSL certificate issues, you can temporarily bypass verification (not recommended for production):
```bash
# Add -k flag to curl command in scripts
curl -k -s -X POST "$API_URL" ...
```

## Color Output

The scripts use ANSI color codes for better readability:
- 🟢 Green: Success messages
- 🔴 Red: Error messages
- 🟡 Yellow: Warning messages
- 🔵 Blue: Info messages

If colors don't display correctly, check your terminal's color support.

## Further Documentation

For complete API documentation, see [../../snapshot-api.md](../../snapshot-api.md)

