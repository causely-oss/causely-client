# Advanced Topics

Advanced patterns and techniques for using the Causely API Client in production workflows.

## Table of Contents

- [Custom Workflows](#custom-workflows)
- [Error Handling](#error-handling)
- [Performance Optimization](#performance-optimization)
- [Reusable Composite Actions](#reusable-composite-actions)
- [Monitoring and Alerting](#monitoring-and-alerting)

## Custom Workflows

### Building Complex Variable Objects

```bash
# Start with base object
VARS=$(jq -n '{options: {}}')

# Add required fields
VARS=$(echo "$VARS" | jq --arg name "$NAME" '.options.name = $name')
VARS=$(echo "$VARS" | jq --arg desc "$DESC" '.options.description = $desc')

# Conditionally add optional fields
if [ -n "$END_TIME" ]; then
    VARS=$(echo "$VARS" | jq --arg end "$END_TIME" '.options.endTime = $end')
fi

if [ -n "$TAGS" ]; then
    TAGS_JSON=$(echo "$TAGS" | build_tags_array)
    VARS=$(echo "$VARS" | jq --argjson tags "$TAGS_JSON" '.options.tags = $tags')
fi
```

### Pagination Patterns

```bash
CURSOR=""
PAGE=1

while true; do
    RESPONSE=$(execute_paginated_query \
        "$API_URL" \
        "$TOKEN" \
        "$QUERY" \
        "$BASE_VARS" \
        "50" \
        "$CURSOR")
    
    DATA=$(extract_graphql_data "$RESPONSE" ".data.getSnapshotsPaginated")
    
    # Process results
    echo "$DATA" | jq '.edges[].node'
    
    # Check if there's a next page
    HAS_NEXT=$(echo "$DATA" | jq -r '.pageInfo.hasNextPage')
    if [ "$HAS_NEXT" != "true" ]; then
        break
    fi
    
    # Get next cursor
    CURSOR=$(echo "$DATA" | jq -r '.pageInfo.endCursor')
    PAGE=$((PAGE + 1))
done
```

## Error Handling

### Custom Error Handling

```bash
# Build and execute with custom error handling
PAYLOAD=$(build_graphql_payload "$QUERY" "$VARS")
RESPONSE=$(execute_graphql_request "$API_URL" "$TOKEN" "$PAYLOAD")

if has_graphql_errors "$RESPONSE"; then
    ERROR_MSG=$(echo "$RESPONSE" | jq -r '.errors[0].message')
    ERROR_CODE=$(echo "$RESPONSE" | jq -r '.errors[0].extensions.code // "UNKNOWN"')
    
    print_error "GraphQL Error ($ERROR_CODE): $ERROR_MSG"
    
    # Send to monitoring service, log, etc.
    # send_to_monitoring "$ERROR_CODE" "$ERROR_MSG"
    
    exit 1
fi
```

### Retry Logic

```bash
MAX_RETRIES=3
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    RESPONSE=$(execute_graphql "$API_URL" "$TOKEN" "$QUERY" "$VARS")
    
    if [ $? -eq 0 ] && ! has_graphql_errors "$RESPONSE"; then
        break
    fi
    
    RETRY_COUNT=$((RETRY_COUNT + 1))
    if [ $RETRY_COUNT -lt $MAX_RETRIES ]; then
        print_warning "Request failed, retrying ($RETRY_COUNT/$MAX_RETRIES)..."
        sleep $((RETRY_COUNT * 2))  # Exponential backoff
    fi
done

if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
    print_error "Request failed after $MAX_RETRIES attempts"
    exit 1
fi
```

## Performance Optimization

### Caching Dependencies

```yaml
- name: Cache jq
  uses: actions/cache@v3
  with:
    path: /usr/bin/jq
    key: jq-${{ runner.os }}

- name: Install jq
  run: |
    if ! command -v jq &> /dev/null; then
      sudo apt-get update && sudo apt-get install -y jq
    fi
```

### Parallel Snapshot Creation

```yaml
jobs:
  baseline:
    runs-on: ubuntu-latest
    steps:
      - name: Create baseline
        run: ./scripts/create_snapshot.sh ...
  
  comparison:
    runs-on: ubuntu-latest
    needs: [baseline, deploy]
    steps:
      - name: Create comparison
        run: ./scripts/create_snapshot.sh ...
```

### Sparse Checkout

```yaml
- uses: actions/checkout@v4
  with:
    repository: Causely/causely-api-client
    sparse-checkout: |
      shell
    sparse-checkout-cone-mode: false
```

## Reusable Composite Actions

Create a reusable composite action for snapshot creation:

**`.github/actions/causely-snapshot/action.yml`:**
```yaml
name: 'Create Causely Snapshot'
description: 'Create a Causely snapshot using bash scripts'

inputs:
  name:
    description: 'Snapshot name'
    required: true
  description:
    description: 'Snapshot description'
    required: true
  start-time:
    description: 'Start time (RFC3339)'
    required: false
    default: ''
  tags:
    description: 'Comma-separated tags (key=value,key2=value2)'
    required: false
    default: ''
  frontegg-client-id:
    description: 'Frontegg client ID'
    required: true
  frontegg-client-secret:
    description: 'Frontegg client secret'
    required: true

outputs:
  snapshot-id:
    description: 'Created snapshot ID'
    value: ${{ steps.create.outputs.snapshot-id }}

runs:
  using: 'composite'
  steps:
    - name: Install dependencies
      shell: bash
      run: |
        sudo apt-get update && sudo apt-get install -y jq
    
    - name: Setup environment
      shell: bash
      run: |
        echo "FRONTEGG_CLIENT_ID=${{ inputs.frontegg-client-id }}" >> $GITHUB_ENV
        echo "FRONTEGG_CLIENT_SECRET=${{ inputs.frontegg-client-secret }}" >> $GITHUB_ENV
    
    - name: Create snapshot
      id: create
      shell: bash
      run: |
        # Build command
        CMD="${{ github.action_path }}/../../../create_snapshot.sh"
        CMD="$CMD --name '${{ inputs.name }}'"
        CMD="$CMD --description '${{ inputs.description }}'"
        
        if [ -n "${{ inputs.start-time }}" ]; then
          CMD="$CMD --start-time '${{ inputs.start-time }}'"
        else
          START_TIME=$(date -u -d "2 hours ago" +"%Y-%m-%dT%H:%M:%SZ")
          CMD="$CMD --start-time '$START_TIME'"
        fi
        
        # Add tags
        if [ -n "${{ inputs.tags }}" ]; then
          IFS=',' read -ra TAGS <<< "${{ inputs.tags }}"
          for tag in "${TAGS[@]}"; do
            CMD="$CMD --tag '$tag'"
          done
        fi
        
        # Execute and capture ID
        OUTPUT=$(eval $CMD)
        SNAPSHOT_ID=$(echo "$OUTPUT" | grep "Snapshot ID:" | awk '{print $NF}')
        echo "snapshot-id=$SNAPSHOT_ID" >> $GITHUB_OUTPUT
```

**Using the composite action:**
```yaml
- name: Create snapshot
  uses: ./.github/actions/causely-snapshot
  with:
    name: 'Pre-deployment Baseline'
    description: 'Baseline for deployment ${{ github.run_number }}'
    tags: 'environment=production,stage=baseline,commit=${{ github.sha }}'
    frontegg-client-id: ${{ secrets.FRONTEGG_CLIENT_ID }}
    frontegg-client-secret: ${{ secrets.FRONTEGG_CLIENT_SECRET }}
```

## Monitoring and Alerting

### Add Workflow Status Badges

In your README.md:
```markdown
![Snapshot Workflow](https://github.com/your-org/your-repo/workflows/Create%20Snapshot/badge.svg)
```

### Custom Notifications

```yaml
- name: Notify on failure
  if: failure()
  uses: actions/github-script@v7
  with:
    script: |
      github.rest.issues.createComment({
        issue_number: context.issue.number,
        owner: context.repo.owner,
        repo: context.repo.repo,
        body: `## ❌ Snapshot Creation Failed
        Workflow: ${{ github.workflow }}
        Run: ${{ github.run_number }}
        Commit: ${{ github.sha }}`
      })
```

## Related Documentation

- **[Shell Implementation](05-shell-implementation.md)** - Complete Shell/Bash guide
- **[GitHub Actions](06-github-actions.md)** - CI/CD integration
- **[Examples](07-examples-and-use-cases.md)** - Real-world examples
