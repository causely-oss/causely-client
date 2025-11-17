#!/bin/sh
#
# Master Test Runner
#
# Runs all test suites and reports overall results
#

set -e

# Colors
if [ -t 1 ]; then
    GREEN='\033[0;32m'
    RED='\033[0;31m'
    BLUE='\033[0;34m'
    YELLOW='\033[1;33m'
    NC='\033[0m'
else
    GREEN=''
    RED=''
    BLUE=''
    YELLOW=''
    NC=''
fi

# ============================================================================
# Setup
# ============================================================================

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
FAILED_SUITES=""
PASSED_SUITES=""
TOTAL_SUITES=0

echo "╔════════════════════════════════════════╗"
echo "║  Causely Bash Library Test Suite      ║"
echo "╚════════════════════════════════════════╝"
echo ""

# ============================================================================
# Dependency Check
# ============================================================================

printf '%b\n' "${BLUE}Checking dependencies...${NC}"

missing_deps=""
for cmd in jq curl; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        missing_deps="$missing_deps $cmd"
    fi
done

if [ -n "$missing_deps" ]; then
    printf '%b\n' "${RED}Missing required dependencies:$missing_deps${NC}"
    echo "Please install missing dependencies and try again."
    exit 1
fi

printf '%b\n' "${GREEN}✓ All dependencies available${NC}"
echo ""

# ============================================================================
# Run Test Suites
# ============================================================================

run_test_suite() {
    _test_file="$1"
    _test_name=$(basename "$_test_file" .sh)
    
    TOTAL_SUITES=$((TOTAL_SUITES + 1))
    
    printf '%b\n' "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    printf '%b\n' "${BLUE}Running: $_test_name${NC}"
    printf '%b\n' "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    if sh "$_test_file"; then
        PASSED_SUITES="$PASSED_SUITES $_test_name"
        return 0
    else
        FAILED_SUITES="$FAILED_SUITES $_test_name"
        return 1
    fi
}

# Run each test suite
run_test_suite "$TESTS_DIR/test_common.sh"
run_test_suite "$TESTS_DIR/test_graphql.sh"
run_test_suite "$TESTS_DIR/test_auth.sh"
run_test_suite "$TESTS_DIR/test_create_snapshot_v2.sh"

# ============================================================================
# Overall Summary
# ============================================================================

echo ""
echo "╔════════════════════════════════════════╗"
echo "║         OVERALL TEST SUMMARY           ║"
echo "╚════════════════════════════════════════╝"
echo ""

# Count passed/failed
PASSED_COUNT=0
FAILED_COUNT=0

for suite in $PASSED_SUITES; do
    PASSED_COUNT=$((PASSED_COUNT + 1))
done

for suite in $FAILED_SUITES; do
    FAILED_COUNT=$((FAILED_COUNT + 1))
done

# Display results
echo "Total test suites: $TOTAL_SUITES"
echo ""

if [ $PASSED_COUNT -gt 0 ]; then
    printf '%b\n' "${GREEN}Passed ($PASSED_COUNT):${NC}"
    for suite in $PASSED_SUITES; do
        printf '%b\n' "${GREEN}  ✓ $suite${NC}"
    done
fi

if [ $FAILED_COUNT -gt 0 ]; then
    echo ""
    printf '%b\n' "${RED}Failed ($FAILED_COUNT):${NC}"
    for suite in $FAILED_SUITES; do
        printf '%b\n' "${RED}  ✗ $suite${NC}"
    done
fi

echo ""
echo "════════════════════════════════════════"

if [ $FAILED_COUNT -eq 0 ]; then
    printf '%b\n' "${GREEN}🎉 All test suites passed!${NC}"
    exit 0
else
    printf '%b\n' "${RED}❌ Some test suites failed${NC}"
    exit 1
fi

