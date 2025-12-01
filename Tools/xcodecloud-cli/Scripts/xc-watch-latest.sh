#!/bin/bash
#
# xc-watch-latest.sh - Watch the most recent build for a workflow
#
# Usage: ./Scripts/xc-watch-latest.sh <WORKFLOW_ID>
#
# Examples:
#   ./Scripts/xc-watch-latest.sh dd86c07d-9030-4821-a301-64969a23ef6d
#

set -e

# Colors
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

CLI_PATH="$(cd "$(dirname "$0")/.." && pwd)/.build/arm64-apple-macosx/release/xcodecloud-cli"

if [[ -z "$1" ]]; then
    echo -e "${RED}Error: Workflow ID required${NC}"
    echo "Usage: $0 <WORKFLOW_ID>"
    echo ""
    echo "Example:"
    echo "  $0 dd86c07d-9030-4821-a301-64969a23ef6d"
    exit 1
fi

WORKFLOW_ID="$1"

# Check credentials
if ! ASC_KEY_ID=$(security find-generic-password -a "$USER" -s "ASC_API_KEY_ID" -w 2>/dev/null); then
    echo -e "${RED}Error: ASC_API_KEY_ID not found in Keychain${NC}"
    exit 1
fi

if ! ASC_ISSUER_ID=$(security find-generic-password -a "$USER" -s "ASC_ISSUER_ID" -w 2>/dev/null); then
    echo -e "${RED}Error: ASC_ISSUER_ID not found in Keychain${NC}"
    exit 1
fi

export ASC_KEY_ID
export ASC_ISSUER_ID
export ASC_PRIVATE_KEY_PATH="${ASC_PRIVATE_KEY_PATH:-/Users/griffin/Downloads/AuthKey_ACR4LF383U.p8}"

echo -e "${BLUE}Fetching latest build for workflow: $WORKFLOW_ID${NC}"
echo ""

# Get latest build
BUILDS_OUTPUT=$("$CLI_PATH" list-builds --workflow "$WORKFLOW_ID" --limit 1)

# Extract build ID from first line after header
BUILD_ID=$(echo "$BUILDS_OUTPUT" | tail -n +4 | head -n 1 | awk '{print $1}')

if [[ -z "$BUILD_ID" || "$BUILD_ID" == "No" ]]; then
    echo -e "${RED}No builds found for this workflow${NC}"
    exit 1
fi

echo "Latest build: $BUILD_ID"
echo ""

# Monitor the build
"$CLI_PATH" monitor-build --build "$BUILD_ID" --follow
