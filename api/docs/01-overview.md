# Overview

## What is Causely API Client?

The Causely API Client is a Shell/Bash toolkit for integrating with the Causely GraphQL API. It provides production-ready scripts, reusable libraries, and GitHub Actions workflows for snapshot creation, comparison, and deployment validation.

## Key Capabilities

- **Snapshot Management**: Create and compare snapshots of your system state
- **Deployment Validation**: Automated pre/post deployment comparison workflows
- **CI/CD Integration**: Ready-to-use GitHub Actions workflows
- **Shell/Bash Implementation**: Production-ready scripts and reusable libraries
- **Flexible Authentication**: Support for both direct JWT tokens and Frontegg OAuth
- **Production Ready**: Comprehensive error handling and documentation

## What Are Snapshots?

Snapshots capture the state of your environment over a given time window. You can:

- **Create snapshots** to capture system state at specific points in time
- **Compare snapshots** to identify changes in entities, defects, resources, and services
- **Get automated assessment** (ACCEPTED/REJECTED) based on comparison results

## Common Use Cases

### 1. Pre/Post Deployment Validation

Capture system state before and after deployments to identify regressions:

```
1. Create "before" snapshot
2. Perform deployment
3. Wait for system stabilization
4. Create "after" snapshot
5. Poll until both are COMPLETE
6. Compare snapshots
7. Review assessment (ACCEPTED/REJECTED)
```

### 2. Shift Left Testing

Compare release candidates in staging/test environments to assess performance and stability before production deployment.

### 3. Scheduled Baseline Snapshots

Create regular snapshots for historical comparison and trend analysis.

### 4. Environment Drift Detection

Compare production vs staging to identify configuration or behavior differences.

## What's Included

- **Shell Scripts**: Production-ready scripts for creating and comparing snapshots
- **Reusable Libraries**: Source the libraries in your own scripts
- **GitHub Actions Workflows**: Ready-to-use CI/CD integration examples
- **Complete Documentation**: Step-by-step guides for all use cases

## Assessment Criteria

Snapshot comparisons provide automated assessment:

**✅ ACCEPTED** if:
- No significant issues detected
- Metrics within acceptable ranges
- System remains stable

**❌ REJECTED** if:
- Significant new defects detected
- Large resource utilization increases
- Service degradation (errors, latency)
- Many entities removed

## Next Steps

1. **[Quick Start](02-quick-start.md)** - Get up and running in minutes
2. **[API Reference](03-api-reference.md)** - Complete GraphQL API documentation
3. **[Shell Implementation](05-shell-implementation.md)** - Most comprehensive implementation
4. **[GitHub Actions](06-github-actions.md)** - CI/CD integration guide

## Requirements

- **Shell/Bash**: POSIX-compliant shell (sh, bash, zsh, dash, ash)
- **jq**: 1.5+ (JSON processing)
- **curl**: Any recent version (HTTP requests)
- **bc**: For floating-point math (in comparison scripts)

See [Quick Start Guide](02-quick-start.md) for installation instructions.
