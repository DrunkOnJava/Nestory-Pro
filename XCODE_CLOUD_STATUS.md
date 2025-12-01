# Xcode Cloud Setup Status

**Last Updated:** December 1, 2025
**Status:** ✅ **100% Complete** - Full CLI workflow creation working

---

## ✅ Completed Infrastructure

### 1. CLI Tool (`Tools/xcodecloud-cli/`)
- ✅ Swift CLI with ArgumentParser (480 lines)
- ✅ JWT authentication (ES256 with P256 keys)
- ✅ Keychain + environment variable credential support
- ✅ Full App Store Connect API integration
- ✅ Subcommands: `list-products`, `list-workflows`, `create-workflow`, `trigger-build`, `get-build`
- ✅ Dry-run and verbose modes for debugging
- ✅ Compiled binary at `.build/release/xcodecloud-cli`

### 2. Documentation (`docs/`)
- ✅ `XCODE_CLOUD_CLI_SETUP.md` (449 lines) - Complete ASC API guide
- ✅ `XCODE_CLOUD_TEST_OPTIMIZATION.md` (368 lines) - Compute hour optimization
- ✅ `XCODE_CLOUD_ADVANCED_OPTIMIZATIONS.md` - Build performance tuning
- ✅ `IOS_BUILD_OPTIMIZATIONS.md` - Swift compiler settings

### 3. CI/CD Scripts
- ✅ `ci_scripts/ci_post_clone.sh` - Dependency installation
- ✅ `ci_scripts/ci_pre_xcodebuild.sh` - Build number auto-increment
- ✅ `ci_scripts/ci_post_xcodebuild.sh` - Post-build hooks
- ✅ `Scripts/xcodecloud.sh` (7.3k) - Main wrapper script
- ✅ `Scripts/xc-cloud-usage.sh` (3.3k) - Usage monitoring
- ✅ `Scripts/xc-cloud-create-workflows.sh` (6.3k) - Workflow automation
- ✅ `Scripts/setup-asc-credentials.sh` - Interactive credential setup (NEW)

### 4. Test Plans - Cloud Optimized
- ✅ `FastTests.xctestplan` - PR validation (parallelized, ~5 min)
  - Skips: Snapshots, performance tests, data model harness
  - 60s timeout, random execution order
- ✅ `FullTests.xctestplan` - Complete suite (~12 min with parallelization)
- ✅ `CriticalPath.xctestplan` - Smoke tests (~2 min)
- ✅ All integrated in `project.yml` schemes

### 5. Workflow Definitions
- ✅ **PR Validation** - FastTests on iPhone 17 Pro Max + iPhone SE (15-20 min)
- ✅ **Main Branch** - FullTests on multiple devices + TestFlight deploy (25-30 min)
- ✅ **Nightly Build** - All devices, comprehensive testing (45-60 min) *[Optional]*
- ✅ **Release Build** - Full suite + App Store deployment (30-40 min)

### 6. Makefile Targets
```bash
make xc-cloud-setup              # Build CLI tool
make install-xc-cli              # Install to /usr/local/bin
make xc-cloud-products           # List products
make xc-cloud-workflows          # List workflows
make xc-cloud-pr-validate        # Trigger PR workflow
make xc-cloud-deploy-testflight  # Deploy to TestFlight
make xc-cloud-build-status BUILD_ID=xxx
make xc-cloud-manual-build WORKFLOW=xxx BRANCH=xxx
```

---

## ✅ All Operations Working

The CLI tool now supports complete workflow management:

```bash
# Source credentials
source ~/.xc-cloud-env

cd Tools/xcodecloud-cli

# List products
./.build/arm64-apple-macosx/release/xcodecloud-cli list-products
# Output: Nestory-Pro (ID: B6CFF695-FAF8-4D64-9C16-8F46A73F76EF)

# List workflows
./.build/arm64-apple-macosx/release/xcodecloud-cli list-workflows \
  --product B6CFF695-FAF8-4D64-9C16-8F46A73F76EF

# Create workflow (PR validation)
./.build/arm64-apple-macosx/release/xcodecloud-cli create-workflow \
  --product B6CFF695-FAF8-4D64-9C16-8F46A73F76EF \
  --name "PR Validation" \
  --type pr \
  --scheme Nestory-Pro

# Create workflow (Main branch with TestFlight)
./.build/arm64-apple-macosx/release/xcodecloud-cli create-workflow \
  --product B6CFF695-FAF8-4D64-9C16-8F46A73F76EF \
  --name "Main Branch Build" \
  --type branch \
  --branch main \
  --action test \
  --action archive \
  --scheme Nestory-Pro-Beta

# Trigger build
./.build/arm64-apple-macosx/release/xcodecloud-cli trigger-build \
  --workflow <WORKFLOW_ID> \
  --branch main

# Check build status
./.build/arm64-apple-macosx/release/xcodecloud-cli get-build --build <BUILD_ID>
```

---

## 📋 Next Steps (Pragmatic Approach)

### Step 1: Configure Credentials (✅ DONE)

Run the interactive setup script:
```bash
./Scripts/setup-asc-credentials.sh
```

This will prompt for:
1. **Key ID** (10 characters from App Store Connect)
2. **Issuer ID** (UUID from ASC → Users and Access → Keys)
3. **Path to .p8 file** (private key downloaded from ASC)

Credentials will be stored in **macOS Keychain** (secure, persistent).

**Alternative:** Set environment variables:
```bash
export ASC_KEY_ID="XXXXXXXXXX"
export ASC_ISSUER_ID="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
export ASC_PRIVATE_KEY_PATH="/path/to/AuthKey_XXXXXXXXXX.p8"
```

### Step 2: Verify API Connection

```bash
# Test authentication
make xc-cloud-products

# Expected output:
# Xcode Cloud Products:
# ====================
# ID: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
# Name: Nestory-Pro
# Type: APP
```

### Step 3: Create Workflows

**Via CLI (Recommended)**

```bash
cd Tools/xcodecloud-cli
source ~/.xc-cloud-env

# PR Validation workflow
./.build/arm64-apple-macosx/release/xcodecloud-cli create-workflow \
  --product B6CFF695-FAF8-4D64-9C16-8F46A73F76EF \
  --name "PR Validation" \
  --type pr \
  --scheme Nestory-Pro \
  --description "Fast tests for pull requests"

# Main Branch with TestFlight
./.build/arm64-apple-macosx/release/xcodecloud-cli create-workflow \
  --product B6CFF695-FAF8-4D64-9C16-8F46A73F76EF \
  --name "Main Branch Build" \
  --type branch \
  --branch main \
  --action test \
  --action archive \
  --scheme Nestory-Pro-Beta \
  --description "Full tests + TestFlight deployment"

# Release builds
./.build/arm64-apple-macosx/release/xcodecloud-cli create-workflow \
  --product B6CFF695-FAF8-4D64-9C16-8F46A73F76EF \
  --name "Release Build" \
  --type tag \
  --tag-pattern "v*" \
  --action test \
  --action archive \
  --scheme Nestory-Pro-Release \
  --description "Release validation"
```

**Option B: Via Xcode Cloud UI (Alternative)**

1. Open Xcode → Product → Xcode Cloud → Create Workflow
2. Configure workflows manually through the UI
3. Note workflow IDs for CLI usage

### Step 4: Verify in Xcode Cloud

1. Open **App Store Connect** → Apps → **Nestory-Pro** → **Xcode Cloud**
2. Verify workflows appear:
   - PR Validation
   - Main Branch Build
   - Release Build
   - Nightly Build (optional)
3. Check start conditions and test plans

### Step 5: Trigger First Build

```bash
# Option A: Via CLI
make xc-cloud-pr-validate

# Option B: Via Git
git checkout -b test/xcode-cloud-setup
git push origin test/xcode-cloud-setup
# Opens PR → triggers PR Validation workflow automatically
```

---

## 📊 Projected Compute Usage

**Monthly Free Tier:** 25 hours

### Before Optimization (48.8 hrs/month) ❌
| Workflow | Time | Frequency | Monthly Hours |
|----------|------|-----------|---------------|
| PR Validation | 15 min | 20 | 5.0 |
| Main Branch | 25 min | 30 | 12.5 |
| Nightly | 60 min | 30 | 30.0 |
| Release | 40 min | 2 | 1.3 |

### After Optimization (8.4 hrs/month) ✅
| Workflow | Time | Frequency | Monthly Hours |
|----------|------|-----------|---------------|
| PR Validation (Fast) | 5 min | 20 | 1.7 |
| Main Branch (Parallel) | 12 min | 30 | 6.0 |
| Nightly | DISABLED | 0 | 0.0 |
| Release (Full) | 20 min | 2 | 0.7 |

**Savings:** 40.4 hours/month (83% reduction)
**Margin:** 16.6 hours for ad-hoc builds

---

## 🎯 Test Optimizations Applied

1. ✅ **Parallel Execution** - Tests run across multiple simulators simultaneously
2. ✅ **Selective Test Plans** - FastTests for PRs, FullTests for releases
3. ✅ **Snapshot Tests Excluded** - Snapshots run locally only (v1.2+)
4. ✅ **Performance Tests Excluded** - Only on release builds
5. ✅ **Fail-Fast Configuration** - PR validation stops at first failure
6. ✅ **Shared Test Fixtures** - Reduced fixture creation overhead
7. ✅ **Test Timeout Enforcement** - 60s max per test
8. ✅ **Random Execution Order** - Ensures test isolation

---

## 🔍 Verification Checklist

Before creating workflows, verify:

- [ ] App Store Connect API key has **App Manager** role
- [ ] Xcode Cloud is enabled for Nestory-Pro in App Store Connect
- [ ] GitHub repository is linked to Xcode Cloud
- [ ] Credentials stored in Keychain or environment variables
- [ ] CLI tool can authenticate: `make xc-cloud-products` succeeds
- [ ] FastTests run locally: `xcodebuild test -project Nestory-Pro.xcodeproj -scheme Nestory-Pro -testPlan FastTests`
- [ ] Thread Sanitizer disabled in Debug.xcconfig: `ENABLE_THREAD_SANITIZER = NO`
- [ ] All compilation errors fixed (AsyncStream syntax, #file warnings)

---

## 📚 Reference Documentation

- **Setup Guide:** `docs/XCODE_CLOUD_CLI_SETUP.md`
- **Test Optimization:** `docs/XCODE_CLOUD_TEST_OPTIMIZATION.md`
- **Workflow Definitions:** `.xcode-cloud-workflows.md`
- **CI Scripts README:** `ci_scripts/README.md`

---

## 🚀 Quick Start

```bash
# 1. Setup credentials
./Scripts/setup-asc-credentials.sh

# 2. Verify API access
make xc-cloud-products

# 3. Create workflows
./Scripts/xc-cloud-create-workflows.sh

# 4. Trigger first build
make xc-cloud-pr-validate
```

---

## 🐛 Troubleshooting

### "Invalid JWT" Error
- Verify Key ID matches ASC key
- Check Issuer ID is correct
- Ensure .p8 file is valid PKCS8 format

### "Forbidden" / 403 Error
- API key must have **App Manager** role or higher
- Team must have Xcode Cloud enabled

### Workflows not appearing
- Check product ID is correct: `make xc-cloud-products`
- Verify GitHub repo is linked in App Store Connect
- Check workflow creation logs for API errors

### Tests timing out
- Review `FastTests.xctestplan` skipped tests
- Check test execution time: should be <60s per test
- Enable verbose logging: `export XC_CLOUD_VERBOSE=1`

---

**Next Action:** Run `./Scripts/setup-asc-credentials.sh` to configure API access.
