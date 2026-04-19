# Contributing to Causely client tooling

This guide is for developers who want to contribute to this repository ([github.com/causely-oss/causely-client](https://github.com/causely-oss/causely-client)). The Go module for the CLI is `github.com/Causely/causely-api-client` (see root [`go.mod`](go.mod)).

## Table of Contents

- [Project Structure](#project-structure)
- [Development Setup](#development-setup)
- [Code Style](#code-style)
- [Testing](#testing)
- [Architecture](#architecture)
- [Submitting Changes](#submitting-changes)

## Project Structure

```
causely-client/
├── README.md                    # User-facing overview
├── CONTRIBUTING.md              # This file (developer guide)
├── go.mod / go.sum              # Go module for the CLI (`cli/`)
├── mcp/                         # MCP skills, references, starter agent configs
│   ├── SKILL.md                 # Master router skill (causely-mcp)
│   ├── complete-investigation.md
│   ├── skills/                  # Leaf skills (one directory per skill)
│   └── plugins/                 # Cursor, Claude, Codex, VS Code, OpenCode snippets
├── cli/                         # Kubernetes install CLI (Go)
│   └── ...
└── api/                         # Shell GraphQL client, docs, GitHub Actions
    ├── README.md
    ├── docs/                    # User documentation (numbered)
    │   ├── 01-overview.md
    │   ├── 02-quick-start.md
    │   ├── 03-api-reference.md
    │   ├── 04-authentication.md
    │   ├── 05-shell-implementation.md
    │   ├── 06-github-actions.md
    │   ├── 07-examples-and-use-cases.md
    │   └── 08-advanced-topics.md
    ├── shell/                   # Shell/Bash implementation
    │   ├── lib/                 # Reusable libraries
    │   │   ├── causely_common.sh
    │   │   ├── causely_auth.sh
    │   │   └── causely_graphql.sh
    │   ├── tests/
    │   └── *.sh                 # Production scripts
    └── github-actions/          # GitHub Actions workflow examples
        └── *.yml
```

## Development Setup

### API shell client (`api/`)

**Prerequisites**

- POSIX-compliant shell (sh, bash, zsh, dash, ash)
- `jq` 1.5+ (JSON processing)
- `curl` (HTTP requests)
- `bc` (floating-point math)

**Clone and run tests**

```bash
git clone https://github.com/causely-oss/causely-client.git
cd causely-client

cd api/shell/tests
./run_all_tests.sh
```

### CLI (`cli/`)

Build from the repository root:

```bash
go build -C cli -o causely .
./causely version
```

See [`cli/README.md`](cli/README.md) for install, auth, and Helm-related behavior.

## Code Style

### POSIX Compliance (shell under `api/shell/`)

All shell code must be **fully POSIX-compliant**:
- Works with sh, ash, dash, bash, zsh
- No Bash-specific extensions
- Tested on Alpine Linux (ash) and Ubuntu (dash)

### Naming Conventions

- **Variables**: `CAUSELY_*` for exported constants, `_*` for internal
- **Functions**: `print_*`, `prevent_*`, `authenticate_*`, `setup_*`
- **Internal variables**: `_fg_*`, `_causely_*`, `_auth_*`

### Error Handling

```bash
# Always check return codes
RESPONSE=$(execute_graphql "$API_URL" "$TOKEN" "$QUERY" "$VARS")
if [ $? -ne 0 ]; then
    print_error "Request failed"
    exit 1
fi

# Use early returns
if [ -z "$REQUIRED_VAR" ]; then
    print_error "Required variable not set"
    exit 1
fi
```

### Documentation

- Include JSDoc-style comments for all exported functions
- Document parameters and return values
- Provide usage examples
- Update relevant documentation files

## Testing

### API shell tests

```bash
cd api/shell/tests

# Run all tests
./run_all_tests.sh

# Run specific test suite
./test_common.sh      # Common utilities (19 tests)
./test_graphql.sh     # GraphQL operations (38 tests)
./test_auth.sh        # Authentication (15 tests)
./test_create_snapshot.sh  # create_snapshot.sh (30 tests)
```

### Test Framework

We use a lightweight, POSIX-compliant test framework (`test_framework.sh`) with no external dependencies.

#### Assertion Functions

```bash
# Assert command succeeds
assert_success "some_command" "Description"

# Assert command fails
assert_failure "some_command" "Description"

# Assert equality
assert_equals "expected" "actual" "Description"

# Assert string contains substring
assert_contains "haystack" "needle" "Description"

# Assert empty/not empty
assert_empty "$var" "Description"
assert_not_empty "$var" "Description"
```

#### Writing Tests

```bash
#!/bin/sh
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
. "$SCRIPT_DIR/tests/test_framework.sh"
. "$SCRIPT_DIR/lib/your_library.sh"

test_suite "Feature Name"

assert_success "your_function 'arg'" \
    "Description of what should happen"

test_summary
```

### Test Coverage Goals

- ✅ Core functions (100%)
- ✅ Error handling (100%)
- ✅ Edge cases (90%)
- ⚠️ Integration tests (minimal - requires credentials)

See [`api/shell/tests/README.md`](api/shell/tests/README.md) for testing documentation.

## Architecture

### Library Organization (`api/shell/lib/`)

Libraries are organized by responsibility:

- **`causely_common.sh`**: General utilities (not domain-specific)
- **`causely_auth.sh`**: Authentication-specific logic
- **`causely_graphql.sh`**: GraphQL operations

### Design Principles

1. **Separation of Concerns**: Each library has a single responsibility
2. **POSIX Compliance**: Works with any POSIX-compliant shell
3. **No Side Effects**: Libraries are safe to source multiple times
4. **Namespacing**: All exported identifiers are prefixed

### Adding New Functionality

#### When to Add to `causely_common.sh`

Add here if the functionality is:
- ✅ General-purpose (not auth-specific)
- ✅ Reusable across multiple scripts
- ✅ Pure utility (no external dependencies)

Examples: Formatting, validation, file operations

#### When to Add to `causely_auth.sh`

Add here if the functionality is:
- ✅ Authentication-specific
- ✅ Requires API credentials
- ✅ Frontegg-related

Examples: Token refresh, credential validation

#### When to Create a New Library

Create a new library (`causely_*.sh`) if:
- ✅ Functionality is domain-specific (not common, not auth)
- ✅ Multiple scripts need it
- ✅ It would bloat existing libraries

Examples: `causely_graphql.sh` (GraphQL utilities)

## Submitting Changes

### Before Submitting

1. ✅ Run API shell tests: `cd api/shell/tests && ./run_all_tests.sh`
2. ✅ Test with multiple shells (sh, bash, dash)
3. ✅ Update documentation if needed
4. ✅ Follow code style guidelines
5. ✅ Write tests for new functionality

### Pull Request Process

1. Create a feature branch
2. Make your changes
3. Add/update tests
4. Update documentation
5. Submit pull request with clear description

### Commit Messages

Use clear, descriptive commit messages:
- Start with a verb (Add, Fix, Update, Remove)
- Be specific about what changed
- Reference issues if applicable

Example:
```
Add retry logic to execute_graphql function

Implements exponential backoff for transient network errors.
Fixes #123
```

## Questions?

- Check [`api/shell/tests/README.md`](api/shell/tests/README.md) for testing documentation
- Review existing code for patterns
- Open an issue for discussion
