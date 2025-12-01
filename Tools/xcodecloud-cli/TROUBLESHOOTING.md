# Xcode Cloud CLI - Troubleshooting Guide

This guide covers common errors and solutions when using the xcodecloud-cli tool.

---

## Common Errors

### "At least one action required"

**Error Message:**
```
Error: At least one action required
```

**Cause:** No `--action` specified when creating a workflow

**Fix:** Add at least one action type:
```bash
--action test
# or
--action test --action archive
```

---

### "--branch required for branch workflows"

**Error Message:**
```
Error: --branch required for branch workflows
```

**Cause:** Using `--type branch` without specifying `--branch`

**Fix:** Add the branch pattern:
```bash
--type branch --branch main
```

---

### "--tag-pattern required for tag workflows"

**Error Message:**
```
Error: --tag-pattern required for tag workflows
```

**Cause:** Using `--type tag` without specifying `--tag-pattern`

**Fix:** Add the tag pattern:
```bash
--type tag --tag-pattern "v*"
```

---

### "No repository found"

**Error Message:**
```
Error: No repository found. Ensure GitHub repo is linked in App Store Connect.
```

**Cause:** GitHub repository not linked to the Xcode Cloud product in App Store Connect

**Fix:**
1. Open [App Store Connect](https://appstoreconnect.apple.com)
2. Navigate to Apps → Nestory-Pro → Xcode Cloud
3. Connect your GitHub repository
4. Retry workflow creation

---

### "HTTP 403 Forbidden"

**Error Message:**
```
Error: HTTP 403: [FORBIDDEN] ...
```

**Cause:** API key lacks required permissions

**Fix:** Ensure your App Store Connect API key has the **App Manager** role:
1. Open App Store Connect → Users and Access → Keys
2. Select your API key
3. Verify role is "App Manager" or higher
4. If not, create a new key with proper permissions

---

### "HTTP 409 Conflict"

**Error Message:**
```
Error: HTTP 409: [ENTITY_ERROR.ATTRIBUTE.DUPLICATE] A workflow with this name already exists
```

**Cause:** Workflow with the same name already exists for this product

**Fix:**
- Use a different `--name` for the workflow, or
- Delete the existing workflow first (via Xcode Cloud UI or CLI), or
- List workflows to find the existing one: `./.build/arm64-apple-macosx/release/xcodecloud-cli list-workflows --product <ID>`

---

### "Invalid JWT" Error

**Error Message:**
```
Error: HTTP 401: Invalid JWT
```

**Cause:** Authentication credentials are incorrect or expired

**Fix:**
1. Verify Key ID matches your App Store Connect key: `echo $ASC_KEY_ID`
2. Verify Issuer ID is correct: `echo $ASC_ISSUER_ID`
3. Ensure .p8 file path is valid: `ls -l $ASC_PRIVATE_KEY_PATH`
4. Check .p8 file is valid PKCS8 format
5. Re-run credential setup: `./Scripts/setup-asc-credentials.sh`

---

### "Failed to retrieve from Keychain"

**Error Message:**
```
Error: Failed to retrieve 'ASC_API_KEY_ID' from Keychain
```

**Cause:** Credentials not stored in macOS Keychain or environment variables not set

**Fix:**

**Option A: Use environment variables**
```bash
source ~/.xc-cloud-env
```

**Option B: Store in Keychain**
```bash
./Scripts/setup-asc-credentials.sh
```

---

### "No macOS versions available" / "No Xcode versions available"

**Error Message:**
```
Error: No macOS versions available
```

**Cause:** API unable to fetch available build environment versions

**Fix:**
1. Verify your App Store Connect API access is working: `./.build/arm64-apple-macosx/release/xcodecloud-cli list-products`
2. Check your internet connection
3. Try again later (may be a temporary App Store Connect API issue)

---

## Debugging Tips

### Enable Verbose Mode

Add `--verbose` flag to see detailed API requests and responses:

```bash
./.build/arm64-apple-macosx/release/xcodecloud-cli create-workflow \
  --product <ID> \
  --name "Test" \
  --type pr \
  --scheme Nestory-Pro \
  --verbose
```

### Enable Dry Run Mode

Test payload structure without making actual API calls:

```bash
export XC_CLOUD_DRY_RUN=1
export XC_CLOUD_VERBOSE=1

./.build/arm64-apple-macosx/release/xcodecloud-cli create-workflow \
  --product <ID> \
  --name "Test" \
  --type pr \
  --scheme Nestory-Pro \
  --verbose
```

This will print the JSON payload that would be sent to the API.

### Check Credentials

Verify your credentials are loaded:

```bash
echo "Key ID: $ASC_KEY_ID"
echo "Issuer ID: $ASC_ISSUER_ID"
echo "Private Key Path: $ASC_PRIVATE_KEY_PATH"
ls -l "$ASC_PRIVATE_KEY_PATH"
```

### View API Response

For detailed API error messages, check the full output:

```bash
./.build/arm64-apple-macosx/release/xcodecloud-cli create-workflow \
  --product <ID> \
  --name "Test" \
  --type pr \
  --scheme Nestory-Pro \
  2>&1 | tee workflow-creation.log
```

---

### "Test destinations required" / Empty testDestinations

**Error Message:**
```
Error: HTTP 409: [ENTITY_ERROR.ATTRIBUTE.REQUIRED] You must provide a value for the attribute 'actions/testConfig/testDestinations'
```

**Cause:** TEST actions require at least one valid test destination object, not an empty array

**Solution:** ✅ **RESOLVED** - TEST workflows now fully supported via CLI!

The CLI now correctly configures test destinations with:
- `runtimeIdentifier: "default"` - Uses latest Xcode version (NOT specific iOS version identifiers)
- iPhone 17 Pro Max simulator as default device
- Proper CiTestDestination structure

**Example - Create TEST workflow:**
```bash
source ~/.xc-cloud-env
./.build/arm64-apple-macosx/release/xcodecloud-cli create-workflow \
  --product <ID> \
  --name "PR Validation" \
  --description "Fast tests for pull requests" \
  --type pr \
  --scheme Nestory-Pro \
  --action test
```

**See also:** `TEST-DESTINATION-FINDINGS.md` for technical details

---

## Getting Help

If you encounter an issue not covered in this guide:

1. Check the implementation plan: `/Users/griffin/.claude/plans/prancy-exploring-nova.md`
2. Review API findings: `XCODE_CLOUD_WORKFLOW_API_FINDINGS.md`
3. Check status documentation: `XCODE_CLOUD_STATUS.md`
4. Enable verbose mode and capture full output
5. Review [App Store Connect API documentation](https://developer.apple.com/documentation/appstoreconnectapi)

---

## Quick Reference

### Environment Variables

```bash
# Required credentials
export ASC_KEY_ID="your-key-id"
export ASC_ISSUER_ID="your-issuer-id"
export ASC_PRIVATE_KEY_PATH="/path/to/AuthKey_XXX.p8"

# Optional debugging
export XC_CLOUD_DRY_RUN=1    # Skip API calls
export XC_CLOUD_VERBOSE=1    # Show detailed output
```

### Binary Location

After `swift build -c release`:
```
.build/arm64-apple-macosx/release/xcodecloud-cli
```

### Common Commands

```bash
# List products
./.build/arm64-apple-macosx/release/xcodecloud-cli list-products

# List workflows
./.build/arm64-apple-macosx/release/xcodecloud-cli list-workflows --product <ID>

# Create PR workflow
./.build/arm64-apple-macosx/release/xcodecloud-cli create-workflow \
  --product <ID> --name "PR Validation" --type pr --scheme Nestory-Pro

# Create branch workflow with multiple actions
./.build/arm64-apple-macosx/release/xcodecloud-cli create-workflow \
  --product <ID> --name "Main Build" --type branch --branch main \
  --action test --action archive --scheme Nestory-Pro-Beta
```

---

**Last Updated:** December 1, 2025
