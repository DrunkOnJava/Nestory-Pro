#!/usr/bin/env bash
# regenerate_project.sh - Regenerate Xcode project from project.yml
# Usage: ./Scripts/regenerate_project.sh [--validate]

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Nestory Pro - Project Regeneration${NC}"
echo "========================================"

# Check for xcodegen
if ! command -v xcodegen >/dev/null 2>&1; then
  echo -e "${RED}error: xcodegen not installed${NC}"
  echo "Install with: brew install xcodegen"
  exit 1
fi

# Check project.yml exists
if [[ ! -f "project.yml" ]]; then
  echo -e "${RED}error: project.yml not found in $ROOT_DIR${NC}"
  exit 1
fi

# Regenerate project
echo -e "\n${GREEN}[1/3]${NC} Regenerating Xcode project from project.yml..."
xcodegen generate --spec project.yml

# List new schemes
echo -e "\n${GREEN}[2/3]${NC} Verifying generated project..."
xcodebuild -project Nestory-Pro.xcodeproj -list

# Optional validation build
if [[ "${1:-}" == "--validate" ]]; then
  echo -e "\n${GREEN}[3/3]${NC} Validating Debug build..."
  xcodebuild \
    -project Nestory-Pro.xcodeproj \
    -scheme Nestory-Pro \
    -configuration Debug \
    -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' \
    -quiet build

  echo -e "\n${GREEN}Build validation successful.${NC}"
else
  echo -e "\n${YELLOW}[3/3]${NC} Skipping build validation (use --validate to enable)"
fi

echo -e "\n${GREEN}Project regenerated successfully.${NC}"
echo ""
echo "Available schemes:"
echo "  - Nestory-Pro       (Debug)"
echo "  - Nestory-Pro-Beta  (TestFlight)"
echo "  - Nestory-Pro-Release (App Store)"
echo ""
echo "Configurations with xcconfigs:"
echo "  - Debug   -> Config/Debug.xcconfig"
echo "  - Beta    -> Config/Beta.xcconfig"
echo "  - Release -> Config/Release.xcconfig"
