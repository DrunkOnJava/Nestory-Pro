# Xcode Cloud CLI - Next Steps (December 1, 2025)

## Current Status: 90% Complete

The Xcode Cloud CLI tool is **90% functional** with the following working features:

✅ **Working Commands:**
- `list-products` - List all Xcode Cloud products
- `list-workflows --product <ID>` - List workflows for a product
- `create-workflow` - Create ARCHIVE and ANALYZE workflows (fully working)
- `trigger-build --workflow <ID> --branch <BRANCH>` - Trigger builds
- `get-build --build <ID>` - Get build status
- `get-workflow --workflow <ID>` - Fetch workflow details (JSON)
- `list-test-destinations` - Added (endpoint doesn't exist, but command ready)

⚠️ **Blocked (Final 10%):**
- Creating TEST action workflows requires valid `testDestinations` objects

## What We Learned Today

### 1. Test Destinations API Endpoint Doesn't Exist
Attempted to call `/v1/ciTestDestinations` → **HTTP 404**

**Conclusion**: Test destinations are not available as standalone API resources.

### 2. Empty testDestinations Arrays Are Rejected

**Payload tested:**
```json
{
  "testConfiguration": {
    "kind": "USE_SCHEME_SETTINGS",
    "testDestinations": []
  }
}
```

**API response:**
```
HTTP 409: [ENTITY_ERROR.ATTRIBUTE.REQUIRED]
You must provide a value for the attribute 'actions/testConfig/testDestinations'
```

**Conclusion**: The API requires at least one valid test destination object, not an empty array.

### 3. Description Field Now Required

The API now requires a non-empty `description` field for workflow creation (previously optional).

**Fix applied**: Updated payload to include description in all workflow types.

## What Needs to Happen Next (Manual Step)

To proceed with TEST workflow implementation, we need a **golden workflow** created manually in the Xcode Cloud UI. This will reveal the exact structure of test destination objects.

### Step-by-Step Instructions

#### 1. Create a Minimal TEST Workflow in Xcode Cloud UI

1. Open [App Store Connect](https://appstoreconnect.apple.com)
2. Navigate to: **Apps** → **Nestory-Pro** → **Xcode Cloud**
3. Click **"Create Workflow"** (or **"+"** button)
4. Configure:
   - **Product**: Nestory-Pro
   - **Branch**: Any branch (e.g., `main`)
   - **Actions**: Add single **TEST** action
   - **Scheme**: `Nestory-Pro`
   - **Test Destination**: Select **iPhone 17 Pro Max** with latest iOS
5. Save the workflow with name: **"Golden Test Workflow"**

#### 2. Get the Workflow ID

After creating:
- Click on the newly created workflow
- Copy the workflow ID from the URL or workflow details

**Alternative**: Use the CLI to list workflows and find it:
```bash
source ~/.xc-cloud-env
cd Tools/xcodecloud-cli
./.build/arm64-apple-macosx/release/xcodecloud-cli list-workflows \
  --product B6CFF695-FAF8-4D64-9C16-8F46A73F76EF
```

#### 3. Fetch and Save the Golden Workflow JSON

```bash
source ~/.xc-cloud-env
cd Tools/xcodecloud-cli

# Replace <WORKFLOW_ID> with actual ID
./.build/arm64-apple-macosx/release/xcodecloud-cli get-workflow \
  --workflow <WORKFLOW_ID> > golden-test-workflow.json

# Display the test destinations structure
cat golden-test-workflow.json | grep -A 50 "testDestinations"
```

#### 4. Provide the JSON to Continue Implementation

Once you have `golden-test-workflow.json`, we can:
1. Extract the exact `CiTestDestination` structure
2. Add response models to the CLI
3. Implement logic to hardcode or fetch test destinations
4. Add CLI flags for device/runtime selection
5. Complete TEST workflow creation support

## Expected testDestinations Structure

Based on the plan analysis, we expect something like:

```json
{
  "testDestinations": [
    {
      "kind": "SIMULATOR",
      "deviceTypeIdentifier": "com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro-Max",
      "deviceTypeName": "iPhone 17 Pro Max",
      "runtimeIdentifier": "com.apple.CoreSimulator.SimRuntime.iOS-18-0",
      "runtimeName": "iOS 18.0"
    }
  ]
}
```

**Note**: This is hypothetical until we inspect the actual workflow JSON.

## Implementation Plan (After Golden Workflow)

Once we have the golden workflow structure:

### Step 3: Add TestDestinationsResponse Models
```swift
struct TestDestination: Codable {
    let kind: String
    let deviceTypeIdentifier: String
    let deviceTypeName: String
    let runtimeIdentifier: String
    let runtimeName: String
}
```

### Step 4: Update buildActions() Method
Replace empty array with hardcoded iPhone 17 Pro Max destination:
```swift
case .test:
    let testDest: [String: Any] = [
        "kind": "SIMULATOR",
        "deviceTypeIdentifier": "com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro-Max",
        "deviceTypeName": "iPhone 17 Pro Max",
        "runtimeIdentifier": "com.apple.CoreSimulator.SimRuntime.iOS-18-0",
        "runtimeName": "iOS 18.0"
    ]

    return [
        "name": "Test - iOS",
        "actionType": "TEST",
        "scheme": scheme,
        "platform": "IOS",
        "isRequiredToPass": true,
        "testConfiguration": [
            "kind": "USE_SCHEME_SETTINGS",
            "testDestinations": [testDest]
        ] as [String: Any]
    ]
```

### Step 5: Add CLI Flags (Optional Enhancement)
```swift
@Option(name: .long, help: "Test device name (e.g., 'iPhone 17 Pro Max')")
var testDeviceName: String?

@Option(name: .long, help: "Test runtime name (e.g., 'iOS 18.0')")
var testRuntimeName: String?
```

### Step 6: Test Complete TEST Workflow Creation
```bash
# Test PR workflow with TEST action
./.build/arm64-apple-macosx/release/xcodecloud-cli create-workflow \
  --product B6CFF695-FAF8-4D64-9C16-8F46A73F76EF \
  --name "PR Validation" \
  --description "Fast tests for pull requests" \
  --type pr \
  --scheme Nestory-Pro \
  --action test

# Verify in Xcode Cloud UI
```

## Alternative: Hardcode Known Values

If creating a golden workflow is not possible right now, we can:
1. Hardcode the expected test destination structure (based on plan)
2. Test if it works with the API
3. Adjust based on API feedback

**Pros**: Can make progress immediately
**Cons**: May require trial-and-error if structure is incorrect

## Files Modified Today

- `main.swift` lines 394-415: Added `ListTestDestinations` command
- `main.swift` line 27: Registered `ListTestDestinations` in subcommands
- `main.swift` lines 830-833: Added `testConfiguration` with empty array (confirmed rejected)
- `TROUBLESHOOTING.md`: Added section on test destinations error
- `TEST-DESTINATION-FINDINGS.md`: Comprehensive research document (new)
- `NEXT-STEPS.md`: This file (new)

## Summary

**What works**: 90% of CLI functionality (ARCHIVE, ANALYZE, listing, triggering, status)

**What's blocked**: TEST action workflows (need valid test destination structure)

**What's needed**: Golden workflow JSON from Xcode Cloud UI

**Estimated time to complete**: 1-2 hours after receiving golden workflow structure

---

**Action Required**: Create golden TEST workflow in Xcode Cloud UI and provide workflow ID or JSON.
