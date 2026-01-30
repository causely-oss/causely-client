# Causely Bash Library Test Suite

Comprehensive test suite for the Causely bash library, ensuring reliability and POSIX compliance.

## 🧪 Quick Start

```bash
# Run all tests
cd tests
./run_all_tests.sh

# Run individual test suite
./test_common.sh
./test_graphql.sh
./test_auth.sh
```

## 📋 Test Coverage

### `test_common.sh` - Common Utilities
Tests for `lib/causely_common.sh`:
- ✅ `command_exists` - Command detection
- ✅ `check_dependencies` - Dependency validation
- ✅ `prevent_sourcing` - Script protection
- ✅ Print functions (`print_error`, `print_success`, etc.)
- ✅ Color constants
- ✅ Include guards

### `test_graphql.sh` - GraphQL Operations
Tests for `lib/causely_graphql.sh`:
- ✅ `build_graphql_payload` - Request building
- ✅ `build_jq_object` - JSON object construction
- ✅ `build_key_value_pair` - Tag building
- ✅ `build_tags_array` - Tag array construction
- ✅ `build_time_filter` - Time range building
- ✅ `extract_graphql_data` - Response parsing
- ✅ `has_graphql_errors` - Error detection
- ✅ `validate_required` - Argument validation
- ✅ `validate_env_vars` - Environment validation
- ✅ Time utilities (`now_rfc3339`)
- ✅ Include guards

### `test_auth.sh` - Authentication
Tests for `lib/causely_auth.sh`:
- ✅ `authenticate_frontegg` - Error handling
- ✅ `setup_causely_auth` - Configuration modes
- ✅ Default environment variables
- ✅ Authentication mode detection
- ✅ Help message functions

### `test_create_snapshot_v2.sh` - Create Snapshot Script
Tests for `create_snapshot_v2.sh`:
- ✅ Script validation (exists, executable)
- ✅ Help message completeness
- ✅ Required argument validation
- ✅ Authentication validation
- ✅ Tag format validation
- ✅ Unknown option handling
- ✅ API URL defaults
- ✅ Script structure (shebang, error handling, sourcing)
- ✅ GraphQL mutation structure
- ✅ Documentation quality

## 🏗️ Test Framework

### Simple Custom Framework

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

#### Test Organization

```bash
#!/bin/sh
set -e

# Setup
SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
. "$SCRIPT_DIR/tests/test_framework.sh"
. "$SCRIPT_DIR/lib/your_library.sh"

# Test suite
test_suite "Feature Name"

assert_success "your_function 'arg'" \
    "Description of what should happen"

# Summary
test_summary
```

## 📊 Output Format

### Individual Test Output

```
=== Test Suite Name ===
  ✓ Test passed
  ✗ Test failed
    Expected: foo
    Actual:   bar
  ⊘ Test skipped

========================================
All tests passed!
Total:  15 tests
Passed: 15
========================================
```

### Master Test Runner Output

```
╔════════════════════════════════════════╗
║  Causely Bash Library Test Suite      ║
╚════════════════════════════════════════╝

Checking dependencies...
✓ All dependencies available

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Running: test_common
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

=== command_exists ===
  ✓ Detects existing command (sh)
  ✓ Returns false for non-existent command
...

╔════════════════════════════════════════╗
║         OVERALL TEST SUMMARY           ║
╚════════════════════════════════════════╝

Total test suites: 3

Passed (3):
  ✓ test_common
  ✓ test_graphql
  ✓ test_auth

🎉 All test suites passed!
```

## 🔧 Writing New Tests

### 1. Create Test File

```bash
cd tests
touch test_myfeature.sh
chmod +x test_myfeature.sh
```

### 2. Add Test Structure

```bash
#!/bin/sh
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
. "$SCRIPT_DIR/tests/test_framework.sh"
. "$SCRIPT_DIR/lib/myfeature.sh"

test_suite "My Feature"

assert_success "my_function 'test'" \
    "my_function works with valid input"

assert_failure "my_function '' 2>/dev/null" \
    "my_function fails with empty input"

test_summary
```

### 3. Add to Master Runner

Edit `run_all_tests.sh`:

```bash
run_test_suite "$TESTS_DIR/test_myfeature.sh"
```

## 🚀 CI/CD Integration

### GitHub Actions

```yaml
- name: Run Library Tests
  run: |
    cd docs/examples/bash/tests
    ./run_all_tests.sh
```

### Exit Codes

- `0` - All tests passed
- `1` - One or more tests failed

## 🐛 Debugging Tests

### Run Individual Test with Verbose Output

```bash
# Don't redirect stderr
sh -x test_common.sh
```

### Check Specific Function

```bash
# Test interactively
. test_framework.sh
. ../lib/causely_common.sh

# Run individual assertions
assert_success "command_exists jq" "jq exists"
```

### Capture Output

```bash
# Use capture_output helper
output=$(capture_output "your_command")
echo "Command output: $output"
```

## 📝 Test Guidelines

### What to Test

✅ **DO test:**
- Function exists and can be called
- Valid inputs produce expected outputs
- Invalid inputs fail gracefully
- Error handling works
- Edge cases (empty strings, nulls, etc.)
- POSIX compliance (works with `sh`, not just `bash`)

❌ **DON'T test:**
- External API calls (mock or skip these)
- Network connectivity
- User's specific credentials
- System-specific behaviors

### Test Naming

- Use descriptive test suite names: `test_suite "Feature Name"`
- Write clear assertion descriptions: `"Does X when Y"`
- Use consistent naming for test files: `test_*.sh`

### Test Isolation

- Each test should be independent
- Don't rely on test execution order
- Clean up temporary files/variables
- Backup and restore environment variables if modified

## 🎯 Coverage Goals

Target coverage areas:
- ✅ Core functions (100%)
- ✅ Error handling (100%)
- ✅ Edge cases (90%)
- ⚠️ Integration tests (minimal - requires credentials)

## 📚 Resources

- **POSIX Shell**: https://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html
- **Testing Best Practices**: https://github.com/sstephenson/bats
- **Shell Style Guide**: https://google.github.io/styleguide/shellguide.html

## 🤝 Contributing

When adding new library functions:

1. Write tests first (TDD approach)
2. Ensure tests pass with `sh` (not just `bash`)
3. Add tests to appropriate test file
4. Update this README if adding new test file
5. Run full test suite before committing

---

**Questions?** Check the main library documentation in `../lib/README.md`

