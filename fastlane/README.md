fastlane documentation
----

# Signing & Authentication

This project uses **Xcode Automatic Signing** with **App Store Connect API Keys** for CI/CD.

> **Note**: Match (certificate sync) is NOT used. Xcode manages signing certificates automatically.

## Setup Requirements

1. **App Store Connect API Key** (for TestFlight/App Store uploads):
   - Generate at: https://appstoreconnect.apple.com/access/api
   - Save the .p8 file to `fastlane/AuthKey_<KEY_ID>.p8`
   - Create `fastlane/.env` from `.env.example` with your credentials

2. **Xcode Signing**:
   - Open Xcode > Signing & Capabilities
   - Enable "Automatically manage signing"
   - Select your team

## Environment Variables

Copy `fastlane/.env.example` to `fastlane/.env` and fill in:
- `APP_STORE_CONNECT_KEY_ID` - Your API key ID
- `APP_STORE_CONNECT_ISSUER_ID` - Your issuer ID
- `APP_STORE_CONNECT_API_KEY_PATH` - Path to .p8 file

## GitHub Actions Secrets

For CI/CD, set these repository secrets:
- `APP_STORE_CONNECT_KEY_ID`
- `APP_STORE_CONNECT_ISSUER_ID`
- `APP_STORE_CONNECT_API_KEY_CONTENT` - Base64-encoded .p8 file content

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios test

```sh
[bundle exec] fastlane ios test
```

Run all tests (unit + UI) on simulator

### ios test_unit

```sh
[bundle exec] fastlane ios test_unit
```

Run unit tests only (faster, for CI)

### ios beta

```sh
[bundle exec] fastlane ios beta
```

Build and upload to TestFlight

### ios release

```sh
[bundle exec] fastlane ios release
```

Build and submit to App Store (manual gating: submit_for_review is false)

### ios bump_version

```sh
[bundle exec] fastlane ios bump_version
```

Bump version (patch/minor/major)

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
