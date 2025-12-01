# Test Destinations Research - December 1, 2025

## ✅ RESOLVED - TEST Workflows Now Fully Supported!

### Key Discovery

**The solution was to use `runtimeIdentifier: "default"`** instead of specific iOS version identifiers like `com.apple.CoreSimulator.SimRuntime.iOS-18-1`.

## Research Journey

### 1. `/v1/ciTestDestinations` Endpoint Does Not Exist
- Attempted to list test destinations via API
- Received HTTP 404: Path provided does not match a defined resource type
- **Conclusion**: Test destinations are not available as a standalone API resource

### 2. Empty `testDestinations` Arrays Are Rejected

**Attempted payload:**
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
HTTP 409: [ENTITY_ERROR.ATTRIBUTE.REQUIRED] You must provide a value for the attribute 'actions/testConfig/testDestinations'
```

**Conclusion**: The `testDestinations` array must contain at least one valid `CiTestDestination` object.

### 3. Golden Workflow Approach (THE SOLUTION!)

Created TEST workflow manually in Xcode Cloud UI, then fetched via CLI:
```bash
./.build/arm64-apple-macosx/release/xcodecloud-cli get-workflow \
  --workflow D1323261-315A-4EAA-B614-83C65D39A3F5 > golden-test-workflow.json
```

Discovered the correct `CiTestDestination` structure from the golden workflow:
```json
{
  "kind": "SIMULATOR",
  "deviceTypeIdentifier": "com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro-Max",
  "deviceTypeName": "iPhone 17 Pro Max",
  "runtimeIdentifier": "default",
  "runtimeName": "Latest from Selected Xcode (iOS 26.1)"
}
```

### 4. Critical Insight: Use "default" Runtime Identifier

**❌ Wrong (tried and failed):**
```swift
"runtimeIdentifier": "com.apple.CoreSimulator.SimRuntime.iOS-18-0"
// Error: HTTP 409: Invalid runtime: com.apple.CoreSimulator.SimRuntime.iOS-18-0

"runtimeIdentifier": "com.apple.CoreSimulator.SimRuntime.iOS-18-1"
// Error: HTTP 409: Invalid runtime: com.apple.CoreSimulator.SimRuntime.iOS-18-1
```

**✅ Correct (from golden workflow):**
```swift
"runtimeIdentifier": "default"
// Means: "Use latest Xcode version"
```

## Final Working Implementation

**Location:** `main.swift` lines 823-844

```swift
case .test:
    let testDestination: [String: Any] = [
        "kind": "SIMULATOR",
        "deviceTypeIdentifier": "com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro-Max",
        "deviceTypeName": "iPhone 17 Pro Max",
        "runtimeIdentifier": "default",
        "runtimeName": "Latest from Selected Xcode (iOS 26.1)"
    ]

    return [
        "name": "Test - iOS",
        "actionType": "TEST",
        "scheme": scheme,
        "platform": "IOS",
        "isRequiredToPass": true,
        "testConfiguration": [
            "kind": "USE_SCHEME_SETTINGS",
            "testDestinations": [testDestination]
        ] as [String: Any]
    ]
```

## Verified Success

Successfully created TEST workflow via CLI:
```bash
✅ Workflow 'PR Validation - CLI TEST' created successfully!
Workflow ID: b5c8d9dd-5499-46ba-9b3a-8531d41e718c
```

## Status

- ✅ ListTestDestinations command added (endpoint doesn't exist, but structure ready for future)
- ✅ Confirmed empty testDestinations arrays are rejected
- ✅ Golden workflow created and inspected
- ✅ Correct CiTestDestination structure implemented
- ✅ TEST workflow creation fully working via CLI!

## Files Modified

- `main.swift` lines 823-844: Implemented correct test destination structure
- `main.swift` lines 394-415: Added ListTestDestinations command
- `main.swift` line 27: Registered ListTestDestinations in subcommands

---

**Last Updated:** December 1, 2025
**Status:** ✅ COMPLETE - TEST workflows fully supported via CLI
