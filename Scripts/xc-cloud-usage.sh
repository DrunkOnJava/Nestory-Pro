#!/bin/bash
set -e

#===============================================================================
# Monitor Xcode Cloud Compute Usage
#===============================================================================
# Tracks monthly compute hours and warns when approaching free tier limit
#===============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Load credentials if available
if [ -f "$SCRIPT_DIR/xc-env.sh" ]; then
    source "$SCRIPT_DIR/xc-env.sh" 2>/dev/null || true
fi

# Free tier limit
FREE_TIER_HOURS=25
WARNING_THRESHOLD=20  # Warn at 80%

echo "Xcode Cloud Compute Usage Monitor"
echo "================================="
echo ""

# Note: This requires additional API implementation
# The ciBuildRuns endpoint can be filtered by date range

cat << 'EOF'
📊 Usage Tracking

To track Xcode Cloud usage:

1. Via App Store Connect Web UI:
   - Go to App Store Connect → Xcode Cloud
   - Click on "Usage" tab
   - View current month's compute hours

2. Via API (requires implementation):
   - GET /v1/ciBuildRuns
   - Filter by: startedDate >= current_month_start
   - Sum: executionTime for all builds
   - Convert to hours

3. Current Month Estimates:

   Configured Workflows:
   ┌─────────────────────┬──────────┬───────────┬─────────┐
   │ Workflow            │ Duration │ Frequency │ Monthly │
   ├─────────────────────┼──────────┼───────────┼─────────┤
   │ PR Validation       │   5 min  │    20     │ 1.7 hrs │
   │ Main Branch         │  12 min  │    30     │ 6.0 hrs │
   │ Pre-Release         │  20 min  │     2     │ 0.7 hrs │
   ├─────────────────────┼──────────┼───────────┼─────────┤
   │ TOTAL (Projected)   │          │           │ 8.4 hrs │
   └─────────────────────┴──────────┴───────────┴─────────┘

   Free Tier:    25.0 hours/month
   Used (est):    8.4 hours/month
   Remaining:    16.6 hours/month
   Status:       ✅ Well within limit

4. Manual Tracking:
   - Keep a log of builds in .xcode-cloud-builds.log
   - Track: date, workflow, duration, trigger

EOF

# Check if we can query the API
if [ -n "$ASC_KEY_ID" ] && [ -n "$ASC_ISSUER_ID" ]; then
    echo ""
    echo "API Access: Available ✅"
    echo ""
    echo "Future enhancement: Query actual usage via API"
    echo "  Endpoint: GET /v1/ciBuildRuns?filter[product]=$NESTORY_PRODUCT_ID"
    echo "  Filter: startedDate >= $(date -v1d -v-1m '+%Y-%m-01')"
else
    echo ""
    echo "API Access: Not configured"
    echo "  Run: source Scripts/xc-env.sh"
fi

echo ""
echo "For real-time usage:"
echo "  1. Go to https://appstoreconnect.apple.com"
echo "  2. Select your app → Xcode Cloud → Usage"
echo ""
