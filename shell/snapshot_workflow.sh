#!/bin/sh
#
# Complete Snapshot Workflow (v2 - using causely_graphql.sh library)
#
# This script demonstrates a complete workflow:
# 1. Create a "before" snapshot
# 2. Wait for system changes (deployment, etc.)
# 3. Create an "after" snapshot
# 4. Compare the snapshots
# 5. Report results
#
# Usage:
#   ./snapshot_workflow_v2.sh [OPTIONS]
#
# Options:
#   -w, --wait SECONDS      Wait time between snapshots (default: 60)
#   -d, --duration HOURS    Snapshot duration in hours (default: 1)
#   --tag KEY=VALUE         Add tag to snapshots (repeatable)
#   -h, --help              Show help
#
# Authentication:
#   Set environment variables: FRONTEGG_CLIENT_ID, FRONTEGG_CLIENT_SECRET
#

set -e

# Source libraries
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/lib/causely_common.sh"
. "$SCRIPT_DIR/lib/causely_auth.sh"
. "$SCRIPT_DIR/lib/causely_graphql.sh"

prevent_sourcing "snapshot_workflow_v2.sh" || exit 1

# Check dependencies
check_dependencies jq curl || exit 1

# ============================================================================
# Configuration
# ============================================================================

WAIT_SECONDS=60
DURATION_HOURS=1
TAGS=""

# Tag separator (newline) for accumulation - used by build_tags_array
# Using literal newline because $(printf '\n') loses the newline in command substitution
TAG_SEPARATOR='
'

# ============================================================================
# Help & Usage
# ============================================================================

show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Complete snapshot workflow: create baseline → wait → create comparison → compare results

Options:
  -w, --wait SECONDS      Wait time between snapshots (default: 60)
  -d, --duration HOURS    Snapshot duration in hours (default: 1)
  --tag KEY=VALUE         Add tag to both snapshots (repeatable)
  -h, --help              Show this help

Authentication:
  Set environment variables: FRONTEGG_CLIENT_ID, FRONTEGG_CLIENT_SECRET

Example:
  # Basic workflow with 2-minute wait
  export FRONTEGG_CLIENT_ID="your-client-id"
  export FRONTEGG_CLIENT_SECRET="your-secret"
  $0 --wait 120

  # With custom tags
  $0 --wait 300 --tag "environment=production" --tag "deployment=v1.2.3"

Typical CI/CD Usage:
  # Take baseline before deployment
  $0 --wait 0 --tag "stage=baseline"
  
  # ... deploy changes ...
  
  # Take comparison after deployment
  $0 --wait 0 --tag "stage=after-deploy"

EOF
    exit "${1:-1}"
}

# ============================================================================
# Argument Parsing
# ============================================================================

while [ $# -gt 0 ]; do
    case "$1" in
        -w|--wait) WAIT_SECONDS="$2"; shift 2 ;;
        -d|--duration) DURATION_HOURS="$2"; shift 2 ;;
        --tag)
            if ! echo "$2" | grep -q '^[^=]\+=.\+$'; then
                print_error "Invalid tag format: $2 (expected KEY=VALUE)"
                show_usage 1
            fi
            # Append tag with separator (skip separator if TAGS is empty)
            if [ -z "$TAGS" ]; then
                TAGS="$2"
            else
                TAGS="${TAGS}${TAG_SEPARATOR}$2"
            fi
            shift 2
            ;;
        -h|--help) show_usage 0 ;;
        *)
            print_error "Unknown option: $1"
            show_usage 1
            ;;
    esac
done

# ============================================================================
# Authentication
# ============================================================================

validate_env_vars FRONTEGG_CLIENT_ID FRONTEGG_CLIENT_SECRET || exit 1
setup_causely_auth || exit 1

# ============================================================================
# Helper Functions
# ============================================================================

# Function to create a snapshot
create_snapshot_with_tags() {
    _name="$1"
    _description="$2"
    _start_time="$3"
    _end_time="$4"
    
    MUTATION='mutation CreateSnapshot($options: SnapshotOptionsInput!) {
      createSnapshot(options: $options) {
        id
        name
        description
        createdAt
        startTime
        endTime
      }
    }'
    
    # Build base variables
    VARS=$(jq -n \
        --arg name "$_name" \
        --arg description "$_description" \
        --arg startTime "$_start_time" \
        --arg endTime "$_end_time" \
        '{options: {name: $name, description: $description, startTime: $startTime, endTime: $endTime}}')
    
    # Add tags if provided
    if [ -n "$TAGS" ]; then
        TAGS_JSON=$(echo "$TAGS" | build_tags_array)
        VARS=$(echo "$VARS" | jq --argjson tags "$TAGS_JSON" '.options.tags = $tags')
    fi
    
    # Execute and return full response
    execute_graphql "$API_URL" "$TOKEN" "$MUTATION" "$VARS"
}

# Function to compare snapshots
compare_snapshots() {
    _snapshot_id1="$1"
    _snapshot_id2="$2"
    
    QUERY='query CompareSnapshots($input: CompareSnapshotsInput!) {
      compareSnapshots(input: $input) {
        comparisonMetadata {
          comparisonDuration
        }
        comparisonDiffs {
          assessment
          entityDiff {
            stableCount
            beforeOnlyCount
            afterOnlyCount
          }
          defectDiff {
            totalNewCount
            totalClearedCount
          }
          resourceSummary {
            before { avgCPUUtilization avgMemoryUtilization }
            after { avgCPUUtilization avgMemoryUtilization }
          }
          serviceSummary {
            before { requestRate requestErrorRate requestDuration }
            after { requestRate requestErrorRate requestDuration }
          }
        }
      }
    }'
    
    # Build variables
    VARS=$(jq -n \
        --arg id1 "$_snapshot_id1" \
        --arg id2 "$_snapshot_id2" \
        '{input: {snapshotIds: [$id1, $id2]}}')
    
    execute_graphql "$API_URL" "$TOKEN" "$QUERY" "$VARS"
}

# ============================================================================
# Main Workflow
# ============================================================================

echo "══════════════════════════════════════════════════════════════════════════════"
print_header "CAUSELY SNAPSHOT WORKFLOW"
echo "══════════════════════════════════════════════════════════════════════════════"

# Calculate times
END_TIME=$(now_rfc3339)
START_TIME=$(time_offset "-${DURATION_HOURS}H")

# ============================================================================
# STEP 1: Create Baseline Snapshot
# ============================================================================

echo ""
print_header "[1/5] Creating Baseline Snapshot"

BASELINE_NAME="Baseline $(date -u +"%Y-%m-%d %H:%M")"
BASELINE_DESC="Baseline snapshot created at $END_TIME"

print_info "Creating snapshot: $BASELINE_NAME"
print_info "Time range: $START_TIME to $END_TIME"

BASELINE_RESPONSE=$(create_snapshot_with_tags \
    "$BASELINE_NAME" \
    "$BASELINE_DESC" \
    "$START_TIME" \
    "$END_TIME")

BASELINE=$(extract_graphql_data "$BASELINE_RESPONSE" ".data.createSnapshot")
BASELINE_ID=$(echo "$BASELINE" | jq -r '.id')

print_success "✅ Baseline created: $BASELINE_ID"
echo ""
echo "$BASELINE" | jq '.'

# ============================================================================
# STEP 2: Wait for Changes
# ============================================================================

echo ""
print_header "[2/5] Waiting for System Changes"

if [ "$WAIT_SECONDS" -eq 0 ]; then
    print_info "Skipping wait (--wait 0 specified)"
else
    print_info "Waiting $WAIT_SECONDS seconds for changes..."
    print_info "(This is where you would deploy changes in production)"
    
    # Countdown timer
    REMAINING=$WAIT_SECONDS
    while [ $REMAINING -gt 0 ]; do
        if [ $REMAINING -le 10 ] || [ $((REMAINING % 10)) -eq 0 ]; then
            printf "  %d seconds remaining...\r" $REMAINING
        fi
        sleep 1
        REMAINING=$((REMAINING - 1))
    done
    
    echo ""
    print_success "✅ Wait complete"
fi

# ============================================================================
# STEP 3: Create Comparison Snapshot
# ============================================================================

echo ""
print_header "[3/5] Creating Comparison Snapshot"

# Recalculate times for comparison snapshot
COMPARISON_END=$(now_rfc3339)
COMPARISON_START=$(time_offset "-${DURATION_HOURS}H")

COMPARISON_NAME="Comparison $(date -u +"%Y-%m-%d %H:%M")"
COMPARISON_DESC="Comparison snapshot created at $COMPARISON_END"

print_info "Creating snapshot: $COMPARISON_NAME"
print_info "Time range: $COMPARISON_START to $COMPARISON_END"

COMPARISON_RESPONSE=$(create_snapshot_with_tags \
    "$COMPARISON_NAME" \
    "$COMPARISON_DESC" \
    "$COMPARISON_START" \
    "$COMPARISON_END")

COMPARISON=$(extract_graphql_data "$COMPARISON_RESPONSE" ".data.createSnapshot")
COMPARISON_ID=$(echo "$COMPARISON" | jq -r '.id')

print_success "✅ Comparison created: $COMPARISON_ID"
echo ""
echo "$COMPARISON" | jq '.'

# ============================================================================
# STEP 4: Compare Snapshots
# ============================================================================

echo ""
print_header "[4/5] Comparing Snapshots"

print_info "Comparing: $(echo "$BASELINE_ID" | cut -c1-8)... vs $(echo "$COMPARISON_ID" | cut -c1-8)..."

COMPARE_RESPONSE=$(compare_snapshots "$BASELINE_ID" "$COMPARISON_ID")
COMPARISON_RESULT=$(extract_graphql_data "$COMPARE_RESPONSE" ".data.compareSnapshots")

DURATION=$(echo "$COMPARISON_RESULT" | jq -r '.comparisonMetadata.comparisonDuration')
print_success "✅ Comparison complete (Duration: $DURATION)"

# ============================================================================
# STEP 5: Analyze Results
# ============================================================================

echo ""
print_header "[5/5] Analyzing Results"

DIFF=$(echo "$COMPARISON_RESULT" | jq '.comparisonDiffs[0]')
ASSESSMENT=$(echo "$DIFF" | jq -r '.assessment')

echo ""
echo "══════════════════════════════════════════════════════════════════════════════"
echo "                            COMPARISON RESULTS"
echo "══════════════════════════════════════════════════════════════════════════════"
echo ""

if [ "$ASSESSMENT" = "ACCEPTED" ]; then
    print_success "Overall Assessment: ✅ ACCEPTED"
else
    print_error "Overall Assessment: ❌ REJECTED"
fi

# Entity Changes
if echo "$DIFF" | jq -e '.entityDiff' > /dev/null 2>&1; then
    ENTITY=$(echo "$DIFF" | jq '.entityDiff')
    STABLE=$(echo "$ENTITY" | jq -r '.stableCount')
    REMOVED=$(echo "$ENTITY" | jq -r '.beforeOnlyCount')
    ADDED=$(echo "$ENTITY" | jq -r '.afterOnlyCount')
    
    echo ""
    echo "Entity Changes:"
    echo "  Stable:  $STABLE"
    echo "  Removed: $REMOVED"
    echo "  Added:   $ADDED"
    
    [ "$REMOVED" -gt 0 ] && print_warning "  ⚠️  $REMOVED entities removed"
    [ "$ADDED" -gt 0 ] && print_info "  ℹ️  $ADDED entities added"
fi

# Defect Changes
if echo "$DIFF" | jq -e '.defectDiff' > /dev/null 2>&1; then
    DEFECT=$(echo "$DIFF" | jq '.defectDiff')
    NEW=$(echo "$DEFECT" | jq -r '.totalNewCount')
    CLEARED=$(echo "$DEFECT" | jq -r '.totalClearedCount')
    
    echo ""
    echo "Root Cause Changes:"
    echo "  New:     $NEW"
    echo "  Cleared: $CLEARED"
    
    if [ "$NEW" -gt 0 ]; then
        print_error "  ❌ Critical: $NEW new root causes detected!"
    fi
    if [ "$CLEARED" -gt 0 ]; then
        print_success "  ✅ Good: $CLEARED root causes cleared"
    fi
fi

# Resource Changes
if echo "$DIFF" | jq -e '.resourceSummary.before and .resourceSummary.after' > /dev/null 2>&1; then
    RESOURCE=$(echo "$DIFF" | jq '.resourceSummary')
    BEFORE=$(echo "$RESOURCE" | jq '.before')
    AFTER=$(echo "$RESOURCE" | jq '.after')
    
    BEFORE_CPU=$(echo "$BEFORE" | jq -r '.avgCPUUtilization')
    AFTER_CPU=$(echo "$AFTER" | jq -r '.avgCPUUtilization')
    CPU_CHANGE=$(printf "%.2f" "$(echo "$AFTER_CPU - $BEFORE_CPU" | bc)")
    
    BEFORE_MEM=$(echo "$BEFORE" | jq -r '.avgMemoryUtilization')
    AFTER_MEM=$(echo "$AFTER" | jq -r '.avgMemoryUtilization')
    MEM_CHANGE=$(printf "%.2f" "$(echo "$AFTER_MEM - $BEFORE_MEM" | bc)")
    
    echo ""
    echo "Resource Changes:"
    printf "  CPU:    %.2f%% → %.2f%% (%+.2f%%)\n" "$BEFORE_CPU" "$AFTER_CPU" "$CPU_CHANGE"
    printf "  Memory: %.2f%% → %.2f%% (%+.2f%%)\n" "$BEFORE_MEM" "$AFTER_MEM" "$MEM_CHANGE"
    
    # Warnings
    if [ "$(echo "$CPU_CHANGE > 10" | bc)" -eq 1 ]; then
        print_warning "  ⚠️  CPU utilization increased significantly"
    fi
    if [ "$(echo "$MEM_CHANGE > 10" | bc)" -eq 1 ]; then
        print_warning "  ⚠️  Memory utilization increased significantly"
    fi
fi

# Service Changes
if echo "$DIFF" | jq -e '.serviceSummary.before and .serviceSummary.after' > /dev/null 2>&1; then
    SERVICE=$(echo "$DIFF" | jq '.serviceSummary')
    BEFORE=$(echo "$SERVICE" | jq '.before')
    AFTER=$(echo "$SERVICE" | jq '.after')
    
    echo ""
    echo "Service Changes:"
    
    if echo "$BEFORE" | jq -e '.requestRate' > /dev/null 2>&1; then
        BEFORE_RATE=$(echo "$BEFORE" | jq -r '.requestRate')
        AFTER_RATE=$(echo "$AFTER" | jq -r '.requestRate')
        RATE_CHANGE=$(printf "%.2f" "$(echo "$AFTER_RATE - $BEFORE_RATE" | bc)")
        printf "  Request Rate: %.2f → %.2f req/s (%+.2f)\n" "$BEFORE_RATE" "$AFTER_RATE" "$RATE_CHANGE"
    fi
    
    if echo "$BEFORE" | jq -e '.requestErrorRate' > /dev/null 2>&1; then
        BEFORE_ERR=$(echo "$BEFORE" | jq -r '.requestErrorRate')
        AFTER_ERR=$(echo "$AFTER" | jq -r '.requestErrorRate')
        ERR_CHANGE=$(printf "%.4f" "$(echo "$AFTER_ERR - $BEFORE_ERR" | bc)")
        printf "  Error Rate:   %.4f → %.4f (%+.4f)\n" "$BEFORE_ERR" "$AFTER_ERR" "$ERR_CHANGE"
        
        if [ "$(echo "$ERR_CHANGE > 0.01" | bc)" -eq 1 ]; then
            print_error "  ❌ Critical: Error rate increased significantly!"
        fi
    fi
    
    if echo "$BEFORE" | jq -e '.requestDuration' > /dev/null 2>&1; then
        BEFORE_DUR=$(echo "$BEFORE" | jq -r '.requestDuration')
        AFTER_DUR=$(echo "$AFTER" | jq -r '.requestDuration')
        DUR_CHANGE=$(printf "%.4f" "$(echo "$AFTER_DUR - $BEFORE_DUR" | bc)")
        DUR_PCT=$(printf "%.1f" "$(echo "scale=1; ($DUR_CHANGE / $BEFORE_DUR) * 100" | bc 2>/dev/null || echo "0")")
        printf "  Duration:     %.4fs → %.4fs (%+.1f%%)\n" "$BEFORE_DUR" "$AFTER_DUR" "$DUR_PCT"
        
        if [ "$(echo "$DUR_PCT > 20" | bc 2>/dev/null || echo 0)" -eq 1 ]; then
            print_warning "  ⚠️  Request duration increased significantly"
        fi
    fi
fi

echo ""
echo "══════════════════════════════════════════════════════════════════════════════"
print_header "WORKFLOW COMPLETE"
echo "══════════════════════════════════════════════════════════════════════════════"
echo ""
echo "Baseline Snapshot ID:   $BASELINE_ID"
echo "Comparison Snapshot ID: $COMPARISON_ID"
echo ""

# Exit based on assessment
if [ "$ASSESSMENT" = "ACCEPTED" ]; then
    print_success "✅ Workflow succeeded - comparison ACCEPTED"
    exit 0
else
    print_error "❌ Workflow failed - comparison REJECTED"
    exit 1
fi

