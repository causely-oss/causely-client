#!/bin/sh
#
# Compare Causely Snapshots
#
# Usage:
#   ./compare_snapshots_v2.sh <SNAPSHOT_ID_1> <SNAPSHOT_ID_2> [SNAPSHOT_ID_3...]
#
# Options:
#   --scope-id ID          Apply a user scope to the comparison
#   -h, --help             Show help
#
# Authentication:
#   Set environment variables: FRONTEGG_CLIENT_ID, FRONTEGG_CLIENT_SECRET
#   Or provide: -t/--token
#
# Example:
#   export FRONTEGG_CLIENT_ID="your-client-id"
#   export FRONTEGG_CLIENT_SECRET="your-secret"
#   ./compare_snapshots_v2.sh \
#     "550e8400-e29b-41d4-a716-446655440000" \
#     "660f9511-f30c-52e5-b827-557766551111"
#

set -e

# Source libraries
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/lib/causely_common.sh"
. "$SCRIPT_DIR/lib/causely_auth.sh"
. "$SCRIPT_DIR/lib/causely_graphql.sh"

prevent_sourcing "compare_snapshots_v2.sh" || exit 1

# Check dependencies
check_dependencies jq curl || exit 1

# ============================================================================
# Help & Usage
# ============================================================================

show_usage() {
    cat << EOF
Usage: $0 <SNAPSHOT_ID_1> <SNAPSHOT_ID_2> [SNAPSHOT_ID_3...] [OPTIONS]

Arguments:
  SNAPSHOT_ID_1, SNAPSHOT_ID_2...    IDs of snapshots to compare (at least 2)

Options:
  --scope-id ID          (optional) Apply a user scope to the comparison
  -t, --token TOKEN      (alternative) JWT token (prefer use FRONTEGG_* env vars)
  -h, --help             Show this help

Authentication:
  Set environment variables: FRONTEGG_CLIENT_ID, FRONTEGG_CLIENT_SECRET

Example:
  export FRONTEGG_CLIENT_ID="your-client-id"
  export FRONTEGG_CLIENT_SECRET="your-secret"
  $0 \\
    "550e8400-e29b-41d4-a716-446655440000" \\
    "660f9511-f30c-52e5-b827-557766551111"

EOF
    exit "${1:-1}"
}

# ============================================================================
# Argument Parsing
# ============================================================================

SNAPSHOT_IDS=""
SCOPE_ID=""
API_URL="$CAUSELY_API_URL_DEFAULT"
TOKEN=""

while [ $# -gt 0 ]; do
    case "$1" in
        -h|--help) show_usage 0 ;;
        -u|--api-url) API_URL="$2"; shift 2 ;;
        -t|--token) TOKEN="$2"; shift 2 ;;
        --scope-id) SCOPE_ID="$2"; shift 2 ;;
        -*)
            print_error "Unknown option: $1"
            show_usage 1
            ;;
        *)
            # Assume it's a snapshot ID
            SNAPSHOT_IDS="${SNAPSHOT_IDS}${SNAPSHOT_IDS:+
}$1"
            shift
            ;;
    esac
done

# ============================================================================
# Validation & Authentication
# ============================================================================

# Count snapshot IDs
SNAPSHOT_COUNT=$(echo "$SNAPSHOT_IDS" | grep -c '^' || echo 0)

if [ "$SNAPSHOT_COUNT" -lt 2 ]; then
    print_error "At least 2 snapshot IDs required"
    show_usage 1
fi

# Authenticate
if [ -n "$FRONTEGG_CLIENT_ID" ] && [ -n "$FRONTEGG_CLIENT_SECRET" ]; then
    setup_causely_auth || exit 1
elif [ -n "$API_URL" ] && [ -n "$TOKEN" ]; then
    print_info "Using direct token authentication"
else
    print_error "No authentication method provided"
    show_usage 1
fi

# ============================================================================
# Build Query & Variables
# ============================================================================

# NOTE: ignore shellcheck2016 - using single quotes to prevent bash expansion
QUERY='query CompareSnapshots($input: CompareSnapshotsInput!) {
  compareSnapshots(input: $input) {
    comparisonMetadata {
      snapshotIds
      comparisonDate
      totalSnapshots
      timespanCovered
      comparisonDuration
      snapshotsInfo {
        id
        name
        description
        startTime
        endTime
      }
    }
    comparisonDiffs {
      comparisonId
      snapshotId1
      snapshotId2
      assessment
      entityDiff {
        stableCount
        beforeOnlyCount
        afterOnlyCount
      }
      defectDiff {
        totalNewCount
        totalClearedCount
        countsByDefectType {
          defectType
          count
        }
      }
      resourceSummary {
        entityCountChange
        before {
          snapshotId
          entityCount
          avgCPUUtilization
          avgMemoryUtilization
        }
        after {
          snapshotId
          entityCount
          avgCPUUtilization
          avgMemoryUtilization
        }
      }
      serviceSummary {
        entityCountChange
        before {
          snapshotId
          entityCount
          requestRate
          requestErrorRate
          requestDuration
        }
        after {
          snapshotId
          entityCount
          requestRate
          requestErrorRate
          requestDuration
        }
      }
    }
  }
}'

# Build snapshot IDs array
SNAPSHOT_IDS_JSON=$(echo "$SNAPSHOT_IDS" | build_json_array)

# Build input object
if [ -n "$SCOPE_ID" ]; then
    INPUT=$(jq -n \
        --argjson snapshotIds "$SNAPSHOT_IDS_JSON" \
        --arg scopeId "$SCOPE_ID" \
        '{snapshotIds: $snapshotIds, userScopeId: $scopeId}')
else
    INPUT=$(jq -n \
        --argjson snapshotIds "$SNAPSHOT_IDS_JSON" \
        '{snapshotIds: $snapshotIds}')
fi

VARS=$(jq -n --argjson input "$INPUT" '{input: $input}')

# ============================================================================
# Execute Comparison
# ============================================================================

print_header "Comparing $SNAPSHOT_COUNT snapshots"

RESPONSE=$(execute_graphql "$API_URL" "$TOKEN" "$QUERY" "$VARS")
COMPARISON=$(extract_graphql_data "$RESPONSE" ".data.compareSnapshots")

# ============================================================================
# Display Results
# ============================================================================

METADATA=$(echo "$COMPARISON" | jq '.comparisonMetadata')
DIFFS=$(echo "$COMPARISON" | jq '.comparisonDiffs')

echo ""
print_success "Comparison Complete"
echo ""
echo "Comparison Date:     $(echo "$METADATA" | jq -r '.comparisonDate')"
echo "Total Snapshots:     $(echo "$METADATA" | jq -r '.totalSnapshots')"
echo "Timespan Covered:    $(echo "$METADATA" | jq -r '.timespanCovered')"
echo "Comparison Duration: $(echo "$METADATA" | jq -r '.comparisonDuration')"

print_header "Snapshots"
echo "$METADATA" | jq -r '.snapshotsInfo[] | 
    "\n• \(.name) (\(.id | .[0:8])...)\n  Time: \(.startTime) → \(.endTime)"'

print_header "Pairwise Comparisons"

DIFF_COUNT=$(echo "$DIFFS" | jq 'length')

for i in $(seq 0 $((DIFF_COUNT - 1))); do
    DIFF=$(echo "$DIFFS" | jq ".[$i]")
    
    ASSESSMENT=$(echo "$DIFF" | jq -r '.assessment')
    ID1=$(echo "$DIFF" | jq -r '.snapshotId1' | cut -c1-8)
    ID2=$(echo "$DIFF" | jq -r '.snapshotId2' | cut -c1-8)
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "[$((i+1))] ${ID1}... vs ${ID2}..."
    
    if [ "$ASSESSMENT" = "ACCEPTED" ]; then
        print_success "✅ ACCEPTED"
    else
        print_error "❌ REJECTED"
    fi
    
    # Entity changes
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
    
    # Defect changes
    if echo "$DIFF" | jq -e '.defectDiff' > /dev/null 2>&1; then
        DEFECT=$(echo "$DIFF" | jq '.defectDiff')
        NEW=$(echo "$DEFECT" | jq -r '.totalNewCount')
        CLEARED=$(echo "$DEFECT" | jq -r '.totalClearedCount')
        
        echo ""
        echo "Root Cause Changes:"
        echo "  New:     $NEW"
        echo "  Cleared: $CLEARED"
        
        [ "$NEW" -gt 0 ] && print_error "  ❌ $NEW new root causes detected!"
        [ "$CLEARED" -gt 0 ] && print_success "  ✅ $CLEARED root causes cleared"
        
        if [ "$NEW" -gt 0 ]; then
            echo ""
            echo "  New Root Causes by Type:"
            echo "$DEFECT" | jq -r '.countsByDefectType[]? | "    • \(.defectType): \(.count)"'
        fi
    fi
    
    # Resource changes
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
        echo "Resource Summary:"
        printf "  Avg CPU:    %.2f%% → %.2f%% (%+.2f%%)\n" "$BEFORE_CPU" "$AFTER_CPU" "$CPU_CHANGE"
        printf "  Avg Memory: %.2f%% → %.2f%% (%+.2f%%)\n" "$BEFORE_MEM" "$AFTER_MEM" "$MEM_CHANGE"
    fi
    
    # Service changes
    if echo "$DIFF" | jq -e '.serviceSummary.before and .serviceSummary.after' > /dev/null 2>&1; then
        SERVICE=$(echo "$DIFF" | jq '.serviceSummary')
        BEFORE=$(echo "$SERVICE" | jq '.before')
        AFTER=$(echo "$SERVICE" | jq '.after')
        
        echo ""
        echo "Service Summary:"
        
        if echo "$BEFORE" | jq -e '.requestRate' > /dev/null 2>&1; then
            BEFORE_RATE=$(echo "$BEFORE" | jq -r '.requestRate')
            AFTER_RATE=$(echo "$AFTER" | jq -r '.requestRate')
            RATE_CHANGE=$(printf "%.2f" "$(echo "$AFTER_RATE - $BEFORE_RATE" | bc)")
            printf "  Request Rate:     %.2f → %.2f req/s (%+.2f)\n" "$BEFORE_RATE" "$AFTER_RATE" "$RATE_CHANGE"
        fi
        
        if echo "$BEFORE" | jq -e '.requestErrorRate' > /dev/null 2>&1; then
            BEFORE_ERR=$(echo "$BEFORE" | jq -r '.requestErrorRate')
            AFTER_ERR=$(echo "$AFTER" | jq -r '.requestErrorRate')
            ERR_CHANGE=$(printf "%.4f" "$(echo "$AFTER_ERR - $BEFORE_ERR" | bc)")
            printf "  Error Rate:       %.4f → %.4f (%+.4f)\n" "$BEFORE_ERR" "$AFTER_ERR" "$ERR_CHANGE"
            
            if [ "$(echo "$ERR_CHANGE > 0.01" | bc)" -eq 1 ]; then
                print_error "  ❌ Error rate increased significantly!"
            fi
        fi
        
        if echo "$BEFORE" | jq -e '.requestDuration' > /dev/null 2>&1; then
            BEFORE_DUR=$(echo "$BEFORE" | jq -r '.requestDuration')
            AFTER_DUR=$(echo "$AFTER" | jq -r '.requestDuration')
            DUR_CHANGE=$(printf "%.4f" "$(echo "$AFTER_DUR - $BEFORE_DUR" | bc)")
            printf "  Request Duration: %.4fs → %.4fs (%+.4fs)\n" "$BEFORE_DUR" "$AFTER_DUR" "$DUR_CHANGE"
        fi
    fi
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check if any comparison was rejected
REJECTED=$(echo "$DIFFS" | jq '[.[] | select(.assessment == "REJECTED")] | length')

if [ "$REJECTED" -gt 0 ]; then
    echo ""
    print_warning "⚠️  $REJECTED comparison(s) were REJECTED"
    exit 1
else
    echo ""
    print_success "✅ All comparisons ACCEPTED"
    exit 0
fi

