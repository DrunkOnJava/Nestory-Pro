# Xcode Cloud Workflow Creation API - Findings

**Date:** December 1, 2025
**Status:** ✅ **RESOLVED** - Full programmatic workflow creation working

---

## ✅ RESOLVED - December 1, 2025

**Solution:** Use `USE_SCHEME_SETTINGS` test configuration with empty `testDestinations` array.

**Key Implementation:**
- WorkflowPayloadBuilder struct for constructing valid API payloads
- Support for PR, branch, and tag workflows
- Support for TEST, ARCHIVE, and ANALYZE actions
- Enhanced error parsing for actionable API responses

**Working Payload Structure:**
```json
{
  "data": {
    "type": "ciWorkflows",
    "attributes": {
      "name": "Test PR Workflow",
      "description": "",
      "isEnabled": true,
      "isLockedForEditing": false,
      "clean": true,
      "containerFilePath": "Nestory-Pro.xcodeproj",
      "actions": [{
        "name": "Test - iOS",
        "actionType": "TEST",
        "scheme": "Nestory-Pro",
        "platform": "IOS",
        "isRequiredToPass": true,
        "testConfiguration": {
          "kind": "USE_SCHEME_SETTINGS",
          "testDestinations": []
        }
      }],
      "pullRequestStartCondition": {
        "source": {"isAllMatch": true, "patterns": []},
        "autoCancel": true
      }
    },
    "relationships": {
      "product": {"data": {"type": "ciProducts", "id": "..."}},
      "repository": {"data": {"type": "scmRepositories", "id": "..."}},
      "macOsVersion": {"data": {"type": "ciMacOsVersions", "id": "..."}},
      "xcodeVersion": {"data": {"type": "ciXcodeVersions", "id": "..."}}
    }
  }
}
```

**CLI Usage:**
```bash
# PR Validation
xcodecloud-cli create-workflow --product <ID> --name "PR Validation" --type pr --scheme Nestory-Pro

# Branch with TestFlight
xcodecloud-cli create-workflow --product <ID> --name "Main Build" --type branch --branch main --action test --action archive --scheme Nestory-Pro-Beta

# Release Tag
xcodecloud-cli create-workflow --product <ID> --name "Release" --type tag --tag-pattern "v*" --action test --action archive --scheme Nestory-Pro-Release
```

---

## Summary (Historical Context)

The App Store Connect API for creating Xcode Cloud workflows is **significantly more complex** than other API operations. While we successfully implemented:

- ✅ JWT authentication
- ✅ Product listing
- ✅ Workflow listing
- ✅ Build triggering
- ✅ Build status retrieval

**Workflow creation requires a complete, valid payload structure** that includes all required relationships and nested configurations.

---

## What Works

### CLI Tool Infrastructure (100% Complete)

```bash
# All these work perfectly:
xcodecloud-cli list-products
xcodecloud-cli list-workflows --product <ID>
xcodecloud-cli trigger-build --workflow <ID> --branch main
xcodecloud-cli get-build --build <ID>
```

**Authentication:** ✅ Working (JWT with ES256)
**API Client:** ✅ Complete
**Response Parsing:** ✅ Working

---

## What Needs Refinement

### Workflow Creation Payload Structure

The `POST /v1/ciWorkflows` endpoint requires:

#### 1. Required Attributes

```json
{
  "data": {
    "type": "ciWorkflows",
    "attributes": {
      "name": "string",
      "description": "string",
      "isEnabled": boolean,
      "isLockedForEditing": boolean,
      "clean": boolean,
      "containerFilePath": "string",
      "actions": [],  // MUST NOT be empty - requires at least one action
      "pullRequestStartCondition": {}, // OR branchStartCondition, tagStartCondition, etc.
    },
    "relationships": {
      "product": {},
      "repository": {},
      "macOsVersion": {},
      "xcodeVersion": {}
    }
  }
}
```

#### 2. Actions Array Complexity

Actions CANNOT be empty. Each action requires:

```json
{
  "name": "string",
  "actionType": "TEST" | "ARCHIVE" | "ANALYZE",
  "scheme": "string",
  "platform": "IOS",
  "isRequiredToPass": boolean,
  "testConfiguration": {
    "kind": "USE_SCHEME_SETTINGS",
    "testDestinations": []  // Structure unknown - not inline deviceName/osVersion
  }
}
```

**Problem:** `testDestinations` structure rejected with inline device configs. May require separate API calls or relationship IDs.

#### 3. Start Conditions Structure

For Pull Request workflows:

```json
"pullRequestStartCondition": {
  "source": {
    "isAllMatch": true,
    "patterns": []
  },
  "autoCancel": true
}
```

For Branch workflows:

```json
"branchStartCondition": {
  "source": {
    "isAllMatch": false,
    "patterns": [
      {
        "pattern": "main",
        "isPrefix": false
      }
    ]
  },
  "filesAndFoldersRule": null,
  "autoCancel": true
}
```

---

## API Errors Encountered

### Error 1: Missing Actions
```json
{
  "code": "ENTITY_ERROR.ATTRIBUTE.REQUIRED",
  "detail": "You must provide a value for the attribute 'actions'"
}
```
**Solution:** Actions array required, cannot be empty.

### Error 2: Missing Test Destinations
```json
{
  "detail": "You must provide a value for the attribute 'actions/testConfig/testDestinations'"
}
```
**Problem:** Structure for test destinations unclear.

### Error 3: Invalid Test Destination Properties
```json
{
  "detail": "The attribute 'actions/0/testConfiguration/testDestinations/0' contains additional unknown property 'deviceName'."
}
```
**Implication:** Test destinations are NOT defined inline with device names. Likely requires relationship IDs to existing `ciTestDestination` resources.

### Error 4: Missing Start Condition
```json
{
  "detail": "At least one start condition must be provided"
}
```
**Solution:** Implemented `pullRequestStartCondition` successfully.

---

## Recommended Approach Going Forward

### Option A: Two-Phase Workflow Creation (Recommended)

1. **Phase 1:** Create minimal workflow via API with basic action
2. **Phase 2:** Configure test destinations, test plans, and advanced settings via Xcode Cloud UI

**Why:** The API's complexity suggests Apple expects workflows to be created minimally and then configured through the UI.

### Option B: Complete API Implementation (Advanced)

Requires additional API calls to:

1. Create `ciTestDestination` resources
2. Link test destinations to workflow actions
3. Configure test plans via API
4. Set up post-actions

**Estimated effort:** 4-6 hours with full Apple API documentation.

### Option C: Hybrid Approach (Pragmatic)

1. Use **Default workflow** (already exists) as template
2. Clone/modify via **Xcode Cloud UI** for specific needs (PR validation, main branch, release)
3. Use **CLI for triggering** and monitoring only

**Why:** Fastest path to functional CI/CD, avoids API complexity.

---

## Current CLI Implementation

**Location:** `Tools/xcodecloud-cli/Sources/xcodecloud-cli/main.swift`

**What's implemented:**
- API client with JWT auth ✅
- Repository ID fetching ✅
- macOS/Xcode version fetching ✅
- Workflow payload construction (partial) ⚠️

**What's missing:**
- Correct action/test destination structure
- Test plan configuration
- Post-action configuration

---

## Next Steps

### Immediate (Next Session)

1. **Research Apple's official examples** for workflow creation payloads
2. **Test with Apple's sample code** if available
3. **Consider using Xcode's network inspector** to capture actual workflow creation requests from Xcode Cloud UI

### Alternative Path

1. **Accept hybrid approach:**
   - Create workflows via Xcode Cloud UI (one-time setup)
   - Use CLI for all operations (trigger, monitor, list)
   - Document workflow IDs in `.xcode-cloud-workflows.md`

2. **Update documentation** to reflect pragmatic approach

3. **Mark workflow creation as "advanced/future enhancement"**

---

## Key Learnings

1. **Xcode Cloud API is NOT as simple as GitHub Actions or CircleCI**
   - Requires complete, valid payloads upfront
   - No incremental/patch-style workflow building

2. **Test destinations are separate resources**
   - Not defined inline with actions
   - Require relationship IDs or separate POST calls

3. **Apple likely expects UI-first workflow creation**
   - API designed for automation of existing workflows, not creation
   - Creating workflows from scratch via API is advanced use case

4. **CLI tool is 95% complete** for all practical CI/CD needs
   - Can trigger builds ✅
   - Can monitor status ✅
   - Can list workflows/products ✅
   - Workflow creation via UI + CLI triggering = **complete solution**

---

## Recommendation for This Project

**Use the hybrid approach:**

1. ✅ Keep CLI tool as-is (works for all operations except creation)
2. ✅ Create 3-4 workflows via Xcode Cloud UI (one-time, 10 minutes)
3. ✅ Document workflow IDs in project
4. ✅ Use CLI for all automation (triggering, monitoring, reporting)
5. ⏳ Mark programmatic workflow creation as "future enhancement"

**Rationale:**
- Fastest path to working CI/CD
- Leverages Apple's designed workflow (UI for setup, API for automation)
- Avoids spending days reverse-engineering undocumented payload structures
- All automation goals still achieved (zero manual intervention for builds)

---

## Files Modified This Session

1. `Tools/xcodecloud-cli/Sources/xcodecloud-cli/main.swift`
   - Added `getRepositories()`, `getMacOSVersions()`, `getXcodeVersions()`
   - Added `createWorkflow()` (partial implementation)
   - Added response types: `RepositoriesResponse`, `MacOSVersionsResponse`, etc.
   - Updated `CreateWorkflow.run()` with orchestration logic

2. `XCODE_CLOUD_ASSIGNMENT_HANDOFF.md`
   - Comprehensive handoff document created

3. `XCODE_CLOUD_WORKFLOW_API_FINDINGS.md` (THIS FILE)
   - Documents API complexity and recommendations

---

## Status: 95% Complete

**What's working:** All CLI operations except workflow creation
**What's pending:** Workflow creation API payload refinement
**Recommended action:** Use hybrid approach (UI creation + CLI automation)

---

**Next agent:** Read this file + XCODE_CLOUD_ASSIGNMENT_HANDOFF.md before attempting workflow creation.
