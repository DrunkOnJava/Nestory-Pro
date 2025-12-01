# Xcode Cloud CLI

A Swift command-line interface for managing Xcode Cloud workflows via the App Store Connect API.

## Features

✅ **Fully Functional:**
- List all Xcode Cloud products
- List workflows for a product
- Create workflows with any action type (TEST, ARCHIVE, ANALYZE)
- Trigger builds on any branch
- Monitor build status
- Fetch workflow details

✅ **Workflow Types Supported:**
- Pull Request workflows (automatic on PR creation)
- Branch workflows (automatic on push)
- Tag workflows (automatic on tag creation)
- Manual workflows

✅ **Action Types Supported:**
- **TEST** - Run unit/UI tests (fully working!)
- **ARCHIVE** - Build and archive
- **ANALYZE** - Static analysis

## Quick Start

### 1. Build the CLI

```bash
cd Tools/xcodecloud-cli
swift build -c release
```

Binary location: `.build/arm64-apple-macosx/release/xcodecloud-cli`

### 2. Set Up Credentials

Create an App Store Connect API key with **App Manager** role:

1. Visit [App Store Connect → Users and Access → Keys](https://appstoreconnect.apple.com/access/api)
2. Create new key (or use existing)
3. Download `.p8` file
4. Note Key ID and Issuer ID

**Option A: Environment Variables (Recommended)**

```bash
# Add to ~/.xc-cloud-env
export ASC_KEY_ID="YOUR_KEY_ID"
export ASC_ISSUER_ID="YOUR_ISSUER_ID"
export ASC_PRIVATE_KEY_PATH="/path/to/AuthKey_XXX.p8"

# Load credentials
source ~/.xc-cloud-env
```

**Option B: macOS Keychain**

```bash
./Scripts/setup-asc-credentials.sh
```

### 3. Find Your Product ID

```bash
./.build/arm64-apple-macosx/release/xcodecloud-cli list-products
```

Example output:
```
Nestory-Pro (B6CFF695-FAF8-4D64-9C16-8F46A73F76EF)
```

## Usage Examples

### List Workflows

```bash
./.build/arm64-apple-macosx/release/xcodecloud-cli list-workflows \
  --product B6CFF695-FAF8-4D64-9C16-8F46A73F76EF
```

### Create PR Workflow with Tests

```bash
./.build/arm64-apple-macosx/release/xcodecloud-cli create-workflow \
  --product B6CFF695-FAF8-4D64-9C16-8F46A73F76EF \
  --name "PR Validation" \
  --description "Fast tests for pull requests" \
  --type pr \
  --scheme Nestory-Pro \
  --action test
```

### Create Branch Workflow with Archive

```bash
./.build/arm64-apple-macosx/release/xcodecloud-cli create-workflow \
  --product B6CFF695-FAF8-4D64-9C16-8F46A73F76EF \
  --name "Main Branch Archive" \
  --description "Archive on main branch push" \
  --type branch \
  --branch main \
  --scheme Nestory-Pro-Beta \
  --action archive
```

### Create Workflow with Multiple Actions

```bash
./.build/arm64-apple-macosx/release/xcodecloud-cli create-workflow \
  --product B6CFF695-FAF8-4D64-9C16-8F46A73F76EF \
  --name "Full CI Pipeline" \
  --description "Test and archive on main" \
  --type branch \
  --branch main \
  --scheme Nestory-Pro-Beta \
  --action test \
  --action archive
```

### Trigger a Build

```bash
./.build/arm64-apple-macosx/release/xcodecloud-cli trigger-build \
  --workflow <WORKFLOW_ID> \
  --branch main
```

### Monitor Build Status

```bash
./.build/arm64-apple-macosx/release/xcodecloud-cli get-build \
  --build <BUILD_ID>
```

### Fetch Workflow Details

```bash
./.build/arm64-apple-macosx/release/xcodecloud-cli get-workflow \
  --workflow <WORKFLOW_ID>
```

## Command Reference

### `list-products`

List all available Xcode Cloud products.

**Options:** None

### `list-workflows`

List workflows for a specific product.

**Required:**
- `--product <ID>` - Product ID from `list-products`

### `create-workflow`

Create a new Xcode Cloud workflow.

**Required:**
- `--product <ID>` - Product ID
- `--name <NAME>` - Workflow name
- `--description <DESC>` - Workflow description
- `--type <TYPE>` - Workflow type: `pr`, `branch`, `tag`, or `manual`
- `--scheme <SCHEME>` - Xcode scheme name
- `--action <ACTION>` - At least one action: `test`, `archive`, or `analyze`

**Type-Specific Options:**
- `--branch <PATTERN>` - Required for `--type branch` (e.g., `main`, `develop`)
- `--tag-pattern <PATTERN>` - Required for `--type tag` (e.g., `v*`, `release-*`)

**Examples:**

```bash
# PR workflow
--type pr

# Branch workflow
--type branch --branch main

# Tag workflow
--type tag --tag-pattern "v*"

# Manual workflow
--type manual
```

### `trigger-build`

Trigger a new build for a workflow.

**Required:**
- `--workflow <ID>` - Workflow ID from `list-workflows`
- `--branch <NAME>` - Branch name to build

### `get-build`

Get build status and details.

**Required:**
- `--build <ID>` - Build ID from `trigger-build`

### `get-workflow`

Fetch complete workflow configuration as JSON.

**Required:**
- `--workflow <ID>` - Workflow ID

## TEST Workflows - Implementation Details

TEST workflows are fully supported via CLI! The CLI configures test destinations with:

- **Device:** iPhone 17 Pro Max simulator (default)
- **Runtime:** `"default"` - Uses latest Xcode version
- **Test Configuration:** `USE_SCHEME_SETTINGS` - Respects your Xcode test plan

**How it works:**

The CLI sends this test destination structure:
```json
{
  "kind": "SIMULATOR",
  "deviceTypeIdentifier": "com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro-Max",
  "deviceTypeName": "iPhone 17 Pro Max",
  "runtimeIdentifier": "default",
  "runtimeName": "Latest from Selected Xcode"
}
```

**Key Insight:** Use `runtimeIdentifier: "default"` instead of specific iOS version identifiers like `com.apple.CoreSimulator.SimRuntime.iOS-18-1`. The API validates these identifiers and rejects unknown versions.

## Debugging

### Enable Verbose Output

```bash
./.build/arm64-apple-macosx/release/xcodecloud-cli create-workflow \
  --product <ID> \
  --name "Test" \
  --type pr \
  --scheme Nestory-Pro \
  --verbose
```

### Dry Run Mode (No API Calls)

```bash
export XC_CLOUD_DRY_RUN=1
export XC_CLOUD_VERBOSE=1

./.build/arm64-apple-macosx/release/xcodecloud-cli create-workflow \
  --product <ID> \
  --name "Test" \
  --type pr \
  --scheme Nestory-Pro
```

This prints the JSON payload without sending it to the API.

### Check Credentials

```bash
echo "Key ID: $ASC_KEY_ID"
echo "Issuer ID: $ASC_ISSUER_ID"
echo "Private Key: $ASC_PRIVATE_KEY_PATH"
ls -l "$ASC_PRIVATE_KEY_PATH"
```

## Architecture

### JWT Authentication

The CLI uses ES256 (ECDSA with P-256) JWT tokens for authentication:

1. Loads `.p8` PKCS8 private key
2. Generates JWT with HS256 header (Key ID + Issuer ID)
3. Signs with ECDSA P-256 private key
4. Sets expiration to 20 minutes (API maximum)
5. Includes in `Authorization: Bearer <JWT>` header

### Workflow Payload Structure

The CLI builds workflow payloads following the App Store Connect API schema:

```json
{
  "data": {
    "type": "ciWorkflows",
    "attributes": {
      "name": "...",
      "description": "...",
      "actions": [...],
      "branchStartCondition": {...},
      "clean": true,
      "containerFilePath": "*.xcodeproj"
    },
    "relationships": {
      "product": {...},
      "repository": {...},
      "macOsVersion": {...},
      "xcodeVersion": {...}
    }
  }
}
```

### Action Types

Each action in the `actions` array follows this structure:

**TEST Action:**
```json
{
  "name": "Test - iOS",
  "actionType": "TEST",
  "scheme": "Nestory-Pro",
  "platform": "IOS",
  "isRequiredToPass": true,
  "testConfiguration": {
    "kind": "USE_SCHEME_SETTINGS",
    "testDestinations": [
      {
        "kind": "SIMULATOR",
        "deviceTypeIdentifier": "com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro-Max",
        "deviceTypeName": "iPhone 17 Pro Max",
        "runtimeIdentifier": "default",
        "runtimeName": "Latest from Selected Xcode"
      }
    ]
  }
}
```

**ARCHIVE Action:**
```json
{
  "name": "Archive - iOS",
  "actionType": "ARCHIVE",
  "scheme": "Nestory-Pro-Beta",
  "platform": "IOS",
  "isRequiredToPass": true
}
```

**ANALYZE Action:**
```json
{
  "name": "Analyze - iOS",
  "actionType": "ANALYZE",
  "scheme": "Nestory-Pro",
  "platform": "IOS",
  "isRequiredToPass": true
}
```

## Troubleshooting

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for common errors and solutions.

## Documentation

- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Common errors and solutions
- [TEST-DESTINATION-FINDINGS.md](TEST-DESTINATION-FINDINGS.md) - TEST workflow research and solution
- [XCODE_CLOUD_STATUS.md](XCODE_CLOUD_STATUS.md) - Feature status overview
- [Implementation Plan](~/.claude/plans/prancy-exploring-nova.md) - Complete 6-phase implementation plan

## Contributing

This CLI was built to support the Nestory-Pro iOS app's CI/CD automation. Contributions welcome!

### Adding New Commands

1. Add new `AsyncParsableCommand` struct in `main.swift`
2. Register in `XcodeCloudCLI.subcommands` array
3. Implement `run() async throws` method
4. Use `AppStoreConnectClient` for API calls

### Testing API Calls

Use dry run mode to test payloads:
```bash
export XC_CLOUD_DRY_RUN=1
export XC_CLOUD_VERBOSE=1
# Run command to see JSON payload
```

## License

MIT License - See project root for details.

---

**Last Updated:** December 1, 2025
**Status:** ✅ Fully Functional - TEST workflows now working!
