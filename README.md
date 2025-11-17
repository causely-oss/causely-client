# Causely API Client

A multi-language client library and CLI toolkit for integrating with the Causely GraphQL API. This repository provides production-ready scripts, reusable libraries, and GitHub Actions workflows for snapshot creation, comparison, and deployment validation.

## Overview

The Causely API Client enables developers and DevOps teams to programmatically interact with the Causely platform's GraphQL backend. It provides tools for capturing system state snapshots, comparing them to identify changes, and integrating these capabilities into CI/CD pipelines for automated deployment validation and monitoring.

## Key Features

- **Multi-Language Support**: Choose from Shell/Bash, Python, or Node.js implementations
- **Snapshot Management**: Create and compare snapshots of your system state
- **Deployment Validation**: Automated pre/post deployment comparison workflows
- **CI/CD Integration**: Ready-to-use GitHub Actions workflows and CI/CD examples
- **Flexible Authentication**: Support for both direct JWT tokens and Frontegg OAuth
- **Production Ready**: Comprehensive error handling, testing, and documentation
- **Reusable Libraries**: Well-structured libraries for building custom workflows

## Quick Start

### Shell/Bash

```bash
# Set up Frontegg authentication
export FRONTEGG_CLIENT_ID="your-client-id"
export FRONTEGG_CLIENT_SECRET="your-client-secret"
export APP_BASE_URL="https://api.causely.app/query"

# Create a snapshot
cd shell
./create_snapshot.sh \
  --name "Production Baseline" \
  --description "Baseline before deployment" \
  --start-time "$(date -u -v-2H +"%Y-%m-%dT%H:%M:%SZ")"
```

## Language Implementations

### Shell/Bash

The Shell implementation provides the most comprehensive and feature-rich library:

- **Reusable Libraries** (`shell/lib/`)
  - `causely_common.sh` - Colors, printing, utilities
  - `causely_auth.sh` - Frontegg authentication
  - `causely_graphql.sh` - GraphQL operations (447+ lines)
- **Production Scripts**
  - `create_snapshot.sh` - Create snapshots with Frontegg auth support
  - `compare_snapshots.sh` - Compare multiple snapshots
  - `snapshot_workflow.sh` - Complete pre/post deployment workflow
- **Test Suite** - Comprehensive POSIX testing framework with 100+ tests
- **CI/CD Ready** - Optimized for GitHub Actions and other CI systems

**Best for**: CI/CD pipelines, automation, and users who prefer shell scripting

[📚 Shell Documentation](shell/README.md)

## Authentication

### Frontegg OAuth (Recommended for CI/CD)

Get your Frontegg credentials:

1. Log into [Causely Portal](https://portal.causely.app/)
2. Open **User Settings** (top right bubble icon)
3. Click **Admin Portal**
4. Navigate to **API Tokens** (bottom of left menu)
5. Click **Generate Token**
6. Set description, role = "Admin", and click **Create**
7. Save the **Client ID** and **Client Secret** (shown only once!)

Then set as environment variables:

```bash
export FRONTEGG_CLIENT_ID="your-client-id"
export FRONTEGG_CLIENT_SECRET="your-client-secret"
```

### Direct JWT Token (For Development)

For development and testing, you can use a direct JWT token:

```bash
./create_snapshot.sh \
  "https://api.causely.app/query" \
  "YOUR_JWT_TOKEN" \
  "Snapshot Name" \
  "Description" \
  "2025-10-20T10:00:00Z"
```

## Use Cases

### 1. Pre/Post Deployment Validation

Capture system state before and after deployments to identify regressions:

```bash
# Before deployment
./create_snapshot.sh --name "Pre-Deploy" --description "..." "$START" "$END"

# Deploy your application
kubectl apply -f deployment.yaml

# After deployment
./create_snapshot.sh --name "Post-Deploy" --description "..." "$START" "$END"

# Compare and validate
./compare_snapshots.sh "$PRE_ID" "$POST_ID"
```

### 2. Shift Left Testing

Compare release candidates in staging/test environments:

```bash
# Create baseline snapshot during load test
# Deploy new release candidate
# Create comparison snapshot during load test
# Compare to assess performance and stability
```

### 3. Scheduled Baseline Snapshots

Create regular snapshots for historical comparison:

```yaml
# GitHub Actions - Hourly snapshots
on:
  schedule:
    - cron: '0 * * * *'
```

### 4. Environment Drift Detection

Compare production vs staging to identify configuration differences:

```bash
./compare_snapshots.sh \
  "$PROD_SNAPSHOT_ID" "$STAGING_SNAPSHOT_ID" \
  --scope Service=payment-service,order-service
```

## Comparison Assessment

Snapshot comparisons provide automated assessment (ACCEPTED/REJECTED) based on:

**❌ REJECTED** if:
- Significant new defects detected
- Large resource utilization increases
- Service degradation (errors, latency)
- Many entities removed

**✅ ACCEPTED** if:
- No significant issues detected
- Metrics within acceptable ranges
- System remains stable

## Project Structure

```
causely-api-client/
├── README.md                    # This file
├── shell/                       # Shell/Bash implementation
│   ├── lib/                    # Reusable libraries
│   │   ├── causely_common.sh
│   │   ├── causely_auth.sh
│   │   └── causely_graphql.sh
│   ├── tests/                  # Comprehensive test suite
│   ├── create_snapshot.sh
│   ├── compare_snapshots.sh
│   └── snapshot_workflow.sh
```

## Documentation

- **[Snapshot API Reference](docs/snapshot-api.md)** - Complete GraphQL API documentation
- **[API Summary](docs/SNAPSHOT_API_SUMMARY.md)** - Quick reference and use cases
- **[Shell Library Overview](shell/LIBRARY_OVERVIEW.md)** - Detailed Shell library documentation
- **[Shell Library API](shell/lib/README_GRAPHQL.md)** - GraphQL library function reference

## Requirements

### Shell/Bash
- POSIX-compliant shell (sh, bash, zsh, dash)
- `jq` 1.5+ (JSON processing)
- `curl` (HTTP requests)
- `bc` (floating-point math for comparisons)

## Installation

### Clone the Repository

```bash
git clone https://github.com/Causely/causely-api-client.git
cd causely-api-client
```

### Install Dependencies

**Shell/Bash:**
```bash
# macOS
brew install jq

# Ubuntu/Debian
sudo apt-get install jq bc

# CentOS/RHEL
sudo yum install jq bc
```

## Testing

### Shell Tests

The Shell implementation includes a comprehensive test suite:

```bash
cd shell/tests

# Run all tests
./run_all_tests.sh

# Run specific test suite
./test_common.sh
./test_graphql.sh
./test_auth.sh
./test_create_snapshot.sh
```

## Examples

### Create a Simple Workflow

```bash
#!/bin/sh
set -e

# Source the library
. shell/lib/causely_graphql.sh

# Authenticate
setup_causely_auth || exit 1

# Query entities
QUERY='query GetEntities($filter: EntityFilter, $first: Int) {
  entityConnection(entityFilter: $filter, first: $first) {
    edges { node { id name typeName } }
  }
}'

# Execute query
FILTER=$(jq -n '{entityTypes: ["Service", "Database"]}')
VARS=$(jq -n --argjson filter "$FILTER" '{entityFilter: $filter, first: 20}')
RESPONSE=$(execute_graphql "$API_URL" "$TOKEN" "$QUERY" "$VARS")

# Display results
echo "$RESPONSE" | jq '.data.entityConnection.edges[].node'
```

### Integrate with CI/CD

**GitHub Actions:**
```yaml
- name: Validate Deployment
  env:
    FRONTEGG_CLIENT_ID: ${{ secrets.FRONTEGG_CLIENT_ID }}
    FRONTEGG_CLIENT_SECRET: ${{ secrets.FRONTEGG_CLIENT_SECRET }}
  run: |
    cd shell
    ./snapshot_workflow.sh --wait 120
```

```

## Exit Codes

All scripts follow standard exit code conventions:

- **0**: Success (comparisons passed/ACCEPTED)
- **1**: Error or failure (comparisons failed/REJECTED)

This allows easy integration with CI/CD pipelines:

```bash
./snapshot_workflow.sh || exit 1  # Fail pipeline on rejection
```

## Contributing

Contributions are welcome! Please ensure:

1. Code follows existing patterns and style
2. Scripts remain POSIX-compliant (for shell)
3. Tests pass before submitting
4. Documentation is updated accordingly

## Support

For questions, issues, or feature requests:

1. Check the [documentation](docs/) for detailed guides
2. Review [examples](docs/examples/) for common patterns
3. Open an issue on GitHub with detailed information
4. Contact the Causely support team

## License

Copyright © 2025 Causely, Inc. All rights reserved.

## Additional Resources

- **[Causely Platform](https://portal.causely.app/)** - Main platform portal
- **[Causely Documentation](https://docs.causely.io/)** - Official documentation
- **[API Authentication Guide](docs/snapshot-api.md#authentication)** - Detailed auth setup

---

**Ready to get started?** Choose your language implementation and check out the corresponding README for detailed instructions!

