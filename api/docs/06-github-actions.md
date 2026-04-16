# GitHub Actions Integration

Complete guide to integrating Causely snapshots into your GitHub Actions CI/CD pipelines.

## Table of Contents

- [Quick Start](#quick-start)
- [Use Cases](#use-cases)
- [Deployment Patterns](#deployment-patterns)
- [Workflow Examples](#workflow-examples)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)

## Quick Start

### 1. Set Up Secrets

In your GitHub repository:

1. Go to **Settings** → **Secrets and variables** → **Actions**
2. Click **New repository secret**
3. Add:
   - `FRONTEGG_CLIENT_ID`: Your Frontegg client ID
   - `FRONTEGG_CLIENT_SECRET`: Your Frontegg client secret

### 2. Choose a Workflow Pattern

**Option A: Checkout Scripts from Repository (Recommended)**

```yaml
- name: Checkout Causely scripts
  uses: actions/checkout@v4
  with:
    repository: Causely/causely-api-client
    sparse-checkout: |
      shell
    path: .causely
```

**Option B: Copy Scripts to Your Repo**

Copy `shell/` directory to your repository and commit it.

### 3. Basic Workflow

```yaml
name: Create Snapshot

on:
  workflow_dispatch:

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
            --name "CI Snapshot" \
            --description "From workflow" \
            --start-time "$START_TIME"
```

## Use Cases

### Use Case 1: Create a Snapshot

Create a snapshot and continue. The snapshot processes in the background.

See workflow example in [Workflow Examples](#workflow-examples) section below.

### Use Case 2: Create Snapshot and Poll for Completion

Wait for the snapshot to complete before proceeding. Useful when you need the snapshot ready for comparison.

See workflow example in [Workflow Examples](#workflow-examples) section below.

## Deployment Patterns

### Pattern 1: Scripts in Same Repository

**Best for:** Teams who want full control and version scripts with their app.

**Setup:**
```bash
# Copy scripts to your repo
cp -r /path/to/causely-api-client/shell your-repo/scripts/
git add scripts/
git commit -m "Add Causely API scripts"
```

**Workflow:**
```yaml
- name: Create snapshot
  run: |
    ./scripts/create_snapshot.sh \
      --name "Deployment ${{ github.run_number }}" \
      --start-time "$(date -u -d '2 hours ago' +'%Y-%m-%dT%H:%M:%SZ')"
```

**Advantages:**
- Scripts versioned with your app
- No external dependencies
- Easy to customize

**Disadvantages:**
- Must manually update scripts
- Duplicates code across repos

### Pattern 2: Scripts in Separate Repository

**Best for:** Organizations with multiple repos using Causely.

**Workflow:**
```yaml
- name: Checkout application
  uses: actions/checkout@v4
  with:
    path: app

- name: Checkout Causely scripts
  uses: actions/checkout@v4
  with:
    repository: your-org/causely-scripts
    path: scripts
    token: ${{ secrets.GITHUB_TOKEN }}

- name: Create snapshot
  run: ./scripts/create_snapshot.sh ...
```

**Advantages:**
- Single source of truth
- Updates propagate to all repos
- Centralized maintenance

### Pattern 3: Checkout from Causely Repository

**Best for:** Always using the latest scripts.

**Workflow:**
```yaml
- name: Checkout Causely scripts
  uses: actions/checkout@v4
  with:
    repository: Causely/causely-api-client
    sparse-checkout: |
      shell
    path: .causely
```

**Advantages:**
- Always up-to-date
- No maintenance required
- Minimal setup

**Disadvantages:**
- Network dependency
- Potential breaking changes

### Pattern 4: Reusable Composite Action

**Best for:** Organizations wanting GitHub Actions-native experience.

See [Advanced Topics](08-advanced-topics.md#reusable-composite-actions) for details.

## Workflow Examples

### Example 1: Simple Snapshot Creation

```yaml
name: Create Snapshot

on:
  workflow_dispatch:
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
        id: snapshot
        run: |
          START_TIME=$(date -u -d "2 hours ago" +"%Y-%m-%dT%H:%M:%SZ")
          
          OUTPUT=$(.causely/shell/create_snapshot.sh \
            --name "CI Snapshot #${{ github.run_number }}" \
            --description "Automated snapshot from workflow" \
            --start-time "$START_TIME" \
            --tag "workflow=${{ github.workflow }}" \
            --tag "commit=${{ github.sha }}")
          
          SNAPSHOT_ID=$(echo "$OUTPUT" | grep "Snapshot ID:" | awk '{print $NF}')
          echo "snapshot_id=$SNAPSHOT_ID" >> $GITHUB_OUTPUT
      
      - name: Add summary
        run: |
          echo "## ✅ Snapshot Created" >> $GITHUB_STEP_SUMMARY
          echo "**Snapshot ID:** \`${{ steps.snapshot.outputs.snapshot_id }}\`" >> $GITHUB_STEP_SUMMARY
          echo "" >> $GITHUB_STEP_SUMMARY
          echo "Note: Snapshot is processing in the background." >> $GITHUB_STEP_SUMMARY
```

### Example 2: Create Snapshot and Poll for Completion

```yaml
name: Create Snapshot and Wait

on:
  workflow_dispatch:

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
        id: create
        run: |
          START_TIME=$(date -u -d "2 hours ago" +"%Y-%m-%dT%H:%M:%SZ")
          
          OUTPUT=$(.causely/shell/create_snapshot.sh \
            --name "CI Snapshot #${{ github.run_number }}" \
            --description "Automated snapshot" \
            --start-time "$START_TIME")
          
          SNAPSHOT_ID=$(echo "$OUTPUT" | grep "Snapshot ID:" | awk '{print $NF}')
          echo "snapshot_id=$SNAPSHOT_ID" >> $GITHUB_OUTPUT
          echo "SNAPSHOT_ID=$SNAPSHOT_ID" >> $GITHUB_ENV
      
      - name: Poll for completion
        id: poll
        run: |
          SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
          . .causely/shell/lib/causely_common.sh
          . .causely/shell/lib/causely_auth.sh
          . .causely/shell/lib/causely_graphql.sh
          
          setup_causely_auth || exit 1
          
          print_header "Waiting for snapshot to complete..."
          
          FINAL_SNAPSHOT=$(poll_snapshot_status \
            "$API_URL" \
            "$TOKEN" \
            "$SNAPSHOT_ID" \
            "30" \      # Poll every 30 seconds
            "2700")     # Max wait 45 minutes
          
          if [ $? -eq 0 ]; then
            print_success "Snapshot completed!"
            echo "status=complete" >> $GITHUB_OUTPUT
          else
            print_error "Snapshot failed or timed out"
            echo "status=failed" >> $GITHUB_OUTPUT
            exit 1
          fi
      
      - name: Add summary
        if: always()
        run: |
          echo "## Snapshot Status" >> $GITHUB_STEP_SUMMARY
          echo "**Snapshot ID:** \`${{ steps.create.outputs.snapshot_id }}\`" >> $GITHUB_STEP_SUMMARY
          echo "**Status:** ${{ steps.poll.outputs.status }}" >> $GITHUB_STEP_SUMMARY
```

### Example 3: Pre/Post Deployment Validation

See `github-actions/deployment-with-snapshots.yml` for a complete production-ready workflow.

## Best Practices

1. **Use Secrets**: Never hardcode credentials
2. **Tag Snapshots**: Add useful metadata (commit, environment, version)
3. **Create Job Summaries**: Add workflow summaries for visibility
4. **Handle Errors**: Check exit codes and fail appropriately
5. **Poll for Completion**: When you need snapshots ready, use polling
6. **Set Appropriate Timeouts**: Default 45 minutes for polling
7. **Test Workflows**: Test in non-production first

## Troubleshooting

### Script Not Found

**Problem:** `create_snapshot.sh: No such file or directory`

**Solutions:**
1. Ensure you've checked out the repository: `uses: actions/checkout@v4`
2. Verify the script path: `.causely/shell/create_snapshot.sh`
3. Make script executable: `chmod +x .causely/shell/create_snapshot.sh`

### Authentication Errors

**Problem:** `❌ Authentication failed`

**Solutions:**
1. Verify secrets are set correctly in repository settings
2. Check that client ID and secret are valid
3. Ensure secrets aren't expired
4. Verify the auth endpoint URL is correct

### Date Command Compatibility

GitHub Actions runners use GNU date (Linux), so this works:

```bash
date -u -d "2 hours ago" +"%Y-%m-%dT%H:%M:%SZ"
```

### jq Not Found

**Problem:** `jq: command not found`

**Solution:**
```yaml
- name: Install dependencies
  run: sudo apt-get update && sudo apt-get install -y jq
```

## Related Documentation

- **[Shell Implementation](05-shell-implementation.md)** - Complete Shell/Bash guide
- **[API Reference](03-api-reference.md)** - GraphQL API documentation
- **[Examples](07-examples-and-use-cases.md)** - Real-world use cases

## Workflow Files

Ready-to-use workflow files in `github-actions/`:

- `simple-snapshot.yml` - Basic snapshot creation
- `simple-snapshot-with-polling.yml` - Create and wait for completion
- `deployment-with-snapshots.yml` - Complete pre/post deployment validation
