# Causely API Client

A Shell/Bash client library and CLI toolkit for integrating with the Causely GraphQL API. This repository provides production-ready scripts, reusable libraries, and GitHub Actions workflows for snapshot creation, comparison, and deployment validation.

## Table of Contents

- [Overview](#overview)
- [Quick Start](#quick-start)
- [Documentation](#documentation)
- [Key Features](#key-features)
- [Project Structure](#project-structure)
- [Requirements](#requirements)
- [Support](#support)

## Overview

The Causely API Client enables developers and DevOps teams to programmatically interact with the Causely platform's GraphQL backend. It provides tools for capturing system state snapshots, comparing them to identify changes, and integrating these capabilities into CI/CD pipelines for automated deployment validation and monitoring.

**What You Can Do:**
- ✅ Create snapshots of your system state
- ✅ Compare snapshots to identify changes
- ✅ Automate deployment validation
- ✅ Integrate with CI/CD pipelines
- ✅ Monitor system health over time

## Quick Start

### 1. Set Up Authentication

Get your Frontegg credentials:

1. Login to [Causely Portal](https://portal.causely.app/)
2. **User Settings** → **Admin Portal** → **API Tokens** → **Generate Token**
3. Save **Client ID** and **Client Secret** (shown only once!)

### 2. Create Your First Snapshot

```bash
# Set up authentication
export FRONTEGG_CLIENT_ID="your-client-id"
export FRONTEGG_CLIENT_SECRET="your-client-secret"

# Create a snapshot
cd shell
./create_snapshot.sh \
  --name "Production Baseline" \
  --description "Baseline before deployment" \
  --start-time "$(date -u -d '2 hours ago' +'%Y-%m-%dT%H:%M:%SZ')"
```

See [Quick Start Guide](docs/02-quick-start.md) for detailed instructions.

## Documentation

All documentation is organized in the `docs/` directory with numbered files for easy navigation:

1. **[Overview](docs/01-overview.md)** - Introduction and key concepts
2. **[Quick Start](docs/02-quick-start.md)** - Get up and running in minutes
3. **[API Reference](docs/03-api-reference.md)** - Complete GraphQL API documentation
4. **[Authentication](docs/04-authentication.md)** - Authentication setup guide
5. **[Shell Implementation](docs/05-shell-implementation.md)** - Shell/Bash implementation guide
6. **[GitHub Actions](docs/06-github-actions.md)** - CI/CD integration guide
7. **[Examples and Use Cases](docs/07-examples-and-use-cases.md)** - Real-world examples
8. **[Advanced Topics](docs/08-advanced-topics.md)** - Advanced patterns and techniques

## Key Features

- **Shell/Bash Implementation**: Production-ready scripts and reusable libraries
- **Snapshot Management**: Create, query, and compare snapshots
- **Deployment Validation**: Automated pre/post deployment comparison workflows
- **CI/CD Integration**: Ready-to-use GitHub Actions workflows
- **Flexible Authentication**: Support for both direct JWT tokens and Frontegg OAuth
- **Production Ready**: Comprehensive error handling, testing, and documentation
- **Reusable Libraries**: Well-structured libraries for building custom workflows
- **Status Polling**: Built-in helpers for waiting for snapshot completion

## What's Included

- **Shell Scripts**: Production-ready scripts for creating and comparing snapshots
- **Reusable Libraries**: Source the libraries in your own scripts
- **GitHub Actions Workflows**: Ready-to-use CI/CD integration examples
- **Complete Documentation**: Step-by-step guides for all use cases

## Requirements

### Shell/Bash (Recommended)
- POSIX-compliant shell (sh, bash, zsh, dash, ash)
- `jq` 1.5+ (JSON processing)
- `curl` (HTTP requests)
- `bc` (floating-point math)

See [Quick Start Guide](docs/02-quick-start.md) for installation instructions.

## Support

For questions, issues, or feature requests:

1. **Check the Documentation:**
   - Start with [Overview](docs/01-overview.md) for introduction
   - See [Quick Start](docs/02-quick-start.md) to get started
   - Review [API Reference](docs/03-api-reference.md) for complete API docs
   - Check [Examples](docs/07-examples-and-use-cases.md) for real-world patterns

2. **Open an Issue:** GitHub issues with detailed information

3. **Contact Support:** Causely support team

## Contributing

Want to contribute to this project? See [CONTRIBUTING.md](CONTRIBUTING.md) for development setup, code style guidelines, testing, and architecture details.

## Additional Resources

- **[Causely Platform](https://portal.causely.app/)** - Main platform portal
- **[Causely Documentation](https://docs.causely.io/)** - Official documentation

---

**Ready to get started?** Begin with the [Quick Start Guide](docs/02-quick-start.md)!
