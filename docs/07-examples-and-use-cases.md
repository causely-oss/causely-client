# Examples and Use Cases

Real-world examples and common use cases for the Causely Snapshot API.

## Table of Contents

- [Use Cases](#use-cases)
- [Shell Script Examples](#shell-script-examples)
- [GitHub Actions Examples](#github-actions-examples)
- [Common Patterns](#common-patterns)

## Use Cases

### 1. Pre/Post Deployment Validation

Validate deployments by comparing system state before and after.

**Workflow:**
1. Create baseline snapshot before deployment
2. Perform deployment
3. Wait for system stabilization (up to 2 hours)
4. Create comparison snapshot after deployment
5. Poll both snapshots until `COMPLETE`
6. Compare snapshots
7. Review assessment (ACCEPTED/REJECTED)

**Benefits:**
- Identify regressions early
- Automated validation in CI/CD
- Historical comparison data

### 2. Shift Left Testing

Compare release candidates in staging/test environments before production.

**Workflow:**
1. Create baseline snapshot during load test
2. Deploy new release candidate
3. Create comparison snapshot during load test
4. Compare to assess performance and stability
5. Make informed go/no-go decisions

### 3. Scheduled Baseline Snapshots

Create regular snapshots for historical comparison and trend analysis.

**Implementation:**
```yaml
# GitHub Actions - Hourly snapshots
on:
  schedule:
    - cron: '0 * * * *'  # Every hour
```

### 4. Environment Drift Detection

Compare production vs staging to identify configuration differences.

**Workflow:**
1. Create snapshot in production
2. Create snapshot in staging
3. Compare with scope filter for specific services
4. Identify configuration or behavior differences

## Shell Script Examples

### Example 1: Create Snapshot with Tags

```bash
#!/bin/sh
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/lib/causely_graphql.sh"

setup_causely_auth || exit 1

# Build tags
TAGS=$(echo -e "environment=production\nversion=1.2.3\nteam=backend" | build_tags_array)

# Build variables
VARS=$(jq -n \
  --arg name "Production Baseline" \
  --arg desc "Baseline before deployment" \
  --arg start "$(time_offset "-2H")" \
  --argjson tags "$TAGS" \
  '{options: {
    name: $name,
    description: $desc,
    startTime: $start,
    tags: $tags
  }}')

# Execute
MUTATION='mutation CreateSnapshot($options: SnapshotOptionsInput!) {
  createSnapshot(options: $options) {
    id
    name
    status
  }
}'

RESPONSE=$(execute_graphql "$API_URL" "$TOKEN" "$MUTATION" "$VARS")
SNAPSHOT=$(extract_graphql_data "$RESPONSE" ".data.createSnapshot")
SNAPSHOT_ID=$(echo "$SNAPSHOT" | jq -r '.id')

print_success "Created snapshot: $SNAPSHOT_ID"
```

### Example 2: Poll for Completion

```bash
#!/bin/sh
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/lib/causely_graphql.sh"

setup_causely_auth || exit 1

# Create snapshot (returns immediately)
RESPONSE=$(execute_graphql "$API_URL" "$TOKEN" "$MUTATION" "$VARS")
SNAPSHOT_ID=$(echo "$RESPONSE" | jq -r '.data.createSnapshot.id')

print_header "Waiting for snapshot to complete..."

# Poll until completion
FINAL_SNAPSHOT=$(poll_snapshot_status \
  "$API_URL" \
  "$TOKEN" \
  "$SNAPSHOT_ID" \
  "30" \      # Poll every 30 seconds
  "2700")     # Max wait 45 minutes

if [ $? -eq 0 ]; then
  print_success "Snapshot completed successfully!"
  echo "$FINAL_SNAPSHOT" | jq '.'
else
  print_error "Snapshot failed or timed out"
  exit 1
fi
```

### Example 3: Pre/Post Deployment Comparison

```bash
#!/bin/sh
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/lib/causely_graphql.sh"

setup_causely_auth || exit 1

# 1. Create baseline snapshot
print_header "Creating baseline snapshot..."
BASELINE_RESPONSE=$(execute_graphql "$API_URL" "$TOKEN" "$BASELINE_MUTATION" "$BASELINE_VARS")
BASELINE_ID=$(echo "$BASELINE_RESPONSE" | jq -r '.data.createSnapshot.id')
print_success "Baseline snapshot: $BASELINE_ID"

# 2. Deploy (your deployment commands here)
print_header "Deploying application..."
# kubectl apply -f deployment.yaml
# or your deployment commands

# 3. Wait for stabilization
print_info "Waiting 2 minutes for system to stabilize..."
sleep 120

# 4. Create comparison snapshot
print_header "Creating comparison snapshot..."
COMPARISON_RESPONSE=$(execute_graphql "$API_URL" "$TOKEN" "$COMPARISON_MUTATION" "$COMPARISON_VARS")
COMPARISON_ID=$(echo "$COMPARISON_RESPONSE" | jq -r '.data.createSnapshot.id')
print_success "Comparison snapshot: $COMPARISON_ID"

# 5. Poll both until complete
print_header "Waiting for snapshots to complete..."
poll_snapshot_status "$API_URL" "$TOKEN" "$BASELINE_ID" || exit 1
poll_snapshot_status "$API_URL" "$TOKEN" "$COMPARISON_ID" || exit 1

# 6. Compare
print_header "Comparing snapshots..."
./compare_snapshots.sh "$BASELINE_ID" "$COMPARISON_ID"
```

## GitHub Actions Examples

### Example 1: Simple Snapshot on Push

```yaml
name: Create Snapshot on Push

on:
  push:
    branches: [main]

jobs:
  snapshot:
    runs-on: ubuntu-latest
    env:
      FRONTEGG_CLIENT_ID: ${{ secrets.FRONTEGG_CLIENT_ID }}
      FRONTEGG_CLIENT_SECRET: ${{ secrets.FRONTEGG_CLIENT_SECRET }}
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Checkout Causely scripts
        uses: actions/checkout@v4
        with:
          repository: Causely/causely-api-client
          sparse-checkout: shell
          path: .causely
      
      - name: Install dependencies
        run: sudo apt-get update && sudo apt-get install -y jq
      
      - name: Create snapshot
        run: |
          START_TIME=$(date -u -d "2 hours ago" +"%Y-%m-%dT%H:%M:%SZ")
          .causely/shell/create_snapshot.sh \
            --name "Deployment ${{ github.run_number }}" \
            --description "Snapshot for commit ${{ github.sha }}" \
            --start-time "$START_TIME" \
            --tag "commit=${{ github.sha }}" \
            --tag "branch=${{ github.ref_name }}"
```

### Example 2: Scheduled Baseline Snapshots

```yaml
name: Hourly Baseline Snapshots

on:
  schedule:
    - cron: '0 * * * *'  # Every hour

jobs:
  snapshot:
    runs-on: ubuntu-latest
    env:
      FRONTEGG_CLIENT_ID: ${{ secrets.FRONTEGG_CLIENT_ID }}
      FRONTEGG_CLIENT_SECRET: ${{ secrets.FRONTEGG_CLIENT_SECRET }}
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Checkout Causely scripts
        uses: actions/checkout@v4
        with:
          repository: Causely/causely-api-client
          sparse-checkout: shell
          path: .causely
      
      - name: Install dependencies
        run: sudo apt-get update && sudo apt-get install -y jq
      
      - name: Create hourly baseline
        run: |
          TIMESTAMP=$(date -u +"%Y-%m-%d_%H:%M")
          START_TIME=$(date -u -d "1 hour ago" +"%Y-%m-%dT%H:%M:%SZ")
          
          .causely/shell/create_snapshot.sh \
            --name "Hourly Baseline $TIMESTAMP" \
            --description "Automated baseline snapshot" \
            --start-time "$START_TIME" \
            --tag "type=baseline" \
            --tag "frequency=hourly"
```

## Common Patterns

### Pattern: Snapshot on Every Deployment

```yaml
on:
  push:
    branches: [main]

jobs:
  deploy:
    steps:
      # ... deployment steps ...
      
      - name: Create snapshot
        run: |
          START_TIME=$(date -u -d "2 hours ago" +"%Y-%m-%dT%H:%M:%SZ")
          ./scripts/create_snapshot.sh \
            --name "Deployment ${{ github.run_number }}" \
            --description "Post-deployment snapshot" \
            --start-time "$START_TIME" \
            --tag "commit=${{ github.sha }}" \
            --tag "environment=production"
```

### Pattern: Compare Before/After Deployment

```yaml
jobs:
  deploy:
    steps:
      - name: Baseline snapshot
        id: baseline
        run: |
          OUTPUT=$(./scripts/create_snapshot.sh ...)
          SNAPSHOT_ID=$(echo "$OUTPUT" | grep "Snapshot ID:" | awk '{print $NF}')
          echo "id=$SNAPSHOT_ID" >> $GITHUB_OUTPUT
      
      # Deploy...
      
      - name: Comparison snapshot
        id: comparison
        run: |
          OUTPUT=$(./scripts/create_snapshot.sh ...)
          SNAPSHOT_ID=$(echo "$OUTPUT" | grep "Snapshot ID:" | awk '{print $NF}')
          echo "id=$SNAPSHOT_ID" >> $GITHUB_OUTPUT
      
      - name: Compare snapshots
        run: |
          ./scripts/compare_snapshots.sh \
            "${{ steps.baseline.outputs.id }}" \
            "${{ steps.comparison.outputs.id }}"
```

### Pattern: Manual Workflow with Inputs

```yaml
on:
  workflow_dispatch:
    inputs:
      environment:
        type: choice
        options: [staging, production]
      version:
        required: true

jobs:
  deploy:
    environment: ${{ inputs.environment }}
    steps:
      - name: Create snapshot
        run: |
          ./scripts/create_snapshot.sh \
            --name "${{ inputs.environment }} - ${{ inputs.version }}" \
            --description "Deployment of ${{ inputs.version }}" \
            --start-time "$(date -u -d '2 hours ago' +'%Y-%m-%dT%H:%M:%SZ')" \
            --tag "environment=${{ inputs.environment }}" \
            --tag "version=${{ inputs.version }}"
```

## Related Documentation

- **[API Reference](03-api-reference.md)** - Complete GraphQL API documentation
- **[Shell Implementation](05-shell-implementation.md)** - Shell/Bash guide
- **[GitHub Actions](06-github-actions.md)** - CI/CD integration guide
- **[Advanced Topics](08-advanced-topics.md)** - Advanced patterns and techniques
