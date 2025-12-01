#!/bin/bash
set -e

#===============================================================================
# Xcode Cloud CLI Wrapper Script
#===============================================================================
# Provides friendly commands for managing Xcode Cloud via App Store Connect API
#
# Usage:
#   ./scripts/xcodecloud.sh list-products
#   ./scripts/xcodecloud.sh list-workflows
#   ./scripts/xcodecloud.sh trigger-build --workflow <id> --branch main
#===============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CLI_TOOL="$PROJECT_ROOT/Tools/xcodecloud-cli/.build/release/xcodecloud-cli"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

#===============================================================================
# Helper Functions
#===============================================================================

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_cli_tool() {
    if [ ! -f "$CLI_TOOL" ]; then
        log_warn "CLI tool not built. Building now..."
        (cd "$PROJECT_ROOT/Tools/xcodecloud-cli" && swift build -c release)
    fi
}

check_credentials() {
    if [ -z "$ASC_KEY_ID" ] && [ -z "$ASC_ISSUER_ID" ]; then
        log_error "App Store Connect credentials not configured!"
        echo ""
        echo "Set environment variables:"
        echo "  export ASC_KEY_ID='XXXXXXXXXX'"
        echo "  export ASC_ISSUER_ID='xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'"
        echo "  export ASC_PRIVATE_KEY_PATH='/path/to/AuthKey_XXXXXXXXXX.p8'"
        echo ""
        echo "Or store in macOS Keychain (see docs/XCODE_CLOUD_CLI_SETUP.md)"
        exit 1
    fi
}

cache_product_id() {
    if [ -z "$NESTORY_PRODUCT_ID" ]; then
        log_info "Fetching Nestory-Pro product ID..."
        PRODUCT_JSON=$("$CLI_TOOL" list-products --json)
        NESTORY_PRODUCT_ID=$(echo "$PRODUCT_JSON" | jq -r '.data[] | select(.attributes.name == "Nestory-Pro") | .id')

        if [ -z "$NESTORY_PRODUCT_ID" ]; then
            log_error "Nestory-Pro product not found in Xcode Cloud"
            exit 1
        fi

        export NESTORY_PRODUCT_ID
        log_info "Product ID: $NESTORY_PRODUCT_ID"
    fi
}

#===============================================================================
# Commands
#===============================================================================

cmd_list_products() {
    log_info "Fetching Xcode Cloud products..."
    "$CLI_TOOL" list-products "$@"
}

cmd_list_workflows() {
    cache_product_id
    log_info "Fetching workflows for Nestory-Pro..."
    "$CLI_TOOL" list-workflows --product "$NESTORY_PRODUCT_ID" "$@"
}

cmd_get_workflow() {
    local workflow_name="$1"
    cache_product_id

    log_info "Finding workflow: $workflow_name"
    WORKFLOWS_JSON=$("$CLI_TOOL" list-workflows --product "$NESTORY_PRODUCT_ID" --json)
    WORKFLOW_ID=$(echo "$WORKFLOWS_JSON" | jq -r ".data[] | select(.attributes.name == \"$workflow_name\") | .id")

    if [ -z "$WORKFLOW_ID" ]; then
        log_error "Workflow '$workflow_name' not found"
        exit 1
    fi

    echo "$WORKFLOW_ID"
}

cmd_trigger_build() {
    local workflow_name=""
    local branch=""
    local tag=""

    while [[ $# -gt 0 ]]; do
        case $1 in
            --workflow)
                workflow_name="$2"
                shift 2
                ;;
            --branch)
                branch="$2"
                shift 2
                ;;
            --tag)
                tag="$2"
                shift 2
                ;;
            *)
                log_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done

    if [ -z "$workflow_name" ]; then
        log_error "Must specify --workflow <name>"
        exit 1
    fi

    if [ -z "$branch" ] && [ -z "$tag" ]; then
        log_error "Must specify either --branch or --tag"
        exit 1
    fi

    WORKFLOW_ID=$(cmd_get_workflow "$workflow_name")
    log_info "Triggering workflow: $workflow_name ($WORKFLOW_ID)"

    if [ -n "$branch" ]; then
        "$CLI_TOOL" trigger-build --workflow "$WORKFLOW_ID" --branch "$branch"
    else
        "$CLI_TOOL" trigger-build --workflow "$WORKFLOW_ID" --tag "$tag"
    fi
}

cmd_get_build() {
    local build_id="$1"
    if [ -z "$build_id" ]; then
        log_error "Must specify build ID"
        exit 1
    fi

    "$CLI_TOOL" get-build --build "$build_id" "$@"
}

cmd_pr_validate() {
    log_info "Triggering PR Validation workflow on current branch..."
    local current_branch=$(git rev-parse --abbrev-ref HEAD)
    cmd_trigger_build --workflow "PR Validation" --branch "$current_branch"
}

cmd_deploy_testflight() {
    log_info "Triggering TestFlight deployment workflow..."
    cmd_trigger_build --workflow "Main Branch - Build & Test" --branch main
}

cmd_help() {
    cat << EOF
Xcode Cloud CLI Wrapper

Usage: $0 <command> [options]

Commands:
  list-products              List all Xcode Cloud products
  list-workflows             List workflows for Nestory-Pro
  trigger-build              Trigger a build
    --workflow <name>          Workflow name (e.g., "PR Validation")
    --branch <name>            Git branch (e.g., main)
    --tag <name>               Git tag (e.g., v1.0.0)
  get-build <id>             Get build status
  pr-validate                Trigger PR validation on current branch
  deploy-testflight          Deploy main branch to TestFlight
  help                       Show this help message

Environment Variables:
  ASC_KEY_ID                 App Store Connect API Key ID
  ASC_ISSUER_ID              App Store Connect Issuer ID
  ASC_PRIVATE_KEY_PATH       Path to .p8 private key file
  NESTORY_PRODUCT_ID         Cached product ID (auto-fetched if not set)

Examples:
  # List all workflows
  $0 list-workflows

  # Trigger PR validation
  $0 pr-validate

  # Trigger manual build on feature branch
  $0 trigger-build --workflow "PR Validation" --branch feature/new-ui

  # Check build status
  $0 get-build xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx

For more details, see: docs/XCODE_CLOUD_CLI_SETUP.md
EOF
}

#===============================================================================
# Main
#===============================================================================

main() {
    check_cli_tool
    check_credentials

    local command="$1"
    shift || true

    case "$command" in
        list-products)
            cmd_list_products "$@"
            ;;
        list-workflows)
            cmd_list_workflows "$@"
            ;;
        trigger-build)
            cmd_trigger_build "$@"
            ;;
        get-build)
            cmd_get_build "$@"
            ;;
        pr-validate)
            cmd_pr_validate "$@"
            ;;
        deploy-testflight)
            cmd_deploy_testflight "$@"
            ;;
        help|--help|-h|"")
            cmd_help
            ;;
        *)
            log_error "Unknown command: $command"
            echo ""
            cmd_help
            exit 1
            ;;
    esac
}

main "$@"
