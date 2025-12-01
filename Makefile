# Makefile for Nestory-Pro
# Provides convenient shortcuts for common development tasks

.PHONY: help build test clean install-deps \
        xc-cloud-setup xc-cloud-products xc-cloud-workflows \
        xc-cloud-pr-validate xc-cloud-deploy-testflight \
        xc-cloud-build-status xc-cloud-manual-build

#===============================================================================
# Default target
#===============================================================================

help: ## Show this help message
	@echo "Nestory-Pro Makefile"
	@echo "===================="
	@echo ""
	@echo "Available targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-25s\033[0m %s\n", $$1, $$2}'

#===============================================================================
# Build & Test
#===============================================================================

build: ## Build the app (Debug configuration)
	xcodebuild -project Nestory-Pro.xcodeproj \
		-scheme Nestory-Pro \
		-configuration Debug \
		-destination 'platform=iOS Simulator,name=iPhone 17 Pro Max'

test: ## Run all tests
	bundle exec fastlane test

test-unit: ## Run unit tests only
	xcodebuild test -project Nestory-Pro.xcodeproj \
		-scheme Nestory-Pro \
		-only-testing:Nestory-ProTests/UnitTests \
		-destination 'platform=iOS Simulator,name=iPhone 17 Pro Max'

test-integration: ## Run integration tests only
	xcodebuild test -project Nestory-Pro.xcodeproj \
		-scheme Nestory-Pro \
		-only-testing:Nestory-ProTests/IntegrationTests \
		-destination 'platform=iOS Simulator,name=iPhone 17 Pro Max'

clean: ## Clean build artifacts
	xcodebuild clean -project Nestory-Pro.xcodeproj -scheme Nestory-Pro

#===============================================================================
# Dependencies
#===============================================================================

install-deps: ## Install Ruby dependencies (Fastlane)
	bundle install

regenerate-project: ## Regenerate Xcode project from project.yml
	xcodegen generate
	@echo "✅ Project regenerated. You may need to reopen Xcode."

#===============================================================================
# Xcode Cloud CLI Setup
#===============================================================================

xc-cloud-setup: ## Setup Xcode Cloud CLI (build Swift tool)
	@echo "Building Xcode Cloud CLI tool..."
	cd Tools/xcodecloud-cli && swift build -c release
	@echo "✅ CLI tool built: Tools/xcodecloud-cli/.build/release/xcodecloud-cli"
	@echo ""
	@echo "Next steps:"
	@echo "  1. Create App Store Connect API key (see docs/XCODE_CLOUD_CLI_SETUP.md)"
	@echo "  2. Set environment variables or store in Keychain"
	@echo "  3. Run: make xc-cloud-products"

install-xc-cli: xc-cloud-setup ## Install CLI tool to /usr/local/bin
	cp Tools/xcodecloud-cli/.build/release/xcodecloud-cli /usr/local/bin/
	@echo "✅ Installed to /usr/local/bin/xcodecloud-cli"

#===============================================================================
# Xcode Cloud Operations
#===============================================================================

xc-cloud-products: ## List all Xcode Cloud products
	./Scripts/xcodecloud.sh list-products

xc-cloud-workflows: ## List workflows for Nestory-Pro
	./Scripts/xcodecloud.sh list-workflows

xc-cloud-pr-validate: ## Trigger PR validation workflow on current branch
	./Scripts/xcodecloud.sh pr-validate

xc-cloud-deploy-testflight: ## Deploy main branch to TestFlight
	./Scripts/xcodecloud.sh deploy-testflight

xc-cloud-build-status: ## Get build status (usage: make xc-cloud-build-status BUILD_ID=xxx)
	@if [ -z "$(BUILD_ID)" ]; then \
		echo "Error: BUILD_ID not specified"; \
		echo "Usage: make xc-cloud-build-status BUILD_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"; \
		exit 1; \
	fi
	./Scripts/xcodecloud.sh get-build $(BUILD_ID)

xc-cloud-manual-build: ## Trigger manual build (usage: make xc-cloud-manual-build WORKFLOW=xxx BRANCH=xxx)
	@if [ -z "$(WORKFLOW)" ] || [ -z "$(BRANCH)" ]; then \
		echo "Error: WORKFLOW and BRANCH required"; \
		echo "Usage: make xc-cloud-manual-build WORKFLOW='PR Validation' BRANCH=feature/foo"; \
		exit 1; \
	fi
	./Scripts/xcodecloud.sh trigger-build --workflow "$(WORKFLOW)" --branch "$(BRANCH)"

#===============================================================================
# FastLane Shortcuts
#===============================================================================

beta: ## Deploy to TestFlight (via Fastlane)
	bundle exec fastlane beta

release: ## Deploy to App Store (via Fastlane)
	bundle exec fastlane release

bump-patch: ## Bump patch version (1.0.0 -> 1.0.1)
	bundle exec fastlane bump_version

bump-minor: ## Bump minor version (1.0.0 -> 1.1.0)
	bundle exec fastlane bump_version type:minor

bump-major: ## Bump major version (1.0.0 -> 2.0.0)
	bundle exec fastlane bump_version type:major

#===============================================================================
# Git Helpers
#===============================================================================

git-status: ## Show git status with helpful formatting
	@git status

git-diff: ## Show git diff with helpful formatting
	@git diff

#===============================================================================
# Documentation
#===============================================================================

docs: ## Open all documentation files
	@open docs/XCODE_CLOUD_CLI_SETUP.md || cat docs/XCODE_CLOUD_CLI_SETUP.md
	@open CLAUDE.md || cat CLAUDE.md
	@open TODO.md || cat TODO.md

#===============================================================================
# Development Shortcuts
#===============================================================================

dev: ## Open project in Xcode
	open Nestory-Pro.xcodeproj

simulator: ## Launch iPhone 17 Pro Max simulator
	open -a Simulator --args -CurrentDeviceUDID xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx

#===============================================================================
# Utility
#===============================================================================

check-deps: ## Check if all dependencies are installed
	@echo "Checking dependencies..."
	@command -v xcodebuild >/dev/null 2>&1 || { echo "❌ xcodebuild not found"; exit 1; }
	@command -v swift >/dev/null 2>&1 || { echo "❌ Swift not found"; exit 1; }
	@command -v bundle >/dev/null 2>&1 || { echo "❌ Bundler not found. Run: gem install bundler"; exit 1; }
	@command -v xcodegen >/dev/null 2>&1 || { echo "❌ XcodeGen not found. Run: brew install xcodegen"; exit 1; }
	@command -v jq >/dev/null 2>&1 || { echo "❌ jq not found. Run: brew install jq"; exit 1; }
	@echo "✅ All dependencies found"
