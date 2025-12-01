# Xcode Cloud CLI Setup - API-First Approach

This document explains how to manage Xcode Cloud **entirely from the command line** using the App Store Connect API.

## Overview

Xcode Cloud is fully scriptable via the [App Store Connect API](https://developer.apple.com/documentation/appstoreconnectapi/xcode-cloud-workflows-and-builds). All operations that would normally require the Xcode GUI can be done via HTTPS endpoints:

- **Products**: `GET /v1/ciProducts` - List Xcode Cloud products
- **Workflows**: `GET/POST/PATCH /v1/ciWorkflows` - Manage build pipelines
- **Builds**: `POST /v1/ciBuildRuns` - Trigger builds programmatically
- **Repositories**: `GET /v1/scmRepositories` - Manage source control

## Prerequisites

### 1. App Store Connect API Key

Create an API key with **App Manager** or **Admin** role:

1. Go to [App Store Connect](https://appstoreconnect.apple.com/) → Users and Access → Keys
2. Click **+** to generate a new API key
3. Name it: `Xcode Cloud CLI`
4. Role: **App Manager** (minimum required for Xcode Cloud operations)
5. Download the `.p8` file (only available once!)

You'll receive:
- **Issuer ID**: `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` (from Keys page header)
- **Key ID**: `XXXXXXXXXX` (10 characters, shown in the key list)
- **Private Key**: `AuthKey_XXXXXXXXXX.p8` file

### 2. Store Credentials Securely

**Option A: Keychain (Recommended)**
```bash
# Store in macOS Keychain
security add-generic-password \
  -a "$USER" \
  -s "ASC_API_KEY_ID" \
  -w "XXXXXXXXXX"

security add-generic-password \
  -a "$USER" \
  -s "ASC_ISSUER_ID" \
  -w "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

# Store private key content (base64 encoded)
cat AuthKey_XXXXXXXXXX.p8 | base64 | \
  security add-generic-password \
    -a "$USER" \
    -s "ASC_PRIVATE_KEY" \
    -w -
```

**Option B: Environment Variables**
```bash
# Add to ~/.zshrc or project .env (DO NOT COMMIT)
export ASC_KEY_ID="XXXXXXXXXX"
export ASC_ISSUER_ID="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
export ASC_PRIVATE_KEY_PATH="/path/to/AuthKey_XXXXXXXXXX.p8"
```

### 3. Install CLI Tool

```bash
# Build the Swift CLI tool
cd Tools/xcodecloud-cli
swift build -c release

# Install to PATH
cp .build/release/xcodecloud-cli /usr/local/bin/

# Or use via Make
make install-xc-cli
```

## Authentication

The App Store Connect API uses **JWT (JSON Web Tokens)** for authentication. Each request must include:

```
Authorization: Bearer <JWT>
```

### JWT Structure

```json
{
  "alg": "ES256",
  "kid": "XXXXXXXXXX",  // Your Key ID
  "typ": "JWT"
}
{
  "iss": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",  // Issuer ID
  "iat": 1638360000,  // Issued at (Unix timestamp)
  "exp": 1638363600,  // Expiration (20 minutes max)
  "aud": "appstoreconnect-v1"
}
```

Signed with your `.p8` private key using **ES256** (ECDSA with P-256 and SHA-256).

### Manual JWT Generation (curl example)

```bash
#!/bin/bash
# generate-jwt.sh - Generate JWT for App Store Connect API

KEY_ID="XXXXXXXXXX"
ISSUER_ID="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
PRIVATE_KEY_PATH="AuthKey_XXXXXXXXXX.p8"

# Header
HEADER=$(echo -n '{"alg":"ES256","kid":"'$KEY_ID'","typ":"JWT"}' | base64 | tr -d '=' | tr '/+' '_-' | tr -d '\n')

# Payload
ISSUED_AT=$(date +%s)
EXPIRES_AT=$((ISSUED_AT + 1200))  # 20 minutes
PAYLOAD=$(echo -n '{"iss":"'$ISSUER_ID'","iat":'$ISSUED_AT',"exp":'$EXPIRES_AT',"aud":"appstoreconnect-v1"}' | base64 | tr -d '=' | tr '/+' '_-' | tr -d '\n')

# Signature (requires OpenSSL)
SIGNATURE=$(echo -n "$HEADER.$PAYLOAD" | openssl dgst -sha256 -sign "$PRIVATE_KEY_PATH" | base64 | tr -d '=' | tr '/+' '_-' | tr -d '\n')

# JWT
JWT="$HEADER.$PAYLOAD.$SIGNATURE"
echo $JWT
```

**Note:** Our Swift CLI handles JWT generation automatically.

## CLI Usage

### List Xcode Cloud Products

Find the product ID for Nestory-Pro:

```bash
xcodecloud-cli list-products
```

Output:
```json
{
  "data": [{
    "id": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
    "type": "ciProducts",
    "attributes": {
      "name": "Nestory-Pro",
      "productType": "APP"
    }
  }]
}
```

**Equivalent curl:**
```bash
JWT=$(./scripts/generate-jwt.sh)

curl -H "Authorization: Bearer $JWT" \
     -H "Content-Type: application/json" \
     "https://api.appstoreconnect.apple.com/v1/ciProducts"
```

### List Workflows

```bash
xcodecloud-cli list-workflows --product <product-id>
```

**Equivalent curl:**
```bash
PRODUCT_ID="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

curl -H "Authorization: Bearer $JWT" \
     "https://api.appstoreconnect.apple.com/v1/ciProducts/$PRODUCT_ID/workflows"
```

### Create Workflow

```bash
xcodecloud-cli create-workflow \
  --product <product-id> \
  --name "PR Validation" \
  --branch-pattern "*/main" \
  --scheme "Nestory-Pro" \
  --actions build,test \
  --test-plan "Nestory-ProTests"
```

**Equivalent curl:**
```bash
curl -X POST \
  -H "Authorization: Bearer $JWT" \
  -H "Content-Type: application/json" \
  -d '{
    "data": {
      "type": "ciWorkflows",
      "attributes": {
        "name": "PR Validation",
        "description": "Validate pull requests before merge",
        "isEnabled": true
      },
      "relationships": {
        "product": {
          "data": {
            "type": "ciProducts",
            "id": "'"$PRODUCT_ID"'"
          }
        },
        "repository": {
          "data": {
            "type": "scmRepositories",
            "id": "'"$REPO_ID"'"
          }
        }
      }
    }
  }' \
  "https://api.appstoreconnect.apple.com/v1/ciWorkflows"
```

### Trigger Build

```bash
xcodecloud-cli trigger-build \
  --workflow <workflow-id> \
  --branch main \
  --commit abc123...
```

**Equivalent curl:**
```bash
WORKFLOW_ID="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
GIT_REF="refs/heads/main"

curl -X POST \
  -H "Authorization: Bearer $JWT" \
  -H "Content-Type: application/json" \
  -d '{
    "data": {
      "type": "ciBuildRuns",
      "relationships": {
        "workflow": {
          "data": {
            "type": "ciWorkflows",
            "id": "'"$WORKFLOW_ID"'"
          }
        },
        "sourceBranchOrTag": {
          "data": {
            "type": "scmGitReferences",
            "id": "'"$GIT_REF"'"
          }
        }
      }
    }
  }' \
  "https://api.appstoreconnect.apple.com/v1/ciBuildRuns"
```

### Monitor Build Status

```bash
xcodecloud-cli get-build --build-id <build-id>
```

**Equivalent curl:**
```bash
BUILD_ID="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

curl -H "Authorization: Bearer $JWT" \
     "https://api.appstoreconnect.apple.com/v1/ciBuildRuns/$BUILD_ID"
```

## Make Targets

Convenience wrappers in `Makefile`:

```bash
# List all products
make xc-cloud-products

# List workflows for Nestory-Pro
make xc-cloud-workflows

# Trigger PR validation workflow
make xc-cloud-pr-validate

# Trigger manual build on specific branch
make xc-cloud-manual-build BRANCH=feature/new-feature

# Get build status
make xc-cloud-build-status BUILD_ID=xxx

# Create new workflow from template
make xc-cloud-create-workflow NAME="Nightly Build" TEMPLATE=nightly
```

## Workflow Configuration

Workflows are defined in `.xcode-cloud-workflows.md` (human-readable) and created via API.

### Workflow Definition Structure

Each workflow requires:

1. **Start Condition** (when to run):
   - Branch/tag pattern: `refs/heads/main`, `refs/tags/v*`
   - Pull request events: `PULL_REQUEST_OPEN`, `PULL_REQUEST_UPDATE`
   - Schedule: Cron expression for periodic builds

2. **Actions** (what to do):
   - `BUILD` - Build the app
   - `BUILD_FOR_TESTING` - Build test bundle
   - `TEST` - Run tests
   - `ANALYZE` - Static analysis
   - `ARCHIVE` - Create distributable archive

3. **Test Configuration**:
   - Test plan: `Nestory-ProTests`
   - Destinations: iPhone/iPad simulator versions
   - Parallel execution: Yes/No

4. **Post-Actions**:
   - TestFlight deployment
   - Notifications (email, Slack)
   - Custom scripts

### Example: Complete Workflow via API

```bash
# Create "PR Validation" workflow
./scripts/create-pr-workflow.sh
```

This script:
1. Fetches product ID
2. Fetches repository ID
3. Creates workflow with:
   - Start condition: PR opened/updated
   - Actions: Build + Test on iPhone 17 Pro Max
   - Post-action: Post status to GitHub

## Environment Variables

The CLI and scripts recognize these environment variables:

| Variable | Description | Required |
|----------|-------------|----------|
| `ASC_KEY_ID` | App Store Connect API Key ID | Yes |
| `ASC_ISSUER_ID` | App Store Connect Issuer ID | Yes |
| `ASC_PRIVATE_KEY_PATH` | Path to `.p8` file | Yes (or use `ASC_PRIVATE_KEY`) |
| `ASC_PRIVATE_KEY` | Base64-encoded private key content | Alternative to path |
| `NESTORY_PRODUCT_ID` | Cached product ID | No (auto-fetched) |
| `XC_CLOUD_DRY_RUN` | Print API calls without executing | No |
| `XC_CLOUD_VERBOSE` | Verbose logging | No |

## Secrets Management

For CI/CD environments (GitHub Actions, etc.):

```yaml
# .github/workflows/trigger-xcode-cloud.yml
name: Trigger Xcode Cloud Build

on:
  push:
    branches: [main]

jobs:
  trigger:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Trigger Xcode Cloud
        env:
          ASC_KEY_ID: ${{ secrets.ASC_KEY_ID }}
          ASC_ISSUER_ID: ${{ secrets.ASC_ISSUER_ID }}
          ASC_PRIVATE_KEY: ${{ secrets.ASC_PRIVATE_KEY }}
        run: |
          ./scripts/xcodecloud.sh trigger-build --workflow pr-validation
```

## Debugging

### Enable Verbose Mode

```bash
export XC_CLOUD_VERBOSE=1
xcodecloud-cli list-workflows --product <id>
```

### Dry Run Mode

```bash
export XC_CLOUD_DRY_RUN=1
xcodecloud-cli trigger-build --workflow <id>
# Prints curl command without executing
```

### Validate JWT

```bash
# Decode JWT to inspect claims
JWT=$(./scripts/generate-jwt.sh)
echo $JWT | cut -d'.' -f2 | base64 -d | jq
```

### Test API Access

```bash
# Simple health check
./scripts/test-api-access.sh
```

## References

- [App Store Connect API - Xcode Cloud](https://developer.apple.com/documentation/appstoreconnectapi/xcode-cloud-workflows-and-builds)
- [WWDC24: Extend your Xcode Cloud workflows](https://developer.apple.com/videos/play/wwdc2024/10200/)
- [JWT Authentication Guide](https://developer.apple.com/documentation/appstoreconnectapi/generating-tokens-for-api-requests)
- [ciProducts API](https://developer.apple.com/documentation/appstoreconnectapi/ciproducts)
- [ciWorkflows API](https://developer.apple.com/documentation/appstoreconnectapi/ciworkflows)
- [ciBuildRuns API](https://developer.apple.com/documentation/appstoreconnectapi/cibuildruns)

## Troubleshooting

### "Invalid JWT" Error

- Check Key ID matches the key in App Store Connect
- Verify Issuer ID is from the correct team
- Ensure JWT expiration (`exp`) is within 20 minutes
- Private key must be in PKCS8 format

### "Forbidden" / 403 Error

- API key must have **App Manager** role or higher
- Key must not be revoked
- Team must have Xcode Cloud enabled

### "Product not found"

- Ensure app exists in App Store Connect
- Xcode Cloud must be enabled for the app (one-time GUI step)
- Check product ID is correct

---

**Last Updated:** November 30, 2025
**API Version:** v1
