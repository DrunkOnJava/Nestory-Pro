#!/bin/bash
#
# release.sh - One-command release pipeline for Nestory-Pro
#
# Usage: ./Scripts/release.sh [version]
#
# Examples:
#   ./Scripts/release.sh              # Interactive: prompts for version
#   ./Scripts/release.sh 1.0.2        # Non-interactive: uses provided version
#   ./Scripts/release.sh 1.0.2-rc1    # Pre-release tag
#
# What it does:
#   1. Validates version format
#   2. Checks if tag already exists
#   3. Creates and pushes git tag
#   4. Finds the triggered Xcode Cloud build
#   5. Monitors build progress
#   6. Prints App Store Connect URL when done
#

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PRODUCT_ID="B6CFF695-FAF8-4D64-9C16-8F46A73F76EF"
RELEASE_WORKFLOW_ID="dd86c07d-9030-4821-a301-64969a23ef6d"
CLI_PATH="$(cd "$(dirname "$0")/.." && pwd)/.build/arm64-apple-macosx/release/xcodecloud-cli"

# Helper functions
log_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

log_success() {
    echo -e "${GREEN}✅${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

log_error() {
    echo -e "${RED}❌${NC} $1"
}

validate_version() {
    local version=$1
    # Accept: 1.0.0, 1.0.0-rc1, 1.0.0-beta.2, etc.
    if [[ ! $version =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.]+)?$ ]]; then
        log_error "Invalid version format: $version"
        log_info "Expected format: MAJOR.MINOR.PATCH (e.g., 1.0.2) or MAJOR.MINOR.PATCH-PRERELEASE (e.g., 1.0.2-rc1)"
        return 1
    fi
    return 0
}

check_credentials() {
    log_info "Checking credentials..."

    if ! ASC_KEY_ID=$(security find-generic-password -a "$USER" -s "ASC_API_KEY_ID" -w 2>/dev/null); then
        log_error "ASC_API_KEY_ID not found in Keychain"
        log_info "Run: security add-generic-password -a \"\$USER\" -s \"ASC_API_KEY_ID\" -w \"YOUR_KEY_ID\""
        return 1
    fi

    if ! ASC_ISSUER_ID=$(security find-generic-password -a "$USER" -s "ASC_ISSUER_ID" -w 2>/dev/null); then
        log_error "ASC_ISSUER_ID not found in Keychain"
        log_info "Run: security add-generic-password -a \"\$USER\" -s \"ASC_ISSUER_ID\" -w \"YOUR_ISSUER_ID\""
        return 1
    fi

    export ASC_KEY_ID
    export ASC_ISSUER_ID
    export ASC_PRIVATE_KEY_PATH="${ASC_PRIVATE_KEY_PATH:-/Users/griffin/Downloads/AuthKey_ACR4LF383U.p8}"

    if [[ ! -f "$ASC_PRIVATE_KEY_PATH" ]]; then
        log_error "Private key not found at: $ASC_PRIVATE_KEY_PATH"
        log_info "Set ASC_PRIVATE_KEY_PATH environment variable or place key at default location"
        return 1
    fi

    log_success "Credentials loaded"
    return 0
}

check_cli() {
    if [[ ! -x "$CLI_PATH" ]]; then
        log_error "CLI not found or not executable at: $CLI_PATH"
        log_info "Run: cd Tools/xcodecloud-cli && swift build -c release"
        return 1
    fi
    log_success "CLI found at: $CLI_PATH"
    return 0
}

check_git_clean() {
    if [[ -n $(git status --porcelain) ]]; then
        log_warning "Working directory has uncommitted changes"
        read -p "Continue anyway? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Aborted"
            exit 1
        fi
    fi
}

check_tag_exists() {
    local tag=$1
    if git rev-parse "$tag" >/dev/null 2>&1; then
        log_error "Tag $tag already exists"
        log_info "Delete it first: git tag -d $tag && git push origin :refs/tags/$tag"
        return 1
    fi
    return 0
}

create_and_push_tag() {
    local tag=$1

    log_info "Creating tag: $tag"
    git tag "$tag"
    log_success "Tag created locally"

    log_info "Pushing tag to origin..."
    git push origin "$tag"
    log_success "Tag pushed to origin"
}

find_latest_build() {
    log_info "Waiting for Xcode Cloud to start build..."

    # Wait a few seconds for Xcode Cloud to process the tag
    sleep 5

    # Try to find the build for this workflow
    # Note: This is a simplified approach - a real implementation would
    # parse the list-builds output (which we'll add in Task 4)
    log_info "Build should be visible in Xcode Cloud shortly"
    log_info "Check: https://appstoreconnect.apple.com"
}

# Main script
main() {
    echo "========================================"
    echo "  Nestory-Pro Release Pipeline"
    echo "========================================"
    echo

    # Get version
    if [[ -n "$1" ]]; then
        VERSION="$1"
        log_info "Using provided version: $VERSION"
    else
        echo -n "Enter version (e.g., 1.0.2): "
        read VERSION
    fi

    # Validate version
    if ! validate_version "$VERSION"; then
        exit 1
    fi

    TAG="v${VERSION}"
    log_info "Will create tag: $TAG"
    echo

    # Pre-flight checks
    check_credentials || exit 1
    check_cli || exit 1
    check_git_clean
    check_tag_exists "$TAG" || exit 1
    echo

    # Confirmation
    log_warning "About to:"
    echo "  1. Create tag: $TAG"
    echo "  2. Push tag to origin"
    echo "  3. Trigger Xcode Cloud 'Release Builds' workflow"
    echo
    read -p "Continue? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Aborted"
        exit 0
    fi
    echo

    # Execute release
    create_and_push_tag "$TAG"
    echo

    find_latest_build
    echo

    log_success "Release pipeline started!"
    echo
    echo "Monitor your build:"
    echo "  → App Store Connect: https://appstoreconnect.apple.com/apps/6737385563/ci/workflows/$RELEASE_WORKFLOW_ID"
    echo "  → Or use: $CLI_PATH get-build --build <BUILD_ID>"
    echo
    log_info "The 'Release Builds' workflow will:"
    echo "  1. Run full test suite (iPhone 17 Pro Max)"
    echo "  2. Create archive with Nestory-Pro-Release scheme"
    echo "  3. Upload to App Store Connect"
    echo "  4. Ready for TestFlight or App Store submission"
    echo
}

# Run main function
main "$@"
